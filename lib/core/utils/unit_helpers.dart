import 'package:proof/core/constants/measurement_units.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';

List<String> unitsForMeasurementType(MeasurementType type) {
  switch (type) {
    case MeasurementType.count:
      return [MeasurementUnits.reps];
    case MeasurementType.weight:
      return [MeasurementUnits.kg, MeasurementUnits.lbs];
    case MeasurementType.duration:
      return [MeasurementUnits.time];
    case MeasurementType.distance:
      return [MeasurementUnits.m, MeasurementUnits.km, MeasurementUnits.mi];
    case MeasurementType.calories:
      return [MeasurementUnits.kcal];
    case MeasurementType.score:
      return [MeasurementUnits.points];
    case MeasurementType.percentage:
      return [MeasurementUnits.percent];
  }
}

String defaultUnitForMeasurementType(MeasurementType type) {
  return unitsForMeasurementType(type).first;
}

PerformanceType defaultPerformanceFor(MeasurementType type) {
  switch (type) {
    case MeasurementType.count:
      return PerformanceType.maxReps;
    case MeasurementType.weight:
    case MeasurementType.calories:
    case MeasurementType.percentage:
      return PerformanceType.maxValue;
    case MeasurementType.duration:
      return PerformanceType.longestDuration;
    case MeasurementType.distance:
      return PerformanceType.longestDistance;
    case MeasurementType.score:
      return PerformanceType.highestScore;
  }
}
