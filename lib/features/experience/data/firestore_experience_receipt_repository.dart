import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:proof/core/constants/firestore_paths.dart';
import 'package:proof/features/experience/data/experience_receipt_permission_probe.dart';
import 'package:proof/features/experience/data/experience_receipt_repository.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/features/experience/domain/experience_status.dart';

class FirestoreExperienceReceiptRepository
    implements ExperienceReceiptRepository {
  FirestoreExperienceReceiptRepository(
    this._firestore, {
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _col(String ownerId) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(ownerId)
          .collection(FirestorePaths.experienceReceipts);

  String _path(String ownerId, String eventId) =>
      '${FirestorePaths.users}/$ownerId/${FirestorePaths.experienceReceipts}/$eventId';

  Never _throwFailure({
    required String operation,
    required String ownerId,
    required String eventId,
    required Object cause,
    Map<String, String> payloadSummary = const {},
  }) {
    final firebase = cause is FirebaseException ? cause : null;
    throw ExperienceReceiptFirestoreFailure(
      operation: operation,
      path: _path(ownerId, eventId),
      authUid: _auth.currentUser?.uid ?? '',
      ownerId: ownerId,
      eventId: eventId,
      cause: cause,
      payloadSummary: payloadSummary,
      hint: firebase != null
          ? ExperienceReceiptFirestoreFailure.hintFor(firebase)
          : '',
    );
  }

  @override
  Future<ExperienceReceipt?> get(String ownerId, String eventId) async {
    try {
      final doc = await _col(ownerId).doc(eventId).get();
      if (!doc.exists) return null;
      return ExperienceReceipt.fromFirestore(doc);
    } catch (e) {
      _throwFailure(
        operation: 'get',
        ownerId: ownerId,
        eventId: eventId,
        cause: e,
      );
    }
  }

  @override
  Future<ExperienceReceipt> claimOrGet(ExperienceReceipt draft) async {
    final ref = _col(draft.ownerId).doc(draft.id);
    final payload = draft.toCreateFirestore(useServerTimestamp: true);
    if (kDebugMode) {
      debugPrint(
        '[Experience] receipt claim path=${_path(draft.ownerId, draft.id)} '
        'auth=${ExperienceReceiptFirestoreFailure.maskUid(_auth.currentUser?.uid ?? '')} '
        'ownerId=${ExperienceReceiptFirestoreFailure.maskUid(draft.ownerId)} '
        'payloadKeys=${payload.keys.toList()}',
      );
    }
    try {
      return await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) {
          return ExperienceReceipt.fromFirestore(snap);
        }
        tx.set(ref, payload);
        return draft;
      });
    } catch (e) {
      _throwFailure(
        operation: 'transaction create (get-then-set)',
        ownerId: draft.ownerId,
        eventId: draft.id,
        cause: e,
        payloadSummary: {
          'ownerId': ExperienceReceiptFirestoreFailure.maskUid(draft.ownerId),
          'eventType': draft.eventType.value,
          'status': draft.status.value,
          'importance': draft.importance.label,
          'schemaVersion': '${draft.schemaVersion}',
        },
      );
    }
  }

  @override
  Future<void> updateStatus({
    required String ownerId,
    required String eventId,
    required ExperienceStatus status,
    DateTime? shownAt,
    DateTime? completedAt,
    DateTime? dismissedAt,
  }) async {
    final data = <String, dynamic>{
      'status': status.value,
    };
    if (shownAt != null) {
      data['shownAt'] = Timestamp.fromDate(shownAt);
    }
    if (completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(completedAt);
    }
    if (dismissedAt != null) {
      data['dismissedAt'] = Timestamp.fromDate(dismissedAt);
    }
    try {
      await _col(ownerId).doc(eventId).update(data);
    } catch (e) {
      _throwFailure(
        operation: 'update',
        ownerId: ownerId,
        eventId: eventId,
        cause: e,
        payloadSummary: {'status': status.value},
      );
    }
  }

  @override
  Future<List<ExperienceReceipt>> listResumable(
    String ownerId, {
    int limit = 20,
  }) async {
    try {
      final snap = await _col(ownerId)
          .where('status', whereIn: [
            ExperienceStatus.pending.value,
            ExperienceStatus.presenting.value,
            ExperienceStatus.failed.value,
          ])
          .limit(limit)
          .get();
      return snap.docs.map(ExperienceReceipt.fromFirestore).toList();
    } catch (e) {
      _throwFailure(
        operation: 'listResumable',
        ownerId: ownerId,
        eventId: '*',
        cause: e,
      );
    }
  }
}
