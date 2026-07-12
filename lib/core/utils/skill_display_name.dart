import 'package:proof/shared/models/skill_model.dart';

class SkillDisplayName {
  SkillDisplayName._();

  static String format(SkillModel skill) {
    final variant = skill.variantName?.trim();
    if (variant != null && variant.isNotEmpty) {
      return '$variant ${skill.name}';
    }
    return skill.name;
  }

  static String stackLabel(SkillModel skill, int proofCount) {
    final label = format(skill);
    final countLabel = proofCount == 1 ? '1 proof' : '$proofCount proofs';
    return '$label · $countLabel';
  }

  static String variantSubtitle(SkillModel skill) {
    final variant = skill.variantName?.trim();
    if (variant == null || variant.isEmpty) return skill.name;
    return variant;
  }
}
