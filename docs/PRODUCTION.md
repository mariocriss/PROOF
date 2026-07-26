# PROOF Production Readiness

Last updated: July 2026

## Launch model (current)

PROOF launches on the **Firebase free (Spark) plan** with:

- Firebase Auth
- Cloud Firestore
- Firebase Crashlytics (release)
- **No** Firebase Storage, Analytics, or FCM in this build

Set feature flags in `lib/core/constants/app_features.dart` and URLs in
`lib/core/constants/app_urls.dart`.

**Do not** use third-party `proof.app` URLs. Leave `AppUrls` null until you own
a domain.

---

## Docs for store / legal / closed testing

| Doc | Purpose |
|---|---|
| [`docs/DATA_INVENTORY.md`](DATA_INVENTORY.md) | Factual data map for Privacy Policy + Play Data safety |
| [`docs/ACCOUNT_DELETION.md`](ACCOUNT_DELETION.md) | Deletion behavior |
| [`docs/ANDROID_SIGNING.md`](ANDROID_SIGNING.md) | Keystore + Play App Signing |
| [`docs/SIGNING_PREUPLOAD_CHECKLIST.md`](SIGNING_PREUPLOAD_CHECKLIST.md) | Pre-upload signing checks |
| [`docs/LAUNCH_URLS_CHECKLIST.md`](LAUNCH_URLS_CHECKLIST.md) | Values to set in `AppUrls` |
| [`docs/FIREBASE_DEPLOYMENT.md`](FIREBASE_DEPLOYMENT.md) | Rules/indexes deploy verification |
| [`docs/BUNDLE_SIZE_AUDIT.md`](BUNDLE_SIZE_AUDIT.md) | ~65 MB AAB breakdown |
| [`docs/CLOSED_TESTING_PLAN.md`](CLOSED_TESTING_PLAN.md) | Device smoke tests |
| [`docs/PLAY_CONSOLE_CHECKLIST.md`](PLAY_CONSOLE_CHECKLIST.md) | Console tasks by owner type |
| [`docs/CLOSED_TEST_FEEDBACK.md`](CLOSED_TEST_FEEDBACK.md) | Tester feedback + log |
| [`docs/LAUNCHER_ICONS.md`](LAUNCHER_ICONS.md) | Icon asset requirements |
| [`docs/MERGED_MANIFEST_PERMISSIONS.md`](MERGED_MANIFEST_PERMISSIONS.md) | Permission audit |

---

## Completed in codebase (launch blockers addressed in-app)

### URLs & passport
- [x] Central `AppUrls` configuration (all null until you supply owned HTTPS URLs)
- [x] Public web passport / QR / share links disabled while passport base URL unset
- [x] PDF export remains available as an offline snapshot

### Legal (draft only — not legal approval)
- [x] In-app Privacy/Terms drafts aligned to Auth, Firestore, Crashlytics, no messaging/Storage/Analytics
- [x] Visible hosted-URL placeholders in legal screens
- [x] Data inventory document for counsel / Play Console

### Signing
- [x] Release builds fail clearly without `android/key.properties` (no debug fallback)
- [x] `key.properties` / `.jks` / `.keystore` gitignored

### Icons
- [x] Flutter default logo replaced with temporary adaptive + legacy placeholders
- [x] Final asset checklist under `branding/launcher/`

### Incomplete UI hidden
- [x] Notification settings removed (no FCM)
- [x] Empty Membership Settings row removed
- [x] Coach invite copy is honest (search by gym handle; no “coming soon” fake flow)

### Security / account
- [x] Account deletion with reauth; Auth deleted only after Firestore cleanup
- [x] Firestore rules + tests for deletion anonymization

---

## You must still provide / do

1. **Owned domain** + hosted Privacy Policy, Terms, optional account-deletion page, support email → set in `AppUrls`
2. **Legal review** of hosted documents (in-app drafts are not approval)
3. **Upload keystore** locally (`docs/ANDROID_SIGNING.md`) + Play App Signing
4. **Final launcher art** (`docs/LAUNCHER_ICONS.md`)
5. Publish `firestore.rules` + indexes
6. Complete Play Console Data safety using `docs/DATA_INVENTORY.md`
7. Closed testing on real devices

---

## Manual steps before store submission

### Firebase Console
1. Publish `firestore.rules` and `firestore.indexes.json`
2. Enable Email/Password auth
3. Enable Crashlytics after first release build

### Legal (hosted pages required for production listing)
1. Host Privacy Policy and Terms on **your** domain
2. Set URLs in `lib/core/constants/app_urls.dart`
3. Optionally enable public passport base URL when a web passport exists

### Android release
1. Copy `android/key.properties.example` → `android/key.properties`
2. Generate upload keystore (see `docs/ANDROID_SIGNING.md`)
3. `flutter build appbundle --release`
4. Upload to Play Console

---

## Remaining launch tasks

### Must-have (owner actions)
- [ ] Host Privacy Policy and Terms on an owned domain; configure `AppUrls`
- [ ] Generate Android upload keystore and first Play Console upload
- [ ] Deploy Firestore indexes and rules to production
- [ ] Replace placeholder launcher icons with approved brand art
- [ ] Test full account deletion on a real device
- [ ] Test password reset and email verification end-to-end
- [ ] Complete Play Data safety form

### Should-have
- [ ] Firebase App Check
- [ ] Staging Firebase project
- [ ] FCM push notifications (then restore settings UI)
- [ ] Public passport web + deep links (then set `publicPassportBaseUrl`)
- [ ] Data export (GDPR)

### Deferred (paid Firebase / Storage)
- [ ] Firebase Storage rules + avatar / proof / gym logo uploads
