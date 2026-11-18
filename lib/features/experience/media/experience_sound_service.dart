enum ExperienceSoundKind {
  none,
  binding,
  stampSoft,
  stampDeep,
  paper,
}

/// Sound abstraction. Production defaults off; missing assets fail silently.
abstract class ExperienceSoundService {
  Future<void> play(ExperienceSoundKind kind);

  Future<void> dispose();
}

/// No-op implementation — used when sounds are disabled or assets missing.
class NoOpExperienceSoundService implements ExperienceSoundService {
  const NoOpExperienceSoundService();

  @override
  Future<void> play(ExperienceSoundKind kind) async {}

  @override
  Future<void> dispose() async {}
}

/// Placeholder player. Custom audio packages are intentionally not required yet.
/// When licensed assets are added under assets/experience/sounds/, wire a real
/// player here. Until then this remains silent (safe fallback).
class PlaceholderExperienceSoundService implements ExperienceSoundService {
  PlaceholderExperienceSoundService();

  bool _disposed = false;

  /// PLACEHOLDER: no licensed audio bundled. Paths reserved for future assets.
  static const assetPaths = <ExperienceSoundKind, String>{
    ExperienceSoundKind.binding: 'assets/experience/sounds/binding_placeholder.wav',
    ExperienceSoundKind.stampSoft: 'assets/experience/sounds/stamp_soft_placeholder.wav',
    ExperienceSoundKind.stampDeep: 'assets/experience/sounds/stamp_deep_placeholder.wav',
    ExperienceSoundKind.paper: 'assets/experience/sounds/paper_placeholder.wav',
  };

  @override
  Future<void> play(ExperienceSoundKind kind) async {
    if (_disposed || kind == ExperienceSoundKind.none) return;
    // Silent placeholder — do not throw if asset missing.
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}

class GatedExperienceSoundService implements ExperienceSoundService {
  GatedExperienceSoundService({
    required this.inner,
    required this.enabled,
  });

  final ExperienceSoundService inner;
  final bool Function() enabled;

  @override
  Future<void> play(ExperienceSoundKind kind) async {
    if (!enabled()) return;
    try {
      await inner.play(kind);
    } catch (_) {
      // Asset or platform failure must never block the experience.
    }
  }

  @override
  Future<void> dispose() => inner.dispose();
}
