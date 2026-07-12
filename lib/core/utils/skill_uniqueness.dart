import 'package:proof/features/skills/data/skill_catalog.dart';
import 'package:proof/shared/models/skill_catalog_variant.dart';
import 'package:proof/shared/models/skill_model.dart';

/// One physical capability + variant = one canonical key = one Proof Stack.
class SkillUniqueness {
  SkillUniqueness._();

  static const String defaultVariantKey = '_default';

  static String canonicalKey(SkillModel skill) {
    final catalogId = skill.catalogId?.trim();
    if (catalogId != null && catalogId.isNotEmpty) {
      final variant = effectiveVariantId(skill);
      return 'catalog:${catalogId.toLowerCase()}:$variant';
    }

    final variant = skill.variantId?.trim();
    if (variant != null && variant.isNotEmpty) {
      return 'name:${_normalize(skill.discipline)}:${_normalize(skill.name)}:${variant.toLowerCase()}';
    }
    return 'name:${_normalize(skill.discipline)}:${_normalize(skill.name)}';
  }

  /// Resolves the variant segment used for duplicate prevention.
  static String effectiveVariantId(SkillModel skill) {
    final stored = skill.variantId?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored.toLowerCase();
    }

    final catalogId = skill.catalogId?.trim();
    if (catalogId != null && catalogId.isNotEmpty) {
      final entry = SkillCatalog.findById(catalogId);
      if (entry != null && entry.supportsVariants) {
        return SkillCatalogVariant.standardId;
      }
      return defaultVariantKey;
    }

    return defaultVariantKey;
  }

  static String _normalize(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

class DuplicateSkillException implements Exception {
  DuplicateSkillException(this.existing);

  final SkillModel existing;
}
