enum UserRole {
  athlete('athlete'),
  coach('coach'),
  gymManager('gym_manager'),
  athleteAndCoach('athlete_and_coach');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String? value) {
    if (value == null || value.isEmpty) return UserRole.athlete;
    if (value == 'both') return UserRole.athleteAndCoach;
    if (value == 'gym') return UserRole.gymManager;
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.athlete,
    );
  }

  bool get isCoach =>
      this == UserRole.coach || this == UserRole.athleteAndCoach;

  bool get isGymManager => this == UserRole.gymManager;

  bool get isAthlete =>
      this == UserRole.athlete || this == UserRole.athleteAndCoach;

  bool get needsPhysicalIdentity =>
      this == UserRole.athlete || this == UserRole.athleteAndCoach;

  String get label => switch (this) {
        UserRole.athlete => 'Athlete',
        UserRole.coach => 'Coach',
        UserRole.gymManager => 'Gym',
        UserRole.athleteAndCoach => 'Athlete + Coach',
      };

  String get description => switch (this) {
        UserRole.athlete =>
          'Build and manage your Physical Identity.',
        UserRole.coach =>
          'Verify proofs for athletes connected to your gym.',
        UserRole.gymManager =>
          'Manage members, coaches and verification access.',
        UserRole.athleteAndCoach =>
          'Track your own Physical Identity and verify athlete proofs.',
      };

  static const List<UserRole> accountTypeOptions = [
    UserRole.athlete,
    UserRole.coach,
    UserRole.gymManager,
    UserRole.athleteAndCoach,
  ];
}
