import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';

void main() {
  SkillModel skill({
    required String id,
    String? catalogId,
    String name = 'Pull-ups',
  }) {
    return SkillModel(
      id: id,
      userId: 'u1',
      name: name,
      discipline: 'Strength',
      createdAt: DateTime(2026, 1, 1),
      defaultUnit: 'reps',
      allowedUnits: const ['reps'],
      measurementType: MeasurementType.count,
      performanceType: PerformanceType.maxReps,
      catalogId: catalogId,
      currentBest: '10',
      currentBestUnit: 'reps',
      normalizedBestValue: 10,
    );
  }

  ProofModel proof({required String id, required String skillId}) {
    return ProofModel(
      id: id,
      userId: 'u1',
      skillId: skillId,
      title: '10 reps',
      recordedAt: DateTime(2026, 7, 1),
      createdAt: DateTime(2026, 7, 1),
      result: '10',
      unit: 'reps',
      proofSource: ProofSource.selfReported,
      normalizedValue: 10,
    );
  }

  test('merge combines duplicate pull-up skills into one summary', () {
    final first = skill(id: 's1', catalogId: 'pull_ups');
    final duplicate = skill(id: 's2', catalogId: 'pull_ups');
    final proofs = [
      proof(id: 'p1', skillId: 's1'),
      proof(id: 'p2', skillId: 's2'),
    ];

    final summaries = ProofStackMerge.buildSummaries(
      skills: [first, duplicate],
      proofs: proofs,
    );

    expect(summaries.length, 1);
    expect(summaries.first.totalProofs, 2);
    expect(summaries.first.skill.name, 'Pull-ups');
  });

  test('merge combines skills with same name when catalog id missing', () {
    final first = skill(id: 's1', name: 'Pull-ups');
    final duplicate = skill(id: 's2', name: 'pull-ups');

    final summaries = ProofStackMerge.buildSummaries(
      skills: [first, duplicate],
      proofs: const [],
    );

    expect(summaries.length, 1);
  });
}
