# Launch URL configuration checklist

Last updated: July 2026

Legal pages are authored under `website/` and intended for Firebase Hosting on
project **`proof-e913a`**.

| Field in `AppUrls` | Current repo default | Notes |
|---|---|---|
| `websiteBaseUrl` | `https://proof-e913a.web.app` | Live after Hosting deploy |
| `privacyPolicyUrl` | `https://proof-e913a.web.app/privacy/` | Play Console Privacy Policy URL |
| `termsOfServiceUrl` | `https://proof-e913a.web.app/terms/` | |
| `accountDeletionUrl` | `https://proof-e913a.web.app/delete-account/` | Play account-deletion URL |
| `supportEmail` | `mario-zderic@hotmail.com` | Matches Hosting support / legal contact |
| `publicPassportBaseUrl` | `null` | Keep null — no public web passport yet |

## Operator details (website + app)

Filled on Privacy, Terms, Support, Delete Account:

- Owner: Mario Zderic
- Support: mario-zderic@hotmail.com
- Jurisdiction: The Netherlands
- Effective date: July 26, 2026

Drafts should still receive legal review before public production launch.

## Deploy Hosting before relying on Play links

```bash
firebase deploy --only hosting --project proof-e913a
```

See `docs/FIREBASE_HOSTING.md`.

## Rules enforced in code

- Only `https://` URLs with a host are treated as configured.
- Public passport QR/share stays disabled while `publicPassportBaseUrl` is null.
