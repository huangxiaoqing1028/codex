# BaseFlow App Store Release Checklist

This project now contains a complete, production-style iOS app structure:

- `AppDelegate` is kept lean and only configures app bootstrap.
- `BaseConverterViewController` owns premium UI and conversion logic.
- English-only UX copy across the product surface.
- Input sanitization and user-facing validation feedback.

## Before shipping to App Store Connect

1. Update bundle ID from `com.example.ObfDemo` to your real reverse-domain ID.
2. Configure signing team and provisioning profile in Xcode.
3. Add App Icons (all required sizes in Asset Catalog).
4. Add Launch Screen assets.
5. Run on real device and complete TestFlight beta pass.
6. Add privacy manifest / nutrition answers in App Store Connect.
7. Bump version and build number.
8. Archive and validate from Xcode Organizer.

## Suggested next upgrades

- Add iPad split layout optimization.
- Add localization scaffolding if non-English languages are planned.
- Add snapshot/UI tests for conversion matrix.
- Add analytics + crash reporting SDK (if needed).
