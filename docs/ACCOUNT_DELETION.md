# Account deletion data map

Last updated: July 2026

This document is the source of truth for PROOF account deletion (privacy / Google Play).

## Flow (required order)

1. User confirms deletion in Account UI.
2. User re-authenticates with password (`ReauthDialog`).
3. Client runs Firestore cleanup (`deleteAllUserData`).
4. **Only if step 3 succeeds**, delete the Firebase Auth user.
5. Navigate to the unauthenticated registration screen.

If step 3 fails: Auth stays intact, friendly error, Crashlytics diagnostic (release), user may retry.

## Gym ownership decision (launch)

**When the deleting user is `gyms/{gymId}.createdBy`:** delete every `gymMemberships` doc for that gym, then the `gymHandles` reservation, then the gym document.

**Rationale:** safest launch-ready behavior. Do not leave an ownerless gym. Other members lose membership records for that gym (no silent orphan owner).

**When the user only has a manager/athlete/coach membership** (not creator): delete only that user's membership docs. Do not delete the gym.

## Collection-by-collection behavior

| Collection / path | Owns doc? | UID as reference? | Action | Rules (after fix) |
|---|---|---|---|---|
| `users/{uid}` | Yes | Doc id | **Delete** | Owner delete allowed |
| `users/{uid}/identity/*` | Yes | Path | **Delete** | Owner write allowed |
| `users/{uid}/skills/*` | Yes | Path | **Delete** | Owner write allowed |
| `users/{uid}/proofs/*` | Yes | Path | **Delete** | Owner delete allowed |
| `users/{uid}/timeline/*` | Yes | Path | **Delete** | Owner delete allowed |
| `handles/{handle}` | Yes (`userId`) | `userId` | **Delete** (free reservation) | Owner delete allowed |
| `publicProfiles/{uid}` | Yes | Doc id | **Delete** | Owner write allowed |
| `coachProfiles/{uid}` | Yes | Doc id | **Delete** | Owner delete allowed |
| `relationships/*` | Participant | `fromUserId` / `toUserId` (legacy requester/recipient) | **Delete** both sides | Participant delete allowed |
| `verificationRequests/*` | Participant | `athleteId` / `coachId` | **Delete** when athlete or coach | **Delete allowed** if `athleteId` or `coachId` == auth |
| `userReports/*` (reporter) | Reporter | `reporterUserId` | **Delete** reports submitted by user | **Delete allowed** if reporter == auth |
| `userReports/*` (reported) | No | `reportedUserId` | **Retain + anonymize** | Subject may update only handle + deleted flag |
| `gymMemberships/*` (own) | Yes | `userId` / doc id | **Delete** | `ownsMembershipDoc` delete |
| `gymMemberships/*` (owned gym) | No | other users | **Delete** all for gym before gym delete | Creator may delete memberships for their gym |
| `gyms/{gymId}` | Creator | `createdBy` | **Delete** if `createdBy` == user | Creator delete allowed |
| `gymHandles/{handle}` | Via gym | `gymId` | **Delete** if user created gym | Creator delete (gym must still exist) |
| Other users' `proofs` referencing coach | No | `coachId` / `verifiedByCoachId` / `requestedCoachId` | **Retain proof; clear coach UIDs; mark historical** | Assigned coach may anonymize on deletion |
| Firebase Auth user | N/A | N/A | **Delete only after** Firestore cleanup succeeds | Auth API |

---

## Retention case 1 — Reports about the deleted user

### What is stored on a report

Reports do **not** store email, display name, avatar, profile URL, or public profile documents. Fields are:

| Field | After subject deletion |
|---|---|
| `reporterUserId` | Unchanged (reporter’s UID) |
| `reportedUserId` | **Retained** — opaque Firebase Auth UID (internal subject id) |
| `reportedHandle` | Replaced with `[deleted]` |
| `reportedAccountDeleted` | Set to `true` |
| `reason`, `details`, `createdAt` | Unchanged |

### Identifier that remains

- **Exactly one deleted-user identifier:** `reportedUserId` (Firebase Auth UID of the former account).
- **Public account references removed:** handle → `[deleted]`. No email, display name, avatar, profile URL, or copied profile payload is stored or retained on the report.

### Why it must remain

Trust & safety / abuse prevention: operators and future moderation tooling need a stable internal key to correlate multiple reports about the same former account without reconstructing a public profile.

### Who can access it

| Accessor | Access |
|---|---|
| Reporting user (client) | Can **read** their own submitted reports (rules). After anonymization they see `[deleted]` for the handle, not a live profile. |
| Reported / deleted user (client) | Cannot read reports. May only apply the anonymization update during deletion. |
| Other end users | No access |
| Firebase project admins / support | Console / Admin SDK for investigation |

### How long it is retained

Launch policy: retained for **up to 24 months** after the reported account is deleted, or until a trust & safety review closes the report and an operator deletes it — whichever comes first. There is **no automated purge job in v1**; deletion is manual via Firebase Console / Admin tooling until a Cloud Function retention job is added.

### Privacy Policy disclosure (required copy)

Include language substantially equivalent to:

> If you report another user, we store the report reason, optional details you provide, your account identifier, and an internal identifier for the reported account. If the reported account is later deleted, we remove their public username from the report and replace it with a deleted-account marker. We may keep the internal identifier and report contents for up to 24 months to investigate abuse and protect the community. We do not keep the deleted user’s email, display name, avatar, or profile page in the report record.

---

## Retention case 2 — Other athletes’ proofs verified by a deleted coach

### Behavior

- The athlete’s proof document is **not** deleted when the coach deletes their account.
- Historical coach verification is **preserved** (`verificationStatus` / stack treatment remains coach-verified when it was verified).
- Live coach references are **cleared:** `coachId`, `requestedCoachId`, and `verifiedByCoachId` set to null.
- `coachAccountDeleted` is set to `true` for historically verified proofs.
- Pending verification requests to that coach are deleted separately; pending proofs are converted to self-reported (no active coach link).
- UI / passport label: **“Verified by coach — account no longer available”** (see `DeletedAccountMarkers.coachUnavailableLabel`).
- No clickable coach profile: `hasActiveCoachReference` is false; coach profile and handle docs are deleted with the account.

### Why not keep raw `coachId`

A raw UID is unnecessary once the coach profile is gone, and it risks stale deep-links or presenting a deleted account as active. Historical verification is represented by status + `coachAccountDeleted`, not a live user id.

### Who can access the anonymized proof

| Accessor | Access |
|---|---|
| Athlete (owner) | Full read/write of their proof |
| Public / friends | Per existing identity visibility rules (proof content), without a live coach link |
| Former coach | No longer resolvable as a profile; cannot re-attach after anonymization |

---

## Timing

- Expected client deletion: typically a few seconds for normal accounts.
- Large proof/skill histories and collection-group coach anonymization may take longer (batched work).
- User-visible completion: Auth deleted and UI navigates to `/register` only after cleanup succeeds.

## Failure / manual recovery

1. User sees: deletion was not completed; account remains usable.
2. User may retry from Account → Delete account.
3. Cleanup is idempotent (missing docs are ignored; already-anonymized reports/proofs are safe to re-apply).
4. If Firestore cleaned but Auth delete failed: retry deletion (cleanup no-ops, Auth delete retries).
5. Ops: Crashlytics event `account_deletion_failed` with stage (`reauth` / `firestore` / `auth`) and Firebase error **code** only (no passwords, emails, or free-text content).
6. Escalation: Firebase Console Auth + Firestore inspection by UID from support ticket (do not log UID in user-facing copy).

## Client vs server reliability

Client-side deletion is **acceptable for Spark launch** once rules permit the exact deletes/anonymizations above and Auth is deleted last.

It is **not** fully reliable for:

- very large accounts (client timeouts / many collection-group proof updates)
- mid-flight app kill
- guaranteed report retention purge after 24 months

**Designed follow-up (not implemented on Spark):** a callable Cloud Function `deleteAccount` that:

1. Verifies `request.auth.uid`
2. Requires recent Auth (App Check + reauth token / `auth_time`)
3. Runs Admin SDK deletes/anonymizations in a defined order
4. Deletes Auth user only after Firestore success
5. Optionally schedules report purge after the retention window
6. Never grants clients admin-like broad delete rules

Do **not** widen client rules beyond the minimal grants in `firestore.rules`.

## Deploy notes

Publish together:

- `firestore.rules` (report subject anonymization + coach proof anonymization)
- `firestore.indexes.json` (collection-group indexes on `proofs.coachId`, `verifiedByCoachId`, `requestedCoachId`)
