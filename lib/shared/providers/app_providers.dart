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
import 'package:proof/shared/services/signup_service.dart';
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
  return FirestoreService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final signupServiceProvider = Provider<SignupService>((ref) {
  return SignupService(
    auth: ref.watch(authServiceProvider),
    firestore: ref.watch(firestoreServiceProvider),
  );
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    yield null;
    return;
  }
  final service = ref.watch(firestoreServiceProvider);
  await service.migrateOnboardingIfNeeded(user.uid);
  yield* service.watchUser(user.uid);
});

/// Runs once per session to sync proof stacks after coach verification decisions.
final verificationStackSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;
  await ref.read(firestoreServiceProvider).syncVerificationStacksForAthlete(
        user.uid,
      );
});

final physicalIdentityProvider = StreamProvider.autoDispose<PhysicalIdentity?>((ref) {
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

/// Runs one-time migrations per session before data streams attach.
final dataBootstrapProvider = FutureProvider.family<void, String>((ref, userId) async {
  final service = ref.read(firestoreServiceProvider);
  await service.mergeDuplicateSkillsIfNeeded(userId);
  await service.migrateTimelineIfNeeded(userId);
  await service.migrateOnboardingIfNeeded(userId);
  await service.syncPublicProfile(userId);
});

final skillsProvider = StreamProvider.autoDispose<List<SkillModel>>((ref) async* {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    yield [];
    return;
  }
  await ref.watch(dataBootstrapProvider(user.uid).future);
  yield* ref.watch(firestoreServiceProvider).watchSkills(user.uid);
});

final proofsProvider = StreamProvider.autoDispose<List<ProofModel>>((ref) {
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

final timelineProvider = StreamProvider.autoDispose<List<TimelineEvent>>((ref) async* {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    yield [];
    return;
  }
  await ref.watch(dataBootstrapProvider(user.uid).future);
  yield* ref.watch(firestoreServiceProvider).watchTimeline(user.uid);
});

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
