# Android release signing — pre-upload checklist

Last updated: July 2026

Companion to this doc: setup instructions in [`ANDROID_SIGNING.md`](ANDROID_SIGNING.md).

## Repository guarantees (already implemented)

- [x] Release tasks **fail** if `android/key.properties` is missing (no debug-key fallback).
- [x] `android/key.properties`, `*.jks`, `*.keystore` are **gitignored**.
- [x] Example file uses placeholders only (`YOUR_STORE_PASSWORD` / `YOUR_KEY_PASSWORD`; alias `proof-upload`).
- [x] Version comes from `pubspec.yaml` (`version: 1.0.0+1` → name `1.0.0`, code `1`).
- [x] Recommended first closed-testing upload: keep `1.0.0+1` unless Play already rejected/used that code.

## Pre-upload checklist (owner)

### Secrets hygiene

- [ ] `android/key.properties` exists **only** on the build machine / CI secret store
- [ ] Keystore file is **not** under Git (`git status` clean of `.jks` / `.keystore`)
- [ ] Passwords are **not** pasted into chat, screenshots, or docs
- [ ] Keystore + passwords backed up in a password manager

### Build

- [ ] Bump version when needed: `version: X.Y.Z+CODE` in `pubspec.yaml` (CODE must increase for every Play upload)
- [ ] `flutter build appbundle --release` succeeds
- [ ] Output: `build/app/outputs/bundle/release/app-release.aab`

### Verify release signing (not debug)

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe" -verify -verbose -certs build\app\outputs\bundle\release\app-release.aab
```

- [ ] Verify reports jar verified
- [ ] Certificate CN/O matches **your upload** key alias `proof-upload` (not “Android Debug”)

### Play App Signing compatibility

- [ ] Play Console → App integrity → Play App Signing **enabled**
- [ ] First upload uses this **upload** keystore
- [ ] Google may re-sign with the app signing key for distribution (expected)

### After upload

- [ ] Play Console shows the new version code
- [ ] Closed testing track selected
- [ ] Retain the same upload key for all future updates

## Failure check (no credentials)

```bash
# With key.properties absent:
flutter build appbundle --release
# Expected: Gradle error “Release signing is not configured…”
```
