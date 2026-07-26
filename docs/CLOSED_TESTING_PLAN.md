# PROOF closed testing plan (release build, physical Android)

Last updated: July 2026

Use a **release** AAB/APK installed via Play closed testing (preferred) or `adb install` of a release artifact. Do **not** use a debug build for sign-off.

**Build under test:** version name ______ / version code ______  
**Tester:** ______  
**Device:** ______ / Android ______  
**Date:** ______

Legend: mark each case **Pass** / **Fail** / **Blocked**.

---

## Global setup

| | |
|---|---|
| **Setup** | Owned Privacy Policy URL configured in Play Console; Firebase project `proof-e913a` rules/indexes deployed; test Gmail (or inbox) for Auth; airplane mode available |
| **Firebase inspect** | Auth users, Firestore `users`, `handles`, `relationships`, `gyms`, `userReports` |

---

## 1. Signup

| | |
|---|---|
| **Setup** | Fresh email never used in this Firebase project |
| **Actions** | Open app → Register → accept terms checkbox → create account with valid password |
| **Expected** | Account created; onboarding starts; verification email sent (or queued) |
| **Firebase** | Auth user exists; optional incomplete `users/{uid}` |
| **Pass/Fail** | |

## 2. Login

| | |
|---|---|
| **Setup** | Existing completed account |
| **Actions** | Sign out → Sign in with email/password |
| **Expected** | Lands on dashboard / correct mode home |
| **Firebase** | Auth session; user doc readable |
| **Pass/Fail** | |

## 3. Password reset

| | |
|---|---|
| **Setup** | Known account |
| **Actions** | Login → Forgot password → enter email |
| **Expected** | Friendly confirmation; reset email arrives; new password works |
| **Firebase** | Auth still exists; no Firestore wipe |
| **Pass/Fail** | |

## 4. Email verification behavior

| | |
|---|---|
| **Setup** | New account |
| **Actions** | Check inbox; tap verify; return to Account → resend if needed |
| **Expected** | Verified state updates after reload; resend does not crash |
| **Firebase** | Auth `emailVerified` true after link |
| **Pass/Fail** | |

## 5. Onboarding — athlete

| | |
|---|---|
| **Setup** | New Auth user |
| **Actions** | Choose athlete → create identity (handle, name) → complete steps without requiring photo upload |
| **Expected** | Onboarding completes; dashboard usable; logo/avatar upload not implied as working |
| **Firebase** | `users/{uid}`, `identity`, `handles/{handle}` |
| **Pass/Fail** | |

## 6. Onboarding — coach

| | |
|---|---|
| **Setup** | New Auth user |
| **Actions** | Choose coach → complete coach profile / specialty flow |
| **Expected** | Coach mode reachable; coach profile doc when applicable |
| **Firebase** | `coachProfiles/{uid}` if created; roles on user |
| **Pass/Fail** | |

## 7. Onboarding — gym manager

| | |
|---|---|
| **Setup** | New Auth user |
| **Actions** | Create gym (name, handle); note logo upload disabled messaging |
| **Expected** | Gym + manager membership created; gym handle reserved |
| **Firebase** | `gyms/{id}`, `gymHandles`, `gymMemberships`, `managedGymIds` |
| **Pass/Fail** | |

## 8. Skills

| | |
|---|---|
| **Setup** | Athlete with identity |
| **Actions** | Add skill from catalog; edit; archive/pause if available |
| **Expected** | Skill list updates; uniqueness rules respected |
| **Firebase** | `users/{uid}/skills/*` |
| **Pass/Fail** | |

## 9. Proofs

| | |
|---|---|
| **Setup** | Athlete with a skill |
| **Actions** | Add self-reported proof; try coach path only if gym membership allows |
| **Expected** | Proof saved; media upload disabled messaging if shown |
| **Firebase** | `users/{uid}/proofs/*` |
| **Pass/Fail** | |

## 10. Proof stack

| | |
|---|---|
| **Setup** | Multiple proofs |
| **Actions** | Open Proof Stack / skill detail |
| **Expected** | Confidence / counts render; no crash on empty |
| **Firebase** | Reads only |
| **Pass/Fail** | |

## 11. Timeline

| | |
|---|---|
| **Setup** | Skills + proofs creating milestones |
| **Actions** | Open Timeline |
| **Expected** | Events list; no duplicate fatal errors |
| **Firebase** | `users/{uid}/timeline/*` |
| **Pass/Fail** | |

## 12. Passport (in-app)

| | |
|---|---|
| **Setup** | Athlete with proofs |
| **Actions** | Open Passport tab/screen |
| **Expected** | Credential card renders; public link/QR **unavailable** until `publicPassportBaseUrl` set |
| **Firebase** | Reads identity/skills/proofs |
| **Pass/Fail** | |

## 13. PDF preview and sharing

| | |
|---|---|
| **Setup** | Passport with data |
| **Actions** | Download / preview PDF → share or save |
| **Expected** | PDF generates; preview opens; share sheet works; no live `proof.app` URL |
| **Firebase** | None required |
| **Pass/Fail** | |

## 14. Friends

| | |
|---|---|
| **Setup** | Two test accounts |
| **Actions** | Search → add friend → accept on other device/account |
| **Expected** | Pending → accepted; lists update |
| **Firebase** | `relationships/friend_*` |
| **Pass/Fail** | |

## 15. Blocking and reporting

| | |
|---|---|
| **Setup** | Two accounts; one visible profile |
| **Actions** | Report user with reason; block user |
| **Expected** | Report succeeds; block hides/prevents as designed; no raw Firebase errors |
| **Firebase** | `userReports/*`; relationship `blocked` |
| **Pass/Fail** | |

## 16. Coach verification

| | |
|---|---|
| **Setup** | Athlete + coach approved at same gym |
| **Actions** | Athlete requests verification; coach approves/declines |
| **Expected** | Request lifecycle works; proof status updates |
| **Firebase** | `verificationRequests/*`; athlete `proofs/*` |
| **Pass/Fail** | |

## 17. Gym membership

| | |
|---|---|
| **Setup** | Gym + athlete/coach accounts |
| **Actions** | Request membership; manager approve/reject/remove |
| **Expected** | Status transitions; roster updates |
| **Firebase** | `gymMemberships/*` |
| **Pass/Fail** | |

## 18. Account deletion

| | |
|---|---|
| **Setup** | Disposable account with skills, friendship, optional gym membership |
| **Actions** | Account → Delete → confirm → password; try wrong password first |
| **Expected** | Wrong password keeps Auth; success returns to unauthenticated UI; handles freed; no orphan ownerless gym if creator |
| **Firebase** | Auth user gone; user tree gone; reports about user anonymized if any |
| **Pass/Fail** | |

## 19. Offline / weak network

| | |
|---|---|
| **Setup** | Logged-in athlete |
| **Actions** | Enable airplane mode; open cached screens; attempt write; restore network |
| **Expected** | No crash; friendly errors on writes; recovery after reconnect |
| **Firebase** | Pending writes may sync after online |
| **Pass/Fail** | |

## 20. Backgrounding and restart

| | |
|---|---|
| **Setup** | Mid-flow (e.g. add proof form) |
| **Actions** | Home button → wait → resume; force-stop → relaunch |
| **Expected** | Session restores or returns to login safely; no corrupt UI |
| **Firebase** | Auth persistence |
| **Pass/Fail** | |

## 21. Uninstall and reinstall

| | |
|---|---|
| **Setup** | Account with cloud data |
| **Actions** | Uninstall app → reinstall from Play track → log in |
| **Expected** | Cloud data restored; local-only prefs may reset |
| **Firebase** | Unchanged docs |
| **Pass/Fail** | |

## 22. Upgrade between test versions

| | |
|---|---|
| **Setup** | Install version code N; create data; upload N+1 to closed track |
| **Actions** | Update from Play; open app |
| **Expected** | Migrates cleanly; no wipe; version code increases |
| **Firebase** | Docs intact |
| **Pass/Fail** | |

---

## Sign-off

| Role | Name | Date | Result |
|---|---|---|---|
| Tester | | | |
| Owner | | | |

Blockers found: _______________________________________________
