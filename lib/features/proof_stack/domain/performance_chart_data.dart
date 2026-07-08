import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';

class PerformanceChartPoint {
  const PerformanceChartPoint({
    required this.date,
    required this.value,
    required this.label,
  });

  final DateTime date;
  final double value;
  final String label;
}

class PerformanceTrendLine {
  const PerformanceTrendLine({
    required this.slope,
    required this.intercept,
  });

  final double slope;
  final double intercept;

  double valueAtIndex(int index) => slope * index + intercept;
}

class PerformanceChartView {
  const PerformanceChartView._({
    required this.isUnlocked,
    required this.points,
    this.trend,
    required this.plottableCount,
  });

  factory PerformanceChartView.build({
    required SkillModel skill,
    required List<ProofModel> proofs,
    int unlockThreshold = 10,
  }) {
    final points = _extractPoints(skill, proofs);
    final unlocked = points.length >= unlockThreshold;

    return PerformanceChartView._(
      isUnlocked: unlocked,
      points: points,
      trend: unlocked ? _linearTrend(points) : null,
      plottableCount: points.length,
    );
  }

  final bool isUnlocked;
  final List<PerformanceChartPoint> points;
  final PerformanceTrendLine? trend;
  final int plottableCount;

  static const defaultUnlockThreshold = 10;

  static List<PerformanceChartPoint> _extractPoints(
    SkillModel skill,
    List<ProofModel> proofs,
  ) {
    final sorted = List<ProofModel>.from(proofs)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final points = <PerformanceChartPoint>[];
    for (final proof in sorted) {
      final value = proof.normalizedValue ??
          ResultNormalizer.parseNormalized(
            proof.result,
            skill.measurementType,
            proof.unit.isNotEmpty ? proof.unit : skill.defaultUnit,
          );
      if (value == null) continue;
      points.add(
        PerformanceChartPoint(
          date: proof.recordedAt,
          value: value,
          label: proof.formattedResult,
        ),
      );
    }
    return points;
  }

  static PerformanceTrendLine linearTrendFromValues(List<double> values) {
    if (values.isEmpty) {
      return const PerformanceTrendLine(slope: 0, intercept: 0);
    }
    if (values.length == 1) {
      return PerformanceTrendLine(slope: 0, intercept: values.first);
    }

    final points = [
      for (var i = 0; i < values.length; i++)
        PerformanceChartPoint(
          date: DateTime.fromMillisecondsSinceEpoch(i),
          value: values[i],
          label: '',
        ),
    ];
    return _linearTrend(points);
  }

  static PerformanceTrendLine _linearTrend(List<PerformanceChartPoint> points) {
    if (points.length == 1) {
      return PerformanceTrendLine(slope: 0, intercept: points.first.value);
    }

    final n = points.length;
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumXX = 0.0;

    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = points[i].value;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator == 0) {
      final average = sumY / n;
      return PerformanceTrendLine(slope: 0, intercept: average);
    }

    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    final intercept = (sumY - (slope * sumX)) / n;
    return PerformanceTrendLine(slope: slope, intercept: intercept);
  }
}
