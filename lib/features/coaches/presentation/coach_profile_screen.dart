import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/verification_request_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class CoachProfileScreen extends ConsumerWidget {
  const CoachProfileScreen({
    super.key,
    required this.handle,
    this.gymId,
  });

  final String handle;
  final String? gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityByHandleProvider(handle));
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
    final managedGyms = ref.watch(managedGymsProvider).valueOrNull ?? [];
    final gymMemberships = gymId != null
        ? ref.watch(gymMembershipsForGymProvider(gymId!)).valueOrNull ?? []
        : const <GymMembershipModel>[];

    return identityAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (identity) {
        if (identity == null) {
          return Scaffold(
            appBar: ProofAppBar(
              title: 'Coach',
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: const Center(child: Text('Coach not found')),
          );
        }

        final coachProfile =
            ref.watch(coachProfileProvider(identity.userId)).valueOrNull;
        final user = ref.watch(currentUserProvider).valueOrNull;

        final existing = relationships.where(
          (r) =>
              r.type == RelationshipType.coach &&
              r.fromUserId == userId &&
              r.toUserId == identity.userId,
        );
        final isConnected =
            existing.any((r) => r.status == RelationshipStatus.accepted);
        final isPending =
            existing.any((r) => r.status == RelationshipStatus.pending);

        final approvedGymMembership = _approvedGymMembership(
          coachUserId: identity.userId,
          gymId: gymId,
          gymMemberships: gymMemberships,
        );
        final isApprovedAtManagedGym = approvedGymMembership != null &&
            managedGyms.any((g) => g.id == approvedGymMembership.gymId);
        final approvedGymName = approvedGymMembership != null
            ? managedGyms
                    .where((g) => g.id == approvedGymMembership.gymId)
                    .firstOrNull
                    ?.name ??
                'your gym'
            : null;

        final topSkills = _topVerifiedSkills(
          ref.watch(coachVerifiedProofsProvider(identity.userId)).valueOrNull ??
              [],
          identity.userId,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ProofAppBar(
            title: 'Coach Profile',
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Container(
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
                      backgroundImage: identity.avatarUrl != null
                          ? NetworkImage(identity.avatarUrl!)
                          : null,
                      child: identity.avatarUrl == null
                          ? Text(
                              identity.displayName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      identity.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '@${identity.handle}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coachProfile?.specialty ??
                          user?.specialty ??
                          'Strength Coach',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (identity.bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        identity.bio,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.inkSecondary,
                              height: 1.4,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(
                            value: '${coachProfile?.verifiedProofCount ?? 0}',
                            label: 'Verified Proofs',
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.divider),
                        Expanded(
                          child: _ProfileStat(
                            value: '${coachProfile?.athleteCount ?? 0}',
                            label: 'Athletes',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (topSkills.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'TOP VERIFIED SKILLS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 12),
                ...topSkills.map(
                  (skill) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      skill,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (userId == identity.userId)
                ProofButton(
                  label: 'This is your profile',
                  onPressed: null,
                )
              else if (isApprovedAtManagedGym)
                ProofButton(
                  label: 'Approved Coach at $approvedGymName',
                  onPressed: null,
                )
              else if (isConnected)
                ProofButton(
                  label: 'Connected Coach',
                  onPressed: null,
                )
              else if (isPending)
                ProofButton(
                  label: 'Request Pending',
                  onPressed: null,
                )
              else if (user?.hasIdentity == true)
                ProofButton(
                  label: 'Request Coach',
                  onPressed: () async {
                    await ref.read(firestoreServiceProvider).sendCoachRequest(
                          athleteId: userId!,
                          coachId: identity.userId,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coach request sent')),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  GymMembershipModel? _approvedGymMembership({
    required String coachUserId,
    required String? gymId,
    required List<GymMembershipModel> gymMemberships,
  }) {
    if (gymId == null) return null;

    for (final membership in gymMemberships) {
      if (membership.userId == coachUserId &&
          membership.membershipType == GymMembershipType.coach &&
          membership.status == GymMembershipStatus.approved) {
        return membership;
      }
    }
    return null;
  }

  List<String> _topVerifiedSkills(
    List<VerificationRequestModel> approved,
    String coachId,
  ) {
    final counts = <String, int>{};
    for (final request in approved.where((r) => r.coachId == coachId)) {
      if (request.skillName.isEmpty) continue;
      counts[request.skillName] = (counts[request.skillName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkMuted,
              ),
        ),
      ],
    );
  }
}
