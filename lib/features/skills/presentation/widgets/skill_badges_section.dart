import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/skill_badge_evaluator.dart';
import 'package:proof/shared/models/skill_model.dart';

class SkillBadgesSection extends StatelessWidget {
  const SkillBadgesSection({super.key, required this.skill});

  final SkillModel skill;

  @override
  Widget build(BuildContext context) {
    final badges = SkillBadgeEvaluator.parseEarned(skill.earnedBadgeIds);
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Badges', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges
              .map(
                (badge) => _BadgeChip(
                  label: SkillBadgeEvaluator.displayLabel(badge, skill),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class PassportBadgesRow extends StatelessWidget {
  const PassportBadgesRow({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: labels
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}
