import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/features/experience/domain/experience_preferences.dart';

/// Synchronous snapshot holder for experience runtime settings.
/// Updated via provider listeners — never reads [Ref] during async work.
class ExperienceRuntimeStore {
  ExperienceRuntimeStore({
    required ExperienceFeatureFlags flags,
    required ExperiencePreferences preferences,
    this.forceGalleryMode = false,
  })  : _flags = flags,
        _preferences = preferences;

  ExperienceFeatureFlags _flags;
  ExperiencePreferences _preferences;

  /// When true, [flags] merges gallery overrides for preview coordinators.
  final bool forceGalleryMode;

  ExperienceFeatureFlags get flags {
    if (!forceGalleryMode) return _flags;
    return _flags.copyWith(
      experienceEngineEnabled: true,
      galleryMode: true,
      accountCreationExperienceEnabled: true,
      firstProofExperienceEnabled: true,
      coachVerificationExperienceEnabled: true,
      passportMotionEnabled: _flags.passportMotionEnabled,
      guideEnabled: _flags.guideEnabled,
      soundsEnabled: _flags.soundsEnabled,
      hapticsEnabled: _flags.hapticsEnabled,
    );
  }

  ExperiencePreferences get preferences => _preferences;

  void updateFlags(ExperienceFeatureFlags next) => _flags = next;

  void updatePreferences(ExperiencePreferences next) => _preferences = next;
}

/// Debug-only persisted test mode override (survives auth/navigation).
class ExperienceDebugTestModePersistence {
  ExperienceDebugTestModePersistence();

  ExperienceFeatureFlags? override;

  bool get isActive => override != null;

  ExperienceFeatureFlags resolve(ExperienceFeatureFlags productionDefault) {
    return override ?? productionDefault;
  }
}
