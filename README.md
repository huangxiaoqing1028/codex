# Base Converter Apps (iOS + Android)

This repository now includes:

- `OCBaseConverter/` (Objective-C iOS app)
- `AndroidBaseConverter/` (Kotlin Android app for Google Play)

## Android (Google Play Ready Baseline)

### Run directly
1. Open `AndroidBaseConverter` with Android Studio (Giraffe+ recommended).
2. Let Gradle sync.
3. Run `app` on emulator or physical Android device.

### Core features
- Premium dark gradient UI (English copy).
- Binary / Octal / Decimal / Hex conversion.
- Swap From/To bases and clear input.
- Dedicated result page.
- One-tap result copy to clipboard.
- Back button on result page.

### For Play Store release
- Replace launcher icon.
- Add privacy policy URL and app listing assets.
- Enable release signing and create AAB from `Build > Generate Signed Bundle / APK`.
