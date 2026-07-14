import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

String formatMembershipRequestDate(DateTime date) {
  final label = ProofDateUtils.formatActivityDate(date);
  if (label == 'Today') return 'Requested today';
  if (label == 'Yesterday') return 'Requested yesterday';
  return 'Requested $label';
}

String formatMemberJoinedDate(DateTime date) {
  return 'Joined ${ProofDateUtils.formatRelative(date)}';
}

String formatCoachSinceDate(DateTime date) {
  return 'Since ${date.year}';
}

String formatCoachSpecialtyLabel(String? specialty) {
  if (specialty == null || specialty.trim().isEmpty) return 'Coach';

  final trimmed = specialty.trim();
  final lower = trimmed.toLowerCase();
  if (lower.endsWith('coach')) {
    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  final titleCased = trimmed
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
  return '$titleCased Coach';
}

class GymCompactEmptyState extends StatelessWidget {
  const GymCompactEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.action,
  });

  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  height: 1.45,
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

class GymSegmentedRequestControl extends StatelessWidget {
  const GymSegmentedRequestControl({
    super.key,
    required this.athleteCount,
    required this.coachCount,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int athleteCount;
  final int coachCount;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Athletes ($athleteCount)',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Coaches ($coachCount)',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class GymRosterCard extends StatelessWidget {
  const GymRosterCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.handle,
    this.avatarUrl,
    this.metricPrimary,
    this.metricSecondary,
    this.onTap,
    this.onManage,
    this.showShieldTrailing = false,
    this.centerMetric = false,
    this.showChevronTrailing = true,
  });

  final String name;
  final String subtitle;
  final String? handle;
  final String? avatarUrl;
  final String? metricPrimary;
  final String? metricSecondary;
  final VoidCallback? onTap;
  final VoidCallback? onManage;
  final bool showShieldTrailing;
  final bool centerMetric;
  final bool showChevronTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IdentityAvatar(
                  avatarUrl: avatarUrl,
                  displayName: name,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (handle != null && handle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@$handle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.accent,
                              ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                if (metricPrimary != null || metricSecondary != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: centerMetric
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.end,
                    children: [
                      if (metricPrimary != null)
                        Text(
                          metricPrimary!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                        ),
                      if (metricSecondary != null)
                        Text(
                          metricSecondary!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                        ),
                    ],
                  ),
                ],
                if (showShieldTrailing) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.inkMuted.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ] else ...[
                  if (onManage != null)
                    IconButton(
                      tooltip: 'Manage membership',
                      icon: const Icon(Icons.more_vert, color: AppColors.inkMuted),
                      onPressed: onManage,
                    ),
                  if (onTap != null && showChevronTrailing)
                    const Icon(Icons.chevron_right, color: AppColors.inkMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GymMembershipRequestCard extends ConsumerWidget {
  const GymMembershipRequestCard({
    super.key,
    required this.membership,
    required this.onReview,
  });

  final GymMembershipModel membership;
  final Future<void> Function(GymMembershipStatus status) onReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync =
        ref.watch(identityByUserIdProvider(membership.userId));
    final coachAsync = ref.watch(coachProfileProvider(membership.userId));

    return identityAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _RosterSkeleton(height: 132),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (identity) {
        final coach = coachAsync.valueOrNull;
        final name = identity?.displayName ?? coach?.displayName ?? 'User';
        final handle = identity?.handle ?? coach?.handle;
        final specialty = membership.membershipType == GymMembershipType.coach
            ? coach?.specialty
            : null;
        final isCoach = membership.membershipType == GymMembershipType.coach;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IdentityAvatar(
                    avatarUrl: identity?.avatarUrl ?? coach?.avatarUrl,
                    displayName: name,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (handle != null && handle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@$handle',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                ),
                          ),
                        ],
                        if (specialty != null && specialty.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            specialty,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          formatMembershipRequestDate(membership.requestedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: isCoach ? 'Approve coach' : 'Approve athlete',
                      button: true,
                      child: ProofButton(
                        label: 'Approve',
                        onPressed: () => onReview(GymMembershipStatus.approved),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      label: isCoach ? 'Decline coach' : 'Decline athlete',
                      button: true,
                      child: ProofButton(
                        label: 'Decline',
                        isOutlined: true,
                        onPressed: () => onReview(GymMembershipStatus.rejected),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class GymMemberRosterCard extends ConsumerWidget {
  const GymMemberRosterCard({
    super.key,
    required this.membership,
    required this.searchQuery,
  });

  final GymMembershipModel membership;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync =
        ref.watch(identityByUserIdProvider(membership.userId));
    final proofsAsync = ref.watch(publicProofsProvider(membership.userId));

    return identityAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _RosterSkeleton(height: 84),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (identity) {
        final name = identity?.displayName ?? 'Member';
        final handle = identity?.handle ?? '';
        if (searchQuery.isNotEmpty &&
            !name.toLowerCase().contains(searchQuery) &&
            !handle.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        final proofs = proofsAsync.valueOrNull ?? [];
        final totalCount = proofs.length;

        String? metricPrimary;
        String? metricSecondary;
        if (totalCount > 0) {
          metricPrimary = '$totalCount';
          metricSecondary = 'Proofs';
        }

        return GymRosterCard(
          name: name,
          handle: handle.isEmpty ? null : handle,
          avatarUrl: identity?.avatarUrl,
          subtitle: formatMemberJoinedDate(
            membership.reviewedAt ?? membership.requestedAt,
          ),
          metricPrimary: metricPrimary,
          metricSecondary: metricSecondary,
          centerMetric: true,
          showShieldTrailing: true,
          onTap: handle.isNotEmpty
              ? () => context.push(
                    '/passport/$handle?gymId=${membership.gymId}',
                  )
              : null,
        );
      },
    );
  }
}

class GymCoachRosterCard extends ConsumerWidget {
  const GymCoachRosterCard({
    super.key,
    required this.membership,
    required this.searchQuery,
  });

  final GymMembershipModel membership;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync =
        ref.watch(identityByUserIdProvider(membership.userId));
    final coachAsync = ref.watch(coachProfileProvider(membership.userId));

    return identityAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _RosterSkeleton(height: 96),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (identity) {
        final coach = coachAsync.valueOrNull;
        final name = identity?.displayName ?? coach?.displayName ?? 'Coach';
        final handle = identity?.handle ?? coach?.handle ?? '';
        final specialty = coach?.specialty;
        if (searchQuery.isNotEmpty &&
            !name.toLowerCase().contains(searchQuery) &&
            !handle.toLowerCase().contains(searchQuery) &&
            !(specialty ?? '').toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        final sinceDate = membership.reviewedAt ?? membership.requestedAt;
        final specialtyLabel = formatCoachSpecialtyLabel(specialty);
        final subtitle = '$specialtyLabel\n${formatCoachSinceDate(sinceDate)}';

        final verifiedCount = coach?.verifiedProofCount ?? 0;
        return GymRosterCard(
          name: name,
          avatarUrl: identity?.avatarUrl ?? coach?.avatarUrl,
          subtitle: subtitle,
          metricPrimary: '$verifiedCount',
          metricSecondary: 'Proofs Verified',
          centerMetric: true,
          showChevronTrailing: false,
          onTap: handle.isNotEmpty
              ? () => context.push(
                    '/coaches/$handle?gymId=${membership.gymId}',
                  )
              : null,
        );
      },
    );
  }
}

class _RosterSkeleton extends StatelessWidget {
  const _RosterSkeleton({required this.height});

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
