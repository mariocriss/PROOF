import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/shared/models/skill_model.dart';

class GoalProgress {
  const GoalProgress({
    required this.hasTarget,
    required this.targetReached,
    required this.progress,
    required this.remainingLabel,
    required this.currentLabel,
    required this.targetLabel,
  });

  final bool hasTarget;
  final bool targetReached;
  final double progress;
  final String remainingLabel;
  final String currentLabel;
  final String targetLabel;

  int get filledSegments {
    if (!hasTarget) return 0;
    return (progress.clamp(0.0, 1.0) * 8).round().clamp(0, 8);
  }

  static GoalProgress? forSkill(SkillModel skill) {
    if (skill.targetValue == null || skill.targetValue!.isEmpty) {
      return null;
    }
    if (skill.currentBest == null || skill.currentBest!.isEmpty) {
      return null;
    }

    final unit = skill.targetUnit ?? skill.defaultUnit;
    final currentLabel = skill.formattedCurrentBest!;
    final targetLabel = skill.formattedTarget!;

    final current = ResultNormalizer.parseNormalized(
      skill.currentBest,
      skill.measurementType,
      skill.currentBestUnit ?? skill.defaultUnit,
    );
    final target = ResultNormalizer.parseNormalized(
      skill.targetValue,
      skill.measurementType,
      unit,
    );

    if (current == null || target == null) return null;

    if (skill.performanceType.higherIsBetter) {
      final reached = current >= target;
      final progress = reached ? 1.0 : (current / target).clamp(0.0, 1.0);
      final remaining = (target - current).clamp(0.0, double.infinity);
      return GoalProgress(
        hasTarget: true,
        targetReached: reached,
        progress: progress,
        currentLabel: currentLabel,
        targetLabel: targetLabel,
        remainingLabel: reached
            ? 'Target achieved'
            : '${_format(remaining)} $unit remaining',
      );
    }

    final reached = current <= target;
    if (reached) {
      return GoalProgress(
        hasTarget: true,
        targetReached: true,
        progress: 1.0,
        currentLabel: currentLabel,
        targetLabel: targetLabel,
        remainingLabel: 'Target achieved',
      );
    }

    final delta = current - target;
    return GoalProgress(
      hasTarget: true,
      targetReached: false,
      progress: 0,
      currentLabel: currentLabel,
      targetLabel: targetLabel,
      remainingLabel: '${_format(delta)} $unit to improve',
    );
  }

  static String _format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
