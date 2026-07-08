import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';

void main() {
  final now = DateTime(2026, 7, 8);
  final skill = SkillModel(
    id: 's1',
    userId: 'u1',
    name: 'Push-ups',
    discipline: 'Strength',
    createdAt: now.subtract(const Duration(days: 30)),
    defaultUnit: 'reps',
    allowedUnits: const ['reps'],
    measurementType: MeasurementType.count,
    performanceType: PerformanceType.maxReps,
    currentBest: '16',
    currentBestUnit: 'reps',
    normalizedBestValue: 16,
    targetValue: '20',
    targetUnit: 'reps',
  );

  ProofModel proof({
    required String id,
    required DateTime recordedAt,
    required double value,
    ProofSource source = ProofSource.selfReported,
  }) {
    return ProofModel(
      id: id,
      userId: 'u1',
      skillId: 's1',
      title: '$value reps',
      recordedAt: recordedAt,
      createdAt: recordedAt,
      result: value.toString(),
      unit: 'reps',
      proofSource: source,
      normalizedValue: value,
    );
  }

  test('summary calculates trend and verification counts', () {
    final proofs = [
      proof(
        id: 'p1',
        recordedAt: now.subtract(const Duration(days: 20)),
        value: 13,
      ),
      proof(
        id: 'p2',
        recordedAt: now.subtract(const Duration(days: 10)),
        value: 15,
        source: ProofSource.coach,
      ),
      proof(id: 'p3', recordedAt: now.subtract(const Duration(days: 2)), value: 16),
    ];

    final summary = ProofStackSkillSummary.build(
      skill: skill,
      proofs: proofs,
      now: () => now,
    );

    expect(summary.totalProofs, 3);
    expect(summary.proofStackLabel, '3 proofs');
    expect(summary.selfReportedCount, 2);
    expect(summary.coachVerifiedCount, 1);
    expect(summary.trend, ProofStackTrend.improving);
  });

  test('single proof uses not enough evidence trend', () {
    final summary = ProofStackSkillSummary.build(
      skill: skill,
      proofs: [
        proof(
          id: 'p1',
          recordedAt: now.subtract(const Duration(days: 2)),
          value: 10,
        ),
      ],
      now: () => now,
    );

    expect(summary.trend, ProofStackTrend.notEnoughEvidence);
    expect(summary.proofStackLabel, '1 proof');
  });

  test('detail groups proofs and builds milestones', () {
    final proofs = [
      proof(
        id: 'p1',
        recordedAt: now.subtract(const Duration(days: 20)),
        value: 13,
      ),
      proof(
        id: 'p2',
        recordedAt: now.subtract(const Duration(days: 10)),
        value: 15,
        source: ProofSource.coach,
      ),
      proof(id: 'p3', recordedAt: now.subtract(const Duration(days: 2)), value: 16),
    ];

    final detail = SkillProofStackDetail.build(
      skill: skill,
      proofs: proofs,
      now: () => now,
    );

    expect(detail.verificationGroups.length, 2);
    expect(detail.verificationGroups.last.isEmpty, isFalse);
    expect(detail.trustProfile.filledSegments, 3);
    expect(detail.performanceHistory.first.formattedResult, contains('13'));
    expect(detail.milestones.any((m) => m.title == 'First proof'), isTrue);
    expect(
      detail.milestones.any((m) => m.title == 'First coach verification'),
      isTrue,
    );
    expect(detail.remainingProgress, '4 reps to target');
  });

  test('inactive trend when no recent proofs', () {
    final proofs = [
      proof(
        id: 'p1',
        recordedAt: now.subtract(const Duration(days: 120)),
        value: 10,
      ),
      proof(
        id: 'p2',
        recordedAt: now.subtract(const Duration(days: 100)),
        value: 11,
      ),
    ];

    final summary = ProofStackSkillSummary.build(
      skill: skill,
      proofs: proofs,
      now: () => now,
    );

    expect(summary.trend, ProofStackTrend.inactive);
  });

  test('declining trend when regression slope is down', () {
    final proofs = [
      proof(
        id: 'p1',
        recordedAt: now.subtract(const Duration(days: 20)),
        value: 16,
      ),
      proof(
        id: 'p2',
        recordedAt: now.subtract(const Duration(days: 10)),
        value: 14,
      ),
      proof(id: 'p3', recordedAt: now.subtract(const Duration(days: 2)), value: 12),
    ];

    final summary = ProofStackSkillSummary.build(
      skill: skill,
      proofs: proofs,
      now: () => now,
    );

    expect(summary.trend, ProofStackTrend.declining);
  });

  test('improving trend when latest dip but average line rises', () {
    final proofs = [
      proof(
        id: 'p1',
        recordedAt: now.subtract(const Duration(days: 50)),
        value: 10,
      ),
      proof(
        id: 'p2',
        recordedAt: now.subtract(const Duration(days: 40)),
        value: 12,
      ),
      proof(
        id: 'p3',
        recordedAt: now.subtract(const Duration(days: 30)),
        value: 14,
      ),
      proof(
        id: 'p4',
        recordedAt: now.subtract(const Duration(days: 20)),
        value: 15,
      ),
      proof(
        id: 'p5',
        recordedAt: now.subtract(const Duration(days: 10)),
        value: 16,
      ),
      proof(
        id: 'p6',
        recordedAt: now.subtract(const Duration(days: 2)),
        value: 14,
      ),
    ];

    final summary = ProofStackSkillSummary.build(
      skill: skill,
      proofs: proofs,
      now: () => now,
    );

    expect(summary.trend, ProofStackTrend.improving);
  });
}
