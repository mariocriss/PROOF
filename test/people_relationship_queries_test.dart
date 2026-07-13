import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/people/domain/people_menu_counts.dart';
import 'package:proof/features/people/domain/people_relationship_queries.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/verification_request_model.dart';

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
      createdAt: DateTime(2026),
    );
  }

  final relationships = [
    friend(id: 'f1', from: 'a', to: 'me', status: RelationshipStatus.accepted),
    friend(id: 'f2', from: 'b', to: 'me'),
    friend(id: 'f3', from: 'me', to: 'c'),
    friend(id: 'f4', from: 'me', to: 'd', status: RelationshipStatus.blocked),
    RelationshipModel(
      id: 'c1',
      fromUserId: 'me',
      toUserId: 'coach1',
      type: RelationshipType.coach,
      status: RelationshipStatus.accepted,
      createdAt: DateTime(2026),
    ),
  ];

  group('people relationship queries', () {
    test('acceptedFriends returns only accepted friendships', () {
      expect(
        acceptedFriends(relationships, 'me').map((r) => r.id),
        ['f1'],
      );
    });

    test('pendingIncomingFriendRequests returns requests addressed to user', () {
      expect(
        pendingIncomingFriendRequests(relationships, 'me').map((r) => r.id),
        ['f2'],
      );
    });

    test('pendingOutgoingFriendRequests returns requests sent by user', () {
      expect(
        pendingOutgoingFriendRequests(relationships, 'me').map((r) => r.id),
        ['f3'],
      );
    });

    test('blockedUserIds returns users blocked by current user', () {
      expect(blockedUserIds(relationships, 'me'), {'d'});
    });

    test('countIncomingFriendRequests matches pending incoming list', () {
      expect(countIncomingFriendRequests(relationships, 'me'), 1);
    });
  });

  group('PeopleMenuCounts', () {
    test('badge uses incoming requests not accepted friend count', () {
      final counts = PeopleMenuCounts.build(
        userId: 'me',
        relationships: relationships,
        verificationRequests: const [],
      );

      expect(counts.friends, 1);
      expect(counts.friendRequests, 1);
      expect(counts.friendsBadge, 1);
    });

    test('friendsBadge is null when no incoming requests remain', () {
      final acceptedOnly = [
        friend(
          id: 'f1',
          from: 'a',
          to: 'me',
          status: RelationshipStatus.accepted,
        ),
      ];

      final counts = PeopleMenuCounts.build(
        userId: 'me',
        relationships: acceptedOnly,
        verificationRequests: const [],
      );

      expect(counts.friends, 1);
      expect(counts.friendRequests, 0);
      expect(counts.friendsBadge, isNull);
    });

    test('includes pending verification and coach request counts', () {
      final withExtras = [
        ...relationships,
        RelationshipModel(
          id: 'c2',
          fromUserId: 'athlete',
          toUserId: 'me',
          type: RelationshipType.coach,
          status: RelationshipStatus.pending,
          createdAt: DateTime(2026),
        ),
      ];

      final counts = PeopleMenuCounts.build(
        userId: 'me',
        relationships: withExtras,
        verificationRequests: [
          VerificationRequestModel(
            id: 'v1',
            proofId: 'p1',
            athleteId: 'me',
            coachId: 'coach1',
            gymId: 'g1',
            skillId: 's1',
            status: VerificationRequestStatus.pending,
            createdAt: DateTime(2026),
          ),
        ],
        coachQueue: 2,
      );

      expect(counts.coaches, 1);
      expect(counts.coachRequests, 1);
      expect(counts.verificationRequests, 1);
      expect(counts.coachQueue, 2);
    });
  });
}
