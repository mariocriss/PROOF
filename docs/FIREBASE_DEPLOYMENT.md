# Firebase deployment verification (Firestore)

Last updated: July 2026

**Do not deploy from CI or an agent unless the owner explicitly asks.**  
This document is commands and checks only.

Project id (from `firebase.json` / FlutterFire): **`proof-e913a`**.

## 1. Confirm active Firebase project

```bash
firebase login
firebase projects:list
firebase use
```

If no project is selected:

```bash
firebase use proof-e913a
```

Confirm the Android app in Console matches `android/app/google-services.json` (`project_id`: `proof-e913a`).

## 2. Inspect diff before deployment

### Rules

```bash
# Local file
# firestore.rules

# Optional: show what Console currently has (requires firebase CLI + permissions)
firebase firestore:rules get > /tmp/remote-firestore.rules
# Compare to local firestore.rules (diff tool of your choice)
```

On Windows PowerShell:

```powershell
firebase firestore:rules get | Out-File -Encoding utf8 remote-firestore.rules
fc.exe firestore.rules remote-firestore.rules
```

### Indexes

```bash
# Local: firestore.indexes.json
# Console: Firestore → Indexes
# Diff manually against local composite + fieldOverrides (proofs collection-group coach fields)
```

## 3. Deploy (only when instructed)

```bash
# Rules only
firebase deploy --only firestore:rules --project proof-e913a

# Indexes only
firebase deploy --only firestore:indexes --project proof-e913a

# Both
firebase deploy --only firestore --project proof-e913a
```

## 4. Verify deployment succeeded

```bash
firebase deploy --only firestore:rules --project proof-e913a
# CLI should print “Deploy complete!”

firebase firestore:rules get
# Spot-check that new account-deletion / anonymization rules are present
```

Console checks:

- Firestore → Rules → published timestamp is current
- Firestore → Indexes → building/enabled for new indexes (collection-group `proofs` coach fields)

## 5. Test production rules without real user PII

Prefer the **emulator** (no production data):

```bash
firebase emulators:exec --only firestore --project proof-e913a-rules-test "npm test --prefix firestore-rules-test"
```

For a **production** smoke check without personal data:

1. Create a throwaway Auth user in the Firebase project (test email).
2. Seed only synthetic documents (fake handles, no real names/emails in content).
3. Exercise read/write/delete from the app against that account.
4. Delete the throwaway Auth user + docs when finished.

Never copy production user exports into test devices.

## 6. Rollback note

Keep the previous `firestore.rules` in Git history. Redeploy the prior commit if a rules mistake locks clients out.
