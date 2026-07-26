# Android release signing

Last updated: July 2026

## Goals

- Debug builds keep working without a keystore.
- Release / Play uploads **never** fall back to the debug key.
- Private keys and passwords stay off Git.

## Files (local only)

| File | Purpose |
|---|---|
| `android/key.properties` | Paths + passwords for the upload key (gitignored) |
| `*.jks` / `*.keystore` | Keystore binary (gitignored; store **outside** the repo) |
| `android/key.properties.example` | Template committed to the repo |

## Create a permanent upload keystore (Windows PowerShell)

Run on a secure machine. **Choose your own passwords** — do not paste them into chat, docs, or Git.

Suggested keystore location (outside the PROOF Git repo):

`C:\Users\mario\proof-signing\proof-upload.jks`

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\proof-signing" | Out-Null

keytool -genkeypair -v `
  -keystore "$env:USERPROFILE\proof-signing\proof-upload.jks" `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias proof-upload
```

`keytool` will prompt you for:

1. **Keystore password (`storePassword`)** — you invent this; protect it in a password manager.
2. **Key password (`keyPassword`)** — you invent this (may match the keystore password if you choose); protect it the same way.
3. Distinguished-name fields (name, org, city, etc.) — enter your real operator details.

Do **not** commit the `.jks` file. Back it up offline with the passwords.

## Configure `android/key.properties`

```powershell
Copy-Item android\key.properties.example android\key.properties
```

Edit `android\key.properties` locally (placeholders only in the example):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=proof-upload
storeFile=C:/Users/mario/proof-signing/proof-upload.jks
```

`storeFile` is resolved via Gradle from the `android/` project. Prefer the absolute Windows path with **forward slashes** as above.

## Build a signed release AAB

```powershell
flutter build appbundle --release
```

Output:

`build\app\outputs\bundle\release\app-release.aab`

If `android/key.properties` is missing, the Gradle release tasks fail with an explicit error (they do **not** sign with debug).

## Verify signature (not debug)

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe" -verify -verbose -certs build\app\outputs\bundle\release\app-release.aab
```

Confirm the certificate is **not** an Android Debug certificate and matches your upload key CN/O.

## Backup

- Store the `.jks` / `.keystore` and the passwords in a secure password manager / offline backup.
- Losing the upload key complicates Play updates (Google offers an upload-key reset process when Play App Signing is enrolled).

## Play App Signing

1. Create / use the app in Play Console (`com.proofapp.mobile`).
2. Enroll in **Play App Signing**.
3. Upload the AAB signed with your **upload** key (`proof-upload`).
4. Google holds the **app signing** key used for device distribution; your upload key is only for Console uploads.

## Pre-upload

Follow [`SIGNING_PREUPLOAD_CHECKLIST.md`](SIGNING_PREUPLOAD_CHECKLIST.md) before every Play upload.
