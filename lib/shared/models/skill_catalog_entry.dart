import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';

class SkillCatalogEntry {
  const SkillCatalogEntry({
    required this.id,
    required this.name,
    required this.discipline,
    required this.defaultUnit,
    required this.allowedUnits,
    required this.measurementType,
    required this.performanceType,
    this.summary = '',
  });

  final String id;
  final String name;
  final String discipline;
  final String summary;
  final String defaultUnit;
  final List<String> allowedUnits;
  final MeasurementType measurementType;
  final PerformanceType performanceType;

  bool get isCustom => id == 'custom_skill';

  bool get hasMultipleUnits => allowedUnits.length > 1;
}
