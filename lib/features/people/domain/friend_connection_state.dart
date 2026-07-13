import 'package:proof/shared/models/relationship_model.dart';

enum FriendConnectionState {
  none,
  outgoingPending,
  incomingPending,
  accepted,
  declined,
  blocked,
}

class FriendConnection {
  const FriendConnection({
    required this.state,
    this.relationship,
  });

  final FriendConnectionState state;
  final RelationshipModel? relationship;

  static FriendConnection resolve({
    required String currentUserId,
    required String otherUserId,
    required List<RelationshipModel> relationships,
  }) {
    final friendLinks = relationships.where(
      (r) =>
          r.type == RelationshipType.friend &&
          ((r.fromUserId == currentUserId && r.toUserId == otherUserId) ||
              (r.fromUserId == otherUserId && r.toUserId == currentUserId)),
    );

    if (friendLinks.isEmpty) {
      return const FriendConnection(state: FriendConnectionState.none);
    }

    final relationship = friendLinks.first;
    return switch (relationship.status) {
      RelationshipStatus.blocked =>
        FriendConnection(state: FriendConnectionState.blocked, relationship: relationship),
      RelationshipStatus.accepted =>
        FriendConnection(state: FriendConnectionState.accepted, relationship: relationship),
      RelationshipStatus.declined ||
      RelationshipStatus.rejected =>
        FriendConnection(state: FriendConnectionState.declined, relationship: relationship),
      RelationshipStatus.pending when relationship.fromUserId == currentUserId =>
        FriendConnection(state: FriendConnectionState.outgoingPending, relationship: relationship),
      RelationshipStatus.pending =>
        FriendConnection(state: FriendConnectionState.incomingPending, relationship: relationship),
    };
  }
}
