# Launcher icons (Android)

Last updated: July 2026

## Status

The default Flutter launcher artwork has been replaced with **temporary solid-color placeholders** so the store build does not ship the Flutter logo.

**Final brand assets are not approved yet.** Replace the placeholders before public production branding review.

## Required assets (supply final art here)

Place final PNGs under `branding/launcher/` (see README in that folder):

| File | Size | Notes |
|---|---|---|
| `ic_launcher_foreground.png` | **1080×1080** (safe zone ~66% center) | Adaptive foreground; transparent background |
| `ic_launcher_background.png` | **1080×1080** | Or solid color only |
| `ic_launcher_full.png` | **1024×1024** | Legacy / Play listing high-res |
| `ic_launcher_round.png` | **1024×1024** | Optional round mask preview |
| `ic_launcher_monochrome.png` | **1080×1080** | Android 13+ themed icon (single-color alpha) |

### Density legacy mipmaps (if not using only adaptive)

| Density | px |
|---|---|
| mdpi | 48×48 |
| hdpi | 72×72 |
| xhdpi | 96×96 |
| xxhdpi | 144×144 |
| xxxhdpi | 192×192 |

## Current Android wiring

- Adaptive: `mipmap-anydpi-v26/ic_launcher.xml`, `ic_launcher_round.xml`
- Foreground vector placeholder: `drawable/ic_launcher_foreground.xml`
- Background color: `values/colors.xml` → `ic_launcher_background`
- Monochrome: `drawable/ic_launcher_monochrome.xml`
- Legacy fallback PNGs: `mipmap-*/ic_launcher.png` (solid placeholder)

Manifest: `android:icon="@mipmap/ic_launcher"` (round via adaptive).

## After final assets arrive

1. Drop files into `branding/launcher/`.
2. Generate mipmaps (e.g. `flutter_launcher_icons` or Android Studio Image Asset Studio).
3. Keep adaptive safe-zone clear of cropped logo edges.
4. Rebuild and visually check on a device / emulator (square, round, themed).
