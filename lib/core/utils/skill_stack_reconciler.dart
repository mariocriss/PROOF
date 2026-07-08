import 'package:proof/core/utils/skill_uniqueness.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';

/// Pure helpers for consolidating duplicate skills into one proof stack.
class SkillStackReconciler {
  SkillStackReconciler._();

  static Map<String, List<SkillModel>> groupNonArchived(
    List<SkillModel> skills,
  ) {
    final groups = <String, List<SkillModel>>{};
    for (final skill in skills.where((s) => s.status != SkillStatus.archived)) {
      groups.putIfAbsent(SkillUniqueness.canonicalKey(skill), () => []).add(skill);
    }
    return groups;
  }

  static List<List<SkillModel>> duplicateGroups(List<SkillModel> skills) {
    return groupNonArchived(skills)
        .values
        .where((group) => group.length > 1)
        .toList();
  }

  /// Proofs still linked to an archived duplicate that has an active primary.
  static List<({ProofModel proof, SkillModel primary})> orphanedProofReassignments({
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
  }) {
    final skillById = {for (final s in skills) s.id: s};
    final reassignments = <({ProofModel proof, SkillModel primary})>[];

    for (final proof in proofs) {
      final skill = skillById[proof.skillId];
      if (skill == null || skill.status != SkillStatus.archived) continue;

      final primary = activePrimaryForArchivedSkill(skill, skills);
      if (primary != null) {
        reassignments.add((proof: proof, primary: primary));
      }
    }

    return reassignments;
  }

  static SkillModel? activePrimaryForArchivedSkill(
    SkillModel archived,
    List<SkillModel> allSkills,
  ) {
    if (archived.status != SkillStatus.archived) return null;

    final key = SkillUniqueness.canonicalKey(archived);
    final matches = allSkills
        .where(
          (s) =>
              s.status == SkillStatus.active &&
              SkillUniqueness.canonicalKey(s) == key,
        )
        .toList();

    if (matches.length != 1) return null;
    return matches.first;
  }

  static bool isTrackedCapability(SkillModel skill) =>
      skill.status != SkillStatus.archived;
}
