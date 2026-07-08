import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/timeline_milestone_evaluator.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';

void main() {
  final now = DateTime(2026, 7, 8);
  final identity = PhysicalIdentity(
    userId: 'u1',
    handle: 'athlete',
    displayName: 'Athlete',
    createdAt: now.subtract(const Duration(days: 400)),
    updatedAt: now,
    isPublic: true,
  );

  SkillModel skill({
    required String id,
    required String name,
    String discipline = 'Strength',
  }) {
    return SkillModel(
      id: id,
      userId: 'u1',
      name: name,
      discipline: discipline,
      createdAt: now,
      defaultUnit: 'reps',
      allowedUnits: const ['reps'],
      measurementType: MeasurementType.count,
      performanceType: PerformanceType.maxReps,
    );
  }

  ProofModel proof({
    required String id,
    required String skillId,
    ProofSource source = ProofSource.selfReported,
    double? normalizedValue,
  }) {
    return ProofModel(
      id: id,
      userId: 'u1',
      skillId: skillId,
      title: 'Proof',
      recordedAt: now,
      createdAt: now,
      result: normalizedValue?.toString() ?? '10',
      unit: 'reps',
      proofSource: source,
      normalizedValue: normalizedValue,
    );
  }

  group('TimelineMilestoneEvaluator', () {
    test('first skill creates started tracking milestone', () {
      final pushUps = skill(id: 's1', name: 'Push-ups');
      final milestones = TimelineMilestoneEvaluator.evaluateSkillAdded(
        skill: pushUps,
        allSkills: [pushUps],
      );

      expect(milestones.length, 1);
      expect(milestones.first.title, 'Started tracking Push-ups');
      expect(milestones.first.milestoneKey, 'first_skill');
    });

    test('new discipline milestone without repeating first skill', () {
      final squat = skill(id: 's2', name: 'Squat', discipline: 'Powerlifting');
      final milestones = TimelineMilestoneEvaluator.evaluateSkillAdded(
        skill: squat,
        allSkills: [
          skill(id: 's1', name: 'Push-ups'),
          squat,
        ],
      );

      expect(
        milestones.any((m) => m.title == 'New discipline added'),
        isTrue,
      );
      expect(
        milestones.any((m) => m.milestoneKey == 'first_skill'),
        isFalse,
      );
    });

    test('proof milestones include first proof and personal best', () {
      final pushUps = skill(id: 's1', name: 'Push-ups');
      final first = proof(id: 'p1', skillId: 's1', normalizedValue: 10);
      final second = proof(id: 'p2', skillId: 's1', normalizedValue: 15);

      final firstMilestones = TimelineMilestoneEvaluator.evaluateProofAdded(
        proof: first,
        skill: pushUps,
        allProofs: [first],
        priorSkillProofs: const [],
        previousConfidence: StackConfidence.limitedEvidence,
        newConfidence: StackConfidence.limitedEvidence,
        isPersonalBest: false,
      );

      expect(
        firstMilestones.any((m) => m.milestoneKey == 'first_proof'),
        isTrue,
      );
      expect(
        firstMilestones.any((m) => m.type == TimelineEventType.personalBest),
        isFalse,
      );

      final pbMilestones = TimelineMilestoneEvaluator.evaluateProofAdded(
        proof: second,
        skill: pushUps,
        allProofs: [first, second],
        priorSkillProofs: [first],
        previousConfidence: StackConfidence.limitedEvidence,
        newConfidence: StackConfidence.developing,
        isPersonalBest: true,
      );

      expect(
        pbMilestones.any((m) => m.title == 'New Push-ups personal best'),
        isTrue,
      );
      expect(
        pbMilestones.any((m) => m.type == TimelineEventType.confidence),
        isTrue,
      );
    });

    test('proof count achievements fire at thresholds only', () {
      final pushUps = skill(id: 's1', name: 'Push-ups');
      final proofs = List.generate(
        10,
        (i) => proof(id: 'p$i', skillId: 's1', normalizedValue: i.toDouble()),
      );
      final latest = proofs.last;

      final milestones = TimelineMilestoneEvaluator.evaluateProofAdded(
        proof: latest,
        skill: pushUps,
        allProofs: proofs,
        priorSkillProofs: proofs.sublist(0, 9),
        previousConfidence: StackConfidence.established,
        newConfidence: StackConfidence.strong,
        isPersonalBest: true,
      );

      expect(
        milestones.any((m) => m.milestoneKey == 'proofs_10'),
        isTrue,
      );
      expect(
        milestones.any((m) => m.milestoneKey == 'proofs_25'),
        isFalse,
      );
    });

    test('one year active milestone after 365 days', () {
      final milestones = TimelineMilestoneEvaluator.evaluateOneYearActive(
        identity: identity,
        asOf: now,
      );

      expect(milestones.length, 1);
      expect(milestones.first.milestoneKey, 'one_year_active');
    });
  });
}
