import 'package:proof/core/constants/measurement_units.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';

class NormalizedResult {
  const NormalizedResult({
    required this.originalResult,
    required this.originalUnit,
    this.normalizedValue,
  });

  final String originalResult;
  final String originalUnit;
  final double? normalizedValue;
}

class ResultNormalizer {
  ResultNormalizer._();

  static NormalizedResult normalize({
    required String rawValue,
    required String unit,
    required MeasurementType measurementType,
  }) {
    final trimmed = rawValue.trim();
    final base = NormalizedResult(
      originalResult: trimmed,
      originalUnit: unit,
    );

    switch (measurementType) {
      case MeasurementType.weight:
        final value = double.tryParse(trimmed);
        if (value == null) return base;
        final kg = unit == MeasurementUnits.lbs ? value * 0.45359237 : value;
        return NormalizedResult(
          originalResult: trimmed,
          originalUnit: unit,
          normalizedValue: kg,
        );

      case MeasurementType.distance:
        final value = double.tryParse(trimmed);
        if (value == null) return base;
        return NormalizedResult(
          originalResult: trimmed,
          originalUnit: unit,
          normalizedValue: _toMeters(value, unit),
        );

      case MeasurementType.duration:
        final seconds = parseDurationToSeconds(trimmed);
        if (seconds == null) return base;
        return NormalizedResult(
          originalResult: trimmed,
          originalUnit: unit,
          normalizedValue: seconds,
        );

      case MeasurementType.count:
      case MeasurementType.calories:
      case MeasurementType.score:
      case MeasurementType.percentage:
        final value = double.tryParse(trimmed);
        if (value == null) return base;
        return NormalizedResult(
          originalResult: trimmed,
          originalUnit: unit,
          normalizedValue: value,
        );
    }
  }

  static double _toMeters(double value, String unit) {
    switch (unit) {
      case MeasurementUnits.mi:
        return value * 1609.344;
      case MeasurementUnits.km:
        return value * 1000;
      case MeasurementUnits.m:
        return value;
      default:
        return value;
    }
  }

  static double? parseDurationToSeconds(String input) {
    final parts = input.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m != null && s != null) return (m * 60 + s).toDouble();
    }
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h != null && m != null && s != null) {
        return (h * 3600 + m * 60 + s).toDouble();
      }
    }
    return double.tryParse(input);
  }

  static double? parseNormalized(String? raw, MeasurementType type, String unit) {
    if (raw == null || raw.isEmpty) return null;
    return normalize(
      rawValue: raw,
      unit: unit,
      measurementType: type,
    ).normalizedValue;
  }
}

class BestResultLogic {
  BestResultLogic._();

  static bool isBetter({
    required double candidate,
    required double? current,
    required PerformanceType performanceType,
  }) {
    if (current == null) return true;
    if (performanceType.higherIsBetter) {
      return candidate > current;
    }
    return candidate < current;
  }

  static bool shouldUpdateSkillBest({
    required NormalizedResult proofResult,
    required SkillBestContext skill,
  }) {
    final candidate = proofResult.normalizedValue;
    if (candidate == null) return false;
    return isBetter(
      candidate: candidate,
      current: skill.normalizedBestValue,
      performanceType: skill.performanceType,
    );
  }
}

class SkillBestContext {
  const SkillBestContext({
    required this.performanceType,
    this.normalizedBestValue,
  });

  final PerformanceType performanceType;
  final double? normalizedBestValue;
}
