import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/goal_progress.dart';
import 'package:proof/core/utils/skill_uniqueness.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/skill_model.dart';

void main() {
  SkillModel skill({
    String? catalogId,
    String? variantId,
    String name = 'Push-ups',
  }) {
    return SkillModel(
      id: 's1',
      userId: 'u1',
      name: name,
      discipline: 'Strength',
      createdAt: DateTime(2026, 1, 1),
      defaultUnit: 'reps',
      allowedUnits: const ['reps'],
      measurementType: MeasurementType.count,
      performanceType: PerformanceType.maxReps,
      catalogId: catalogId,
      variantId: variantId,
      currentBest: '16',
      currentBestUnit: 'reps',
      normalizedBestValue: 16,
      targetValue: '30',
      targetUnit: 'reps',
    );
  }

  test('canonical key separates variants for catalog skills', () {
    final standard = skill(catalogId: 'strength_push_ups', variantId: 'standard');
    final diamond = skill(catalogId: 'strength_push_ups', variantId: 'diamond');

    expect(
      SkillUniqueness.canonicalKey(standard),
      isNot(SkillUniqueness.canonicalKey(diamond)),
    );
    expect(
      SkillUniqueness.canonicalKey(standard),
      contains(':standard'),
    );
  });

  test('legacy catalog skills without variant map to standard', () {
    final legacy = skill(catalogId: 'strength_push_ups');
    final explicit = skill(catalogId: 'strength_push_ups', variantId: 'standard');

    expect(
      SkillUniqueness.canonicalKey(legacy),
      SkillUniqueness.canonicalKey(explicit),
    );
  });

  test('goal progress caps at 100 percent for higher-is-better skills', () {
    final onTrack = skill();
    final progress = GoalProgress.forSkill(onTrack);

    expect(progress, isNotNull);
    expect(progress!.progress, closeTo(16 / 30, 0.01));
    expect(progress.targetReached, isFalse);
    expect(progress.remainingLabel, '14 reps remaining');
  });

  test('goal progress reports target achieved when reached', () {
    final reached = skill()
        .copyWith(
          currentBest: '30',
          normalizedBestValue: 30,
        );
    final progress = GoalProgress.forSkill(reached);

    expect(progress?.targetReached, isTrue);
    expect(progress?.progress, 1.0);
    expect(progress?.remainingLabel, 'Target achieved');
  });
}
