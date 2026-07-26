# Google Play Console readiness checklist

Last updated: July 2026

Mark each item with owner type:

| Tag | Meaning |
|---|---|
| **Code** | Repository / app build |
| **Firebase** | Firebase Console / CLI |
| **Play** | Play Console |
| **Legal** | Counsel / policy text |
| **Design** | Brand / store artwork |
| **Owner** | Domain, email, business decisions |

---

## App identity

| Item | Tag | Status |
|---|---|---|
| Create Play app | Play / Owner | [ ] |
| Package name = `com.proof.proof` | Code / Play | [ ] |
| App name “PROOF” | Code / Play | [ ] |

## Signing & binary

| Item | Tag | Status |
|---|---|---|
| Create upload keystore (local) | Owner / Code | [ ] |
| `key.properties` configured (gitignored) | Owner | [ ] |
| Play App Signing enrolled | Play | [ ] |
| Build signed AAB (`flutter build appbundle --release`) | Code | [ ] |
| Upload AAB to closed track | Play | [ ] |
| Version code increments each upload | Code | [ ] |

## Declarations

| Item | Tag | Status |
|---|---|---|
| Ads declaration (likely **No ads**) | Play / Owner | [ ] |
| Content rating questionnaire | Play / Owner | [ ] |
| Target audience / age | Play / Owner | [ ] |
| News app / COVID / etc. declarations as applicable | Play / Owner | [ ] |
| Data safety form (use `docs/DATA_INVENTORY.md`) | Play / Legal / Owner | [ ] |
| Privacy Policy URL (owned HTTPS) | Legal / Owner / Play | [ ] |
| Account deletion URL or in-console instructions | Legal / Owner / Play | [ ] |
| App access — how reviewers log in (test account) | Owner / Play | [ ] |

## Store listing

| Item | Tag | Status |
|---|---|---|
| Short + full description | Owner / Design | [ ] |
| App icon (512) — final brand preferred | Design | [ ] |
| Feature graphic | Design | [ ] |
| Phone screenshots (required counts) | Design | [ ] |
| Support email / website | Owner | [ ] |
| Category | Owner / Play | [ ] |

## Closed testing

| Item | Tag | Status |
|---|---|---|
| Closed testing track created | Play | [ ] |
| Release notes | Owner | [ ] |
| Countries / testers | Play / Owner | [ ] |
| Tester opt-in link shared | Play / Owner | [ ] |
| Feedback process (`docs/CLOSED_TEST_FEEDBACK.md`) | Owner | [ ] |
| Execute `docs/CLOSED_TESTING_PLAN.md` on devices | Owner | [ ] |

## Production access (later — not this milestone)

| Item | Tag | Status |
|---|---|---|
| Closed-test feedback summary | Owner | [ ] |
| Apply for production access when eligible | Play / Owner | [ ] |
| Production track rollout | Play | [ ] |

## Firebase (parallel)

| Item | Tag | Status |
|---|---|---|
| Deploy `firestore.rules` | Firebase | [ ] |
| Deploy `firestore.indexes.json` | Firebase | [ ] |
| Crashlytics enabled | Firebase | [ ] |
| Auth email/password enabled | Firebase | [ ] |

## Code already done (verify still true)

| Item | Tag | Status |
|---|---|---|
| No third-party `proof.app` URLs | Code | [x] |
| Public passport gated | Code | [x] |
| Release refuses debug signing fallback | Code | [x] |
| Account deletion flow | Code | [x] |
| Incomplete notification settings hidden | Code | [x] |

## Blockers that are **not** repository work

1. Owned domain + hosted legal pages (**Legal / Owner**)
2. Support email (**Owner**)
3. Final launcher / store artwork (**Design**)
4. Play Console account + closed track (**Play / Owner**)
5. Firebase production deploy of rules/indexes (**Firebase / Owner**)
