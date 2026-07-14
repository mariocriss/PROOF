import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/gym_model.dart';
import 'package:proof/shared/providers/app_providers.dart';

final activeGymsProvider = StreamProvider.autoDispose<List<GymModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchActiveGyms();
});

final userGymMembershipsProvider =
    StreamProvider.autoDispose<List<GymMembershipModel>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchMembershipsForUser(userId);
});

final managedGymsProvider = FutureProvider.autoDispose<List<GymModel>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return Future.value([]);
  return ref.watch(firestoreServiceProvider).getGymsManagedByUser(userId);
});

final gymProvider = FutureProvider.family<GymModel?, String>((ref, gymId) {
  return ref.watch(firestoreServiceProvider).getGym(gymId);
});

final gymMembershipsForGymProvider =
    StreamProvider.autoDispose.family<List<GymMembershipModel>, String>(
  (ref, gymId) {
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return const Stream<List<GymMembershipModel>>.empty();
    }

    final user = authState.valueOrNull;
    if (user == null) {
      return Stream.value(const <GymMembershipModel>[]);
    }

    return Stream.fromFuture(user.getIdToken()).asyncExpand(
      (_) => ref.read(firestoreServiceProvider).watchGymMemberships(gymId: gymId),
    );
  },
);

class GymCoachOption {
  const GymCoachOption({
    required this.membership,
    required this.coachProfile,
    required this.gymName,
  });

  final GymMembershipModel membership;
  final CoachProfile? coachProfile;
  final String gymName;

  String get displayName {
    final profileName = coachProfile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final handle = coachProfile?.handle.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';

    return 'Coach';
  }

  String? get avatarUrl => coachProfile?.avatarUrl;

  String get subtitle => 'Approved coach at $gymName';
}

final gymCoachesForAthleteProvider =
    FutureProvider.autoDispose<List<GymCoachOption>>((ref) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return [];

  final memberships = await ref.watch(userGymMembershipsProvider.future);
  return _loadCoachOptions(ref, memberships);
});

Future<List<GymCoachOption>> _loadCoachOptions(
  Ref ref,
  List<GymMembershipModel> memberships,
) async {
  final firestore = ref.read(firestoreServiceProvider);
  final approvedAthleteGyms = memberships
      .where(
        (m) =>
            m.membershipType == GymMembershipType.athlete &&
            m.status == GymMembershipStatus.approved,
      )
      .map((m) => m.gymId)
      .toSet()
      .toList();

  if (approvedAthleteGyms.isEmpty) return [];

  final optionsPerGym = await Future.wait(
    approvedAthleteGyms.map((gymId) async {
      final gym = await firestore.getGym(gymId);
      if (gym == null) return <GymCoachOption>[];

      final coaches = await firestore.getApprovedCoachesForGym(gymId);
      if (coaches.isEmpty) return <GymCoachOption>[];

      final profiles = await Future.wait(
        coaches.map((coach) => firestore.getCoachProfile(coach.userId)),
      );

      return List<GymCoachOption>.generate(coaches.length, (index) {
        return GymCoachOption(
          membership: coaches[index],
          coachProfile: profiles[index],
          gymName: gym.name,
        );
      });
    }),
  );

  return optionsPerGym.expand((options) => options).toList();
}
