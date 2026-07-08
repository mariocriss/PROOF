import 'package:proof/shared/models/skill_model.dart';

/// One physical capability = one canonical key = one Proof Stack.
class SkillUniqueness {
  SkillUniqueness._();

  static String canonicalKey(SkillModel skill) {
    final catalogId = skill.catalogId?.trim();
    if (catalogId != null && catalogId.isNotEmpty) {
      return 'catalog:${catalogId.toLowerCase()}';
    }
    return 'name:${_normalize(skill.discipline)}:${_normalize(skill.name)}';
  }

  static String _normalize(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

class DuplicateSkillException implements Exception {
  DuplicateSkillException(this.existing);

  final SkillModel existing;
}
