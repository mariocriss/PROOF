import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/people/domain/friend_connection_state.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class PersonProfileScreen extends ConsumerWidget {
  const PersonProfileScreen({super.key, required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileByHandleProvider(handle));
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: ProofAppBar(
          title: 'Profile',
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: ProofAppBar(
              title: 'Profile',
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: const Center(
              child: EmptyState(
                title: 'Person not found',
                message: 'No public profile exists for this handle.',
              ),
            ),
          );
        }

        final connection = ref.watch(friendConnectionProvider(profile.userId));
        final isFriend = connection.state == FriendConnectionState.accepted;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ProofAppBar(
            title: 'Profile',
            leading: BackButton(onPressed: () => context.pop()),
            actions: [
              if (isFriend && userId != null && userId != profile.userId)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    final currentUserId = userId!;
                    final service = ref.read(firestoreServiceProvider);
                    if (value == 'remove') {
                      final rel = connection.relationship;
                      if (rel != null) await service.removeFriend(rel.id);
                    } else if (value == 'block') {
                      await service.blockUser(
                        fromUserId: currentUserId,
                        toUserId: profile.userId,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'remove', child: Text('Remove friend')),
                    const PopupMenuItem(value: 'block', child: Text('Block user')),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _ProfileHeader(profile: profile),
              const SizedBox(height: 20),
              if (profile.bio.isNotEmpty) ...[
                _SectionCard(
                  title: 'About',
                  child: Text(profile.bio),
                ),
                const SizedBox(height: 16),
              ],
              _SectionCard(
                title: 'Physical Identity',
                child: Text(
                  profile.identityStatus,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (profile.publicTopSkills.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: isFriend ? 'Top capabilities' : 'Top capabilities',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final skill in profile.publicTopSkills.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${skill.name} · ${skill.resultLabel}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (isFriend) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Passport',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View ${profile.displayName.split(' ').first}\'s full passport.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ProofButton(
                        label: 'Open Passport',
                        isOutlined: true,
                        onPressed: () => context.push('/passport/${profile.handle}'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Passport',
                  child: Text(
                    'Connect to see more of this passport.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: FriendConnectionButton(
                  profile: profile,
                  connection: connection,
                  userId: userId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final PublicProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final locationAge = <String>[
      if (profile.city.isNotEmpty) profile.city,
      if (profile.ageVisible && profile.publicAge != null)
        '${profile.publicAge}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.surfaceElevated,
            backgroundImage:
                profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            '@${profile.handle}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
          if (locationAge.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              locationAge,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
