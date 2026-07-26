# Firebase Android app — com.proofapp.mobile

The Play Console app package is **`com.proofapp.mobile`**.
Do **not** reuse the old Firebase Android app registered as `com.proof.proof`.

`android/app/google-services.json` is intentionally absent until you register
the new Android app and run FlutterFire.

## Firebase Console steps

1. Open [Firebase Console](https://console.firebase.google.com/) → project **`proof-e913a`**.
2. Project settings (gear) → **Your apps**.
3. **Add app** → **Android**.
4. Android package name: **`com.proofapp.mobile`** (must match exactly).
5. App nickname (optional): `PROOF Android`.
6. Debug signing certificate SHA-1: optional for closed testing with email/password Auth; add later if you enable Google Sign-In.
7. Register the app.
8. Download **`google-services.json`**.
9. Place it at:
   `android/app/google-services.json`
10. Confirm the file’s `client_info.android_client_info.package_name` is `com.proofapp.mobile`.

## Regenerate FlutterFire config

From the repo root (`C:\Users\mario\PROOF`):

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=proof-e913a
```

When prompted:
- Select project **`proof-e913a`**
- Select the **new** Android app (`com.proofapp.mobile`)
- Keep the existing iOS app if offered (`com.proof.proof`)

This rewrites:
- `android/app/google-services.json`
- `lib/firebase_options.dart`
- `firebase.json` Flutter platform metadata

## After configure

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Do not build a Play upload AAB until `google-services.json` and
`firebase_options.dart` include `com.proofapp.mobile`.
