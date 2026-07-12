import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/goal_progress.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/widgets/confidence_block_progress.dart';

class SkillGoalProgressCard extends StatelessWidget {
  const SkillGoalProgressCard({
    super.key,
    required this.skill,
    this.onEditTarget,
    this.onGoalReached,
  });

  final SkillModel skill;
  final VoidCallback? onEditTarget;
  final VoidCallback? onGoalReached;

  @override
  Widget build(BuildContext context) {
    final progress = GoalProgress.forSkill(skill);
    final hasTarget = skill.formattedTarget != null;
    if (!hasTarget && progress == null) {
      return const SizedBox.shrink();
    }

    final goal = progress;
    final hasMeasurableProgress = goal != null && goal.hasTarget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Goal',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (onEditTarget != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.inkMuted,
                  onPressed: onEditTarget,
                  tooltip: 'Edit target',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _GoalRow(
            label: 'Current best',
            value: goal?.currentLabel ?? skill.formattedCurrentBest ?? '—',
          ),
          const SizedBox(height: 12),
          _GoalRow(
            label: 'Target',
            value: goal?.targetLabel ?? skill.formattedTarget ?? 'Not set',
          ),
          if (hasMeasurableProgress) ...[
            const SizedBox(height: 20),
            if (goal.targetReached) ...[
              Text(
                'Goal reached',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                goal.targetLabel,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ] else ...[
              Text(
                'Progress',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(goal.progress * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            ConfidenceBlockProgress(
              filled: goal.filledSegments,
              total: 8,
            ),
            const SizedBox(height: 12),
            Text(
              goal.remainingLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: goal.targetReached
                        ? AppColors.accent
                        : AppColors.inkSecondary,
                  ),
            ),
            if (goal.targetReached && onGoalReached != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onGoalReached,
                      child: const Text('Set a new target'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
