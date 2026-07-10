import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(physicalIdentityProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final counts = ref.watch(moreMenuCountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More',
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'People. Trust. Settings.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (identity != null)
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surfaceElevated,
                      backgroundImage: identity.avatarUrl != null
                          ? NetworkImage(identity.avatarUrl!)
                          : null,
                      child: identity.avatarUrl == null
                          ? Text(
                              identity.displayName.isNotEmpty
                                  ? identity.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const PeopleSectionLabel(title: 'PEOPLE'),
              MoreMenuCard(
                children: [
                  MoreMenuRow(
                    icon: Icons.people_outline,
                    title: 'Friends',
                    subtitle: 'Connect with people you trust',
                    badge: counts.friends,
                    onTap: () => context.push('/friends'),
                  ),
                  MoreMenuRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Coaches',
                    subtitle: 'Find and connect with coaches',
                    badge: counts.coaches,
                    onTap: () => context.push('/coaches'),
                  ),
                  MoreMenuRow(
                    icon: Icons.location_city_outlined,
                    title: 'Gyms',
                    subtitle: 'Explore gyms and communities',
                    onTap: () => context.push('/gyms'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const PeopleSectionLabel(title: 'REQUESTS'),
              MoreMenuCard(
                children: [
                  MoreMenuRow(
                    icon: Icons.fact_check_outlined,
                    title: 'Verification Requests',
                    subtitle: 'Proofs waiting for coach review',
                    badge: counts.verificationRequests,
                    onTap: () => context.push('/verification-requests'),
                  ),
                  MoreMenuRow(
                    icon: Icons.person_add_outlined,
                    title: 'Friend Requests',
                    subtitle: 'People who want to connect',
                    badge: counts.friendRequests,
                    onTap: () => context.push('/friend-requests'),
                  ),
                  MoreMenuRow(
                    icon: Icons.shield_outlined,
                    title: 'Coach Requests',
                    subtitle: 'Coaches who want to connect',
                    badge: counts.coachRequests,
                    onTap: () => context.push('/coach-requests'),
                  ),
                ],
              ),
              if (user?.isCoach == true) ...[
                const SizedBox(height: 24),
                const PeopleSectionLabel(title: 'COACH TOOLS'),
                MoreMenuCard(
                  children: [
                    MoreMenuRow(
                      icon: Icons.inbox_outlined,
                      title: 'Verification Queue',
                      subtitle: 'Review pending proof requests',
                      badge: counts.coachQueue,
                      onTap: () => context.push('/coach/verification-queue'),
                    ),
                    MoreMenuRow(
                      icon: Icons.groups_outlined,
                      title: 'My Athletes',
                      subtitle: 'Athletes you coach',
                      onTap: () => context.push('/coach/athletes'),
                    ),
                    MoreMenuRow(
                      icon: Icons.verified_outlined,
                      title: 'Verified Proofs',
                      subtitle: 'Proofs you have verified',
                      onTap: () => context.push('/coach/verified-proofs'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const PeopleSectionLabel(title: 'SETTINGS'),
              MoreMenuCard(
                children: [
                  MoreMenuRow(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your public profile',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  MoreMenuRow(
                    icon: Icons.lock_outline,
                    title: 'Account',
                    subtitle: 'Manage your account and privacy',
                    onTap: () => context.push('/account'),
                  ),
                  MoreMenuRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage your notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  MoreMenuRow(
                    icon: Icons.help_outline,
                    title: 'Help',
                    subtitle: 'Get help and contact support',
                    onTap: () => context.push('/faq'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProofButton(
                label: 'Sign out',
                isOutlined: true,
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
              const SizedBox(height: 28),
              IdentityBannerCard(onTap: () => context.go('/passport')),
            ],
          ),
        ),
      ),
    );
  }
}
