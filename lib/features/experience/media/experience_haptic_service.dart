import 'package:flutter/services.dart';

enum ExperienceHapticKind {
  none,
  pulse,
  tap,
  thud,
  doubleThud,
}

abstract class ExperienceHapticService {
  Future<void> play(ExperienceHapticKind kind);
}

class NoOpExperienceHapticService implements ExperienceHapticService {
  const NoOpExperienceHapticService();

  @override
  Future<void> play(ExperienceHapticKind kind) async {}
}

/// Conservative platform mapping via Flutter HapticFeedback.
class PlatformExperienceHapticService implements ExperienceHapticService {
  const PlatformExperienceHapticService();

  static const Duration doubleThudGap = Duration(milliseconds: 80);

  @override
  Future<void> play(ExperienceHapticKind kind) async {
    switch (kind) {
      case ExperienceHapticKind.none:
        return;
      case ExperienceHapticKind.pulse:
      case ExperienceHapticKind.tap:
        await HapticFeedback.lightImpact();
      case ExperienceHapticKind.thud:
        await HapticFeedback.mediumImpact();
      case ExperienceHapticKind.doubleThud:
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(doubleThudGap);
        await HapticFeedback.mediumImpact();
    }
  }
}

class GatedExperienceHapticService implements ExperienceHapticService {
  GatedExperienceHapticService({
    required this.inner,
    required this.enabled,
  });

  final ExperienceHapticService inner;
  final bool Function() enabled;

  @override
  Future<void> play(ExperienceHapticKind kind) async {
    if (!enabled()) return;
    try {
      await inner.play(kind);
    } catch (_) {}
  }
}

class RecordingExperienceHapticService implements ExperienceHapticService {
  RecordingExperienceHapticService();

  final List<ExperienceHapticKind> played = [];

  @override
  Future<void> play(ExperienceHapticKind kind) async {
    if (kind != ExperienceHapticKind.none) played.add(kind);
  }
}
