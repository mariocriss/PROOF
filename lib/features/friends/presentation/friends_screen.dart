import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/people/domain/people_search.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  late int _tab;
  final _discoverController = TextEditingController();
  final _friendsController = TextEditingController();
  PublicProfileModel? _handleMatch;
  bool _handleLookupInFlight = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    if (_tab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markRequestsSeen());
    }
  }

  @override
  void dispose() {
    _discoverController.dispose();
    _friendsController.dispose();
    super.dispose();
  }

  void _markRequestsSeen() {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    ref.read(firestoreServiceProvider).markIncomingFriendRequestsSeen(userId);
  }

  Future<void> _lookupHandle(String query) async {
    final handle = PeopleSearch.handleFromQuery(query);
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
    final profile = await ref
        .read(firestoreServiceProvider)
        .lookupPublicProfileByHandle(handle);
    if (!mounted) return;
    setState(() {
      _handleMatch = profile;
      _handleLookupInFlight = false;
    });
  }

  void _onDiscoverQueryChanged(String value) {
    setState(() {});
    _lookupHandle(value);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
    final friends = userId == null
        ? <RelationshipModel>[]
        : acceptedFriends(relationships, userId);
    final incomingCount = ref.watch(incomingFriendRequestCountProvider);
    final discoverQuery = _discoverController.text;
    final friendsQuery = _friendsController.text.trim().toLowerCase();
    final profilesAsync = ref.watch(searchablePublicProfilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'People',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          PeopleSegmentTabs(
            tabs: const ['Discover', 'Requests', 'Friends'],
            selectedIndex: _tab,
            tabBadges: incomingCount > 0 ? {1: incomingCount} : const {},
            onSelected: (index) {
              setState(() => _tab = index);
              if (index == 1) _markRequestsSeen();
            },
          ),
          const SizedBox(height: 24),
          if (_tab == 0) ...[
            TextField(
              controller: _discoverController,
              onChanged: _onDiscoverQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or @handle',
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
            profilesAsync.when(
              loading: () => const _StatusCard(message: 'Searching…'),
              error: (e, _) => _StatusCard(
                title: 'Could not load people',
                message: e.toString(),
              ),
              data: (_) {
                if (!PeopleSearch.shouldSearch(discoverQuery)) {
                  return const _StatusCard(
                    message: 'Search for people by name, @handle, or city.',
                  );
                }

                final results = PeopleSearch.mergeResults(
                  filtered:
                      ref.watch(peopleSearchResultsProvider(discoverQuery)),
                  extra: const [],
                  handleMatch: _handleMatch,
                  currentUserId: userId ?? '',
                  blockedUserIds: userId == null
                      ? const {}
                      : blockedUserIds(relationships, userId),
                );

                if (_handleLookupInFlight) {
                  return const _StatusCard(message: 'Searching…');
                }

                if (results.isEmpty) {
                  return const _StatusCard(
                    title: 'No people found',
                    message: 'Try another name or username.',
                  );
                }

                return Column(
                  children: [
                    for (final profile in results)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PersonSearchCard(profile: profile),
                      ),
                  ],
                );
              },
            ),
          ] else if (_tab == 1)
            FriendRequestsList(
              relationships: relationships,
              userId: userId,
            )
          else ...[
            TextField(
              controller: _friendsController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search your friends',
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
            PeopleSectionLabel(title: 'FRIENDS · ${friends.length}'),
            if (friends.isEmpty)
              const _StatusCard(
                message: 'No friends connected yet. Discover people you trust.',
              )
            else
              for (final friend in friends)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FriendRow(
                    userId: friend.fromUserId == userId
                        ? friend.toUserId
                        : friend.fromUserId,
                    query: friendsQuery,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _FriendRow extends ConsumerWidget {
  const _FriendRow({required this.userId, required this.query});

  final String userId;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendDisplayProfileProvider(userId));

    return profileAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        if (query.isNotEmpty) {
          final matches = profile.displayNameLowercase.contains(query) ||
              profile.handleLowercase.contains(query.replaceAll('@', '')) ||
              profile.city.toLowerCase().contains(query);
          if (!matches) return const SizedBox.shrink();
        }

        return _PersonListTile(
          profile: profile,
          onTap: () => context.push('/people/${profile.handle}'),
        );
      },
    );
  }
}

class _PersonSearchCard extends ConsumerWidget {
  const _PersonSearchCard({required this.profile});

  final PublicProfileModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final connection = ref.watch(friendConnectionProvider(profile.userId));

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/people/${profile.handle}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              PublicProfileAvatar(profile: profile),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '@${profile.handle}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                    ),
                    if (profile.city.isNotEmpty)
                      Text(
                        profile.city,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              FriendConnectionButton(
                profile: profile,
                connection: connection,
                userId: userId,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonListTile extends StatelessWidget {
  const _PersonListTile({
    required this.profile,
    required this.onTap,
  });

  final PublicProfileModel profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              PublicProfileAvatar(profile: profile),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '@${profile.handle}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                    ),
                    if (profile.city.isNotEmpty)
                      Text(
                        profile.city,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                      ),
                    if (profile.identityStatus.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.identityStatus,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
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
      return const _StatusCard(message: 'No pending friend requests.');
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
    final profileAsync = ref.watch(friendDisplayProfileProvider(otherId));

    return profileAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => context.push('/people/${profile.handle}'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PublicProfileAvatar(profile: profile),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text('@${profile.handle}'),
                          ],
                        ),
                      ),
                    ],
                  ),
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
            ),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({this.title, required this.message});

  final String? title;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          if (title != null) const SizedBox(height: 6),
          Text(message),
        ],
      ),
    );
  }
}
