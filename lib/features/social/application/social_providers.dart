import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/features/social/domain/gym_activity.dart';
import 'package:proof/features/social/domain/social_comment.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';

/// Approved gyms whose activity this member may read.
List<String> approvedSocialGymIds(List<GymMembershipModel> memberships) {
  final ids = <String>[];
  for (final membership in memberships) {
    if (membership.status != GymMembershipStatus.approved) continue;
    if (!ids.contains(membership.gymId)) ids.add(membership.gymId);
  }
  return ids;
}

/// Athlete memberships that are allowed to publish a proof.
List<String> approvedAthleteShareGymIds(List<GymMembershipModel> memberships) {
  final ids = <String>[];
  for (final membership in memberships) {
    if (membership.membershipType != GymMembershipType.athlete) continue;
    if (membership.status != GymMembershipStatus.approved) continue;
    if (!ids.contains(membership.gymId)) ids.add(membership.gymId);
  }
  return ids;
}

String? resolveSocialGymId(List<String> gymIds, String? selected) {
  if (gymIds.isEmpty) return null;
  if (selected != null && gymIds.contains(selected)) return selected;
  return gymIds.first;
}

final selectedSocialGymIdProvider = StateProvider<String?>((ref) => null);

final socialFeedPageSizeProvider = StateProvider.autoDispose
    .family<int, String>((ref, gymId) => 20);

final socialCommentPageSizeProvider = StateProvider.autoDispose
    .family<int, SocialActivityRef>((ref, activity) => 40);

class SocialActivityRef {
  const SocialActivityRef({required this.gymId, required this.activityId});

  final String gymId;
  final String activityId;

  @override
  bool operator ==(Object other) {
    return other is SocialActivityRef &&
        other.gymId == gymId &&
        other.activityId == activityId;
  }

  @override
  int get hashCode => Object.hash(gymId, activityId);
}

/// Resolves whether Social should invite the user to join a gym.
final socialFeedStateProvider = Provider<SocialFeedState>((ref) {
  final memberships = ref.watch(userGymMembershipsProvider);
  if (memberships.isLoading && !memberships.hasValue) {
    return SocialFeedState.loading;
  }
  final gymIds = approvedSocialGymIds(memberships.valueOrNull ?? const []);
  return gymIds.isEmpty ? SocialFeedState.noGym : SocialFeedState.ready;
});

final socialBlockedUserIdsProvider = Provider<Set<String>>((ref) {
  final userId = ref.watch(currentAuthUidProvider);
  if (userId == null) return const {};
  final relationships = ref.watch(relationshipsProvider).valueOrNull ?? const [];
  return blockedUserIds(relationships, userId);
});

final gymActivityFeedProvider = StreamProvider.autoDispose
    .family<List<GymActivity>, String>((ref, gymId) {
  final limit = ref.watch(socialFeedPageSizeProvider(gymId));
  return ref.watch(firestoreServiceProvider).watchGymActivity(
        gymId: gymId,
        limit: limit,
      );
});

final gymActivityProvider = StreamProvider.autoDispose
    .family<GymActivity?, SocialActivityRef>((ref, activity) {
  return ref.watch(firestoreServiceProvider).watchGymActivityDoc(
        gymId: activity.gymId,
        activityId: activity.activityId,
      );
});

final gymActivityLikedProvider = StreamProvider.autoDispose
    .family<bool, SocialActivityRef>((ref, activity) {
  final userId = ref.watch(currentAuthUidProvider);
  if (userId == null) return Stream.value(false);
  return ref.watch(firestoreServiceProvider).watchGymActivityLiked(
        gymId: activity.gymId,
        activityId: activity.activityId,
        userId: userId,
      );
});

final gymActivityCommentsProvider = StreamProvider.autoDispose
    .family<List<SocialComment>, SocialActivityRef>((ref, activity) {
  final limit = ref.watch(socialCommentPageSizeProvider(activity));
  return ref.watch(firestoreServiceProvider).watchGymActivityComments(
        gymId: activity.gymId,
        activityId: activity.activityId,
        limit: limit,
      );
});
