import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/features/people/domain/blocked_user_entry.dart';
import 'package:proof/features/people/domain/friend_connection_state.dart';
import 'package:proof/features/people/domain/friend_request_policy.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/features/privacy/presentation/blocked_users_screen.dart';
import 'package:proof/features/privacy/presentation/privacy_settings_screen.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/services/firestore_service.dart';

RelationshipModel _blocked({
  required String from,
  required String to,
  required String blockedBy,
}) {
  return RelationshipModel(
    id: RelationshipModel.friendDocId(from, to),
    fromUserId: from,
    toUserId: to,
    type: RelationshipType.friend,
    status: RelationshipStatus.blocked,
    createdAt: DateTime(2026),
    blockedByUserId: blockedBy,
  );
}

PublicProfileModel _profile({
  required String userId,
  required String name,
  required String handle,
}) {
  return PublicProfileModel(
    userId: userId,
    displayName: name,
    handle: handle,
    displayNameLowercase: name.toLowerCase(),
    handleLowercase: handle.toLowerCase(),
    updatedAt: DateTime(2026),
  );
}

class _FakeFirestoreService extends Fake implements FirestoreService {
  _FakeFirestoreService({this.throwOnUnblock, this.onUnblock});

  final List<String> unblockCalls = [];
  final Object? throwOnUnblock;
  final void Function()? onUnblock;

  @override
  Future<void> unblockUser({
    required String currentUserId,
    required String relationshipId,
  }) async {
    unblockCalls.add(relationshipId);
    if (throwOnUnblock != null) throw throwOnUnblock!;
    onUnblock?.call();
  }
}

class _CountingUnblockService extends Fake implements FirestoreService {
  _CountingUnblockService(this._onUnblock);

  final Future<void> Function() _onUnblock;
  int calls = 0;

  @override
  Future<void> unblockUser({
    required String currentUserId,
    required String relationshipId,
  }) async {
    calls++;
    await _onUnblock();
  }
}

void main() {
  group('relationshipsBlockedByMe', () {
    test('includes only people the current user personally blocked', () {
      const me = 'me';
      const them = 'them';
      const other = 'other';

      final mine = _blocked(from: me, to: them, blockedBy: me);
      final againstMe = _blocked(from: me, to: other, blockedBy: other);

      expect(relationshipsBlockedByMe([mine, againstMe], me), [mine]);
      expect(relationshipsBlockedByMe([mine, againstMe], other), [againstMe]);
    });

    test('excludes blocks against the current user', () {
      const me = 'me';
      const them = 'them';
      final againstMe = _blocked(from: them, to: me, blockedBy: them);

      expect(relationshipsBlockedByMe([againstMe], me), isEmpty);
      expect(blockedUserIds([againstMe], me), {them});
    });
  });

  group('canUnblockRelationship', () {
    test('allows only the blocker', () {
      const me = 'me';
      const them = 'them';
      final rel = _blocked(from: me, to: them, blockedBy: me);

      expect(canUnblockRelationship(rel, me), isTrue);
      expect(canUnblockRelationship(rel, them), isFalse);
      expect(canUnblockRelationship(rel, 'outsider'), isFalse);
    });
  });

  group('BlockedUserEntry', () {
    test('sorts by display name and builds only blocker-owned rows', () {
      const me = 'me';
      final chris = _blocked(from: me, to: 'c', blockedBy: me);
      final alex = _blocked(from: 'a', to: me, blockedBy: me);
      final ignored = _blocked(from: me, to: 'x', blockedBy: 'x');

      final entries = BlockedUserEntry.buildSorted(
        relationships: [chris, alex, ignored],
        currentUserId: me,
        profilesByUserId: {
          'c': _profile(userId: 'c', name: 'Chris', handle: 'chris'),
          'a': _profile(userId: 'a', name: 'Alex', handle: 'alex'),
        },
      );

      expect(entries.map((e) => e.displayName), ['Alex', 'Chris']);
      expect(entries.map((e) => e.otherUserId), ['a', 'c']);
    });

    test('empty list stays empty', () {
      expect(
        BlockedUserEntry.buildSorted(
          relationships: const [],
          currentUserId: 'me',
          profilesByUserId: const {},
        ),
        isEmpty,
      );
    });
  });

  group('unblock does not recreate friendship', () {
    test('friend request policy stays none while blocked', () {
      final existing = _blocked(from: 'a', to: 'b', blockedBy: 'a');
      expect(
        FriendRequestPolicy.decide(
          fromUserId: 'b',
          toUserId: 'a',
          existing: existing,
          reversePendingExists: false,
        ),
        FriendRequestAction.none,
      );
    });

    test('after delete resolve returns none (no auto friendship)', () {
      final connection = FriendConnection.resolve(
        currentUserId: 'me',
        otherUserId: 'them',
        relationships: const [],
      );
      expect(connection.state, FriendConnectionState.none);
      expect(connection.relationship, isNull);
    });
  });

  group('BlockedUsersScreen', () {
    testWidgets('empty state renders correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            blockedUsersEntriesProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: BlockedUsersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blocked users'), findsWidgets);
      expect(find.text('You haven\'t blocked anyone.'), findsOneWidget);
    });

    testWidgets('lists people blocked by me', (tester) async {
      final entry = BlockedUserEntry(
        relationship: _blocked(from: 'me', to: 'them', blockedBy: 'me'),
        otherUserId: 'them',
        profile: _profile(userId: 'them', name: 'Taylor', handle: 'taylor'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            blockedUsersEntriesProvider.overrideWith((ref) async => [entry]),
          ],
          child: const MaterialApp(home: BlockedUsersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Taylor'), findsOneWidget);
      expect(find.text('@taylor'), findsOneWidget);
      expect(find.text('Unblock'), findsOneWidget);
      expect(find.text('You haven\'t blocked anyone.'), findsNothing);
    });

    testWidgets('successful unblock removes the row', (tester) async {
      final entries = <BlockedUserEntry>[
        BlockedUserEntry(
          relationship: _blocked(from: 'me', to: 'them', blockedBy: 'me'),
          otherUserId: 'them',
          profile: _profile(userId: 'them', name: 'Taylor', handle: 'taylor'),
        ),
      ];
      final service = _FakeFirestoreService(onUnblock: () => entries.clear());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreServiceProvider.overrideWithValue(service),
            currentAuthUidProvider.overrideWithValue('me'),
            blockedUsersEntriesProvider.overrideWith(
              (ref) async => List<BlockedUserEntry>.of(entries),
            ),
          ],
          child: const MaterialApp(home: BlockedUsersScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Taylor'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Unblock'));
      await tester.pumpAndSettle();
      expect(find.text('Unblock Taylor?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Unblock'));
      await tester.pumpAndSettle();

      expect(service.unblockCalls, hasLength(1));
      expect(find.text('Taylor has been unblocked'), findsOneWidget);
      expect(find.text('Taylor'), findsNothing);
      expect(find.text('You haven\'t blocked anyone.'), findsOneWidget);
    });

    testWidgets('permission failure keeps the list item', (tester) async {
      final service = _FakeFirestoreService(
        throwOnUnblock: StateError('Only the blocker can unblock this user.'),
      );
      final entry = BlockedUserEntry(
        relationship: _blocked(from: 'me', to: 'them', blockedBy: 'me'),
        otherUserId: 'them',
        profile: _profile(userId: 'them', name: 'Taylor', handle: 'taylor'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreServiceProvider.overrideWithValue(service),
            currentAuthUidProvider.overrideWithValue('me'),
            blockedUsersEntriesProvider.overrideWith((ref) async => [entry]),
          ],
          child: const MaterialApp(home: BlockedUsersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Unblock'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Unblock'));
      await tester.pumpAndSettle();

      expect(find.text('Taylor'), findsOneWidget);
      expect(
        find.text('Only the blocker can unblock this user.'),
        findsOneWidget,
      );
    });

    testWidgets('duplicate confirm taps do not produce duplicate writes', (
      tester,
    ) async {
      final service = _CountingUnblockService(() async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      final entry = BlockedUserEntry(
        relationship: _blocked(from: 'me', to: 'them', blockedBy: 'me'),
        otherUserId: 'them',
        profile: _profile(userId: 'them', name: 'Taylor', handle: 'taylor'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreServiceProvider.overrideWithValue(service),
            currentAuthUidProvider.overrideWithValue('me'),
            blockedUsersEntriesProvider.overrideWith((ref) async => [entry]),
          ],
          child: const MaterialApp(home: BlockedUsersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Unblock'));
      await tester.pumpAndSettle();

      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      ).last;
      await tester.tap(confirm);
      await tester.pump();
      await tester.tap(confirm);
      await tester.pump();
      await tester.tap(confirm);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(service.calls, 1);
    });
  });

  group('FriendConnectionButton blocked states', () {
    testWidgets('blocker sees Unblock; blocked participant does not', (
      tester,
    ) async {
      final rel = _blocked(from: 'me', to: 'them', blockedBy: 'me');
      final profile = _profile(
        userId: 'them',
        name: 'Taylor',
        handle: 'taylor',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FriendConnectionButton(
                profile: profile,
                connection: FriendConnection(
                  state: FriendConnectionState.blocked,
                  relationship: rel,
                ),
                userId: 'me',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Unblock'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FriendConnectionButton(
                profile: _profile(userId: 'me', name: 'Me', handle: 'me'),
                connection: FriendConnection(
                  state: FriendConnectionState.blocked,
                  relationship: rel,
                ),
                userId: 'them',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('Unblock'), findsNothing);
    });
  });

  group('navigation discoverability', () {
    testWidgets('Privacy settings exposes Blocked users', (tester) async {
      final identity = PhysicalIdentity(
        userId: 'me',
        displayName: 'Me',
        handle: 'me',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const PrivacySettingsScreen()),
          GoRoute(
            path: '/blocked-users',
            builder: (_, _) =>
                const Scaffold(body: Text('blocked-users-route')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            physicalIdentityProvider.overrideWith(
              (ref) => Stream.value(identity),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blocked users'), findsOneWidget);
      await tester.tap(find.text('Blocked users'));
      await tester.pumpAndSettle();
      expect(find.text('blocked-users-route'), findsOneWidget);
    });
  });
}
