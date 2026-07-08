import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/timeline_rebuilder.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';

void main() {
  final base = DateTime(2025, 1, 1);
  final identity = PhysicalIdentity(
    userId: 'u1',
    handle: 'athlete',
    displayName: 'Athlete',
    createdAt: base,
    updatedAt: base,
    isPublic: true,
  );

  SkillModel skill({
    required String id,
    required String name,
    required DateTime createdAt,
    String discipline = 'Strength',
  }) {
    return SkillModel(
      id: id,
      userId: 'u1',
      name: name,
      discipline: discipline,
      createdAt: createdAt,
      defaultUnit: 'reps',
      allowedUnits: const ['reps'],
      measurementType: MeasurementType.count,
      performanceType: PerformanceType.maxReps,
    );
  }

  ProofModel proof({
    required String id,
    required String skillId,
    required DateTime recordedAt,
    double normalizedValue = 10,
    ProofSource source = ProofSource.selfReported,
  }) {
    return ProofModel(
      id: id,
      userId: 'u1',
      skillId: skillId,
      title: 'Proof',
      recordedAt: recordedAt,
      createdAt: recordedAt,
      result: normalizedValue.toString(),
      unit: 'reps',
      proofSource: source,
      normalizedValue: normalizedValue,
    );
  }

  test('rebuild replaces noisy history with milestone story', () {
    final pushUps = skill(
      id: 's1',
      name: 'Push-ups',
      createdAt: base.add(const Duration(days: 1)),
    );
    final squat = skill(
      id: 's2',
      name: 'Squat',
      createdAt: base.add(const Duration(days: 10)),
      discipline: 'Powerlifting',
    );

    final proofs = [
      proof(
        id: 'p1',
        skillId: 's1',
        recordedAt: base.add(const Duration(days: 2)),
        normalizedValue: 10,
      ),
      proof(
        id: 'p2',
        skillId: 's1',
        recordedAt: base.add(const Duration(days: 3)),
        normalizedValue: 15,
      ),
      proof(
        id: 'p3',
        skillId: 's1',
        recordedAt: base.add(const Duration(days: 4)),
        normalizedValue: 12,
      ),
    ];

    final events = TimelineRebuilder.rebuild(
      userId: 'u1',
      identity: identity,
      skills: [pushUps, squat],
      proofs: proofs,
      now: () => base.add(const Duration(days: 400)),
    );

    expect(events.any((e) => e.title.contains('Proof added')), isFalse);
    expect(events.any((e) => e.title.contains('Skill added')), isFalse);
    expect(
      events.any((e) => e.milestoneKey == 'identity_created'),
      isTrue,
    );
    expect(
      events.any((e) => e.title == 'Started tracking Push-ups'),
      isTrue,
    );
    expect(
      events.any((e) => e.title == 'New Push-ups personal best'),
      isTrue,
    );
    expect(
      events.any((e) => e.title == 'New discipline added'),
      isTrue,
    );
    expect(
      events.any((e) => e.milestoneKey == 'one_year_active'),
      isTrue,
    );
    expect(
      events.every((later) {
        final index = events.indexOf(later);
        if (index == 0) return true;
        return !later.createdAt.isBefore(events[index - 1].createdAt);
      }),
      isTrue,
    );
  });

  test('rebuild with no identity returns empty list', () {
    expect(
      TimelineRebuilder.rebuild(
        userId: 'u1',
        identity: null,
        skills: const [],
        proofs: const [],
      ),
      isEmpty,
    );
  });
}
