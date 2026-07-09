import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class CoachesScreen extends ConsumerStatefulWidget {
  const CoachesScreen({super.key});

  @override
  ConsumerState<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends ConsumerState<CoachesScreen> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
    final coaches = ref.watch(coachProfilesProvider).valueOrNull ?? [];

    final myCoachLinks = userId == null ? <RelationshipModel>[] : myCoaches(relationships, userId);
    final pendingForCoach =
        userId == null ? <RelationshipModel>[] : pendingCoachRequestsForCoach(relationships, userId);
    final pendingSent = relationships
        .where(
          (r) =>
              r.type == RelationshipType.coach &&
              r.status == RelationshipStatus.pending &&
              r.fromUserId == userId,
        )
        .toList();

    final filteredCoaches = coaches.where((coach) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return coach.displayName.toLowerCase().contains(q) ||
          coach.handle.toLowerCase().contains(q) ||
          coach.specialty.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Coaches',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          PeopleSegmentTabs(
            tabs: const ['My Coaches', 'Discover', 'Requests'],
            selectedIndex: _tab,
            onSelected: (index) => setState(() => _tab = index),
          ),
          const SizedBox(height: 24),
          if (_tab == 0) ...[
            const PeopleSectionLabel(title: 'MY COACHES'),
            if (myCoachLinks.isEmpty)
              const _EmptyPeopleCard(
                message: 'No coaches connected yet. Discover coaches to strengthen your identity.',
              )
            else
              ...myCoachLinks.map(
                (link) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ConnectedCoachTile(coachUserId: link.toUserId),
                ),
              ),
            const SizedBox(height: 20),
            ProofButton(
              label: 'Find Coaches',
              onPressed: () => setState(() => _tab = 1),
            ),
          ] else if (_tab == 1) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search coaches...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const PeopleSectionLabel(title: 'SUGGESTED COACHES'),
            if (filteredCoaches.isEmpty)
              const _EmptyPeopleCard(message: 'No coaches found yet.')
            else
              ...filteredCoaches.map(
                (coach) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DiscoverCoachRow(
                    coach: coach,
                    userId: userId,
                    relationships: relationships,
                  ),
                ),
              ),
          ] else ...[
            if (pendingForCoach.isNotEmpty) ...[
              const PeopleSectionLabel(title: 'INCOMING REQUESTS'),
              ...pendingForCoach.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CoachRequestCard(
                    relationship: request,
                    otherUserId: request.fromUserId,
                    isIncoming: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (pendingSent.isNotEmpty) ...[
              const PeopleSectionLabel(title: 'SENT REQUESTS'),
              ...pendingSent.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CoachRequestCard(
                    relationship: request,
                    otherUserId: request.toUserId,
                    isIncoming: false,
                  ),
                ),
              ),
            ],
            if (pendingForCoach.isEmpty && pendingSent.isEmpty)
              const _EmptyPeopleCard(message: 'No pending coach requests.'),
          ],
        ],
      ),
    );
  }
}

class _ConnectedCoachTile extends ConsumerWidget {
  const _ConnectedCoachTile({required this.coachUserId});

  final String coachUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(coachProfileProvider(coachUserId)).valueOrNull;
    if (profile == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return CoachListCard(
      profile: profile,
      onTap: () => context.push('/coaches/${profile.handle}'),
    );
  }
}

class _DiscoverCoachRow extends ConsumerWidget {
  const _DiscoverCoachRow({
    required this.coach,
    required this.userId,
    required this.relationships,
  });

  final CoachProfile coach;
  final String? userId;
  final List<RelationshipModel> relationships;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = relationships.where(
      (r) =>
          r.type == RelationshipType.coach &&
          r.fromUserId == userId &&
          r.toUserId == coach.userId,
    );
    final isConnected = existing.any((r) => r.status == RelationshipStatus.accepted);
    final isPending = existing.any((r) => r.status == RelationshipStatus.pending);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.push('/coaches/${coach.handle}'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: coach.avatarUrl != null
                        ? NetworkImage(coach.avatarUrl!)
                        : null,
                    child: coach.avatarUrl == null
                        ? Text(coach.displayName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.displayName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          '@${coach.handle} · ${coach.specialty}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${coach.athleteCount} Athletes · ${coach.verifiedProofCount} Verified Proofs',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isConnected)
            const Chip(label: Text('Connected'))
          else if (isPending)
            const Chip(label: Text('Pending'))
          else
            SizedBox(
              width: 108,
              child: ProofButton(
                label: 'Add Coach',
                onPressed: userId == null
                    ? null
                    : () async {
                        await ref.read(firestoreServiceProvider).sendCoachRequest(
                              athleteId: userId!,
                              coachId: coach.userId,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coach request sent')),
                          );
                        }
                      },
              ),
            ),
        ],
      ),
    );
  }
}

class _CoachRequestCard extends ConsumerWidget {
  const _CoachRequestCard({
    required this.relationship,
    required this.otherUserId,
    required this.isIncoming,
  });

  final RelationshipModel relationship;
  final String otherUserId;
  final bool isIncoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityByUserIdProvider(otherUserId));

    return identityAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (identity) {
        final name = identity?.displayName ?? 'User';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleSmall),
              if (identity != null)
                Text(
                  '@${identity.handle}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              if (isIncoming) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ProofButton(
                        label: 'Accept',
                        onPressed: () async {
                          await ref
                              .read(firestoreServiceProvider)
                              .respondToRelationship(
                                relationshipId: relationship.id,
                                accept: true,
                              );
                          await ref
                              .read(firestoreServiceProvider)
                              .syncCoachProfile(relationship.toUserId);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProofButton(
                        label: 'Decline',
                        isOutlined: true,
                        onPressed: () => ref
                            .read(firestoreServiceProvider)
                            .respondToRelationship(
                              relationshipId: relationship.id,
                              accept: false,
                            ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Waiting for response',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyPeopleCard extends StatelessWidget {
  const _EmptyPeopleCard({required this.message});

  final String message;

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
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inkSecondary,
            ),
      ),
    );
  }
}
