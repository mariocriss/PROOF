import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/proof_stack/domain/performance_chart_data.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';

void main() {
  final skill = SkillModel(
    id: 's1',
    userId: 'u1',
    name: 'Push-ups',
    discipline: 'Strength',
    createdAt: DateTime(2026, 1, 1),
    defaultUnit: 'reps',
    allowedUnits: const ['reps'],
    measurementType: MeasurementType.count,
    performanceType: PerformanceType.maxReps,
  );

  List<ProofModel> proofs(int count) {
    return List.generate(
      count,
      (i) => ProofModel(
        id: 'p$i',
        userId: 'u1',
        skillId: 's1',
        title: '${10 + i} reps',
        recordedAt: DateTime(2026, 1, i + 1),
        createdAt: DateTime(2026, 1, i + 1),
        result: '${10 + i}',
        unit: 'reps',
        proofSource: ProofSource.selfReported,
        normalizedValue: (10 + i).toDouble(),
      ),
    );
  }

  test('chart locked below 10 proofs', () {
    final chart = PerformanceChartView.build(
      skill: skill,
      proofs: proofs(4),
    );

    expect(chart.isUnlocked, isFalse);
    expect(chart.plottableCount, 4);
    expect(chart.trend, isNull);
  });

  test('chart unlocked at 10 proofs with trend line', () {
    final chart = PerformanceChartView.build(
      skill: skill,
      proofs: proofs(10),
    );

    expect(chart.isUnlocked, isTrue);
    expect(chart.points.length, 10);
    expect(chart.trend, isNotNull);
    expect(chart.trend!.slope, greaterThan(0));
  });
}
