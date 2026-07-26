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
    this.subdiscipline = '',
    this.supportsVariants = false,
    this.variants = const [],
    this.aliases = const [],
    this.tags = const [],
    this.equipmentOptions = const [],
    this.isActive = true,
    this.isSystemSkill = true,
  });

  final String id;
  final String name;
  final String discipline;
  final String subdiscipline;
  final String summary;
  final String defaultUnit;
  final List<String> allowedUnits;
  final MeasurementType measurementType;
  final PerformanceType performanceType;
  final bool supportsVariants;
  final List<SkillCatalogVariant> variants;
  final List<String> aliases;
  final List<String> tags;
  final List<String> equipmentOptions;
  final bool isActive;
  final bool isSystemSkill;

  bool get isCustom =>
      id == 'custom_skill' ||
      id == 'custom_team_sports_skill' ||
      id == 'custom_combat_sports_skill' ||
      id.startsWith('custom_');

  bool get hasMultipleUnits => allowedUnits.length > 1;

  bool get higherIsBetter => performanceType.higherIsBetter;

  /// Primary discipline plus discovery tags (e.g. Calisthenics, HYROX).
  List<String> get allDisciplines {
    final values = <String>{discipline, ...tags};
    return values.toList();
  }

  SkillCatalogVariant? findVariant(String? variantId) {
    if (variantId == null || variantId.isEmpty) return null;
    for (final variant in variants) {
      if (variant.id == variantId) return variant;
    }
    return null;
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    if (discipline.toLowerCase().contains(q)) return true;
    if (subdiscipline.toLowerCase().contains(q)) return true;
    if (summary.toLowerCase().contains(q)) return true;
    for (final alias in aliases) {
      if (alias.toLowerCase().contains(q)) return true;
    }
    for (final tag in tags) {
      if (tag.toLowerCase().contains(q)) return true;
    }
    for (final variant in variants) {
      if (variant.name.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}
