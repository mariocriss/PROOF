enum ExperienceStatus {
  pending('pending'),
  presenting('presenting'),
  completed('completed'),
  dismissed('dismissed'),
  failed('failed');

  const ExperienceStatus(this.value);

  final String value;

  bool get isTerminal =>
      this == ExperienceStatus.completed ||
      this == ExperienceStatus.dismissed ||
      this == ExperienceStatus.failed;

  bool get mayResume =>
      this == ExperienceStatus.pending ||
      this == ExperienceStatus.presenting ||
      this == ExperienceStatus.failed;

  static ExperienceStatus fromString(String? value) {
    return ExperienceStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ExperienceStatus.pending,
    );
  }
}
