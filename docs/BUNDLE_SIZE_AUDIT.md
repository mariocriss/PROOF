# Release AAB size audit

Last updated: July 2026  
Analyzed file: `build/app/outputs/bundle/release/app-release.aab` (~**64.9 MB** on disk)

## Executive summary

The ~65 MB AAB is dominated by **Flutter engine + app native libraries for three ABIs** and **native debug symbols** packaged in bundle metadata—not by app images or branding placeholders. Play Store delivers **per-device splits**, so download size on a typical `arm64-v8a` phone is substantially smaller than the universal AAB.

**No code/assets were removed** in this pass (nothing was both clearly unused and required for closed-test safety).

## On-disk breakdown (uncompressed extract)

| Area | Approx. size | Notes |
|---|---|---|
| `BUNDLE-METADATA/.../debugsymbols` | **~80 MB** uncompressed | `libflutter.so.sym` / `libapp.so.sym` per ABI for native crash symbolication; compressed into AAB |
| `base/lib/arm64-v8a` | ~21.5 MB | Phone / modern devices |
| `base/lib/armeabi-v7a` | ~19.5 MB | Older 32-bit ARM |
| `base/lib/x86_64` | ~23.0 MB | Emulators / some Chromebooks; **not** needed for most phones |
| `base/dex` | ~19 MB | Java/Kotlin (Firebase, AndroidX, plugins) |
| `base/assets/flutter_assets` | ~0.16 MB | Tiny; see fonts below |
| Launcher / branding placeholders | Negligible | Adaptive vectors + small solid mipmaps |

### Largest runtime libraries (per ABI)

- `libflutter.so` (~8–13 MB depending on ABI)
- `libapp.so` (Dart AOT, ~10–11 MB) — includes app + Dart packages (`pdf`, `printing`, Riverpod, etc.)
- `libdartjni.so` (~77–125 KB)

### Bundled fonts

| Font | Size | Source |
|---|---|---|
| `MaterialIcons-Regular.otf` | ~13 KB | Flutter Material (tree-shaken) |
| `CupertinoIcons.ttf` | ~0.8 KB | `cupertino_icons` package (no `CupertinoIcons` usages in `lib/`) |
| Inter (via `google_fonts`) | **Not shipped as a large asset** | Loaded by `google_fonts` at runtime / cache — not a multi‑MB AAB asset |

### PDF-related dependencies

| Package | Role | Size impact |
|---|---|---|
| `pdf` | Passport PDF generation | Contributes to Dart AOT (`libapp.so`), not a separate multi‑MB asset |
| `printing` | PDF preview / print / share | Same; also pulls platform bits into DEX/native as needed |
| `qr_flutter` | QR when public passport enabled | Small; UI gated when `AppUrls.publicPassportBaseUrl` is null |
| `share_plus` / `path_provider` | Share PDF / temp files | Small |

Passport PDF remains a supported launch feature; do not remove these packages for closed testing.

### Duplicate / unused findings

| Item | Verdict |
|---|---|
| Duplicate resources | No large duplicate image sets found in `flutter_assets` |
| Unused image assets | App does not ship a large `assets/` image tree |
| Debug-only resources in AAB | Native **debug symbols** are present under bundle metadata (expected for Crashlytics/NDK); not the Flutter “debug” APK |
| Branding placeholders | Solid-color mipmaps + vector adaptive icons — **not** a size problem |
| `cupertino_icons` | Appears unused in Dart code (~0.8 KB font). Candidate for later removal; left in place for this closed-test prep |
| `image_picker` | Still depended on; gated by `AppFeatures.cloudStorageEnabled == false` |

## Play delivery note

Universal AAB ≠ user download size. Expect roughly **one ABI’s native libs + DEX + assets** on device (order-of-magnitude often ~25–40 MB compressed download, device-dependent). Confirm in Play Console after upload (“App size” / device catalog).

## Optional future size work (not done now)

1. ABI filters to drop `x86_64` if emulator/Chromebook support is not required.
2. `--split-debug-info` / obfuscation + upload symbols to Crashlytics separately.
3. Remove unused `cupertino_icons` after a dedicated cleanup PR.
4. Revisit `google_fonts` (bundle a single Inter file offline) if offline-first typography becomes a requirement.

## Re-run analysis

```powershell
flutter build appbundle --release
# Unzip AAB (it is a ZIP) and inspect base/lib, base/dex, base/assets, BUNDLE-METADATA
```
