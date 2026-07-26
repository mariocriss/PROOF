import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/skills/data/skill_catalog.dart';

void main() {
  test('catalog IDs are unique', () {
    final ids = SkillCatalog.all.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('legacy push-up and pull-up IDs remain stable', () {
    expect(SkillCatalog.findById('strength_push_ups'), isNotNull);
    expect(SkillCatalog.findById('strength_pull_ups'), isNotNull);
    expect(SkillCatalog.findById('strength_squats'), isNotNull);
    expect(SkillCatalog.findById('core_plank'), isNotNull);
  });

  test('push-up variants include expanded options and keep legacy ids', () {
    final pushUps = SkillCatalog.findById('strength_push_ups')!;
    final ids = pushUps.variants.map((v) => v.id).toSet();
    expect(ids.contains('standard'), isTrue);
    expect(ids.contains('knees'), isTrue);
    expect(ids.contains('diamond'), isTrue);
    expect(ids.contains('weighted'), isTrue);
    expect(ids.contains('hand_release'), isTrue);
    expect(ids.contains('max_1_min'), isTrue);
  });

  test('empty search returns curated active skills only', () {
    final browsing = SkillCatalog.search();
    expect(browsing.every((e) => e.isActive || e.isCustom), isTrue);
    expect(browsing.length, lessThan(SkillCatalog.all.length));
    expect(browsing.length, greaterThanOrEqualTo(80));
  });

  test('search finds inactive skills and aliases', () {
    final byAlias = SkillCatalog.search(query: 'press-up');
    expect(byAlias.any((e) => e.name == 'Push-ups'), isTrue);

    final inactive = SkillCatalog.search(query: 'Ultramarathon');
    expect(inactive.any((e) => e.name == 'Ultramarathon'), isTrue);
  });

  test('discipline filter includes tagged skills', () {
    final gymnasticsTagged = SkillCatalog.search(
      query: 'pull',
      discipline: 'Gymnastics',
    );
    expect(gymnasticsTagged.any((e) => e.name == 'Pull-ups'), isTrue);
  });

  test('no duplicate pistol squat base skills', () {
    final pistols = SkillCatalog.all
        .where((e) => e.name.toLowerCase().contains('pistol squat'))
        .toList();
    expect(pistols.length, 1);
  });

  test('team sports and combat sports expose an active custom skill', () {
    final team = SkillCatalog.search(discipline: 'Team Sports');
    final combat = SkillCatalog.search(discipline: 'Combat Sports');

    expect(team.any((e) => e.isCustom && e.discipline == 'Team Sports'), isTrue);
    expect(
      combat.any((e) => e.isCustom && e.discipline == 'Combat Sports'),
      isTrue,
    );
  });
}
