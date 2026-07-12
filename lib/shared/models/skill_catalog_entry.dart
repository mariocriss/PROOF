import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/skill_catalog_variant.dart';

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
    this.supportsVariants = false,
    this.variants = const [],
  });

  final String id;
  final String name;
  final String discipline;
  final String summary;
  final String defaultUnit;
  final List<String> allowedUnits;
  final MeasurementType measurementType;
  final PerformanceType performanceType;
  final bool supportsVariants;
  final List<SkillCatalogVariant> variants;

  bool get isCustom => id == 'custom_skill';

  bool get hasMultipleUnits => allowedUnits.length > 1;

  SkillCatalogVariant? findVariant(String? variantId) {
    if (variantId == null || variantId.isEmpty) return null;
    for (final variant in variants) {
      if (variant.id == variantId) return variant;
    }
    return null;
  }
}
