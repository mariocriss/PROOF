import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/friends/presentation/friends_screen.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Friend Requests',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FriendRequestsList(
            relationships: relationships,
            userId: userId,
          ),
        ],
      ),
    );
  }
}

class CoachRequestsScreen extends ConsumerWidget {
  const CoachRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
    final incoming =
        userId == null ? [] : pendingCoachRequestsForCoach(relationships, userId);
    final sent = relationships
        .where(
          (r) =>
              r.type == RelationshipType.coach &&
              r.status == RelationshipStatus.pending &&
              r.fromUserId == userId,
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Coach Requests',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (incoming.isEmpty && sent.isEmpty)
            const _EmptyCard(message: 'No pending coach requests.')
          else ...[
            if (incoming.isNotEmpty) ...[
              const PeopleSectionLabel(title: 'INCOMING'),
              ...incoming.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CoachRequestRow(relationship: r, incoming: true),
                ),
              ),
            ],
            if (sent.isNotEmpty) ...[
              const PeopleSectionLabel(title: 'SENT'),
              ...sent.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CoachRequestRow(relationship: r, incoming: false),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CoachRequestRow extends ConsumerWidget {
  const _CoachRequestRow({
    required this.relationship,
    required this.incoming,
  });

  final RelationshipModel relationship;
  final bool incoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherId =
        incoming ? relationship.fromUserId : relationship.toUserId;
    final identityAsync = ref.watch(identityByUserIdProvider(otherId));

    return identityAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (identity) {
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
              Text(identity?.displayName ?? 'User'),
              if (identity != null) Text('@${identity.handle}'),
              if (incoming) ...[
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
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(message),
    );
  }
}
