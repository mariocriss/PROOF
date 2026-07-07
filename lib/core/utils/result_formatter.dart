import 'package:proof/core/constants/measurement_units.dart';

class ResultFormatter {
  ResultFormatter._();

  static String display(String value, String unit) {
    if (value.isEmpty) return '';
    if (unit == MeasurementUnits.time) return value;
    if (unit == MeasurementUnits.percent) return '$value%';
    return '$value ${MeasurementUnits.label(unit)}';
  }
}
