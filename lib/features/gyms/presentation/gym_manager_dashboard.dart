import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/gyms/domain/gym_manager_view_data.dart';
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
    final membershipsLoading =
        membershipsAsync.isLoading && !membershipsAsync.hasValue;
    final membershipsError = membershipsAsync.hasError
        ? membershipsAsync.error
        : null;
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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.data,
    required this.onNavigate,
    this.membershipsLoading = false,
    this.membershipsError,
    this.onRetryMemberships,
  });

  final GymManagerDashboardData data;
  final void Function(int tab, {int? requestsSubTab}) onNavigate;
  final bool membershipsLoading;
  final Object? membershipsError;
  final VoidCallback? onRetryMemberships;

  @override
  Widget build(BuildContext context) {
    final gym = data.gym;
    final stats = data.stats;

    return SafeArea(
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                        ),
                        if (data.locationLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            data.locationLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  if (membershipsLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
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
                  GymProfileCompletenessCard(
                    completeness: data.completeness,
                    onComplete: () => onNavigate(4),
                  ),
                  const GymManagerSectionLabel(title: 'OVERVIEW'),
                  GymManagerCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GymStatTile(
                              value: stats.approvedAthletes > 0
                                  ? '${stats.approvedAthletes}'
                                  : '—',
                              label: 'Athletes',
                              isZero: stats.approvedAthletes == 0,
                            ),
                            GymStatTile(
                              value: stats.approvedCoaches > 0
                                  ? '${stats.approvedCoaches}'
                                  : '—',
                              label: 'Coaches',
                              isZero: stats.approvedCoaches == 0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 12),
                        if (stats.pendingAthleteRequests > 0)
                          GymStatTile(
                            value: '${stats.pendingAthleteRequests}',
                            label: 'Athlete Requests',
                          )
                        else
                          const GymZeroStatLine(
                            text: 'No pending athlete requests',
                          ),
                        const SizedBox(height: 12),
                        if (stats.pendingCoachRequests > 0)
                          GymStatTile(
                            value: '${stats.pendingCoachRequests}',
                            label: 'Coach Requests',
                          )
                        else
                          const GymZeroStatLine(
                            text: 'No pending coach requests',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const GymManagerSectionLabel(title: 'ATTENTION REQUIRED'),
                  if (data.attentionItems.isEmpty)
                    GymCaughtUpCard(gymName: gym.name)
                  else
                    ...data.attentionItems.map(
                      (item) => GymAttentionCard(
                        item: item,
                        onTap: () => onNavigate(
                          item.targetTab,
                          requestsSubTab: item.requestsSubTab,
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  const GymManagerSectionLabel(title: 'QUICK ACTIONS'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      GymQuickActionTile(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Review Athlete Requests',
                        badge: stats.pendingAthleteRequests,
                        onTap: () => onNavigate(1, requestsSubTab: 0),
                      ),
                      GymQuickActionTile(
                        icon: Icons.sports_outlined,
                        label: 'Review Coach Requests',
                        badge: stats.pendingCoachRequests,
                        onTap: () => onNavigate(1, requestsSubTab: 1),
                      ),
                      GymQuickActionTile(
                        icon: Icons.people_outline,
                        label: 'View Members',
                        onTap: () => onNavigate(2),
                      ),
                      GymQuickActionTile(
                        icon: Icons.verified_outlined,
                        label: 'View Coaches',
                        onTap: () => onNavigate(3),
                      ),
                      GymQuickActionTile(
                        icon: Icons.edit_outlined,
                        label: 'Edit Gym Profile',
                        onTap: () => onNavigate(4),
                      ),
                      GymQuickActionTile(
                        icon: Icons.mail_outline,
                        label: 'Invite Coach',
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Invite Coach'),
                              content: Text(
                                'Coaches can find @${gym.handle} and request to join your gym.',
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
                    ],
                  ),
                  const SizedBox(height: 28),
                  const GymManagerSectionLabel(title: 'RECENT ACTIVITY'),
                  GymManagerCard(
                    child: data.activity.isEmpty
                        ? const GymManagerEmptyPanel(
                            title: 'No activity yet',
                            description:
                                'Membership approvals and gym updates will appear here.',
                            icon: Icons.history,
                          )
                        : Column(
                            children: data.activity
                                .map((e) => GymActivityRow(item: e))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab({
    required this.data,
    required this.initialSubTab,
    required this.onSubTabChanged,
  });

  final GymManagerDashboardData data;
  final int initialSubTab;
  final ValueChanged<int> onSubTabChanged;

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
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
    final gym = widget.data.gym;
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
            child: Row(
              children: [
                _RequestTabChip(
                  label: 'Athletes',
                  badge: widget.data.stats.pendingAthleteRequests,
                  selected: _subTab == 0,
                  onTap: () {
                    setState(() => _subTab = 0);
                    widget.onSubTabChanged(0);
                  },
                ),
                const SizedBox(width: 8),
                _RequestTabChip(
                  label: 'Coaches',
                  badge: widget.data.stats.pendingCoachRequests,
                  selected: _subTab == 1,
                  onTap: () {
                    setState(() => _subTab = 1);
                    widget.onSubTabChanged(1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: pending.isEmpty
                  ? [
                      GymManagerEmptyPanel(
                        title: _subTab == 0
                            ? 'No athlete requests'
                            : 'No coach requests',
                        description: _subTab == 0
                            ? 'When athletes select ${gym.name} as their gym, their membership requests will appear here.'
                            : 'Coaches who want to join this gym will appear here for review.',
                        icon: Icons.inbox_outlined,
                      ),
                    ]
                  : pending
                      .map((m) => _MembershipRequestCard(membership: m))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTabChip extends StatelessWidget {
  const _RequestTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(badge > 0 ? '$label ($badge)' : label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accent.withValues(alpha: 0.15),
      checkmarkColor: AppColors.accent,
    );
  }
}

class _MembersTab extends StatefulWidget {
  const _MembersTab({required this.data});

  final GymManagerDashboardData data;

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
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
                  hint: 'Search athletes',
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
                      GymManagerEmptyPanel(
                        title: 'No approved members yet',
                        description:
                            'Approved athletes will appear here once you accept their membership requests.',
                        icon: Icons.people_outline,
                      ),
                    ]
                  : members
                      .map(
                        (m) => _MemberCard(
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

class _CoachesTab extends StatefulWidget {
  const _CoachesTab({required this.data, required this.onInvite});

  final GymManagerDashboardData data;
  final VoidCallback onInvite;

  @override
  State<_CoachesTab> createState() => _CoachesTabState();
}

class _CoachesTabState extends State<_CoachesTab> {
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
                      GymManagerEmptyPanel(
                        title: 'No approved coaches yet',
                        description:
                            'Approve coach requests or invite a coach to begin building your gym team.',
                        icon: Icons.sports_outlined,
                        action: ProofButton(
                          label: 'Invite Coach',
                          onPressed: widget.onInvite,
                        ),
                      ),
                    ]
                  : coaches
                      .map(
                        (m) => _CoachMemberCard(
                          membership: m,
                          gymName: widget.data.gym.name,
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
                  title: 'Manager Account',
                  subtitle: user?.email ?? '',
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
                  title: 'Account Settings',
                  subtitle: 'Privacy and account preferences',
                  onTap: () => context.push('/account'),
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

class _MembershipRequestCard extends ConsumerWidget {
  const _MembershipRequestCard({required this.membership});

  final GymMembershipModel membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync =
        ref.watch(identityByUserIdProvider(membership.userId));
    final coachAsync = ref.watch(coachProfileProvider(membership.userId));

    return identityAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _SkeletonBox(height: 100),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (identity) {
        final coach = coachAsync.valueOrNull;
        final name = identity?.displayName ??
            coach?.displayName ??
            'User';
        final handle = identity?.handle ?? coach?.handle;

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
                children: [
                  IdentityAvatar(
                    avatarUrl: identity?.avatarUrl ?? coach?.avatarUrl,
                    displayName: name,
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          membership.membershipType.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                        ),
                        if (handle != null)
                          Text(
                            '@$handle',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ProofButton(
                      label: membership.membershipType ==
                              GymMembershipType.coach
                          ? 'Approve as Coach'
                          : 'Approve',
                      onPressed: () => _review(
                        context,
                        ref,
                        GymMembershipStatus.approved,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ProofButton(
                      label: 'Decline',
                      isOutlined: true,
                      onPressed: () => _review(
                        context,
                        ref,
                        GymMembershipStatus.rejected,
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

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    GymMembershipStatus status,
  ) async {
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
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    required this.membership,
    required this.searchQuery,
  });

  final GymMembershipModel membership;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync =
        ref.watch(identityByUserIdProvider(membership.userId));

    return identityAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _SkeletonBox(height: 72),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (identity) {
        final name = identity?.displayName ?? 'Member';
        if (searchQuery.isNotEmpty &&
            !name.toLowerCase().contains(searchQuery) &&
            !(identity?.handle ?? '').contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return _PersonListTile(
          name: name,
          handle: identity?.handle,
          avatarUrl: identity?.avatarUrl,
          subtitle:
              'Joined ${ProofDateUtils.formatDate(membership.reviewedAt ?? membership.requestedAt)}',
          statusLabel: 'Approved',
          onTap: identity?.handle != null
              ? () => context.push('/passport/${identity!.handle}')
              : null,
        );
      },
    );
  }
}

class _CoachMemberCard extends ConsumerWidget {
  const _CoachMemberCard({
    required this.membership,
    required this.gymName,
    required this.searchQuery,
  });

  final GymMembershipModel membership;
  final String gymName;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync =
        ref.watch(identityByUserIdProvider(membership.userId));
    final coachAsync = ref.watch(coachProfileProvider(membership.userId));

    return identityAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _SkeletonBox(height: 88),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (identity) {
        final coach = coachAsync.valueOrNull;
        final name = identity?.displayName ?? coach?.displayName ?? 'Coach';
        final handle = identity?.handle ?? coach?.handle;
        if (searchQuery.isNotEmpty &&
            !name.toLowerCase().contains(searchQuery) &&
            !(handle ?? '').contains(searchQuery) &&
            !(coach?.specialty ?? '').toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return _PersonListTile(
          name: name,
          handle: handle,
          avatarUrl: identity?.avatarUrl ?? coach?.avatarUrl,
          subtitle: coach?.specialty ?? 'Coach at $gymName',
          trailing: coach != null
              ? '${coach.verifiedProofCount} verified'
              : null,
          statusLabel: 'Approved',
          onTap: handle != null
              ? () => context.push('/coaches/$handle')
              : null,
        );
      },
    );
  }
}

class _PersonListTile extends StatelessWidget {
  const _PersonListTile({
    required this.name,
    required this.subtitle,
    required this.statusLabel,
    this.handle,
    this.avatarUrl,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final String statusLabel;
  final String? handle;
  final String? avatarUrl;
  final String? trailing;
  final VoidCallback? onTap;

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
              children: [
                IdentityAvatar(
                  avatarUrl: avatarUrl,
                  displayName: name,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                      ),
                      if (handle != null)
                        Text(
                          '@$handle',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.accent,
                              ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                            ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        trailing!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                      ),
                    ],
                  ],
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
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
