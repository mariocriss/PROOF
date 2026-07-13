import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/people/domain/friend_request_policy.dart';
import 'package:proof/shared/models/relationship_model.dart';

void main() {
  RelationshipModel rel({
    required String from,
    required String to,
    RelationshipStatus status = RelationshipStatus.pending,
  }) {
    return RelationshipModel(
      id: RelationshipModel.friendDocId(from, to),
      fromUserId: from,
      toUserId: to,
      type: RelationshipType.friend,
      status: status,
      createdAt: DateTime(2026),
    );
  }

  group('FriendRequestPolicy.decide', () {
    test('returns none when sending request to self', () {
      expect(
        FriendRequestPolicy.decide(
          fromUserId: 'a',
          toUserId: 'a',
        ),
        FriendRequestAction.none,
      );
    });

    test('creates pending request when no relationship exists', () {
      expect(
        FriendRequestPolicy.decide(
          fromUserId: 'a',
          toUserId: 'b',
        ),
        FriendRequestAction.createPending,
      );
    });

    test('accepts when cross-request already pending from other user', () {
      expect(
        FriendRequestPolicy.decide(
          fromUserId: 'a',
          toUserId: 'b',
          reversePendingExists: true,
        ),
        FriendRequestAction.acceptExisting,
      );
    });

    test('does nothing for accepted or blocked relationships', () {
      for (final status in [
        RelationshipStatus.accepted,
        RelationshipStatus.blocked,
      ]) {
        expect(
          FriendRequestPolicy.decide(
            fromUserId: 'a',
            toUserId: 'b',
            existing: rel(from: 'a', to: 'b', status: status),
          ),
          FriendRequestAction.none,
        );
      }
    });

    test('does nothing for duplicate outgoing pending request', () {
      expect(
        FriendRequestPolicy.decide(
          fromUserId: 'a',
          toUserId: 'b',
          existing: rel(from: 'a', to: 'b'),
        ),
        FriendRequestAction.none,
      );
    });

    test('accepts when incoming pending request exists on same record', () {
      expect(
        FriendRequestPolicy.decide(
          fromUserId: 'a',
          toUserId: 'b',
          existing: rel(from: 'b', to: 'a'),
        ),
        FriendRequestAction.acceptExisting,
      );
    });

    test('reopens declined request from original requester', () {
      expect(
        FriendRequestPolicy.decide(
          fromUserId: 'a',
          toUserId: 'b',
          existing: rel(
            from: 'a',
            to: 'b',
            status: RelationshipStatus.declined,
          ),
        ),
        FriendRequestAction.reopenDeclined,
      );
    });

    test('reopens rejected request from original requester', () {
      expect(
        FriendRequestPolicy.decide(
          fromUserId: 'a',
          toUserId: 'b',
          existing: rel(
            from: 'a',
            to: 'b',
            status: RelationshipStatus.rejected,
          ),
        ),
        FriendRequestAction.reopenDeclined,
      );
    });
  });
}
