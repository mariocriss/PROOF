import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/skill_stack_reconciler.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';

void main() {
  SkillModel skill({
    required String id,
    SkillStatus status = SkillStatus.active,
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
      status: status,
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

  test('duplicateGroups finds active and paused duplicates', () {
    final groups = SkillStackReconciler.duplicateGroups([
      skill(id: 's1', catalogId: 'strength_pull_ups'),
      skill(id: 's2', catalogId: 'strength_pull_ups', status: SkillStatus.paused),
      skill(id: 's3', name: 'Push-ups', catalogId: 'strength_push_ups'),
    ]);

    expect(groups.length, 1);
    expect(groups.first.map((s) => s.id), containsAll(['s1', 's2']));
  });

  test('orphanedProofReassignments finds proofs on archived duplicates', () {
    final primary = skill(id: 's1', catalogId: 'strength_pull_ups');
    final archived = skill(
      id: 's2',
      catalogId: 'strength_pull_ups',
      status: SkillStatus.archived,
    );
    final proofs = [proof(id: 'p1', skillId: 's2')];

    final reassignments = SkillStackReconciler.orphanedProofReassignments(
      skills: [primary, archived],
      proofs: proofs,
    );

    expect(reassignments.length, 1);
    expect(reassignments.first.primary.id, 's1');
    expect(reassignments.first.proof.id, 'p1');
  });

  test('isTrackedCapability excludes archived skills', () {
    expect(
      SkillStackReconciler.isTrackedCapability(
        skill(id: 's1', status: SkillStatus.archived),
      ),
      isFalse,
    );
    expect(
      SkillStackReconciler.isTrackedCapability(
        skill(id: 's1', status: SkillStatus.paused),
      ),
      isTrue,
    );
  });
}
