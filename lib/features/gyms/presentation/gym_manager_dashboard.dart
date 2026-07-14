import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/gyms/domain/gym_manager_view_data.dart';
import 'package:proof/features/gyms/presentation/widgets/gym_manager_roster_widgets.dart';
import 'package:proof/features/gyms/presentation/widgets/gym_manager_widgets.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/gym_model.dart';
import 'package:proof/shared/providers/app_mode_provider.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class GymManagerDashboardScreen extends ConsumerStatefulWidget {
  const GymManagerDashboardScreen({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymManagerDashboardScreen> createState() =>
      _GymManagerDashboardScreenState();
}

class _GymManagerDashboardScreenState
    extends ConsumerState<GymManagerDashboardScreen> {
  int _tab = 0;
  int _requestsSubTab = 0;

  void _goToTab(int tab, {int? requestsSubTab}) {
    setState(() {
      _tab = tab;
      if (requestsSubTab != null) _requestsSubTab = requestsSubTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      final previousUid = previous?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;
      if (previousUid != nextUid && nextUid != null) {
        ref.invalidate(gymMembershipsForGymProvider(widget.gymId));
      }
    });

    final authState = ref.watch(authStateProvider);
    final authReady =
        !authState.isLoading && authState.valueOrNull != null;

    final gymAsync = ref.watch(gymProvider(widget.gymId));
    final membershipsAsync =
        ref.watch(gymMembershipsForGymProvider(widget.gymId));

    if (gymAsync.isLoading && !gymAsync.hasValue) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: GymManagerSkeleton(),
      );
    }

    if (gymAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: ${gymAsync.error}')),
      );
    }

    final gym = gymAsync.value;
    if (gym == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Gym not found')),
      );
    }

    final memberships = membershipsAsync.valueOrNull ?? [];
    final waitingForMemberships = authReady &&
        !membershipsAsync.hasValue &&
        !membershipsAsync.hasError;
    final membershipsLoading = !authReady || waitingForMemberships;
    final membershipsError = authReady && membershipsAsync.hasError
        ? membershipsAsync.error
        : null;

    if (waitingForMemberships) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const GymManagerSkeleton(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _goToTab,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent.withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Members',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_outlined),
              selectedIcon: Icon(Icons.sports),
              label: 'Coaches',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      );
    }

    final data = GymManagerDashboardData.build(
      gym: gym,
      memberships: memberships,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: [
          _OverviewTab(
            data: data,
            onNavigate: _goToTab,
            onInviteCoach: () => _showInviteCoach(context),
            membershipsLoading: membershipsLoading,
            membershipsError: membershipsError,
            onRetryMemberships: () => ref.invalidate(
              gymMembershipsForGymProvider(widget.gymId),
            ),
          ),
          _RequestsTab(
            data: data,
            initialSubTab: _requestsSubTab,
            onSubTabChanged: (i) => setState(() => _requestsSubTab = i),
          ),
          _MembersTab(data: data),
          _CoachesTab(data: data, onInvite: () => _showInviteCoach(context)),
          _MoreTab(
            gymId: widget.gymId,
            data: data,
            onEditProfile: () => context.push('/gym-manager/${widget.gymId}/edit'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goToTab,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: data.stats.pendingAthleteRequests +
                      data.stats.pendingCoachRequests >
                  0,
              label: Text(
                '${data.stats.pendingAthleteRequests + data.stats.pendingCoachRequests}',
              ),
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: const Icon(Icons.inbox),
            label: 'Requests',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Members',
          ),
          const NavigationDestination(
            icon: Icon(Icons.sports_outlined),
            selectedIcon: Icon(Icons.sports),
            label: 'Coaches',
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  void _showInviteCoach(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Coach'),
        content: const Text(
          'Share your gym handle so coaches can find you and request membership. '
          'Direct coach invites are coming soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({
    required this.data,
    required this.onNavigate,
    required this.onInviteCoach,
    this.membershipsLoading = false,
    this.membershipsError,
    this.onRetryMemberships,
  });

  final GymManagerDashboardData data;
  final void Function(int tab, {int? requestsSubTab}) onNavigate;
  final VoidCallback onInviteCoach;
  final bool membershipsLoading;
  final Object? membershipsError;
  final VoidCallback? onRetryMemberships;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = data.gym;
    final stats = data.stats;

    var coachVerifications = 0;
    for (final membership in data.approvedCoaches) {
      final coach = ref.watch(coachProfileProvider(membership.userId)).valueOrNull;
      if (coach != null) {
        coachVerifications += coach.verifiedProofCount;
      }
    }

    final hasPending = stats.pendingAthleteRequests > 0 ||
        stats.pendingCoachRequests > 0;
    final recentActivity = data.activity.take(5).toList();

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IdentityAvatar(
                      avatarUrl: gym.logoUrl,
                      displayName: gym.name,
                      radius: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gym.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${gym.handle}',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.inkMuted,
                                    ),
                          ),
                          if (data.locationLabel.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              data.locationLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.inkSecondary,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          GymStatusBadge(status: gym.status),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Gym settings',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => onNavigate(4),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (membershipsLoading) ...[
                      const GymManagerSkeleton(),
                    ] else ...[
                      if (membershipsError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GymManagerCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Could not load membership data',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$membershipsError',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                                if (onRetryMemberships != null) ...[
                                  const SizedBox(height: 12),
                                  ProofButton(
                                    label: 'Retry',
                                    onPressed: onRetryMemberships,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const GymManagerSectionLabel(title: 'NEEDS ATTENTION'),
                      if (hasPending)
                        GymNeedsAttentionCard(
                          athleteRequests: stats.pendingAthleteRequests,
                          coachRequests: stats.pendingCoachRequests,
                          onAthleteTap: () =>
                              onNavigate(1, requestsSubTab: 0),
                          onCoachTap: () => onNavigate(1, requestsSubTab: 1),
                        )
                      else
                        const GymCaughtUpCard(),
                      const SizedBox(height: 24),
                      const GymManagerSectionLabel(title: 'COMMUNITY'),
                      GymCommunityCard(
                        memberCount: stats.approvedAthletes,
                        coachCount: stats.approvedCoaches,
                        onMembersTap: () => onNavigate(2),
                        onCoachesTap: () => onNavigate(3),
                      ),
                      if (coachVerifications > 0) ...[
                        const SizedBox(height: 24),
                        const GymManagerSectionLabel(title: 'TRUST & ACTIVITY'),
                        GymTrustMetricsCard(
                          coachVerifications: coachVerifications,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const GymManagerSectionLabel(title: 'RECENT ACTIVITY'),
                      GymManagerCard(
                        child: recentActivity.isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No activity yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Membership approvals and gym updates will appear here.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.inkMuted,
                                          height: 1.45,
                                        ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: recentActivity
                                    .map((item) => GymActivityRow(item: item))
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 24),
                      const GymManagerSectionLabel(title: 'QUICK ACTIONS'),
                      GymQuickActionsRow(
                        pendingRequestCount: stats.pendingAthleteRequests +
                            stats.pendingCoachRequests,
                        onReviewRequests: () => onNavigate(1),
                        onMembers: () => onNavigate(2),
                        onInviteCoach: onInviteCoach,
                        onSettings: () => onNavigate(4),
                      ),
                      if (!data.completeness.isComplete) ...[
                        const SizedBox(height: 28),
                        GymProfileCompletenessCard(
                          completeness: data.completeness,
                          onComplete: () => onNavigate(4),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends ConsumerStatefulWidget {
  const _RequestsTab({
    required this.data,
    required this.initialSubTab,
    required this.onSubTabChanged,
  });

  final GymManagerDashboardData data;
  final int initialSubTab;
  final ValueChanged<int> onSubTabChanged;

  @override
  ConsumerState<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<_RequestsTab> {
  late int _subTab;

  @override
  void initState() {
    super.initState();
    _subTab = widget.initialSubTab;
  }

  @override
  void didUpdateWidget(covariant _RequestsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubTab != oldWidget.initialSubTab) {
      _subTab = widget.initialSubTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _subTab == 0
        ? widget.data.athletePending
        : widget.data.coachPending;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              'Requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GymSegmentedRequestControl(
              athleteCount: widget.data.stats.pendingAthleteRequests,
              coachCount: widget.data.stats.pendingCoachRequests,
              selectedIndex: _subTab,
              onChanged: (index) {
                setState(() => _subTab = index);
                widget.onSubTabChanged(index);
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: pending.isEmpty
                  ? [
                      GymCompactEmptyState(
                        title: 'All caught up',
                        description: _subTab == 0
                            ? 'There are no pending athlete requests.'
                            : 'There are no pending coach requests.',
                      ),
                    ]
                  : pending
                      .map(
                        (m) => GymMembershipRequestCard(
                          membership: m,
                          onReview: (status) => _reviewMembership(
                            context,
                            ref,
                            membership: m,
                            status: status,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends ConsumerStatefulWidget {
  const _MembersTab({required this.data});

  final GymManagerDashboardData data;

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final members = widget.data.approvedAthletes;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Members',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                GymSearchField(
                  controller: _search,
                  hint: 'Search members',
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: members.isEmpty
                  ? [
                      const GymCompactEmptyState(
                        title: 'No members yet',
                        description: 'Approved athletes will appear here.',
                      ),
                    ]
                  : members
                      .map(
                        (m) => GymMemberRosterCard(
                          membership: m,
                          searchQuery: query,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachesTab extends ConsumerStatefulWidget {
  const _CoachesTab({required this.data, required this.onInvite});

  final GymManagerDashboardData data;
  final VoidCallback onInvite;

  @override
  ConsumerState<_CoachesTab> createState() => _CoachesTabState();
}

class _CoachesTabState extends ConsumerState<_CoachesTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final coaches = widget.data.approvedCoaches;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Coaches',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                GymSearchField(
                  controller: _search,
                  hint: 'Search coaches',
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: coaches.isEmpty
                  ? [
                      GymCompactEmptyState(
                        title: 'No coaches yet',
                        description: 'Approved coaches will appear here.',
                        action: ProofButton(
                          label: 'Invite Coach',
                          onPressed: widget.onInvite,
                        ),
                      ),
                    ]
                  : coaches
                      .map(
                        (m) => GymCoachRosterCard(
                          membership: m,
                          searchQuery: query,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTab extends ConsumerWidget {
  const _MoreTab({
    required this.gymId,
    required this.data,
    required this.onEditProfile,
  });

  final String gymId;
  final GymManagerDashboardData data;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final roles = <AppMode>[];
    if (user?.isGymManager == true) roles.add(AppMode.gymManager);
    if (user?.hasIdentity == true) roles.add(AppMode.athlete);
    if (user?.isCoach == true) roles.add(AppMode.coach);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'More',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            const PeopleSectionLabel(title: 'GYM MANAGEMENT'),
            MoreMenuCard(
              children: [
                MoreMenuRow(
                  icon: Icons.edit_outlined,
                  title: 'Edit Gym Profile',
                  subtitle: 'Update name, logo, and contact details',
                  onTap: onEditProfile,
                ),
                MoreMenuRow(
                  icon: Icons.apartment_outlined,
                  title: 'Gym Details',
                  subtitle: '@${data.gym.handle} · ${data.locationLabel.isEmpty ? 'Add location' : data.locationLabel}',
                  onTap: onEditProfile,
                ),
                MoreMenuRow(
                  icon: Icons.mail_outline,
                  title: 'Invite Coach',
                  subtitle: 'Share your gym with coaches',
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Invite Coach'),
                        content: Text(
                          'Coaches can search for @${data.gym.handle} and request membership.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                MoreMenuRow(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Membership Settings',
                  subtitle: 'Review requests from the Requests tab',
                  onTap: () {},
                ),
              ],
            ),
            if (roles.length > 1) ...[
              const SizedBox(height: 24),
              const PeopleSectionLabel(title: 'SWITCH MODE'),
              MoreMenuCard(
                children: roles.map((mode) {
                  final label = switch (mode) {
                    AppMode.athlete => 'Athlete',
                    AppMode.coach => 'Coach',
                    AppMode.gymManager => 'Gym Manager',
                  };
                  return MoreMenuRow(
                    icon: switch (mode) {
                      AppMode.athlete => Icons.person_outline,
                      AppMode.coach => Icons.sports_outlined,
                      AppMode.gymManager => Icons.apartment_outlined,
                    },
                    title: label,
                    subtitle: 'Switch to $label mode',
                    onTap: () {
                      ref.read(activeAppModeProvider.notifier).state = mode;
                      switch (mode) {
                        case AppMode.athlete:
                          context.go('/dashboard');
                        case AppMode.coach:
                          context.go('/more');
                        case AppMode.gymManager:
                          context.go('/gym-manager/$gymId');
                      }
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            const PeopleSectionLabel(title: 'ACCOUNT'),
            MoreMenuCard(
              children: [
                MoreMenuRow(
                  icon: Icons.person_outline,
                  title: 'Account',
                  subtitle: user != null && user.email.isNotEmpty
                      ? user.email
                      : 'Manage your account and privacy',
                  onTap: () => context.push('/account'),
                ),
                MoreMenuRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage alerts and updates',
                  onTap: () => context.push('/notifications'),
                ),
                MoreMenuRow(
                  icon: Icons.lock_outline,
                  title: 'Privacy settings',
                  subtitle: 'Control discoverability and public profile',
                  onTap: () => context.push('/privacy-settings'),
                ),
                MoreMenuRow(
                  icon: Icons.help_outline,
                  title: 'Help',
                  subtitle: 'FAQ and support',
                  onTap: () => context.push('/faq'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const PeopleSectionLabel(title: 'SESSION'),
            MoreMenuCard(
              children: [
                MoreMenuRow(
                  icon: Icons.logout,
                  title: 'Log Out',
                  subtitle: 'Sign out of ${data.gym.name}',
                  onTap: () => _confirmLogout(context, ref, data.gym.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    String gymName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: Text(
          'You will need to sign in again to manage $gymName.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(activeAppModeProvider.notifier).state = null;
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) context.go('/login');
  }
}

Future<void> _reviewMembership(
  BuildContext context,
  WidgetRef ref, {
  required GymMembershipModel membership,
  required GymMembershipStatus status,
}) async {
  final userId = ref.read(authStateProvider).valueOrNull?.uid;
  if (userId == null) return;
  await ref.read(firestoreServiceProvider).reviewGymMembership(
        membershipId: membership.id,
        status: status,
        reviewedBy: userId,
      );
  if (status == GymMembershipStatus.approved &&
      membership.membershipType == GymMembershipType.coach) {
    await ref
        .read(firestoreServiceProvider)
        .ensureCoachProfile(membership.userId);
  }
}

class GymEditProfileScreen extends ConsumerStatefulWidget {
  const GymEditProfileScreen({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymEditProfileScreen> createState() =>
      _GymEditProfileScreenState();
}

class _GymEditProfileScreenState extends ConsumerState<GymEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _countryController;
  TextEditingController? _cityController;
  TextEditingController? _addressController;
  TextEditingController? _websiteController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  TextEditingController? _descriptionController;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController?.dispose();
    _countryController?.dispose();
    _cityController?.dispose();
    _addressController?.dispose();
    _websiteController?.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    _descriptionController?.dispose();
    super.dispose();
  }

  void _init(GymModel gym) {
    if (_initialized) return;
    _initialized = true;
    _nameController = TextEditingController(text: gym.name);
    _countryController = TextEditingController(text: gym.country);
    _cityController = TextEditingController(text: gym.city);
    _addressController = TextEditingController(text: gym.address);
    _websiteController = TextEditingController(text: gym.website);
    _emailController = TextEditingController(text: gym.contactEmail);
    _phoneController = TextEditingController(text: gym.phone);
    _descriptionController = TextEditingController(text: gym.description);
  }

  Future<void> _save(GymModel original) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = GymModel(
        id: original.id,
        name: _nameController!.text.trim(),
        handle: original.handle,
        logoUrl: original.logoUrl,
        country: _countryController!.text.trim(),
        city: _cityController!.text.trim(),
        address: _addressController!.text.trim(),
        website: _websiteController!.text.trim(),
        description: _descriptionController!.text.trim(),
        contactEmail: _emailController!.text.trim(),
        managerName: original.managerName,
        phone: _phoneController!.text.trim(),
        status: original.status,
        createdBy: original.createdBy,
        createdAt: original.createdAt,
      );
      await ref.read(firestoreServiceProvider).updateGym(updated);
      ref.invalidate(gymProvider(widget.gymId));
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymAsync = ref.watch(gymProvider(widget.gymId));

    return gymAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (gym) {
        if (gym == null) {
          return const Scaffold(body: Center(child: Text('Gym not found')));
        }
        _init(gym);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ProofAppBar(
            title: 'Edit Gym Profile',
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ProofTextField(
                    controller: _nameController!,
                    label: 'Gym name',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(
                    controller: _descriptionController!,
                    label: 'Description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(controller: _cityController!, label: 'City'),
                  const SizedBox(height: 16),
                  ProofTextField(
                    controller: _countryController!,
                    label: 'Country',
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(
                    controller: _addressController!,
                    label: 'Address',
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(
                    controller: _websiteController!,
                    label: 'Website',
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(
                    controller: _emailController!,
                    label: 'Contact email',
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(controller: _phoneController!, label: 'Phone'),
                  const SizedBox(height: 24),
                  ProofButton(
                    label: 'Save changes',
                    isLoading: _isLoading,
                    onPressed: () => _save(gym),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
