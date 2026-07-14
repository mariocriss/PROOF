import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/gyms/domain/gym_manager_view_data.dart';
import 'package:proof/shared/models/gym_model.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class GymManagerSectionLabel extends StatelessWidget {
  const GymManagerSectionLabel({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.inkMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class GymManagerCard extends StatelessWidget {
  const GymManagerCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GymStatusBadge extends StatelessWidget {
  const GymStatusBadge({super.key, required this.status});

  final GymStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      GymStatus.active => 'Active Gym',
      GymStatus.draft => 'Draft',
      GymStatus.suspended => 'Suspended',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class GymManagerSkeleton extends StatelessWidget {
  const GymManagerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        _SkeletonBox(height: 120),
        SizedBox(height: 16),
        _SkeletonBox(height: 88),
        SizedBox(height: 16),
        _SkeletonBox(height: 140),
        SizedBox(height: 16),
        _SkeletonBox(height: 180),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class GymOverviewStat extends StatelessWidget {
  const GymOverviewStat({
    super.key,
    required this.count,
    required this.label,
  });

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

class GymStatTile extends StatelessWidget {
  const GymStatTile({
    super.key,
    required this.value,
    required this.label,
    this.isZero = false,
  });

  final String value;
  final String label;
  final bool isZero;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isZero ? AppColors.inkMuted : AppColors.ink,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

class GymZeroStatLine extends StatelessWidget {
  const GymZeroStatLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.inkMuted,
            fontStyle: FontStyle.italic,
          ),
    );
  }
}

class GymAttentionCard extends StatelessWidget {
  const GymAttentionCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final GymAttentionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.actionLabel} →',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GymQuickActionTile extends StatelessWidget {
  const GymQuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bg = highlighted ? AppColors.accent : AppColors.surface;
    final border = highlighted
        ? AppColors.accent
        : AppColors.border;
    final iconColor = highlighted ? Colors.white : AppColors.accent;
    final textColor = highlighted ? Colors.white : AppColors.ink;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: highlighted ? Colors.white : AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badge',
                          style: TextStyle(
                            color: highlighted
                                ? AppColors.accent
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: textColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GymActivityRow extends StatelessWidget {
  const GymActivityRow({super.key, required this.item});

  final GymActivityItem item;

  IconData get _icon => switch (item.type) {
        GymActivityType.athleteJoined => Icons.person_add_alt_1_outlined,
        GymActivityType.coachApproved => Icons.verified_outlined,
        GymActivityType.athleteRequest => Icons.inbox_outlined,
        GymActivityType.coachRequest => Icons.sports_outlined,
        GymActivityType.requestDeclined => Icons.block_outlined,
        GymActivityType.profileUpdated => Icons.apartment_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              ],
            ),
          ),
          Text(
            formatGymActivityDate(item.date),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class GymManagerEmptyPanel extends StatelessWidget {
  const GymManagerEmptyPanel({
    super.key,
    required this.title,
    required this.description,
    this.action,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String description;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

class GymCaughtUpCard extends StatelessWidget {
  const GymCaughtUpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GymManagerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                'All caught up',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'There are no pending membership requests.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class GymProfileCompletenessCard extends StatelessWidget {
  const GymProfileCompletenessCard({
    super.key,
    required this.completeness,
    required this.onComplete,
  });

  final GymProfileCompleteness completeness;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (completeness.isComplete) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GymManagerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete your gym profile',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completeness.percent / 100,
                minHeight: 6,
                backgroundColor: AppColors.surfaceElevated,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${completeness.percent}% complete',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
            if (completeness.missingFields.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Missing:\n${completeness.missingFields.take(3).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.4,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            ProofButton(
              label: 'Complete Profile',
              onPressed: onComplete,
            ),
          ],
        ),
      ),
    );
  }
}

class GymSearchField extends StatelessWidget {
  const GymSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class GymNeedsAttentionCard extends StatelessWidget {
  const GymNeedsAttentionCard({
    super.key,
    required this.athleteRequests,
    required this.coachRequests,
    required this.onAthleteTap,
    required this.onCoachTap,
  });

  final int athleteRequests;
  final int coachRequests;
  final VoidCallback onAthleteTap;
  final VoidCallback onCoachTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Needs Attention',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (athleteRequests > 0)
                Expanded(
                  child: _AttentionMetric(
                    count: athleteRequests,
                    label: athleteRequests == 1
                        ? 'Athlete Request'
                        : 'Athlete Requests',
                    onTap: onAthleteTap,
                  ),
                ),
              if (athleteRequests > 0 && coachRequests > 0)
                const SizedBox(width: 16),
              if (coachRequests > 0)
                Expanded(
                  child: _AttentionMetric(
                    count: coachRequests,
                    label: coachRequests == 1
                        ? 'Coach Request'
                        : 'Coach Requests',
                    onTap: onCoachTap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionMetric extends StatelessWidget {
  const _AttentionMetric({
    required this.count,
    required this.label,
    required this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$count $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GymCommunityCard extends StatelessWidget {
  const GymCommunityCard({
    super.key,
    required this.memberCount,
    required this.coachCount,
    required this.onMembersTap,
    required this.onCoachesTap,
  });

  final int memberCount;
  final int coachCount;
  final VoidCallback onMembersTap;
  final VoidCallback onCoachesTap;

  @override
  Widget build(BuildContext context) {
    return GymManagerCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _TappableStat(
              count: memberCount,
              label: memberCount == 1 ? 'Member' : 'Members',
              onTap: onMembersTap,
            ),
            Container(
              width: 1,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            _TappableStat(
              count: coachCount,
              label: coachCount == 1 ? 'Coach' : 'Coaches',
              onTap: onCoachesTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TappableStat extends StatelessWidget {
  const _TappableStat({
    required this.count,
    required this.label,
    required this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: '$count $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GymOverviewStat(count: count, label: label),
            ),
          ),
        ),
      ),
    );
  }
}

class GymTrustMetricsCard extends StatelessWidget {
  const GymTrustMetricsCard({
    super.key,
    required this.coachVerifications,
    this.proofsRecorded,
  });

  final int coachVerifications;
  final int? proofsRecorded;

  @override
  Widget build(BuildContext context) {
    if (coachVerifications <= 0 && (proofsRecorded ?? 0) <= 0) {
      return const SizedBox.shrink();
    }

    return GymManagerCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (coachVerifications > 0) ...[
              GymOverviewStat(
                count: coachVerifications,
                label: coachVerifications == 1
                    ? 'Coach Verification'
                    : 'Coach Verifications',
              ),
              if (proofsRecorded != null && proofsRecorded! > 0) ...[
                Container(
                  width: 1,
                  color: AppColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
                GymOverviewStat(
                  count: proofsRecorded!,
                  label: 'Proofs Recorded',
                ),
              ],
            ] else if (proofsRecorded != null && proofsRecorded! > 0)
              GymOverviewStat(
                count: proofsRecorded!,
                label: 'Proofs Recorded',
              ),
          ],
        ),
      ),
    );
  }
}

class GymQuickActionsRow extends StatelessWidget {
  const GymQuickActionsRow({
    super.key,
    required this.pendingRequestCount,
    required this.onReviewRequests,
    required this.onMembers,
    required this.onInviteCoach,
    required this.onSettings,
  });

  final int pendingRequestCount;
  final VoidCallback onReviewRequests;
  final VoidCallback onMembers;
  final VoidCallback onInviteCoach;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GymQuickActionTile(
            icon: Icons.inbox_outlined,
            label: 'Review Requests',
            badge: pendingRequestCount > 0 ? pendingRequestCount : null,
            highlighted: pendingRequestCount > 0,
            onTap: onReviewRequests,
          ),
          const SizedBox(width: 10),
          GymQuickActionTile(
            icon: Icons.people_outline,
            label: 'Members',
            onTap: onMembers,
          ),
          const SizedBox(width: 10),
          GymQuickActionTile(
            icon: Icons.person_add_outlined,
            label: 'Invite Coach',
            onTap: onInviteCoach,
          ),
          const SizedBox(width: 10),
          GymQuickActionTile(
            icon: Icons.settings_outlined,
            label: 'Gym Settings',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}
