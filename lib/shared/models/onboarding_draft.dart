class OnboardingDraft {
  const OnboardingDraft({
    this.physicalIdentity = const {},
    this.coachProfile = const {},
    this.gymProfile = const {},
    this.selectedGymId,
  });

  final Map<String, dynamic> physicalIdentity;
  final Map<String, dynamic> coachProfile;
  final Map<String, dynamic> gymProfile;
  final String? selectedGymId;

  factory OnboardingDraft.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const OnboardingDraft();
    return OnboardingDraft(
      physicalIdentity: Map<String, dynamic>.from(
        data['physicalIdentity'] as Map? ?? {},
      ),
      coachProfile: Map<String, dynamic>.from(
        data['coachProfile'] as Map? ?? {},
      ),
      gymProfile: Map<String, dynamic>.from(
        data['gymProfile'] as Map? ?? {},
      ),
      selectedGymId: data['selectedGymId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'physicalIdentity': physicalIdentity,
      'coachProfile': coachProfile,
      'gymProfile': gymProfile,
      if (selectedGymId != null) 'selectedGymId': selectedGymId,
    };
  }

  OnboardingDraft copyWith({
    Map<String, dynamic>? physicalIdentity,
    Map<String, dynamic>? coachProfile,
    Map<String, dynamic>? gymProfile,
    String? selectedGymId,
  }) {
    return OnboardingDraft(
      physicalIdentity: physicalIdentity ?? this.physicalIdentity,
      coachProfile: coachProfile ?? this.coachProfile,
      gymProfile: gymProfile ?? this.gymProfile,
      selectedGymId: selectedGymId ?? this.selectedGymId,
    );
  }

  static String? string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    return value.toString();
  }
}
