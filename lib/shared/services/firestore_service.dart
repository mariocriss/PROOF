import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/core/constants/firestore_paths.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/models/user_model.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _users.doc(userId);

  DocumentReference<Map<String, dynamic>> _identityRef(String userId) =>
      _userRef(userId)
          .collection(FirestorePaths.identity)
          .doc(FirestorePaths.profile);

  CollectionReference<Map<String, dynamic>> _skillsRef(String userId) =>
      _userRef(userId).collection(FirestorePaths.skills);

  CollectionReference<Map<String, dynamic>> _proofsRef(String userId) =>
      _userRef(userId).collection(FirestorePaths.proofs);

  CollectionReference<Map<String, dynamic>> _timelineRef(String userId) =>
      _userRef(userId).collection(FirestorePaths.timeline);

  CollectionReference<Map<String, dynamic>> get _handles =>
      _firestore.collection('handles');

  // ── User ──────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _userRef(user.id).set(user.toFirestore());
  }

  /// Creates the user doc if missing (e.g. account existed before Firestore write).
  Future<void> ensureUserDocument({required String userId, required String email}) async {
    final doc = await _userRef(userId).get();
    if (doc.exists) return;

    final now = DateTime.now();
    await createUser(UserModel(
      id: userId,
      email: email,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Stream<UserModel?> watchUser(String userId) {
    return _userRef(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _userRef(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> markHasIdentity(String userId) async {
    await _userRef(userId).update({
      'hasIdentity': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Physical Identity ─────────────────────────────────────────────────────

  Future<bool> isHandleAvailable(String handle) async {
    final doc = await _handles.doc(handle.toLowerCase()).get();
    return !doc.exists;
  }

  Future<void> createIdentity(PhysicalIdentity identity) async {
    final handle = identity.handle.toLowerCase();
    final batch = _firestore.batch();

    batch.set(_identityRef(identity.userId), identity.toFirestore());
    batch.set(_handles.doc(handle), {'userId': identity.userId});
    // Use set+merge so this works even if the user doc was never created.
    batch.set(
      _userRef(identity.userId),
      {
        'hasIdentity': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await addTimelineEvent(
      userId: identity.userId,
      type: TimelineEventType.identityCreated,
      title: 'Physical identity created',
      subtitle: '@$handle',
    );
  }

  Future<void> updateIdentity(PhysicalIdentity identity) async {
    final current = await getIdentity(identity.userId);
    final batch = _firestore.batch();

    batch.update(_identityRef(identity.userId), identity.toFirestore());

    if (current != null && current.handle != identity.handle) {
      batch.delete(_handles.doc(current.handle.toLowerCase()));
      batch.set(_handles.doc(identity.handle.toLowerCase()), {
        'userId': identity.userId,
      });
    }

    await batch.commit();
    await addTimelineEvent(
      userId: identity.userId,
      type: TimelineEventType.profileUpdated,
      title: 'Profile updated',
    );
  }

  Future<PhysicalIdentity?> getIdentity(String userId) async {
    final doc = await _identityRef(userId).get();
    if (!doc.exists) return null;
    return PhysicalIdentity.fromFirestore(doc);
  }

  Stream<PhysicalIdentity?> watchIdentity(String userId) {
    return _identityRef(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PhysicalIdentity.fromFirestore(doc);
    });
  }

  Stream<PhysicalIdentity?> watchIdentityByHandle(String handle) async* {
    final handleDoc = await _handles.doc(handle.toLowerCase()).get();
    if (!handleDoc.exists) {
      yield null;
      return;
    }
    final userId = handleDoc.data()!['userId'] as String;
    yield* watchIdentity(userId);
  }

  // ── Skills ────────────────────────────────────────────────────────────────

  Future<void> addSkill(SkillModel skill) async {
    await _skillsRef(skill.userId).doc(skill.id).set(skill.toFirestore());
    final subtitle = skill.formattedCurrentBest != null
        ? '${skill.discipline} · ${skill.formattedCurrentBest}'
        : skill.discipline;
    await addTimelineEvent(
      userId: skill.userId,
      type: TimelineEventType.skillAdded,
      title: 'Skill added: ${skill.name}',
      subtitle: subtitle,
      referenceId: skill.id,
    );
  }

  Future<void> updateSkill(SkillModel skill) async {
    await _skillsRef(skill.userId).doc(skill.id).update(skill.toFirestore());
  }

  Future<void> updateSkillStatus({
    required String userId,
    required String skillId,
    required SkillStatus status,
  }) async {
    await _skillsRef(userId).doc(skillId).update({'status': status.value});
  }

  Future<void> deleteSkill({
    required String userId,
    required String skillId,
  }) async {
    await _skillsRef(userId).doc(skillId).delete();
  }

  Future<SkillModel?> getSkill(String userId, String skillId) async {
    final doc = await _skillsRef(userId).doc(skillId).get();
    if (!doc.exists) return null;
    return SkillModel.fromFirestore(doc);
  }

  Stream<List<SkillModel>> watchSkills(String userId) {
    return _skillsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SkillModel.fromFirestore).toList());
  }

  // ── Proofs ────────────────────────────────────────────────────────────────

  Future<void> addProof(ProofModel proof) async {
    await _proofsRef(proof.userId).doc(proof.id).set(proof.toFirestore());

    final skill = await getSkill(proof.userId, proof.skillId);
    if (skill == null) {
      await addTimelineEvent(
        userId: proof.userId,
        type: TimelineEventType.proofAdded,
        title: 'Proof added: ${proof.formattedResult}',
        subtitle: proof.proofSource.label,
        referenceId: proof.id,
      );
      return;
    }

    final skillProofs = await _proofsRef(proof.userId)
        .where('skillId', isEqualTo: proof.skillId)
        .get();
    final allProofs = skillProofs.docs.map(ProofModel.fromFirestore).toList();
    final stackConfidence = ProofStackCalculator.calculate(allProofs);

    var updatedSkill = skill.copyWith(stackConfidence: stackConfidence);

    if (proof.normalizedValue != null &&
        BestResultLogic.isBetter(
          candidate: proof.normalizedValue!,
          current: skill.normalizedBestValue,
          performanceType: skill.performanceType,
        )) {
      updatedSkill = updatedSkill.copyWith(
        currentBest: proof.result,
        currentBestUnit: proof.unit,
        normalizedBestValue: proof.normalizedValue,
      );
    }

    await updateSkill(updatedSkill);

    await addTimelineEvent(
      userId: proof.userId,
      type: TimelineEventType.proofAdded,
      title: 'Proof added: ${proof.formattedResult}',
      subtitle: proof.proofSource.label,
      referenceId: proof.id,
    );
  }

  Stream<List<ProofModel>> watchProofs(String userId) {
    return _proofsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProofModel.fromFirestore).toList());
  }

  Stream<List<ProofModel>> watchProofsForSkill(String userId, String skillId) {
    return _proofsRef(userId)
        .where('skillId', isEqualTo: skillId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProofModel.fromFirestore).toList());
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  Future<void> addTimelineEvent({
    required String userId,
    required TimelineEventType type,
    required String title,
    String subtitle = '',
    String? referenceId,
  }) async {
    final event = TimelineEvent(
      id: _timelineRef(userId).doc().id,
      userId: userId,
      type: type,
      title: title,
      subtitle: subtitle,
      referenceId: referenceId,
      createdAt: DateTime.now(),
    );
    await _timelineRef(userId).doc(event.id).set(event.toFirestore());
  }

  Stream<List<TimelineEvent>> watchTimeline(String userId) {
    return _timelineRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TimelineEvent.fromFirestore).toList());
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Future<void> updateAvatarUrl(String userId, String avatarUrl) async {
    await _identityRef(userId).update({
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
