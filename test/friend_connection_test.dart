import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/people/domain/friend_connection_state.dart';
import 'package:proof/shared/models/relationship_model.dart';

void main() {
  RelationshipModel friend({
    required String id,
    required String from,
    required String to,
    RelationshipStatus status = RelationshipStatus.pending,
  }) {
    return RelationshipModel(
      id: id,
      fromUserId: from,
      toUserId: to,
      type: RelationshipType.friend,
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('FriendConnection.resolve', () {
    test('returns none when no relationship exists', () {
      final result = FriendConnection.resolve(
        currentUserId: 'me',
        otherUserId: 'other',
        relationships: const [],
      );
      expect(result.state, FriendConnectionState.none);
      expect(result.relationship, isNull);
    });

    test('returns outgoing pending when current user sent request', () {
      final rel = friend(id: 'r1', from: 'me', to: 'other');
      final result = FriendConnection.resolve(
        currentUserId: 'me',
        otherUserId: 'other',
        relationships: [rel],
      );
      expect(result.state, FriendConnectionState.outgoingPending);
      expect(result.relationship?.id, 'r1');
    });

    test('returns incoming pending when other user sent request', () {
      final rel = friend(id: 'r1', from: 'other', to: 'me');
      final result = FriendConnection.resolve(
        currentUserId: 'me',
        otherUserId: 'other',
        relationships: [rel],
      );
      expect(result.state, FriendConnectionState.incomingPending);
    });

    test('returns accepted for accepted friendships', () {
      final rel = friend(
        id: 'r1',
        from: 'other',
        to: 'me',
        status: RelationshipStatus.accepted,
      );
      final result = FriendConnection.resolve(
        currentUserId: 'me',
        otherUserId: 'other',
        relationships: [rel],
      );
      expect(result.state, FriendConnectionState.accepted);
    });

    test('returns declined for declined and rejected statuses', () {
      for (final status in [
        RelationshipStatus.declined,
        RelationshipStatus.rejected,
      ]) {
        final rel = friend(
          id: 'r1',
          from: 'me',
          to: 'other',
          status: status,
        );
        final result = FriendConnection.resolve(
          currentUserId: 'me',
          otherUserId: 'other',
          relationships: [rel],
        );
        expect(result.state, FriendConnectionState.declined);
      }
    });

    test('returns blocked for blocked relationships', () {
      final rel = friend(
        id: 'r1',
        from: 'me',
        to: 'other',
        status: RelationshipStatus.blocked,
      );
      final result = FriendConnection.resolve(
        currentUserId: 'me',
        otherUserId: 'other',
        relationships: [rel],
      );
      expect(result.state, FriendConnectionState.blocked);
    });

    test('ignores coach relationships', () {
      final rel = RelationshipModel(
        id: 'c1',
        fromUserId: 'me',
        toUserId: 'coach',
        type: RelationshipType.coach,
        status: RelationshipStatus.accepted,
        createdAt: DateTime(2026),
      );
      final result = FriendConnection.resolve(
        currentUserId: 'me',
        otherUserId: 'coach',
        relationships: [rel],
      );
      expect(result.state, FriendConnectionState.none);
    });
  });
}
