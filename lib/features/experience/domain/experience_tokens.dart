import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:proof/core/theme/app_colors.dart';

/// Material, ink, shadow, and timing tokens for the Experience system.
/// Compatible with the existing sage/minimal theme — does not replace AppTheme.
class ExperienceTokens {
  ExperienceTokens._();

  // —— Surfaces ——
  static const Color paperBackground = AppColors.background; // #FAFAF8
  static const Color vellumOverlay = Color(0xF2FAFAF8);
  static const Color ledgerSurface = AppColors.surfaceElevated;
  static const Color passportCover = Color(0xFF2C4A3E);

  // —— Ink (trust class, not rarity) ——
  static const Color identityInk = Color(0xFF1A3328);
  static const Color recordInk = AppColors.ink;
  static const Color witnessInk = Color(0xFF1A3328);
  static const Color archivalInk = Color(0xB37A8B99);
  static const Color institutionalInk = Color(0xFF2A3544);
  static const Color ceremonialBurgundy = Color(0xFF5C1A2A);
  static const Color restrainedGold = Color(0xFFB8A06A);

  // —— Shadows ——
  static List<BoxShadow> get contactShadow => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.08),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];

  static List<BoxShadow> get pageLiftShadow => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.06),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get passportVolumeShadow => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.10),
          offset: const Offset(0, 12),
          blurRadius: 32,
        ),
      ];

  static const double stampImpressionDepth = 1.5;

  // —— Geometry ——
  static const double cornerRadiusSoft = 12;
  static const double cornerRadiusStamp = 4;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // —— Timing ——
  static const Duration instant = Duration.zero;
  static const Duration tick = Duration(milliseconds: 120);
  static const Duration breath = Duration(milliseconds: 320);
  static const Duration pauseMin = Duration(milliseconds: 480);
  static const Duration pauseMax = Duration(milliseconds: 720);
  static const Duration momentMin = Duration(milliseconds: 1200);
  static const Duration momentMax = Duration(milliseconds: 2400);
  static const Duration chapterMin = Duration(milliseconds: 3000);
  static const Duration chapterMax = Duration(milliseconds: 6000);
  static const Duration legacyMin = Duration(milliseconds: 6000);
  static const Duration legacyMax = Duration(milliseconds: 10000);

  /// Primary curve: decisive, calm.
  static const Curve primaryCurve = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Micro settle only — bounce ≤ ~2%.
  static const Curve settleCurve = Cubic(0.34, 1.05, 0.64, 1.0);

  static const Curve exitCurve = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Safe upper bound so experiences never trap the user.
  static const Duration safeAnimationTimeout = Duration(seconds: 12);
}

/// Named timing presets for reference moments.
enum ExperienceTimingPreset {
  tick,
  breath,
  pause,
  moment,
  chapter,
  legacy;

  Duration get duration => switch (this) {
        ExperienceTimingPreset.tick => ExperienceTokens.tick,
        ExperienceTimingPreset.breath => ExperienceTokens.breath,
        ExperienceTimingPreset.pause => ExperienceTokens.pauseMax,
        ExperienceTimingPreset.moment => const Duration(milliseconds: 2400),
        ExperienceTimingPreset.chapter => const Duration(milliseconds: 3200),
        ExperienceTimingPreset.legacy => const Duration(milliseconds: 6000),
      };
}
