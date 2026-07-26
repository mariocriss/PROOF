# Firebase Hosting (PROOF website)

Last updated: July 2026

Static site root: `website/`  
Firebase project (from `.firebaserc` / FlutterFire): **`proof-e913a`**

## Local preview (does not deploy)

```bash
firebase emulators:start --only hosting --project proof-e913a
```

Open `http://127.0.0.1:5000`.

## Deploy (owner only — do not run unless instructed)

```bash
firebase deploy --only hosting --project proof-e913a
```

After deploy, pages are available at:

- https://proof-e913a.web.app/
- https://proof-e913a.web.app/privacy/
- https://proof-e913a.web.app/terms/
- https://proof-e913a.web.app/delete-account/
- https://proof-e913a.web.app/support/

(`*.firebaseapp.com` mirrors the same Hosting site.)

## App wiring

`lib/core/constants/app_urls.dart` points Privacy / Terms / Delete Account / website
base at these Hosting URLs. `supportEmail` is `mario-zderic@hotmail.com`.
`publicPassportBaseUrl` stays unset until a real public passport exists.
