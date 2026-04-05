package com.codexlabs.basecraft.ui

import android.annotation.SuppressLint
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.codexlabs.basecraft.R

class WebViewActivity : AppCompatActivity() {

    private lateinit var webView: WebView
    private lateinit var loadingView: ProgressBar
    private var logoView: ImageView? = null

    private var dataString: String = ""
    private var keywords: ArrayList<String> = arrayListOf()
    private var colorString: String = "#FFFFFF"
    private var style: Int = 0
    private var clearCache: Boolean = false
    private var isFull: Boolean = false
    private var isAdjustLayout: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        readIntentData()
        setupOrientation()
        buildContentView()
        setupStatusBarStyle()
        initWebView()
        clearWebViewCacheIfNeeded()
        loadPage()
        setupBackPressed()
    }

    private fun readIntentData() {
        dataString = intent.getStringExtra(EXTRA_URL).orEmpty()
        style = intent.getIntExtra(EXTRA_STYLE, 0)
        colorString = intent.getStringExtra(EXTRA_COLOR).orEmpty().ifBlank { "#FFFFFF" }
        keywords = intent.getStringArrayListExtra(EXTRA_KEYWORDS) ?: arrayListOf()
        clearCache = intent.getBooleanExtra(EXTRA_CLEAR_CACHE, false)
        isFull = intent.getBooleanExtra(EXTRA_IS_FULL, false)
        isAdjustLayout = intent.getIntExtra(EXTRA_ADJUST_LAYOUT, 0)
    }

    private fun setupOrientation() {
        requestedOrientation = if (isFull) {
            ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        } else {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        }
    }

    private fun setupStatusBarStyle() {
        window.statusBarColor = parseColorSafe(colorString)
        ViewCompat.getWindowInsetsController(window.decorView)?.isAppearanceLightStatusBars = style == 0
    }

    private fun buildContentView() {
        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.WHITE)
        }

        webView = WebView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        loadingView = ProgressBar(this).apply {
            isIndeterminate = true
            visibility = View.GONE
        }
        val loadingParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER
        }

        logoView = ImageView(this).apply {
            setImageResource(R.mipmap.ic_launcher_round)
            layoutParams = FrameLayout.LayoutParams(160.dp(), 160.dp(), Gravity.CENTER)
            scaleType = ImageView.ScaleType.FIT_CENTER
        }

        root.addView(webView)
        root.addView(logoView)
        root.addView(loadingView, loadingParams)

        setContentView(root)
        applyAdjustLayout(root)
    }

    private fun applyAdjustLayout(root: View) {
        ViewCompat.setOnApplyWindowInsetsListener(root) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            when (isAdjustLayout) {
                1 -> webView.setPadding(0, 0, 0, systemBars.bottom)
                2 -> webView.setPadding(0, systemBars.top, 0, systemBars.bottom)
                3 -> webView.setPadding(0, 0, 0, 0)
                else -> webView.setPadding(0, systemBars.top, 0, 0)
            }
            insets
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun initWebView() {
        webView.settings.apply {
            javaScriptEnabled = true
            javaScriptCanOpenWindowsAutomatically = false
            loadsImagesAutomatically = true
            domStorageEnabled = true
            databaseEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            mediaPlaybackRequiresUserGesture = false
            cacheMode = WebSettings.LOAD_DEFAULT
            useWideViewPort = true
            loadWithOverviewMode = true
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            setSupportMultipleWindows(false)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                safeBrowsingEnabled = true
            }
        }
        WebView.setWebContentsDebuggingEnabled(false)
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, false)

        webView.setBackgroundColor(parseColorSafe(colorString))
        webView.isHorizontalScrollBarEnabled = false
        webView.isVerticalScrollBarEnabled = false

        webView.webChromeClient = WebChromeClient()
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView?,
                request: WebResourceRequest?
            ): Boolean {
                val url = request?.url?.toString() ?: return false
                if (keywords.any { url.contains(it, ignoreCase = true) }) {
                    openExternalUrl(url)
                    return true
                }
                if (url.startsWith("http://") || url.startsWith("https://")) {
                    return false
                }
                if (!url.startsWith("about:")) {
                    openExternalUrl(url)
                    return true
                }
                return false
            }

            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                loadingView.visibility = View.GONE
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                loadingView.visibility = View.GONE
                logoView?.visibility = View.GONE
            }

            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest?,
                error: android.webkit.WebResourceError?
            ) {
                if (request?.isForMainFrame == true) {
                    loadingView.visibility = View.GONE
                    logoView?.visibility = View.GONE
                    Toast.makeText(
                        this@WebViewActivity,
                        "Network error, please try again",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

    private fun clearWebViewCacheIfNeeded() {
        if (!clearCache) return
        webView.clearCache(true)
        webView.clearHistory()
        webView.clearFormData()
        android.webkit.CookieManager.getInstance().removeAllCookies(null)
        android.webkit.CookieManager.getInstance().flush()
    }

    private fun loadPage() {
        if (dataString.isBlank()) {
            Toast.makeText(this, "URL is empty", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        if (dataString.startsWith("http://") || dataString.startsWith("https://")) {
            webView.loadUrl(dataString)
        } else {
            Toast.makeText(this, "Invalid URL", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    private fun setupBackPressed() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (webView.canGoBack()) {
                    webView.goBack()
                } else {
                    finish()
                }
            }
        })
    }

    private fun openExternalUrl(url: String) {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        } catch (_: ActivityNotFoundException) {
            Toast.makeText(this, "Cannot open link", Toast.LENGTH_SHORT).show()
        }
    }

    private fun parseColorSafe(color: String?): Int {
        return try {
            Color.parseColor(if (color.isNullOrBlank()) "#FFFFFF" else color)
        } catch (_: Exception) {
            Color.WHITE
        }
    }

    private fun Int.dp(): Int = (this * resources.displayMetrics.density).toInt()

    override fun onDestroy() {
        webView.apply {
            loadUrl("about:blank")
            stopLoading()
            clearHistory()
            removeAllViews()
            destroy()
        }
        super.onDestroy()
    }

    companion object {
        const val EXTRA_URL = "extra_url"
        const val EXTRA_STYLE = "extra_style"
        const val EXTRA_COLOR = "extra_color"
        const val EXTRA_KEYWORDS = "extra_keywords"
        const val EXTRA_CLEAR_CACHE = "extra_clear_cache"
        const val EXTRA_IS_FULL = "extra_is_full"
        const val EXTRA_ADJUST_LAYOUT = "extra_adjust_layout"

        fun start(context: Context, decision: StartupDecision) {
            val intent = Intent(context, WebViewActivity::class.java).apply {
                putExtra(EXTRA_URL, decision.data)
                putExtra(EXTRA_STYLE, decision.style)
                putExtra(EXTRA_COLOR, decision.color)
                putStringArrayListExtra(EXTRA_KEYWORDS, ArrayList(decision.keywords))
                putExtra(EXTRA_CLEAR_CACHE, decision.clearCache)
                putExtra(EXTRA_IS_FULL, decision.isFull)
                putExtra(EXTRA_ADJUST_LAYOUT, decision.adjustLayout)
            }
            context.startActivity(intent)
            if (context is Activity) {
                context.overridePendingTransition(0, 0)
            }
        }
    }
}
