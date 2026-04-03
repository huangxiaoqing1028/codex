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
                .url(REMOTE_CONFIG_URL)
                .get()
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return null
                val body = response.body?.string().orEmpty()
                if (body.isBlank()) return null

                val json = JSONObject(body)
                val flag = json.optBoolean("flag", false)
                val link = json.optString("link", "")
                StartupDecision(flag, link)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun routeToNext(decision: StartupDecision) {
        val intent = if (decision.flag && decision.link.isNotBlank()) {
            Intent(this, WebViewActivity::class.java)
                .putExtra(WebViewActivity.EXTRA_URL, decision.link)
        } else {
            Intent(this, MainActivity::class.java)
        }
        startActivity(intent)
        finish()
    }

    companion object {
        // Replace with your real endpoint.
        private const val REMOTE_CONFIG_URL = "https://example.com/startup-config"
        private const val MAX_RETRY_COUNT = 5
        private const val RETRY_INTERVAL_MS = 1_500L
    }
}

data class StartupDecision(
    val flag: Boolean,
    val link: String
)
