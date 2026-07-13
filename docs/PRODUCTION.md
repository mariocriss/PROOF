# PROOF Production Readiness

Last updated: July 2026

## Launch model (current)

PROOF launches on the **Firebase free (Spark) plan** with:

- Firebase Auth
- Cloud Firestore
- **No Firebase Storage** (photo uploads deferred)

Set `AppFeatures.cloudStorageEnabled = false` in `lib/core/constants/app_features.dart` until Storage is enabled.

---

## Completed in codebase

### Security
- [x] Firestore rules hardened (handle ownership, gym handle ownership, relationship field immutability)
- [x] `userReports` collection with create/read rules
- [x] Firestore rules unit tests for relationships
- [x] Participant-scoped relationship queries (no unsafe `whereIn`)

### Auth & account
- [x] Password reset (`Forgot password?` on login)
- [x] Email verification sent on registration + resend from Account
- [x] Account deletion with password re-authentication
- [x] Complete Firestore cleanup: relationships, verification requests, user reports, public profile, skills, proofs, timeline, handles, gym data

### Privacy & legal
- [x] Terms acceptance checkbox at registration
- [x] In-app Privacy Policy and Terms screens + external links
- [x] Privacy settings screen (`isPublic` / discoverability toggle)
- [x] Links from Account and Settings

### Trust & safety
- [x] Report user from any profile (not only friends)
- [x] Block user (existing)

### Storage-free launch
- [x] Removed `firebase_storage` dependency
- [x] Proof media upload disabled with user-facing message
- [x] Avatar/gym logo uploads skipped until Storage is enabled

### Operations
- [x] Firebase Crashlytics wired in `main.dart` (release builds only)
- [x] CI: `flutter test` + Firestore rules tests

### Android release preparation
- [x] Release signing scaffold (`key.properties.example` + conditional signing in Gradle)
- [x] App display name set to `PROOF`

---

## Manual steps before store submission

### Firebase Console
1. Publish `firestore.rules` and `firestore.indexes.json`
2. Enable **Email/Password** auth (already used)
3. Enable **Crashlytics** in Firebase Console after first release build
4. Optional: enable **App Check** when ready

### Legal (hosted pages required)
1. Publish Privacy Policy at `https://proof.app/privacy`
2. Publish Terms of Service at `https://proof.app/terms`
3. Update URLs in `lib/core/constants/legal_constants.dart` if domains differ

### Android release
1. Copy `android/key.properties.example` to `android/key.properties`
2. Generate upload keystore
3. Build: `flutter build appbundle --release`
4. Upload to Google Play Console

---

## Remaining launch tasks

### Must-have
- [ ] Host Privacy Policy and Terms at live URLs
- [ ] Generate Android release keystore and first Play Console upload
- [ ] Deploy Firestore indexes to production
- [ ] Publish updated Firestore rules (includes `userReports`)
- [ ] Test full account deletion on a real device
- [ ] Test password reset and email verification end-to-end

### Should-have
- [ ] Firebase App Check
- [ ] Staging Firebase project separate from production
- [ ] Push notifications (FCM)
- [ ] Public passport web page or deep links for `proof.app/passport/{handle}`
- [ ] Data export (GDPR)

### Deferred (requires paid Firebase / Storage)
- [ ] Firebase Storage rules + avatar uploads
- [ ] Proof photo attachments
- [ ] Gym logo uploads
