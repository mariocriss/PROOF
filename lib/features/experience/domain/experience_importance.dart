/// Importance tiers for experience moments.
enum ExperienceImportance {
  t0Silent(0, 'T0'),
  t1Whisper(1, 'T1'),
  t2Moment(2, 'T2'),
  t3Landmark(3, 'T3'),
  t4Legacy(4, 'T4');

  const ExperienceImportance(this.rank, this.label);

  final int rank;
  final String label;

  bool get presentsOverlay => rank >= ExperienceImportance.t2Moment.rank;

  bool get showsGuide => rank >= ExperienceImportance.t2Moment.rank;

  static ExperienceImportance fromString(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return ExperienceImportance.values.firstWhere(
      (v) =>
          v.name.toLowerCase() == normalized ||
          v.label.toLowerCase() == normalized ||
          v.rank.toString() == normalized,
      orElse: () => ExperienceImportance.t0Silent,
    );
  }
}
