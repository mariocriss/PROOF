import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/skill_display_name.dart';
import 'package:proof/features/skills/domain/skill_dropdown.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';

SkillModel _skill({
  required String id,
  String name = 'Pull-up',
  String? variantId,
  String? variantName,
  String? catalogId,
  SkillStatus status = SkillStatus.active,
}) {
  return SkillModel(
    id: id,
    userId: 'user',
    name: name,
    discipline: 'Calisthenics',
    createdAt: DateTime(2026),
    defaultUnit: 'reps',
    allowedUnits: const ['reps'],
    measurementType: MeasurementType.count,
    performanceType: PerformanceType.maxReps,
    catalogId: catalogId,
    variantId: variantId,
    variantName: variantName,
    status: status,
  );
}

/// Mirrors the Add Proof skill dropdown contract (ID-based, deduped).
class SkillIdDropdownHarness extends StatelessWidget {
  const SkillIdDropdownHarness({
    super.key,
    required this.skills,
    required this.selectedId,
    this.onChanged,
  });

  final List<SkillModel> skills;
  final String? selectedId;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final items = uniqueSkillsById(
      skills.where((s) => s.status == SkillStatus.active),
    );
    final value = resolvedSkillDropdownValue(
      selectedId: selectedId,
      skills: items,
    );

    return MaterialApp(
      home: Scaffold(
        body: Form(
          child: DropdownButtonFormField<String>(
            key: ValueKey('harness-$value-${items.length}'),
            initialValue: value,
            items: [
              for (final s in items)
                DropdownMenuItem<String>(
                  value: s.id,
                  child: Text(SkillDisplayName.format(s)),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

void main() {
  group('uniqueSkillsById', () {
    test('keeps a single skill', () {
      final skills = [_skill(id: 'a')];
      expect(uniqueSkillsById(skills).map((s) => s.id), ['a']);
    });

    test('deduplicates duplicate skill IDs and keeps first', () {
      final first = _skill(id: 'a', name: 'Pull-up');
      final second = _skill(id: 'a', name: 'Pull-up refreshed');
      final result = uniqueSkillsById([first, second, _skill(id: 'b')]);
      expect(result.map((s) => s.id), ['a', 'b']);
      expect(result.first.name, 'Pull-up');
    });

    test('keeps same display name when IDs differ', () {
      final result = uniqueSkillsById([
        _skill(id: 'a', name: 'Pull-up', variantId: 'standard'),
        _skill(id: 'b', name: 'Pull-up', variantId: 'wide'),
      ]);
      expect(result.map((s) => s.id), ['a', 'b']);
    });

    test('keeps catalog and custom skills with distinct IDs', () {
      final result = uniqueSkillsById([
        _skill(id: 'catalog-1', catalogId: 'pull_up'),
        _skill(id: 'custom-1', name: 'My move'),
      ]);
      expect(result.map((s) => s.id), ['catalog-1', 'custom-1']);
    });
  });

  group('resolvedSkillDropdownValue', () {
    test('returns selected ID when it exists once', () {
      final skills = [_skill(id: 'a'), _skill(id: 'b')];
      expect(resolvedSkillDropdownValue(selectedId: 'b', skills: skills), 'b');
    });

    test('returns null when selected ID is missing', () {
      final skills = [_skill(id: 'a')];
      expect(
        resolvedSkillDropdownValue(selectedId: 'missing', skills: skills),
        isNull,
      );
    });

    test('returns null when selected ID appears more than once', () {
      final skills = [_skill(id: 'a'), _skill(id: 'a')];
      expect(
        resolvedSkillDropdownValue(selectedId: 'a', skills: skills),
        isNull,
      );
    });
  });

  group('skillById', () {
    test('resolves refreshed SkillModel instances by ID', () {
      final selectedId = 'skill-1';
      final original = _skill(id: selectedId, name: 'Pull-up');
      final refreshed = _skill(id: selectedId, name: 'Pull-up');
      expect(identical(original, refreshed), isFalse);
      expect(skillById([refreshed], selectedId)?.id, selectedId);
    });
  });

  group('SkillIdDropdownHarness', () {
    testWidgets('renders with one skill', (tester) async {
      await tester.pumpWidget(
        SkillIdDropdownHarness(
          skills: [_skill(id: 'a')],
          selectedId: 'a',
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('survives refreshed SkillModel instances for same ID', (
      tester,
    ) async {
      await tester.pumpWidget(
        SkillIdDropdownHarness(
          skills: [_skill(id: 'a', name: 'Pull-up')],
          selectedId: 'a',
        ),
      );
      await tester.pumpWidget(
        SkillIdDropdownHarness(
          skills: [
            _skill(id: 'a', name: 'Pull-up'), // new instance after proof save
          ],
          selectedId: 'a',
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('dedupes duplicate IDs so dropdown does not assert', (
      tester,
    ) async {
      await tester.pumpWidget(
        SkillIdDropdownHarness(
          skills: [
            _skill(id: 'a'),
            _skill(id: 'a'),
            _skill(id: 'b'),
          ],
          selectedId: 'a',
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing selected ID uses null instead of crashing', (
      tester,
    ) async {
      await tester.pumpWidget(
        SkillIdDropdownHarness(
          skills: [_skill(id: 'a')],
          selectedId: 'gone',
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('same display name different IDs stay separate', (
      tester,
    ) async {
      final skills = [
        _skill(id: 'a', name: 'Pull-up', variantName: 'Standard'),
        _skill(id: 'b', name: 'Pull-up', variantName: 'Wide'),
      ];
      expect(uniqueSkillsById(skills).map((s) => s.id), ['a', 'b']);

      await tester.pumpWidget(
        SkillIdDropdownHarness(skills: skills, selectedId: 'b'),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Wide Pull-up'), findsOneWidget);
    });

    testWidgets('repeated proof-style refreshes keep selection by ID', (
      tester,
    ) async {
      var skills = [_skill(id: 'a')];
      String? selected = 'a';

      Future<void> pump() async {
        await tester.pumpWidget(
          SkillIdDropdownHarness(
            skills: skills,
            selectedId: selected,
            onChanged: (id) => selected = id,
          ),
        );
        await tester.pump();
      }

      await pump();
      for (var i = 0; i < 3; i++) {
        // Simulate addProof updating the skill document → new SkillModel.
        skills = [_skill(id: 'a', name: 'Pull-up')];
        await pump();
        expect(tester.takeException(), isNull);
        expect(selected, 'a');
      }
    });
  });
}
