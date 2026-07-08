import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/models/user_model.dart';
import 'package:proof/shared/services/auth_service.dart';
import 'package:proof/shared/services/firestore_service.dart';
import 'package:proof/shared/services/storage_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firestoreProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final physicalIdentityProvider = StreamProvider<PhysicalIdentity?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).watchIdentity(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final skillsProvider = StreamProvider<List<SkillModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final service = ref.watch(firestoreServiceProvider);
      return _skillsWithMerge(service, user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

Stream<List<SkillModel>> _skillsWithMerge(
  FirestoreService service,
  String userId,
) async* {
  await service.mergeDuplicateSkillsIfNeeded(userId);
  yield* service.watchSkills(userId);
}

final proofsProvider = StreamProvider<List<ProofModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(firestoreServiceProvider).watchProofs(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final timelineProvider = StreamProvider<List<TimelineEvent>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final service = ref.watch(firestoreServiceProvider);
      return _timelineWithMigration(service, user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

Stream<List<TimelineEvent>> _timelineWithMigration(
  FirestoreService service,
  String userId,
) async* {
  await service.migrateTimelineIfNeeded(userId);
  yield* service.watchTimeline(userId);
}

final publicSkillsProvider =
    StreamProvider.family<List<SkillModel>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).watchSkills(userId);
});

final publicProofsProvider =
    StreamProvider.family<List<ProofModel>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).watchProofs(userId);
});

final publicTimelineProvider =
    StreamProvider.family<List<TimelineEvent>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).watchTimeline(userId);
});

final identityByHandleProvider =
    StreamProvider.family<PhysicalIdentity?, String>((ref, handle) {
  return ref.watch(firestoreServiceProvider).watchIdentityByHandle(handle);
});
