# Experience sound assets — production requirements

**Status:** PLACEHOLDER — no licensed audio is bundled yet.  
`PlaceholderExperienceSoundService` fails silently until assets are added.

## Passport Issuance (`binding_placeholder.wav`)

- **Character:** soft cloth-bound cover opening
- **Avoid:** horror creak, old door sounds
- **Duration:** 300–600 ms
- **Volume:** low, dry recording
- **Use:** once per issuance open

## First Proof (`stamp_soft_placeholder.wav`)

- **Character:** soft rubber stamp on dense paper
- **Duration:** 150–350 ms
- **Resonance:** minimal
- **Use:** at flat stamp contact only

## Coach Verification (`stamp_deep_placeholder.wav`)

- **Character:** heavier official stamp, slightly lower pitch
- **Duration:** 200–450 ms
- **Avoid:** metallic clang, cinematic boom
- **Use:** at witness emboss contact only (double haptic accompanies)

## Technical spec (all sounds)

| Property | Requirement |
|----------|-------------|
| Format | WAV (PCM) or OGG Vorbis |
| Sample rate | 44.1 kHz or 48 kHz |
| Channels | Mono preferred |
| Target loudness | −18 to −14 LUFS integrated |
| Trim | Remove silence > 20 ms at start/end |
| Loop | None — single one-shot |
| License | Must be owned or properly licensed for commercial app use |

## Fallback behavior

- If asset missing or decode fails → continue silently
- If user disabled sound → never play
- If `simulateSoundFailure` (debug) → skip playback
- Never block experience completion
- Never interrupt other device audio aggressively (no ducking unless platform default)

## File paths (when added)

```
assets/experience/sounds/binding_placeholder.wav
assets/experience/sounds/stamp_soft_placeholder.wav
assets/experience/sounds/stamp_deep_placeholder.wav
assets/experience/sounds/paper_placeholder.wav
```

Register in `pubspec.yaml` under `flutter: assets:` before shipping.

## Haptic pairing

| Moment | Haptic | Sound |
|--------|--------|-------|
| Issuance open | pulse (light) | binding |
| First proof stamp | thud (medium) | stamp soft |
| Coach witness | doubleThud (80 ms gap) | stamp deep |

Haptics respect user preference and device capability independently of sound.
