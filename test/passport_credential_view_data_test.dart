import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/passport/domain/passport_credential_view_data.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';

void main() {
  final now = DateTime(2026, 7, 9);

  final identity = PhysicalIdentity(
    userId: 'u1',
    handle: 'mario',
    displayName: 'Mario Rossi',
    createdAt: DateTime(2026, 1, 15),
    updatedAt: DateTime(2026, 1, 15),
  );

  SkillModel skill({
    required String id,
    required String name,
  }) {
    return SkillModel(
      id: id,
      userId: 'u1',
      name: name,
      discipline: 'Strength',
      createdAt: DateTime(2026, 1, 20),
      defaultUnit: 'reps',
      allowedUnits: const ['reps'],
      measurementType: MeasurementType.count,
      performanceType: PerformanceType.maxReps,
      status: SkillStatus.active,
    );
  }

  ProofModel proof({
    required String id,
    required String skillId,
    required DateTime recordedAt,
    ProofSource source = ProofSource.selfReported,
  }) {
    return ProofModel(
      id: id,
      userId: 'u1',
      skillId: skillId,
      title: '40 reps',
      recordedAt: recordedAt,
      createdAt: recordedAt,
      result: '40',
      unit: 'reps',
      proofSource: source,
    );
  }

  test('builds credential stats and trust indicators from live data', () {
    final skills = [
      skill(id: 's1', name: 'Push-ups'),
      skill(id: 's2', name: 'Pull-ups'),
    ];

    final proofs = [
      proof(
        id: 'p1',
        skillId: 's1',
        recordedAt: DateTime(2026, 1, 21),
      ),
      proof(
        id: 'p2',
        skillId: 's1',
        recordedAt: DateTime(2026, 2, 10),
      ),
      proof(
        id: 'p3',
        skillId: 's1',
        recordedAt: DateTime(2026, 3, 5),
        source: ProofSource.coach,
      ),
    ];

    final timeline = [
      TimelineEvent(
        id: 't1',
        userId: 'u1',
        type: TimelineEventType.milestone,
        title: 'Reached Developing',
        createdAt: DateTime(2026, 3, 1),
      ),
    ];

    final data = PassportCredentialViewData.build(
      identity: identity,
      skills: skills,
      proofs: proofs,
      timeline: timeline,
      publicUrl: 'https://proof.app/passport/mario',
      now: () => now,
    );

    expect(data.skillsCount, 2);
    expect(data.proofsCount, 3);
    expect(data.coachVerifiedCount, 1);
    expect(data.trustIndicators.mostConsistent, 'Push-ups');
    expect(data.trustIndicators.latestMilestone, 'Reached Developing');
    expect(data.publicUrl, contains('mario'));
  });
}
