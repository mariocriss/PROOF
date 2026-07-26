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
- [x] Account deletion with password re-authentication (Auth deleted **only after** Firestore cleanup)
- [x] Firestore cleanup covers relationships, verification requests, reporter-owned reports, public profile, skills, proofs, timeline, handles, gym memberships, and owned gyms
- [x] Account deletion rules + orchestration unit tests (see `docs/ACCOUNT_DELETION.md`)

### Account deletion (privacy)

Full map: [`docs/ACCOUNT_DELETION.md`](ACCOUNT_DELETION.md)

| Category | Behavior |
|---|---|
| Deleted | User profile, identity, skills, proofs, timeline, handles, coach profile, public profile, both sides of relationships/blocks/friend requests, own verification requests (athlete or coach), reports **submitted by** the user, own gym memberships, gyms the user **created** (all memberships at that gym + gym handle + gym) |
| Retained | Reports **about** the user (moderation), with handle replaced by `[deleted]` and only the opaque `reportedUserId` kept; other athletes' historically coach-verified proofs with live coach UIDs cleared and label “Verified by coach — account no longer available” |
| Timing | Seconds for typical accounts; batched subcollection deletes + collection-group coach anonymization |
| Failure | Auth kept; friendly error; release Crashlytics `account_deletion_failed` with stage + error code only; user can retry |
| Gym ownership | Created gyms are **closed** (not left ownerless) |

**Deploy note:** publish updated `firestore.rules` before relying on in-app deletion in production.

**Follow-up (not on Spark):** callable Cloud Function deletion job for large accounts / mid-flight kills — designed in `docs/ACCOUNT_DELETION.md`, not implemented as an admin client path.
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
- [ ] Publish updated Firestore rules (account deletion deletes for verificationRequests / reporter userReports / gym creator membership cleanup)
- [ ] Test full account deletion on a real device (see `docs/ACCOUNT_DELETION.md`)
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
