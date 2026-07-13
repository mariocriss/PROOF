import 'package:proof/shared/models/relationship_model.dart';

enum FriendRequestAction {
  none,
  createPending,
  acceptExisting,
  reopenDeclined,
}

class FriendRequestPolicy {
  const FriendRequestPolicy._();

  static FriendRequestAction decide({
    required String fromUserId,
    required String toUserId,
    RelationshipModel? existing,
    bool reversePendingExists = false,
  }) {
    if (fromUserId == toUserId) return FriendRequestAction.none;

    if (existing != null) {
      if (existing.status == RelationshipStatus.accepted ||
          existing.status == RelationshipStatus.blocked) {
        return FriendRequestAction.none;
      }
      if (existing.status == RelationshipStatus.pending) {
        if (existing.fromUserId == toUserId) {
          return FriendRequestAction.acceptExisting;
        }
        return FriendRequestAction.none;
      }
      if (existing.fromUserId == fromUserId &&
          (existing.status == RelationshipStatus.declined ||
              existing.status == RelationshipStatus.rejected)) {
        return FriendRequestAction.reopenDeclined;
      }
      return FriendRequestAction.none;
    }

    if (reversePendingExists) {
      return FriendRequestAction.acceptExisting;
    }

    return FriendRequestAction.createPending;
  }
}
