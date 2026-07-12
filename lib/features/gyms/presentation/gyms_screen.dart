import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/gyms/domain/gym_search.dart';
import 'package:proof/features/gyms/presentation/widgets/gym_manager_widgets.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/gym_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class GymsScreen extends ConsumerStatefulWidget {
  const GymsScreen({super.key});

  @override
  ConsumerState<GymsScreen> createState() => _GymsScreenState();
}

class _GymsScreenState extends ConsumerState<GymsScreen> {
  final _search = TextEditingController();
  GymModel? _handleMatch;
  bool _handleLookupInFlight = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _lookupHandle(String query) async {
    final handle = GymSearch.handleFromQuery(query);
    final shouldLookup = query.trim().startsWith('@') && handle.isNotEmpty;
    if (!shouldLookup) {
      if (_handleMatch != null || _handleLookupInFlight) {
        setState(() {
          _handleMatch = null;
          _handleLookupInFlight = false;
        });
      }
      return;
    }

    setState(() => _handleLookupInFlight = true);
    final gym =
        await ref.read(firestoreServiceProvider).getGymByHandle(handle);
    if (!mounted) return;
    setState(() {
      _handleMatch = gym;
      _handleLookupInFlight = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _lookupHandle(value);
  }

  @override
  Widget build(BuildContext context) {
    final gymsAsync = ref.watch(activeGymsProvider);
    final memberships = ref.watch(userGymMembershipsProvider).valueOrNull ?? [];
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final query = _search.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Find a gym',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: gymsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            title: 'Could not load gyms',
            message: _friendlyFirestoreError(e),
            action: ProofButton(
              label: 'Try again',
              onPressed: () => ref.invalidate(activeGymsProvider),
            ),
          ),
        ),
        data: (gyms) {
          final myGymIds = memberships.map((m) => m.gymId).toSet();
          final myGyms = gyms.where((gym) => myGymIds.contains(gym.id)).toList();
          final filtered = GymSearch.mergeResults(
            filtered: GymSearch.filterActiveGyms(gyms, query),
            handleMatch: _handleMatch,
          );
          final searching = GymSearch.shouldSearch(query);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Search for a gym by name, city, country, or @handle.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: 16),
              GymSearchField(
                controller: _search,
                hint: 'Search gyms or @handle',
                onChanged: _onSearchChanged,
              ),
              if (_handleLookupInFlight) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              if (myGyms.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionTitle(title: 'Your gyms'),
                const SizedBox(height: 12),
                ...myGyms.map(
                  (gym) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGymCard(
                      context: context,
                      gym: gym,
                      memberships: memberships,
                      userId: userId,
                    ),
                  ),
                ),
              ],
              if (searching) ...[
                const SizedBox(height: 28),
                _SectionTitle(title: 'Search results'),
                const SizedBox(height: 12),
                if (filtered.isEmpty && !_handleLookupInFlight)
                  EmptyState(
                    title: 'No gyms found',
                    message: query.trim().startsWith('@')
                        ? 'No gym matches that handle. Check the spelling or ask the gym manager for their @handle.'
                        : 'Try another name, city, or country.',
                  )
                else
                  ...filtered.map(
                    (gym) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildGymCard(
                        context: context,
                        gym: gym,
                        memberships: memberships,
                        userId: userId,
                      ),
                    ),
                  ),
              ] else if (myGyms.isEmpty) ...[
                const SizedBox(height: 28),
                const EmptyState(
                  title: 'Search to find a gym',
                  message:
                      'Gyms are not listed automatically. Search by name, location, or @handle to request athlete or coach membership.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildGymCard({
    required BuildContext context,
    required GymModel gym,
    required List<GymMembershipModel> memberships,
    required String? userId,
  }) {
    final athleteMembership = memberships.where(
      (m) =>
          m.gymId == gym.id && m.membershipType == GymMembershipType.athlete,
    );
    final coachMembership = memberships.where(
      (m) => m.gymId == gym.id && m.membershipType == GymMembershipType.coach,
    );
    final managerMembership = memberships.where(
      (m) =>
          m.gymId == gym.id && m.membershipType == GymMembershipType.manager,
    );

    return _GymCard(
      gymName: gym.name,
      handle: gym.handle,
      location: _gymLocationLabel(gym),
      description: gym.description,
      athleteStatus:
          athleteMembership.isEmpty ? null : athleteMembership.first.status,
      coachStatus: coachMembership.isEmpty ? null : coachMembership.first.status,
      isManager: managerMembership.isNotEmpty &&
          managerMembership.first.status.isActive,
      onRequestAthlete: userId == null
          ? null
          : () => _requestMembership(
                context,
                gymId: gym.id,
                userId: userId,
                type: GymMembershipType.athlete,
              ),
      onRequestCoach: userId == null
          ? null
          : () => _requestMembership(
                context,
                gymId: gym.id,
                userId: userId,
                type: GymMembershipType.coach,
              ),
      onManage: managerMembership.isNotEmpty &&
              managerMembership.first.status.isActive
          ? () => context.push('/gym-manager/${gym.id}')
          : null,
    );
  }

  Future<void> _requestMembership(
    BuildContext context, {
    required String gymId,
    required String userId,
    required GymMembershipType type,
  }) async {
    try {
      final result =
          await ref.read(firestoreServiceProvider).requestGymMembership(
                gymId: gymId,
                userId: userId,
                type: type,
              );
      if (!context.mounted) return;

      final message = switch (result) {
        GymMembershipRequestResult.created =>
          '${type.label} request sent — pending gym approval',
        GymMembershipRequestResult.alreadyPending =>
          'You already have a pending ${type.label.toLowerCase()} request for this gym',
        GymMembershipRequestResult.alreadyApproved =>
          'You are already an approved ${type.label.toLowerCase()} at this gym',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      ref.invalidate(userGymMembershipsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyFirestoreError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

String _gymLocationLabel(GymModel gym) {
  final parts = [
    if (gym.city.isNotEmpty) gym.city,
    if (gym.country.isNotEmpty) gym.country,
  ];
  if (parts.isNotEmpty) return parts.join(', ');
  return gym.address;
}

String _friendlyFirestoreError(Object error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Firestore blocked this request (permission-denied). '
          'Confirm rules are published on project proof-e913a, then fully restart the app.';
    }
    return 'Firestore error (${error.code}): ${error.message ?? 'Please try again.'}';
  }

  final message = error.toString();
  if (message.contains('Not signed in') || message.contains('Signed-in account')) {
    return message;
  }
  if (message.contains('index') || message.contains('FAILED_PRECONDITION')) {
    return 'Gym data is still syncing. Pull to refresh or try again in a moment.';
  }
  if (message.contains('permission-denied')) {
    return 'Could not send the request. Publish the latest Firestore rules on proof-e913a, then restart the app.';
  }
  return 'Something went wrong. Please try again.';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({
    required this.gymName,
    required this.handle,
    required this.location,
    required this.description,
    required this.athleteStatus,
    required this.coachStatus,
    required this.isManager,
    this.onRequestAthlete,
    this.onRequestCoach,
    this.onManage,
  });

  final String gymName;
  final String handle;
  final String location;
  final String description;
  final GymMembershipStatus? athleteStatus;
  final GymMembershipStatus? coachStatus;
  final bool isManager;
  final VoidCallback? onRequestAthlete;
  final VoidCallback? onRequestCoach;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            gymName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$handle',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                  ),
            ),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              location,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (athleteStatus != null) ...[
            const SizedBox(height: 12),
            _StatusChip(status: athleteStatus!, prefix: 'Athlete'),
          ],
          if (coachStatus != null) ...[
            const SizedBox(height: 8),
            _StatusChip(status: coachStatus!, prefix: 'Coach'),
          ],
          const SizedBox(height: 16),
          if (onManage != null)
            ProofButton(label: 'Manage gym', onPressed: onManage!)
          else ...[
            if (athleteStatus == null && onRequestAthlete != null)
              ProofButton(
                label: 'Request athlete membership',
                isOutlined: true,
                onPressed: onRequestAthlete,
              ),
            if (coachStatus == null && onRequestCoach != null) ...[
              const SizedBox(height: 8),
              ProofButton(
                label: 'Request to coach here',
                isOutlined: true,
                onPressed: onRequestCoach,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.prefix});

  final GymMembershipStatus status;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      GymMembershipStatus.approved => AppColors.accent,
      GymMembershipStatus.pending => AppColors.inkMuted,
      GymMembershipStatus.rejected => AppColors.error,
      _ => AppColors.inkSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$prefix · ${status.label}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
