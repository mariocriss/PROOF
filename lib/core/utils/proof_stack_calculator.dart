import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';

/// Computes stack confidence from proof history for a skill.
class ProofStackCalculator {
  ProofStackCalculator._();

  static StackConfidence calculate(List<ProofModel> proofs) {
    if (proofs.isEmpty) return StackConfidence.limitedEvidence;

    final count = proofs.length;
    final dates = proofs.map((p) => _dateOnly(p.recordedAt)).toSet();
    final distinctDates = dates.length;
    final spanDays = _spanDays(proofs);
    final coachProofCount =
        proofs.where((p) => p.proofSource == ProofSource.coach).length;

    if (count >= 20 &&
        spanDays >= 180 &&
        coachProofCount >= 3 &&
        _hasConsistentProgression(proofs)) {
      return StackConfidence.trusted;
    }

    if (count >= 10 && spanDays >= 90 && coachProofCount >= 2) {
      return StackConfidence.strong;
    }

    if (count >= 5 && spanDays >= 30 && coachProofCount >= 1) {
      return StackConfidence.established;
    }

    if (count >= 3 && distinctDates >= 2) {
      return StackConfidence.developing;
    }

    return StackConfidence.limitedEvidence;
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static int _spanDays(List<ProofModel> proofs) {
    if (proofs.length < 2) return 0;
    final sorted = proofs.map((p) => p.recordedAt).toList()..sort();
    return sorted.last.difference(sorted.first).inDays;
  }

  static bool _hasConsistentProgression(List<ProofModel> proofs) {
    final values = proofs
        .map((p) => p.normalizedValue)
        .whereType<double>()
        .toList();
    if (values.length < 3) {
      return proofs.where((p) => p.proofSource.isTrusted).length >= 2;
    }
    values.sort();
    return values.last > values.first;
  }
}
