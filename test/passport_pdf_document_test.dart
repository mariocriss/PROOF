import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/passport/domain/passport_export_data.dart';
import 'package:proof/features/passport/presentation/pdf/passport_pdf_document.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';

void main() {
  test('generates a non-empty multipage-capable PDF for complete profile', () async {
    final identity = PhysicalIdentity(
      userId: 'u1',
      handle: 'mario',
      displayName: 'Mario Rossi',
      bio: 'Lifelong physical identity.',
      location: 'Rotterdam',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final skills = [
      SkillModel(
        id: 's1',
        userId: 'u1',
        name: 'Push-ups',
        discipline: 'Conditioning',
        createdAt: DateTime(2024, 2, 1),
        defaultUnit: 'reps',
        allowedUnits: const ['reps'],
        measurementType: MeasurementType.count,
        performanceType: PerformanceType.maxReps,
        status: SkillStatus.active,
        isFeatured: true,
        currentBest: '55',
        currentBestUnit: 'reps',
      ),
      SkillModel(
        id: 's2',
        userId: 'u1',
        name: 'Deadlift',
        discipline: 'Strength',
        createdAt: DateTime(2024, 3, 1),
        defaultUnit: 'kg',
        allowedUnits: const ['kg'],
        measurementType: MeasurementType.weight,
        performanceType: PerformanceType.maxValue,
        status: SkillStatus.active,
        currentBest: '140',
        currentBestUnit: 'kg',
      ),
    ];

    final proofs = [
      ProofModel(
        id: 'p1',
        userId: 'u1',
        skillId: 's1',
        title: '50 reps',
        recordedAt: DateTime(2026, 1, 10),
        createdAt: DateTime(2026, 1, 10),
        result: '50',
        unit: 'reps',
        proofSource: ProofSource.selfReported,
      ),
      ProofModel(
        id: 'p2',
        userId: 'u1',
        skillId: 's1',
        title: '55 reps',
        recordedAt: DateTime(2026, 2, 10),
        createdAt: DateTime(2026, 2, 10),
        result: '55',
        unit: 'reps',
        proofSource: ProofSource.coach,
      ),
    ];

    final timeline = [
      TimelineEvent(
        id: 't1',
        userId: 'u1',
        type: TimelineEventType.milestone,
        title: 'Joined PROOF',
        createdAt: DateTime(2024, 1, 1),
      ),
      TimelineEvent(
        id: 't2',
        userId: 'u1',
        type: TimelineEventType.personalBest,
        title: 'New Push-ups personal best',
        subtitle: '55 reps',
        createdAt: DateTime(2026, 2, 10),
      ),
    ];

    final export = PassportExportData.fromPassport(
      identity: identity,
      skills: skills,
      proofs: proofs,
      timeline: timeline,
      gymName: 'CrossFit Rotterdam',
      now: () => DateTime(2026, 7, 25),
    );

    final bytes = await PassportPdfDocument.build(export);
    expect(bytes.length, greaterThan(1000));
    expect(export.publicUrl, isNull);
  });

  test('generates PDF for sparse profile without optional data', () async {
    final export = PassportExportData.fromPassport(
      identity: PhysicalIdentity(
        userId: 'u2',
        handle: 'newbie',
        displayName: 'New Athlete',
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      ),
      skills: [
        SkillModel(
          id: 's1',
          userId: 'u2',
          name: 'Squats',
          discipline: 'Strength',
          createdAt: DateTime(2026, 7, 1),
          defaultUnit: 'reps',
          allowedUnits: const ['reps'],
          measurementType: MeasurementType.count,
          performanceType: PerformanceType.maxReps,
          status: SkillStatus.active,
        ),
      ],
      proofs: const [],
      timeline: const [],
      now: () => DateTime(2026, 7, 25),
    );

    final bytes = await PassportPdfDocument.build(export);
    expect(bytes.length, greaterThan(500));
    expect(export.bio, isNull);
    expect(export.gymName, isNull);
    expect(export.featuredSkills.length, 1);
  });
}
