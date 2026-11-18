/// Experience event types. Only the three reference moments are production-wired.
/// Remaining values exist for extensibility and must not trigger in production.
enum ExperienceEventType {
  onboardingCompleted('onboarding_completed'),
  firstProofCreated('first_proof_created'),
  coachVerified('coach_verified'),
  // Future — definitions may exist; production triggers must stay off.
  silentMoment('silent_moment'),
  whisper('whisper'),
  momentDemo('moment_demo'),
  landmarkDemo('landmark_demo'),
  annualChapter('annual_chapter'),
  personalRecord('personal_record'),
  competition('competition'),
  returnAfterAbsence('return_after_absence');

  const ExperienceEventType(this.value);

  final String value;

  bool get isProductionReference =>
      this == ExperienceEventType.onboardingCompleted ||
      this == ExperienceEventType.firstProofCreated ||
      this == ExperienceEventType.coachVerified;

  static ExperienceEventType fromString(String? value) {
    return ExperienceEventType.values.firstWhere(
      (t) => t.value == value || t.name == value,
      orElse: () => ExperienceEventType.silentMoment,
    );
  }
}
