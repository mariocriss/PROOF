import 'package:proof/core/utils/skill_uniqueness.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';

class ProofStackMerge {
  ProofStackMerge._();

  static List<ProofStackSkillSummary> buildSummaries({
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    DateTime Function()? now,
  }) {
    final active =
        skills.where((s) => s.status == SkillStatus.active).toList();
    final groups = <String, List<SkillModel>>{};

    for (final skill in active) {
      groups.putIfAbsent(SkillUniqueness.canonicalKey(skill), () => []).add(skill);
    }

    final summaries = groups.entries.map((entry) {
      final group = entry.value;
      final primary = pickPrimarySkill(group, proofs);
      final skillIds = group.map((s) => s.id).toSet();
      final mergedProofs =
          proofs.where((p) => skillIds.contains(p.skillId)).toList();

      return ProofStackSkillSummary.build(
        skill: primary,
        proofs: mergedProofs,
        now: now,
      );
    }).toList();

    summaries.sort((a, b) {
      final aDate = a.lastUpdated ?? a.skill.createdAt;
      final bDate = b.lastUpdated ?? b.skill.createdAt;
      return bDate.compareTo(aDate);
    });

    return summaries;
  }

  static SkillModel pickPrimarySkill(
    List<SkillModel> group,
    List<ProofModel> proofs,
  ) {
    if (group.length == 1) return group.first;

    SkillModel best = group.first;
    var bestScore = _score(best, group, proofs);

    for (final candidate in group.skip(1)) {
      final score = _score(candidate, group, proofs);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }

    return best;
  }

  static List<SkillModel> siblingSkills({
    required SkillModel skill,
    required List<SkillModel> allSkills,
  }) {
    final key = SkillUniqueness.canonicalKey(skill);
    return allSkills
        .where(
          (s) =>
              s.status == SkillStatus.active &&
              SkillUniqueness.canonicalKey(s) == key,
        )
        .toList();
  }

  static List<ProofModel> proofsForSkillGroup({
    required SkillModel skill,
    required List<SkillModel> allSkills,
    required List<ProofModel> allProofs,
  }) {
    final siblings = siblingSkills(skill: skill, allSkills: allSkills);
    final ids = siblings.map((s) => s.id).toSet();
    return allProofs.where((p) => ids.contains(p.skillId)).toList();
  }

  static SkillModel resolvePrimary({
    required SkillModel skill,
    required List<SkillModel> allSkills,
    required List<ProofModel> allProofs,
  }) {
    final siblings = siblingSkills(skill: skill, allSkills: allSkills);
    if (siblings.length <= 1) return skill;
    return pickPrimarySkill(siblings, allProofs);
  }

  static int _score(
    SkillModel skill,
    List<SkillModel> group,
    List<ProofModel> proofs,
  ) {
    final proofCount = proofs.where((p) => p.skillId == skill.id).length;
    final hasBest =
        skill.currentBest != null && skill.currentBest!.isNotEmpty ? 1 : 0;
    return proofCount * 1000 + hasBest * 100 - skill.createdAt.millisecondsSinceEpoch ~/ 1000000;
  }
}
