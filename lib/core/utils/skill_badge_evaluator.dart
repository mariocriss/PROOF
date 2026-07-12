import 'package:proof/core/utils/goal_progress.dart';
import 'package:proof/features/skills/data/skill_catalog.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_badge.dart';
import 'package:proof/shared/models/skill_model.dart';

class SkillBadgeEvaluator {
  SkillBadgeEvaluator._();

  static List<SkillBadgeId> newlyEarned({
    required SkillModel skill,
    required List<ProofModel> stackProofs,
    required List<SkillModel> allSkills,
    required List<ProofModel> allProofs,
    required bool isPersonalBest,
    required int personalBestCount,
    required StackConfidence confidence,
  }) {
    final earned = skill.earnedBadgeIds.toSet();
    final awarded = <SkillBadgeId>[];

    void tryAward(SkillBadgeId badge) {
      if (!earned.contains(badge.value)) {
        awarded.add(badge);
      }
    }

    final proofCount = stackProofs.length;
    if (proofCount >= 1) tryAward(SkillBadgeId.firstProof);
    if (proofCount >= 10) tryAward(SkillBadgeId.proofs10);
    if (proofCount >= 25) tryAward(SkillBadgeId.proofs25);
    if (proofCount >= 50) tryAward(SkillBadgeId.proofs50);
    if (proofCount >= 100) tryAward(SkillBadgeId.proofs100);

    final coachCount =
        stackProofs.where((p) => p.isCoachVerifiedForStack).length;
    if (coachCount >= 1) tryAward(SkillBadgeId.firstCoachVerification);
    if (coachCount >= 5) tryAward(SkillBadgeId.coachVerifications5);

    if (confidence == StackConfidence.established) {
      tryAward(SkillBadgeId.establishedSkill);
    }
    if (confidence == StackConfidence.strong) {
      tryAward(SkillBadgeId.strongSkill);
    }
    if (confidence == StackConfidence.trusted) {
      tryAward(SkillBadgeId.trustedSkill);
    }

    if (personalBestCount >= 1) tryAward(SkillBadgeId.firstPersonalBest);
    if (personalBestCount >= 3) tryAward(SkillBadgeId.personalBests3);
    if (personalBestCount >= 10) tryAward(SkillBadgeId.personalBests10);

    final goal = GoalProgress.forSkill(skill);
    if (goal?.targetReached == true) {
      tryAward(SkillBadgeId.goalReached);
    }

    final variantId = skill.variantId?.trim();
    if (variantId != null &&
        variantId.isNotEmpty &&
        proofCount == 1 &&
        skill.catalogId != null) {
      tryAward(SkillBadgeId.variantFirstProof);
    }

    final catalogId = skill.catalogId?.trim();
    if (catalogId != null && catalogId.isNotEmpty) {
      final entry = SkillCatalog.findById(catalogId);
      if (entry != null && entry.supportsVariants) {
        final skillsWithProofs = allSkills.where((s) {
          if (s.catalogId != catalogId) return false;
          final id = s.variantId?.trim();
          if (id == null || id.isEmpty) return false;
          return allProofs.any((p) => p.skillId == s.id);
        });
        final variantCount =
            skillsWithProofs.map((s) => s.variantId!.toLowerCase()).toSet().length;
        if (variantCount >= 3) {
          tryAward(SkillBadgeId.variantsDocumented3);
        }
      }
    }

    return awarded;
  }

  static String displayLabel(SkillBadgeId badge, SkillModel skill) {
    if (badge == SkillBadgeId.variantFirstProof) {
      final variant = skill.variantName?.trim();
      if (variant != null && variant.isNotEmpty) {
        return 'First $variant ${skill.name} Proof';
      }
    }
    if (badge == SkillBadgeId.variantsDocumented3) {
      return 'Three ${skill.name} Variants Documented';
    }
    return badge.label;
  }

  static List<SkillBadgeId> parseEarned(List<String> ids) {
    return ids
        .map(SkillBadgeId.fromString)
        .whereType<SkillBadgeId>()
        .toList();
  }
}
