import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/verification_status.dart';

void main() {
  ProofModel proof({
    required VerificationStatus status,
    ProofSource source = ProofSource.selfReported,
  }) {
    final now = DateTime(2026, 7, 1);
    return ProofModel(
      id: 'p1',
      userId: 'u1',
      skillId: 's1',
      title: '40 reps',
      recordedAt: now,
      createdAt: now,
      result: '40',
      unit: 'reps',
      proofSource: source,
      verificationStatus: status,
      normalizedValue: 40,
    );
  }

  test('pending verification does not count as coach verified in stack', () {
    final confidence = ProofStackCalculator.calculate([
      proof(status: VerificationStatus.pendingVerification),
      proof(
        status: VerificationStatus.pendingVerification,
        source: ProofSource.coach,
      ),
      proof(status: VerificationStatus.selfReported),
    ]);

    expect(confidence, isNot(StackConfidence.established));
  });

  test('coach verified status counts toward stack confidence', () {
    final baseDate = DateTime(2026, 1, 1);
    final proofs = List.generate(5, (index) {
      final date = baseDate.add(Duration(days: index * 10));
      return ProofModel(
        id: 'p$index',
        userId: 'u1',
        skillId: 's1',
        title: '40 reps',
        recordedAt: date,
        createdAt: date,
        result: '40',
        unit: 'reps',
        proofSource: index == 4 ? ProofSource.coach : ProofSource.selfReported,
        verificationStatus: index == 4
            ? VerificationStatus.coachVerified
            : VerificationStatus.selfReported,
        normalizedValue: 40,
      );
    });

    final confidence = ProofStackCalculator.calculate(proofs);
    expect(confidence, StackConfidence.established);
  });
}
