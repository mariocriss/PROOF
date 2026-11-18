/// Compile-time + runtime feature flags for the Experience Engine.
/// All production defaults are OFF.
class ExperienceFeatureFlags {
  const ExperienceFeatureFlags({
    this.experienceEngineEnabled = false,
    this.passportMotionEnabled = false,
    this.guideEnabled = false,
    this.soundsEnabled = false,
    this.hapticsEnabled = false,
    this.accountCreationExperienceEnabled = false,
    this.firstProofExperienceEnabled = false,
    this.coachVerificationExperienceEnabled = false,
    this.galleryMode = false,
  });

  final bool experienceEngineEnabled;
  final bool passportMotionEnabled;
  final bool guideEnabled;
  final bool soundsEnabled;
  final bool hapticsEnabled;
  final bool accountCreationExperienceEnabled;
  final bool firstProofExperienceEnabled;
  final bool coachVerificationExperienceEnabled;

  /// When true, gallery may present without writing production receipts.
  final bool galleryMode;

  static const ExperienceFeatureFlags productionOff = ExperienceFeatureFlags();

  static const ExperienceFeatureFlags allOnForGallery = ExperienceFeatureFlags(
    experienceEngineEnabled: true,
    passportMotionEnabled: true,
    guideEnabled: true,
    soundsEnabled: false,
    hapticsEnabled: true,
    accountCreationExperienceEnabled: true,
    firstProofExperienceEnabled: true,
    coachVerificationExperienceEnabled: true,
    galleryMode: true,
  );

  ExperienceFeatureFlags copyWith({
    bool? experienceEngineEnabled,
    bool? passportMotionEnabled,
    bool? guideEnabled,
    bool? soundsEnabled,
    bool? hapticsEnabled,
    bool? accountCreationExperienceEnabled,
    bool? firstProofExperienceEnabled,
    bool? coachVerificationExperienceEnabled,
    bool? galleryMode,
  }) {
    return ExperienceFeatureFlags(
      experienceEngineEnabled:
          experienceEngineEnabled ?? this.experienceEngineEnabled,
      passportMotionEnabled:
          passportMotionEnabled ?? this.passportMotionEnabled,
      guideEnabled: guideEnabled ?? this.guideEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      accountCreationExperienceEnabled: accountCreationExperienceEnabled ??
          this.accountCreationExperienceEnabled,
      firstProofExperienceEnabled:
          firstProofExperienceEnabled ?? this.firstProofExperienceEnabled,
      coachVerificationExperienceEnabled:
          coachVerificationExperienceEnabled ??
              this.coachVerificationExperienceEnabled,
      galleryMode: galleryMode ?? this.galleryMode,
    );
  }

  bool isTypeEnabled(String eventTypeValue) {
    if (!experienceEngineEnabled && !galleryMode) return false;
    return switch (eventTypeValue) {
      'onboarding_completed' => accountCreationExperienceEnabled,
      'first_proof_created' => firstProofExperienceEnabled,
      'coach_verified' => coachVerificationExperienceEnabled,
      _ => galleryMode,
    };
  }
}
