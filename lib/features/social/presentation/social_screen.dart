import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/social/application/social_providers.dart';
import 'package:proof/features/social/domain/gym_activity.dart';
import 'package:proof/features/social/presentation/widgets/gym_activity_card.dart';
import 'package:proof/shared/providers/gym_providers.dart';

/// Gym-only activity from approved members, including your own shares.
class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialFeedStateProvider);
    final memberships = ref.watch(userGymMembershipsProvider).valueOrNull ?? [];
    final gymIds = approvedSocialGymIds(memberships);
    final selected = ref.watch(selectedSocialGymIdProvider);
    final gymId = resolveSocialGymId(gymIds, selected);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Social',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your gym',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                  if (state == SocialFeedState.ready &&
                      gymId != null &&
                      gymIds.length > 1) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('social-gym-$gymId'),
                      initialValue: gymId,
                      decoration: const InputDecoration(labelText: 'Gym'),
                      items: [
                        for (final id in gymIds)
                          DropdownMenuItem(
                            value: id,
                            child: _SocialGymName(gymId: id),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        ref.read(selectedSocialGymIdProvider.notifier).state =
                            value;
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: switch (state) {
                SocialFeedState.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                SocialFeedState.noGym => _EmptyMessage(
                    message: 'Join a gym to see activity from athletes there.',
                    actionLabel: 'Find a gym',
                    onAction: () => context.push('/gyms'),
                  ),
                SocialFeedState.ready when gymId == null => _EmptyMessage(
                    message: 'Join a gym to see activity from athletes there.',
                    actionLabel: 'Find a gym',
                    onAction: () => context.push('/gyms'),
                  ),
                SocialFeedState.ready => _GymFeed(gymId: gymId!),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GymFeed extends ConsumerWidget {
  const _GymFeed({required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(gymActivityFeedProvider(gymId));
    final blocked = ref.watch(socialBlockedUserIdsProvider);

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _EmptyMessage(
        message: 'Could not load gym activity.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(gymActivityFeedProvider(gymId)),
      ),
      data: (activity) {
        final visible = visibleGymActivity(
          activity: activity,
          blockedUserIds: blocked,
        );
        final pageSize = ref.watch(socialFeedPageSizeProvider(gymId));
        final canLoadMore = activity.length >= pageSize;
        if (visible.isEmpty && !canLoadMore) {
          return const _EmptyMessage(
            message: 'Your gym activity will appear here.',
          );
        }
        if (visible.isEmpty) {
          return _EmptyMessage(
            message: 'Your gym activity will appear here.',
            actionLabel: 'Load more',
            onAction: () {
              ref.read(socialFeedPageSizeProvider(gymId).notifier).state =
                  pageSize + 20;
            },
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          itemCount: visible.length + (canLoadMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= visible.length) {
              return TextButton(
                onPressed: () {
                  ref.read(socialFeedPageSizeProvider(gymId).notifier).state =
                      pageSize + 20;
                },
                child: const Text('Load more'),
              );
            }
            final item = visible[index];
            return GymActivityCard(
              key: ValueKey(item.id),
              activity: item,
              onOpen: () => context.push(
                '/social/activity/${item.gymId}/${item.id}',
              ),
            );
          },
        );
      },
    );
  }
}

class _SocialGymName extends ConsumerWidget {
  const _SocialGymName({required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(gymProvider(gymId)).valueOrNull?.name;
    return Text(
      name == null || name.isEmpty ? 'Your gym' : name,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 36,
              color: AppColors.inkMuted.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
