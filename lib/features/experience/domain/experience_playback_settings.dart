import 'package:flutter/foundation.dart';

/// Debug-only playback tuning for Gallery QA. Not persisted to production.
@immutable
class ExperiencePlaybackSettings {
  const ExperiencePlaybackSettings({
    this.silentMomentMs = 550,
    this.animationSpeed = 1.0,
    this.showSemanticLabels = false,
    this.showAnimationBounds = false,
    this.showEventDiagnostics = false,
    this.simulateSoundFailure = false,
    this.simulateSourceMissing = false,
    this.simulatePresentationException = false,
    this.backgroundPreset = ExperienceBackgroundPreset.neutral,
    this.deviceWidth,
    this.textScale = 1.0,
  });

  final int silentMomentMs;
  final double animationSpeed;
  final bool showSemanticLabels;
  final bool showAnimationBounds;
  final bool showEventDiagnostics;
  final bool simulateSoundFailure;
  final bool simulateSourceMissing;
  final bool simulatePresentationException;
  final ExperienceBackgroundPreset backgroundPreset;
  final double? deviceWidth;
  final double textScale;

  Duration get silentMomentDuration =>
      Duration(milliseconds: silentMomentMs);

  Duration scale(Duration d) {
    if (animationSpeed <= 0) return Duration.zero;
    return Duration(
      milliseconds: (d.inMilliseconds / animationSpeed).round(),
    );
  }

  ExperiencePlaybackSettings copyWith({
    int? silentMomentMs,
    double? animationSpeed,
    bool? showSemanticLabels,
    bool? showAnimationBounds,
    bool? showEventDiagnostics,
    bool? simulateSoundFailure,
    bool? simulateSourceMissing,
    bool? simulatePresentationException,
    ExperienceBackgroundPreset? backgroundPreset,
    double? deviceWidth,
    double? textScale,
  }) {
    return ExperiencePlaybackSettings(
      silentMomentMs: silentMomentMs ?? this.silentMomentMs,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      showSemanticLabels: showSemanticLabels ?? this.showSemanticLabels,
      showAnimationBounds: showAnimationBounds ?? this.showAnimationBounds,
      showEventDiagnostics: showEventDiagnostics ?? this.showEventDiagnostics,
      simulateSoundFailure:
          simulateSoundFailure ?? this.simulateSoundFailure,
      simulateSourceMissing:
          simulateSourceMissing ?? this.simulateSourceMissing,
      simulatePresentationException: simulatePresentationException ??
          this.simulatePresentationException,
      backgroundPreset: backgroundPreset ?? this.backgroundPreset,
      deviceWidth: deviceWidth ?? this.deviceWidth,
      textScale: textScale ?? this.textScale,
    );
  }
}

enum ExperienceBackgroundPreset {
  neutral,
  dashboard,
  passport,
  proofDetail,
}
