# PROOF data inventory (launch build)

Last updated: July 2026

**Purpose:** factual input for a hosted Privacy Policy and Google Play Data safety.  
**Not legal advice.** Have counsel review before production.

## Services in this build

| Service | Used? | Notes |
|---|---|---|
| Firebase Authentication | Yes | Email/password |
| Cloud Firestore | Yes | Primary app data |
| Firebase Crashlytics | Yes | Release builds only |
| Google Analytics | No | |
| Firebase Cloud Messaging | No | Notification settings removed from UI |
| Firebase Storage | No | `AppFeatures.cloudStorageEnabled = false` |
| Health Connect | No | |
| Continuous location / GPS | No | Optional free-text “location” on profiles only |
| In-app messaging / chat | No | |

## Data types collected or stored

| Data type | Examples | Collected? | Shared with other users? | Purpose |
|---|---|---|---|---|
| Email | Account email | Yes (Auth) | No | Account |
| Password | Auth credential | Yes (Auth hashed) | No | Account |
| User ID | Firebase UID | Yes | Indirectly via relationships | Account / social graph |
| Name | Display name | Yes | Per privacy / friendships | Profile |
| Handle | `@handle` | Yes | Per privacy / search | Profile |
| Photos | Avatar / proof / gym logo | **Not in this build** | — | Deferred |
| Approximate location | City text field | Optional text | Per privacy | Profile |
| Precise location | GPS | No | — | — |
| User content | Skills, proofs, timeline, bios | Yes | Per privacy / coach / gym | Core product |
| Messages | Chat | No | — | — |
| Relationships | Friends, blocks, coach links, gym memberships | Yes | Counterparties | Social / verification |
| Reports | Reason, details, reporter/subject ids | Yes | Admins / reporter only | Safety |
| Diagnostics | Crashlytics stacks | Yes (release) | Google Firebase | Stability |
| Device IDs / advertising | Ad ID | Not intentionally | — | — |

## Account deletion

See `docs/ACCOUNT_DELETION.md`. Users delete from Account → password reauth → Firestore cleanup → Auth delete.

## Hosted URLs (placeholders)

Configure in `lib/core/constants/app_urls.dart` before Play production:

- Privacy Policy URL
- Terms URL
- Account deletion info URL (Play Console)
- Support email
- Public passport base URL (optional; disabled until set)

## Play Data safety mapping hints

Declare collection of: email, name/handle, user-generated content, app activity as needed for crash reporting, and account identifiers.  
Do **not** declare: messages, health, precise location, photos (until Storage is enabled), or analytics if still unused.
