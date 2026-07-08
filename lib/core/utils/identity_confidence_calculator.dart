import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';

/// Aggregates per-skill stack confidence into an overall identity confidence.
class IdentityConfidenceCalculator {
  IdentityConfidenceCalculator._();

  static StackConfidence calculate({
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
  }) {
    if (proofs.isEmpty) return StackConfidence.limitedEvidence;

    final activeSkills =
        skills.where((s) => s.status == SkillStatus.active).toList();
    if (activeSkills.isEmpty) return StackConfidence.limitedEvidence;

    var weightedSum = 0.0;
    var totalWeight = 0;

    for (final skill in activeSkills) {
      final skillProofs =
          proofs.where((p) => p.skillId == skill.id).toList();
      if (skillProofs.isEmpty) continue;

      final confidence = skill.stackConfidence ??
          ProofStackCalculator.calculate(skillProofs);
      final weight = skillProofs.length;
      weightedSum += _score(confidence) * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return StackConfidence.limitedEvidence;
    return _fromScore(weightedSum / totalWeight);
  }

  static int _score(StackConfidence level) {
    switch (level) {
      case StackConfidence.limitedEvidence:
        return 1;
      case StackConfidence.developing:
        return 2;
      case StackConfidence.established:
        return 3;
      case StackConfidence.strong:
        return 4;
      case StackConfidence.trusted:
        return 5;
    }
  }

  static StackConfidence _fromScore(double avg) {
    if (avg >= 4.5) return StackConfidence.trusted;
    if (avg >= 3.5) return StackConfidence.strong;
    if (avg >= 2.5) return StackConfidence.established;
    if (avg >= 1.5) return StackConfidence.developing;
    return StackConfidence.limitedEvidence;
  }
}
