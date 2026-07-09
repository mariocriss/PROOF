import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/verification_request_model.dart';
import 'package:proof/shared/providers/app_providers.dart';

final relationshipsProvider =
    StreamProvider<List<RelationshipModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchRelationshipsForUser(user.uid);
});

final coachProfilesProvider = StreamProvider<List<CoachProfile>>((ref) {
  return ref.watch(firestoreServiceProvider).watchCoachProfiles();
});

final coachProfileProvider =
    StreamProvider.family<CoachProfile?, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).watchCoachProfile(userId);
});

final verificationRequestsProvider =
    StreamProvider<List<VerificationRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .watchVerificationRequestsForAthlete(user.uid);
});

final coachVerificationQueueProvider =
    StreamProvider<List<VerificationRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .watchVerificationQueueForCoach(user.uid);
});

final coachVerifiedProofsProvider =
    StreamProvider.family<List<VerificationRequestModel>, String>((ref, coachId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchApprovedVerificationsForCoach(coachId);
});

final coachApprovedVerificationsProvider =
    StreamProvider<List<VerificationRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .watchApprovedVerificationsForCoach(user.uid);
});

final identityByUserIdProvider =
    FutureProvider.family<PhysicalIdentity?, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getIdentity(userId);
});

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
}

final moreMenuCountsProvider = Provider<MoreMenuCounts>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return const MoreMenuCounts();

  final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
  final verificationRequests =
      ref.watch(verificationRequestsProvider).valueOrNull ?? [];
  final coachQueue =
      ref.watch(coachVerificationQueueProvider).valueOrNull ?? [];

  final friends = relationships
      .where(
        (r) =>
            r.type == RelationshipType.friend &&
            r.status == RelationshipStatus.accepted &&
            (r.fromUserId == userId || r.toUserId == userId),
      )
      .length;

  final coaches = relationships
      .where(
        (r) =>
            r.type == RelationshipType.coach &&
            r.status == RelationshipStatus.accepted &&
            r.fromUserId == userId,
      )
      .length;

  final friendRequests = relationships
      .where(
        (r) =>
            r.type == RelationshipType.friend &&
            r.status == RelationshipStatus.pending &&
            r.toUserId == userId,
      )
      .length;

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
    coachQueue: coachQueue.length,
  );
});

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

List<RelationshipModel> pendingFriendRequests(
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
