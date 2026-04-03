# Base Converter Apps (iOS + Android)

This repository now includes:

- `OCBaseConverter/` (Objective-C iOS app)
- `AndroidBaseConverter/` (Kotlin Android app for Google Play)

## Android (Google Play Ready Baseline)

### Run directly
1. Open `AndroidBaseConverter` with Android Studio (Giraffe+ recommended).
2. Let Gradle sync.
3. Run `app` on emulator or physical Android device.

> Toolchain pin: AGP **8.1.1** + Gradle **8.0** for Android Studio compatibility.

### Core features
- Premium dark gradient UI (English copy).
- Binary / Octal / Decimal / Hex conversion.
- Swap From/To bases and clear input.
- Dedicated result page.
- One-tap result copy to clipboard.
- Back button on result page.
- Custom blue “p” launcher logo integrated (adaptive icon + in-page logo).

- Splash AB routing with fail-safe: retries startup API up to 5 times (1.5s interval); if still failing, app falls back to native converter to avoid splash lock.
- If API returns `flag=true` with a non-empty `link`, app opens H5 page (WebView).
- Otherwise app enters native base-conversion flow.
- H5 WebView applies system-bars insets to avoid status bar / navigation bar overlap.

### For Play Store release
- Replace launcher icon.
- Add privacy policy URL and app listing assets.
- Enable release signing and create AAB from `Build > Generate Signed Bundle / APK`.


## Startup API response format
```json
{
  "flag": true,
  "link": "https://your-h5-url.com"
}
```

`REMOTE_CONFIG_URL` is in `SplashActivity.kt`.