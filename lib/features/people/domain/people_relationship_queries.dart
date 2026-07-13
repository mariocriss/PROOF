import 'package:proof/shared/models/relationship_model.dart';

List<RelationshipModel> acceptedFriends(
  List<RelationshipModel> relationships,
  String userId,
) {
  return relationships
      .where(
        (r) =>
            r.type == RelationshipType.friend &&
            r.status == RelationshipStatus.accepted &&
            (r.fromUserId == userId || r.toUserId == userId),
      )
      .toList();
}

List<RelationshipModel> pendingIncomingFriendRequests(
  List<RelationshipModel> relationships,
  String userId,
) {
  return relationships
      .where(
        (r) =>
            r.type == RelationshipType.friend &&
            r.status == RelationshipStatus.pending &&
            r.toUserId == userId,
      )
      .toList();
}

List<RelationshipModel> pendingOutgoingFriendRequests(
  List<RelationshipModel> relationships,
  String userId,
) {
  return relationships
      .where(
        (r) =>
            r.type == RelationshipType.friend &&
            r.status == RelationshipStatus.pending &&
            r.fromUserId == userId,
      )
      .toList();
}

int countIncomingFriendRequests(
  List<RelationshipModel> relationships,
  String userId,
) {
  return pendingIncomingFriendRequests(relationships, userId).length;
}

int countAcceptedFriends(
  List<RelationshipModel> relationships,
  String userId,
) {
  return acceptedFriends(relationships, userId).length;
}

Set<String> blockedUserIds(
  List<RelationshipModel> relationships,
  String userId,
) {
  return relationships
      .where(
        (r) =>
            r.type == RelationshipType.friend &&
            r.status == RelationshipStatus.blocked &&
            r.fromUserId == userId,
      )
      .map((r) => r.toUserId)
      .toSet();
}

List<RelationshipModel> myCoaches(
  List<RelationshipModel> relationships,
  String userId,
) {
  return relationships
      .where(
        (r) =>
            r.type == RelationshipType.coach &&
            r.status == RelationshipStatus.accepted &&
            r.fromUserId == userId,
      )
      .toList();
}

List<RelationshipModel> pendingCoachRequestsForCoach(
  List<RelationshipModel> relationships,
  String coachId,
) {
  return relationships
      .where(
        (r) =>
            r.type == RelationshipType.coach &&
            r.status == RelationshipStatus.pending &&
            r.toUserId == coachId,
      )
      .toList();
}

List<RelationshipModel> myAthletes(
  List<RelationshipModel> relationships,
  String coachId,
) {
  return relationships
      .where(
        (r) =>
            r.type == RelationshipType.coach &&
            r.status == RelationshipStatus.accepted &&
            r.toUserId == coachId,
      )
      .toList();
}
