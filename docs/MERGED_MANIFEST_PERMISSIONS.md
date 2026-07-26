# Merged release manifest — permission audit

Last updated: July 2026

Source inspected: `build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`
after `flutter build appbundle --release`.

## Permissions present

| Permission | Likely source | Purpose | Required? | Runtime prompt? | Play Data safety / declarations | Remove? |
|---|---|---|---|---|---|---|
| `android.permission.INTERNET` | Flutter / Firebase | Network for Auth, Firestore, Crashlytics | Yes | No (normal) | Declare network use / data collection as applicable | **Keep** |
| `android.permission.ACCESS_NETWORK_STATE` | Firebase / Play services libs | Check connectivity before network calls | Yes for Firebase stack | No | Related to app functionality, not a sensitive runtime permission | **Keep** |
| `com.google.android.providers.gsf.permission.READ_GSERVICES` | Google Play services / Firebase | Legacy GSF access used by Google libraries | Brought by Google deps | No | Usually not listed as a user-facing permission; do not request manually | **Keep** (dependency) |
| `com.proofapp.mobile.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX / Firebase Crashlytics or Play services | Signature permission so dynamic receivers stay not-exported | Framework requirement | No | Internal; not a user permission | **Keep** |

## Permissions **not** present in this release merge

| Expected from deps | Status | Notes |
|---|---|---|
| `CAMERA` / `READ_MEDIA_*` / `READ_EXTERNAL_STORAGE` from `image_picker` | **Not merged** into this release APK | `image_picker` remains a dependency and is called only when `AppFeatures.cloudStorageEnabled` is true (currently false). Newer plugin manifests may omit always-on permissions until used; **re-audit** when Storage is enabled. |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | **Not merged** | Matches “no location permission” launch claim |
| `POST_NOTIFICATIONS` | **Not merged** | Matches no FCM |
| `READ_HEALTH` / Health Connect | **Not merged** | Matches launch claim |

## Recommendation

No permission removals required for this launch configuration. Re-run this audit whenever dependencies change or Storage / camera / notifications are enabled.
