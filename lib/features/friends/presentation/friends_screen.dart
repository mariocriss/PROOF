import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tab = 0;
  final _handleController = TextEditingController();

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
    final friends = userId == null ? <RelationshipModel>[] : acceptedFriends(relationships, userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Friends',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          PeopleSegmentTabs(
            tabs: const ['My Friends', 'Discover', 'Requests'],
            selectedIndex: _tab,
            onSelected: (index) => setState(() => _tab = index),
          ),
          const SizedBox(height: 24),
          if (_tab == 0) ...[
            const PeopleSectionLabel(title: 'MY FRIENDS'),
            if (friends.isEmpty)
              const _EmptyCard(
                message: 'No friends connected yet. Discover people you trust.',
              )
            else
              ...friends.map(
                (friend) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FriendTile(
                    userId: friend.fromUserId == userId
                        ? friend.toUserId
                        : friend.fromUserId,
                  ),
                ),
              ),
          ] else if (_tab == 1) ...[
            TextField(
              controller: _handleController,
              decoration: InputDecoration(
                hintText: 'Search by @handle',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ProofButton(
              label: 'Send Friend Request',
              onPressed: () => _sendFriendRequest(context),
            ),
          ] else
            FriendRequestsList(
              relationships: relationships,
              userId: userId,
            ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest(BuildContext context) async {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;

    final handle = _handleController.text.trim().replaceAll('@', '');
    if (handle.isEmpty) return;

    final targetId =
        await ref.read(firestoreServiceProvider).resolveUserIdByHandle(handle);
    if (targetId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Handle not found')),
        );
      }
      return;
    }

    await ref.read(firestoreServiceProvider).sendFriendRequest(
          fromUserId: userId,
          toUserId: targetId,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
    }
  }
}

class FriendRequestsList extends ConsumerWidget {
  const FriendRequestsList({
    super.key,
    required this.relationships,
    required this.userId,
  });

  final List<RelationshipModel> relationships;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = userId == null
        ? <RelationshipModel>[]
        : pendingFriendRequests(relationships, userId!);
    final sent = relationships
        .where(
          (r) =>
              r.type == RelationshipType.friend &&
              r.status == RelationshipStatus.pending &&
              r.fromUserId == userId,
        )
        .toList();

    if (incoming.isEmpty && sent.isEmpty) {
      return const _EmptyCard(message: 'No pending friend requests.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (incoming.isNotEmpty) ...[
          const PeopleSectionLabel(title: 'INCOMING'),
          ...incoming.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FriendRequestCard(relationship: request, incoming: true),
            ),
          ),
        ],
        if (sent.isNotEmpty) ...[
          const PeopleSectionLabel(title: 'SENT'),
          ...sent.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FriendRequestCard(relationship: request, incoming: false),
            ),
          ),
        ],
      ],
    );
  }
}

class _FriendTile extends ConsumerWidget {
  const _FriendTile({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityByUserIdProvider(userId));
    return identityAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (identity) {
        if (identity == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: identity.avatarUrl != null
                    ? NetworkImage(identity.avatarUrl!)
                    : null,
                child: identity.avatarUrl == null
                    ? Text(identity.displayName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text('@${identity.handle}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FriendRequestCard extends ConsumerWidget {
  const _FriendRequestCard({
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
                        onPressed: () => ref
                            .read(firestoreServiceProvider)
                            .respondToRelationship(
                              relationshipId: relationship.id,
                              accept: true,
                            ),
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
      width: double.infinity,
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
