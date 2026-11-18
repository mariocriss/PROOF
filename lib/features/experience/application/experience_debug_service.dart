import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/constants/firestore_paths.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/application/experience_event_factory.dart';
import 'package:proof/features/experience/application/experience_providers.dart';
import 'package:proof/features/experience/data/experience_receipt_permission_probe.dart';
import 'package:proof/features/experience/data/experience_receipt_repository.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/features/experience/presentation/gallery/experience_test_mode_panel.dart';
import 'package:proof/shared/providers/app_providers.dart';

/// Debug-only operations for internal QA. Never available in release.
class ExperienceDebugService {
  ExperienceDebugService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required ExperienceReceiptRepository receipts,
    required ExperienceEventFactory factory,
    required ExperienceCoordinator galleryCoordinator,
  })  : _firestore = firestore,
        _auth = auth,
        _receipts = receipts,
        _factory = factory,
        _galleryCoordinator = galleryCoordinator;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ExperienceReceiptRepository _receipts;
  final ExperienceEventFactory _factory;
  final ExperienceCoordinator _galleryCoordinator;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.experienceReceipts);

  Future<List<ExperienceReceipt>> listReceipts(String uid) async {
    final snap = await _col(uid).limit(50).get();
    return snap.docs.map(ExperienceReceipt.fromFirestore).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<ExperienceReceipt>> listPending(String uid) =>
      _receipts.listResumable(uid);

  Future<void> clearAllReceipts(String uid) async {
    assert(kDebugMode);
    final snap = await _col(uid).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<ExperienceReceiptPermissionTestResult> testReceiptPermissions() {
    assert(kDebugMode);
    return runExperienceReceiptPermissionTest(
      firestore: _firestore,
      auth: _auth,
    );
  }

  /// Preview replay — does not write receipts (gallery coordinator).
  Future<void> previewEvent(ExperienceEvent event) async {
    assert(kDebugMode);
    _galleryCoordinator.resetGalleryQueue();
    await _galleryCoordinator.offer(event);
  }

  ExperienceEvent mockOnboarding(String uid, {String name = 'Test Athlete'}) {
    return _factory.onboardingCompleted(
      userId: uid,
      context: ExperienceContext(displayName: name, userId: uid),
    );
  }

  ExperienceEvent mockFirstProof(String uid) {
    return _factory.galleryPreview(
      type: ExperienceEventType.firstProofCreated,
      importance: ExperienceImportance.t3Landmark,
      context: ExperienceContext(
        userId: uid,
        skillName: '5K Run',
        proofResult: '24:10',
        proofId: 'mock-proof',
      ),
      ownerId: uid,
    );
  }

  ExperienceEvent mockCoachVerify(String uid, {String coach = 'Jordan Lee'}) {
    return _factory.galleryPreview(
      type: ExperienceEventType.coachVerified,
      importance: ExperienceImportance.t3Landmark,
      context: ExperienceContext(
        userId: uid,
        skillName: '5K Run',
        proofResult: '24:10',
        proofId: 'mock-proof',
        coachName: coach,
        verificationDate: DateTime.now(),
      ),
      ownerId: uid,
    );
  }

  static ExperienceFeatureFlags enableAllReferences() {
    return ExperienceTestMode.allReferencesOn;
  }

  static const ExperienceFeatureFlags disableAllReferences =
      ExperienceFeatureFlags();
}

final experienceDebugServiceProvider = Provider<ExperienceDebugService>((ref) {
  return ExperienceDebugService(
    firestore: ref.watch(firestoreProvider),
    auth: FirebaseAuth.instance,
    receipts: ref.watch(experienceReceiptRepositoryProvider),
    factory: ref.watch(experienceEventFactoryProvider),
    galleryCoordinator: ref.watch(experienceGalleryCoordinatorProvider),
  );
});
