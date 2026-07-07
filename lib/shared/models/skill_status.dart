enum SkillStatus {
  active('active'),
  paused('paused'),
  archived('archived');

  const SkillStatus(this.value);
  final String value;

  static SkillStatus fromString(String? value) {
    return SkillStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SkillStatus.active,
    );
  }

  String get label {
    switch (this) {
      case SkillStatus.active:
        return 'Active';
      case SkillStatus.paused:
        return 'Paused';
      case SkillStatus.archived:
        return 'Archived';
    }
  }
}
