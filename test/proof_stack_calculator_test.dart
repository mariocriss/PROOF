import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';

void main() {
  ProofModel proof({
    required String id,
    required DateTime recordedAt,
    ProofSource source = ProofSource.selfReported,
  }) {
    return ProofModel(
      id: id,
      userId: 'u1',
      skillId: 's1',
      title: '16 reps',
      recordedAt: recordedAt,
      createdAt: recordedAt,
      result: '16',
      unit: 'reps',
      proofSource: source,
      normalizedValue: 16,
    );
  }

  test('developing requires at least three proofs on two dates', () {
    final now = DateTime(2026, 7, 8);
    final proofs = [
      proof(id: 'p1', recordedAt: now.subtract(const Duration(days: 10))),
      proof(id: 'p2', recordedAt: now.subtract(const Duration(days: 5))),
      proof(id: 'p3', recordedAt: now),
    ];

    expect(
      ProofStackCalculator.calculate(proofs),
      StackConfidence.developing,
    );
  });

  test('limited evidence when proofs share the same date', () {
    final now = DateTime(2026, 7, 8);
    final proofs = [
      proof(id: 'p1', recordedAt: now),
      proof(id: 'p2', recordedAt: now),
      proof(id: 'p3', recordedAt: now),
    ];

    expect(
      ProofStackCalculator.calculate(proofs),
      StackConfidence.limitedEvidence,
    );
  });
}
