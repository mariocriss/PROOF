import 'package:proof/features/people/domain/people_relationship_queries.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/verification_request_model.dart';

class MoreMenuCounts {
  const MoreMenuCounts({
    this.friends = 0,
    this.coaches = 0,
    this.verificationRequests = 0,
    this.friendRequests = 0,
    this.coachRequests = 0,
    this.coachQueue = 0,
  });

  final int friends;
  final int coaches;
  final int verificationRequests;
  final int friendRequests;
  final int coachRequests;
  final int coachQueue;

  int? get friendsBadge => friendRequests > 0 ? friendRequests : null;
}

class PeopleMenuCounts {
  const PeopleMenuCounts._();

  static MoreMenuCounts build({
    required String userId,
    required List<RelationshipModel> relationships,
    required List<VerificationRequestModel> verificationRequests,
    int coachQueue = 0,
    bool includeCoaches = true,
  }) {
    final friends = countAcceptedFriends(relationships, userId);
    final coaches = includeCoaches ? myCoaches(relationships, userId).length : 0;
    final friendRequests = countIncomingFriendRequests(relationships, userId);

    final coachRequests = relationships
        .where(
          (r) =>
              r.type == RelationshipType.coach &&
              r.status == RelationshipStatus.pending &&
              r.toUserId == userId,
        )
        .length;

    final pendingVerifications = verificationRequests
        .where((r) => r.status == VerificationRequestStatus.pending)
        .length;

    return MoreMenuCounts(
      friends: friends,
      coaches: coaches,
      verificationRequests: pendingVerifications,
      friendRequests: friendRequests,
      coachRequests: coachRequests,
      coachQueue: coachQueue,
    );
  }
}
