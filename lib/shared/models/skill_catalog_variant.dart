class SkillCatalogVariant {
  const SkillCatalogVariant({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  static const String otherId = 'other';
  static const String standardId = 'standard';
}
