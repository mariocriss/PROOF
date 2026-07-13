import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/features/people/domain/friend_connection_state.dart';
import 'package:proof/features/people/domain/people_menu_counts.dart';
import 'package:proof/features/people/domain/people_relationship_queries.dart';
import 'package:proof/features/people/domain/people_search.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/verification_request_model.dart';
import 'package:proof/shared/providers/app_providers.dart';

export 'package:proof/features/people/domain/people_menu_counts.dart';
export 'package:proof/features/people/domain/people_relationship_queries.dart';

final proofStackSummariesProvider =
    Provider.autoDispose<List<ProofStackSkillSummary>>((ref) {
  final skills = ref.watch(skillsProvider).valueOrNull ?? [];
  final proofs = ref.watch(proofsProvider).valueOrNull ?? [];
  return ProofStackMerge.buildSummaries(skills: skills, proofs: proofs);
});

final relationshipsProvider = StreamProvider<List<RelationshipModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchRelationshipsForUser(user.uid);
});

final searchablePublicProfilesProvider =
    StreamProvider<List<PublicProfileModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchSearchablePublicProfiles();
});

final peopleSearchResultsProvider =
    Provider.autoDispose.family<List<PublicProfileModel>, String>((ref, query) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
  final profiles = ref.watch(searchablePublicProfilesProvider).valueOrNull ?? [];
  final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
  final blockedIds = blockedUserIds(relationships, userId);

  return PeopleSearch.filterProfiles(
    profiles,
    query,
    currentUserId: userId,
    blockedUserIds: blockedIds,
  );
});

final publicProfileProvider =
    FutureProvider.autoDispose.family<PublicProfileModel?, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getPublicProfile(userId);
});

final publicProfileByHandleProvider =
    FutureProvider.autoDispose.family<PublicProfileModel?, String>((ref, handle) {
  return ref.watch(firestoreServiceProvider).getOrSyncPublicProfileByHandle(handle);
});

final coachProfilesProvider = StreamProvider.autoDispose<List<CoachProfile>>((ref) {
  return ref.watch(firestoreServiceProvider).watchCoachProfiles();
});

final coachProfileProvider =
    StreamProvider.autoDispose.family<CoachProfile?, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).watchCoachProfile(userId);
});

final verificationRequestsProvider =
    StreamProvider.autoDispose<List<VerificationRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .watchVerificationRequestsForAthlete(user.uid);
});

final coachVerificationQueueProvider =
    StreamProvider.autoDispose<List<VerificationRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .watchVerificationQueueForCoach(user.uid);
});

final coachVerifiedProofsProvider =
    StreamProvider.autoDispose.family<List<VerificationRequestModel>, String>(
        (ref, coachId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchApprovedVerificationsForCoach(coachId);
});

final coachApprovedVerificationsProvider =
    StreamProvider.autoDispose<List<VerificationRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .watchApprovedVerificationsForCoach(user.uid);
});

final identityByUserIdProvider =
    FutureProvider.autoDispose.family<PhysicalIdentity?, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getIdentity(userId);
});

final incomingFriendRequestCountProvider = Provider<int>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return 0;
  final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
  return countIncomingFriendRequests(relationships, userId);
});

final friendConnectionProvider =
    Provider.autoDispose.family<FriendConnection, String>((ref, otherUserId) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
  final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
  return FriendConnection.resolve(
    currentUserId: userId,
    otherUserId: otherUserId,
    relationships: relationships,
  );
});

final moreMenuCountsProvider = Provider<MoreMenuCounts>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return const MoreMenuCounts();

  final user = ref.watch(currentUserProvider).valueOrNull;
  final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
  final verificationRequests =
      ref.watch(verificationRequestsProvider).valueOrNull ?? [];
  final coachQueue = user?.isCoach == true
      ? ref.watch(coachVerificationQueueProvider).valueOrNull ?? []
      : const <VerificationRequestModel>[];

  return PeopleMenuCounts.build(
    userId: userId,
    relationships: relationships,
    verificationRequests: verificationRequests,
    coachQueue: coachQueue.length,
    includeCoaches: true,
  );
});

/// Back-compat alias used by request screens.
List<RelationshipModel> pendingFriendRequests(
  List<RelationshipModel> relationships,
  String userId,
) =>
    pendingIncomingFriendRequests(relationships, userId);
