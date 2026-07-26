import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/passport/domain/passport_export_data.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/models/verification_status.dart';

void main() {
  final now = DateTime(2026, 7, 25);

  PhysicalIdentity identity({
    String name = 'Mario Rossi',
    String handle = 'mario',
    String bio = 'Athlete',
    String location = 'Rotterdam, Netherlands',
  }) {
    return PhysicalIdentity(
      userId: 'u1',
      handle: handle,
      displayName: name,
      bio: bio,
      location: location,
      createdAt: DateTime(2024, 3, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  SkillModel skill({
    required String id,
    required String name,
    String discipline = 'Strength',
    bool featured = false,
    String? best,
  }) {
    return SkillModel(
      id: id,
      userId: 'u1',
      name: name,
      discipline: discipline,
      createdAt: DateTime(2024, 4, 1),
      defaultUnit: 'reps',
      allowedUnits: const ['reps'],
      measurementType: MeasurementType.count,
      performanceType: PerformanceType.maxReps,
      status: SkillStatus.active,
      isFeatured: featured,
      currentBest: best,
      currentBestUnit: best == null ? null : 'reps',
    );
  }

  ProofModel proof({
    required String id,
    required String skillId,
    required DateTime recordedAt,
    ProofSource source = ProofSource.selfReported,
    VerificationStatus status = VerificationStatus.selfReported,
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
      verificationStatus: status,
    );
  }

  test('builds complete export with public URL and summary metrics', () {
    final data = PassportExportData.fromPassport(
      identity: identity(),
      skills: [
        skill(id: 's1', name: 'Push-ups', featured: true, best: '55'),
        skill(id: 's2', name: 'Pull-ups', discipline: 'Gymnastics', best: '12'),
      ],
      proofs: [
        proof(id: 'p1', skillId: 's1', recordedAt: DateTime(2026, 1, 1)),
        proof(
          id: 'p2',
          skillId: 's1',
          recordedAt: DateTime(2026, 2, 1),
          source: ProofSource.coach,
          status: VerificationStatus.coachVerified,
        ),
        proof(id: 'p3', skillId: 's2', recordedAt: DateTime(2026, 3, 1)),
      ],
      timeline: [
        TimelineEvent(
          id: 't1',
          userId: 'u1',
          type: TimelineEventType.milestone,
          title: 'First coach verification',
          subtitle: 'Push-ups',
          createdAt: DateTime(2026, 2, 1),
        ),
      ],
      gymName: 'CrossFit Rotterdam',
      coachName: 'Chris',
      now: () => now,
    );

    expect(data.publicUrl, 'https://proof.app/passport/mario');
    expect(data.displayName, 'Mario Rossi');
    expect(data.totalSkills, 2);
    expect(data.totalProofs, 3);
    expect(data.coachVerifiedProofs, 1);
    expect(data.gymName, 'CrossFit Rotterdam');
    expect(data.coachName, 'Chris');
    expect(data.featuredSkills, isNotEmpty);
    expect(data.featuredSkills.first.name, 'Push-ups');
    expect(data.domains.length, 2);
    expect(data.milestones, isNotEmpty);
    expect(data.suggestedFilename, 'PROOF_Mario_Rossi_Physical_Passport_2026.pdf');
  });

  test('hides optional fields when missing', () {
    final data = PassportExportData.fromPassport(
      identity: identity(bio: '', location: ''),
      skills: [skill(id: 's1', name: 'Push-ups')],
      proofs: [
        proof(id: 'p1', skillId: 's1', recordedAt: DateTime(2026, 1, 1)),
      ],
      timeline: const [],
      now: () => now,
    );

    expect(data.bio, isNull);
    expect(data.location, isNull);
    expect(data.gymName, isNull);
    expect(data.coachName, isNull);
    expect(data.milestones, isEmpty);
    expect(data.timeline, isEmpty);
  });

  test('excludes pending and rejected proofs from export counts', () {
    final data = PassportExportData.fromPassport(
      identity: identity(),
      skills: [skill(id: 's1', name: 'Push-ups')],
      proofs: [
        proof(id: 'p1', skillId: 's1', recordedAt: DateTime(2026, 1, 1)),
        proof(
          id: 'p2',
          skillId: 's1',
          recordedAt: DateTime(2026, 1, 2),
          status: VerificationStatus.pendingVerification,
        ),
        proof(
          id: 'p3',
          skillId: 's1',
          recordedAt: DateTime(2026, 1, 3),
          status: VerificationStatus.rejected,
        ),
      ],
      timeline: const [],
      now: () => now,
    );

    expect(data.totalProofs, 1);
  });

  test('sanitizes filename for long and special names', () {
    expect(
      PassportExportData.sanitizeFilenamePart('Mario / Rossi?'),
      'Mario_Rossi',
    );
    expect(
      PassportExportData.sanitizeFilenamePart('A' * 80).length,
      40,
    );
    expect(PassportExportData.sanitizeFilenamePart('@@@'), '');
  });

  test('handles many skills without inventing ranking data', () {
    final skills = List.generate(
      25,
      (i) => skill(
        id: 's$i',
        name: 'Skill $i',
        discipline: i.isEven ? 'Strength' : 'Endurance',
        best: '${10 + i}',
      ),
    );
    final proofs = skills
        .map(
          (s) => proof(
            id: 'p-${s.id}',
            skillId: s.id,
            recordedAt: DateTime(2026, 1, 1),
          ),
        )
        .toList();

    final data = PassportExportData.fromPassport(
      identity: identity(name: 'Very Long Athlete Name With Many Words'),
      skills: skills,
      proofs: proofs,
      timeline: const [],
      now: () => now,
    );

    expect(data.totalSkills, 25);
    expect(data.featuredSkills.length, lessThanOrEqualTo(6));
    expect(data.skillsByDomain.keys.length, 2);
    expect(data.suggestedFilename.contains('Very_Long_Athlete'), isTrue);
    for (final skill in data.featuredSkills) {
      // No percentile/ranking fields exist on export model.
      expect(skill.evidenceSummary.contains('%'), isFalse);
    }
  });

  test('export model does not expose private contact fields', () {
    final data = PassportExportData.fromPassport(
      identity: identity(),
      skills: const [],
      proofs: const [],
      timeline: const [],
      now: () => now,
    );

    final encoded = data.toString();
    expect(encoded.toLowerCase().contains('email'), isFalse);
    expect(encoded.toLowerCase().contains('phone'), isFalse);
    expect(data.publicUrl.startsWith('https://proof.app/passport/'), isTrue);
  });
}
