import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/people/domain/blocked_user_entry.dart';
import 'package:proof/features/people/presentation/unblock_user_flow.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(blockedUsersEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Blocked users',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              title: 'Couldn\'t load blocked users',
              message: 'Check your connection and try again.',
              action: ProofButton(
                label: 'Try again',
                onPressed: () => ref.invalidate(blockedUsersEntriesProvider),
              ),
            ),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  title: 'Blocked users',
                  message: 'You haven\'t blocked anyone.',
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _BlockedUserTile(entry: entries[index]);
            },
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends ConsumerWidget {
  const _BlockedUserTile({required this.entry});

  final BlockedUserEntry entry;

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null) return;

    final success = await confirmAndUnblockUser(
      context: context,
      ref: ref,
      currentUserId: userId,
      relationship: entry.relationship,
      displayName: entry.displayName,
    );
    if (!context.mounted) return;
    if (success) {
      ref.invalidate(blockedUsersEntriesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        entry.profile ??
        PublicProfileModel(
          userId: entry.otherUserId,
          displayName: entry.displayName,
          handle: entry.handle ?? '',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          searchable: false,
        );

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: entry.handle == null
            ? null
            : () => context.push('/people/${entry.handle}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              PublicProfileAvatar(profile: profile),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.handle != null)
                      Text(
                        '@${entry.handle}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              ProofButton(
                label: 'Unblock',
                isOutlined: true,
                onPressed: () => _unblock(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
