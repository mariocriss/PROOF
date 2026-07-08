import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/core/constants/firestore_paths.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/core/utils/skill_stack_reconciler.dart';
import 'package:proof/core/utils/skill_uniqueness.dart';
import 'package:proof/core/utils/timeline_milestone_evaluator.dart';
import 'package:proof/core/utils/timeline_rebuilder.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
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

  static const int timelineMigrationVersion = 2;
  static const int skillMergeVersion = 2;

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
    await _recordTimelineMilestones(
      identity.userId,
      TimelineMilestoneEvaluator.evaluateIdentityCreated(identity: identity),
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
    final existing = await findActiveSkillByCanonicalKey(skill.userId, skill);
    if (existing != null) {
      throw DuplicateSkillException(existing);
    }

    await _skillsRef(skill.userId).doc(skill.id).set(skill.toFirestore());

    final skillsSnap = await _skillsRef(skill.userId).get();
    final allSkills = skillsSnap.docs.map(SkillModel.fromFirestore).toList();

    await _recordTimelineMilestones(
      skill.userId,
      TimelineMilestoneEvaluator.evaluateSkillAdded(
        skill: skill,
        allSkills: allSkills,
      ),
    );

    final identity = await getIdentity(skill.userId);
    if (identity != null) {
      await _recordTimelineMilestones(
        skill.userId,
        TimelineMilestoneEvaluator.evaluateOneYearActive(
          identity: identity,
          asOf: DateTime.now(),
        ),
      );
    }
  }

  Future<SkillModel?> findActiveSkillByCanonicalKey(
    String userId,
    SkillModel skill,
  ) async {
    final key = SkillUniqueness.canonicalKey(skill);
    final snap = await _skillsRef(userId).get();
    for (final doc in snap.docs) {
      final existing = SkillModel.fromFirestore(doc);
      if (SkillStackReconciler.isTrackedCapability(existing) &&
          SkillUniqueness.canonicalKey(existing) == key) {
        return existing;
      }
    }
    return null;
  }

  Future<void> mergeDuplicateSkillsIfNeeded(String userId) async {
    final version = await _skillMergeVersion(userId);
    if (version >= skillMergeVersion) return;

    var skills =
        (await _skillsRef(userId).get()).docs.map(SkillModel.fromFirestore).toList();
    var proofs =
        (await _proofsRef(userId).get()).docs.map(ProofModel.fromFirestore).toList();

    proofs = await _mergeDuplicateSkillGroups(userId, skills, proofs);

    skills =
        (await _skillsRef(userId).get()).docs.map(SkillModel.fromFirestore).toList();
    proofs =
        (await _proofsRef(userId).get()).docs.map(ProofModel.fromFirestore).toList();

    await _reassignProofsFromArchivedDuplicates(userId, skills, proofs);

    skills =
        (await _skillsRef(userId).get()).docs.map(SkillModel.fromFirestore).toList();
    proofs =
        (await _proofsRef(userId).get()).docs.map(ProofModel.fromFirestore).toList();

    await _recalculateActiveSkillStacks(skills, proofs);

    await _userRef(userId).set(
      {
        'skillMergeVersion': skillMergeVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<ProofModel>> _mergeDuplicateSkillGroups(
    String userId,
    List<SkillModel> skills,
    List<ProofModel> proofs,
  ) async {
    var updatedProofs = List<ProofModel>.from(proofs);

    for (final group in SkillStackReconciler.duplicateGroups(skills)) {
      final primary = ProofStackMerge.pickPrimarySkill(group, updatedProofs);

      for (final duplicate in group.where((s) => s.id != primary.id)) {
        for (final proof
            in updatedProofs.where((p) => p.skillId == duplicate.id)) {
          await _proofsRef(userId).doc(proof.id).update({'skillId': primary.id});
        }
        await updateSkillStatus(
          userId: userId,
          skillId: duplicate.id,
          status: SkillStatus.archived,
        );
      }

      updatedProofs = updatedProofs
          .map(
            (proof) => group.any((s) => s.id == proof.skillId && s.id != primary.id)
                ? ProofModel(
                    id: proof.id,
                    userId: proof.userId,
                    skillId: primary.id,
                    title: proof.title,
                    recordedAt: proof.recordedAt,
                    createdAt: proof.createdAt,
                    result: proof.result,
                    unit: proof.unit,
                    proofSource: proof.proofSource,
                    notes: proof.notes,
                    mediaUrl: proof.mediaUrl,
                    originalResult: proof.originalResult,
                    originalUnit: proof.originalUnit,
                    normalizedValue: proof.normalizedValue,
                    location: proof.location,
                  )
                : proof,
          )
          .toList();

      final primaryProofs =
          updatedProofs.where((p) => p.skillId == primary.id).toList();
      await _syncSkillEvidence(primary, primaryProofs);
    }

    return updatedProofs;
  }

  Future<void> _reassignProofsFromArchivedDuplicates(
    String userId,
    List<SkillModel> skills,
    List<ProofModel> proofs,
  ) async {
    final reassignments = SkillStackReconciler.orphanedProofReassignments(
      skills: skills,
      proofs: proofs,
    );

    for (final item in reassignments) {
      await _proofsRef(userId)
          .doc(item.proof.id)
          .update({'skillId': item.primary.id});
    }
  }

  Future<void> _recalculateActiveSkillStacks(
    List<SkillModel> skills,
    List<ProofModel> proofs,
  ) async {
    final activeSkills =
        skills.where((s) => s.status == SkillStatus.active).toList();
    final groups = SkillStackReconciler.groupNonArchived(activeSkills);

    for (final group in groups.values) {
      final primary = ProofStackMerge.pickPrimarySkill(group, proofs);
      final skillIds = group.map((s) => s.id).toSet();
      final stackProofs =
          proofs.where((p) => skillIds.contains(p.skillId)).toList();
      await _syncSkillEvidence(primary, stackProofs);
    }
  }

  Future<void> _syncSkillEvidence(
    SkillModel skill,
    List<ProofModel> proofs,
  ) async {
    if (proofs.isEmpty) {
      await _skillsRef(skill.userId).doc(skill.id).update({
        'currentBest': null,
        'currentBestUnit': null,
        'normalizedBestValue': null,
        'stackConfidence': ProofStackCalculator.calculate(proofs).value,
      });
      return;
    }

    final confidence = ProofStackCalculator.calculate(proofs);
    var updated = skill.copyWith(stackConfidence: confidence);

    for (final proof in proofs) {
      if (proof.normalizedValue != null &&
          BestResultLogic.isBetter(
            candidate: proof.normalizedValue!,
            current: updated.normalizedBestValue,
            performanceType: skill.performanceType,
          )) {
        updated = updated.copyWith(
          currentBest: proof.result,
          currentBestUnit: proof.unit,
          normalizedBestValue: proof.normalizedValue,
        );
      }
    }

    await updateSkill(updated);
  }

  Future<int> _skillMergeVersion(String userId) async {
    final doc = await _userRef(userId).get();
    return doc.data()?['skillMergeVersion'] as int? ?? 0;
  }

  Future<void> updateSkill(SkillModel skill) async {
    await _skillsRef(skill.userId).doc(skill.id).update(skill.toFirestore());
  }

  Future<void> updateSkillTarget({
    required String userId,
    required String skillId,
    String? targetValue,
    String? targetUnit,
  }) async {
    final trimmed = targetValue?.trim() ?? '';
    if (trimmed.isEmpty) {
      await _skillsRef(userId).doc(skillId).update({
        'targetValue': FieldValue.delete(),
        'targetUnit': FieldValue.delete(),
      });
      return;
    }

    await _skillsRef(userId).doc(skillId).update({
      'targetValue': trimmed,
      'targetUnit': targetUnit,
    });
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

    final allProofsSnap = await _proofsRef(proof.userId).get();
    final allProofs = allProofsSnap.docs.map(ProofModel.fromFirestore).toList();

    final skill = await getSkill(proof.userId, proof.skillId);
    if (skill == null) return;

    final priorSkillProofs = allProofs
        .where((p) => p.skillId == proof.skillId && p.id != proof.id)
        .toList();
    final skillProofs =
        allProofs.where((p) => p.skillId == proof.skillId).toList();
    final previousConfidence =
        skill.stackConfidence ?? ProofStackCalculator.calculate(priorSkillProofs);
    final newConfidence = ProofStackCalculator.calculate(skillProofs);

    final priorBest = _bestNormalizedValue(skill, priorSkillProofs);
    final isPersonalBest = proof.normalizedValue != null &&
        BestResultLogic.isBetter(
          candidate: proof.normalizedValue!,
          current: priorBest,
          performanceType: skill.performanceType,
        ) &&
        priorSkillProofs.isNotEmpty;

    await _syncSkillEvidence(skill, skillProofs);

    final milestones = TimelineMilestoneEvaluator.evaluateProofAdded(
      proof: proof,
      skill: skill,
      allProofs: allProofs,
      priorSkillProofs: priorSkillProofs,
      previousConfidence: previousConfidence,
      newConfidence: newConfidence,
      isPersonalBest: isPersonalBest,
    );

    await _recordTimelineMilestones(proof.userId, milestones);

    final identity = await getIdentity(proof.userId);
    if (identity != null) {
      await _recordTimelineMilestones(
        proof.userId,
        TimelineMilestoneEvaluator.evaluateOneYearActive(
          identity: identity,
          asOf: DateTime.now(),
        ),
      );
    }
  }

  double? _bestNormalizedValue(SkillModel skill, List<ProofModel> proofs) {
    double? best;
    for (final proof in proofs) {
      if (proof.normalizedValue != null &&
          BestResultLogic.isBetter(
            candidate: proof.normalizedValue!,
            current: best,
            performanceType: skill.performanceType,
          )) {
        best = proof.normalizedValue;
      }
    }
    return best;
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

  Future<void> deleteProof({
    required String userId,
    required String proofId,
  }) async {
    final proofDoc = await _proofsRef(userId).doc(proofId).get();
    if (!proofDoc.exists) return;

    final proof = ProofModel.fromFirestore(proofDoc);
    final skillId = proof.skillId;

    await _proofsRef(userId).doc(proofId).delete();

    final skill = await getSkill(userId, skillId);
    if (skill == null) return;

    final remainingSnap = await _proofsRef(userId)
        .where('skillId', isEqualTo: skillId)
        .get();
    final remaining =
        remainingSnap.docs.map(ProofModel.fromFirestore).toList();
    await _syncSkillEvidence(skill, remaining);
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  Future<void> _recordTimelineMilestones(
    String userId,
    List<TimelineMilestoneCandidate> candidates,
  ) async {
    for (final candidate in candidates) {
      await addTimelineEvent(
        userId: userId,
        type: candidate.type,
        title: candidate.title,
        subtitle: candidate.subtitle,
        referenceId: candidate.referenceId,
        milestoneKey: candidate.milestoneKey,
      );
    }
  }

  Future<void> addTimelineEvent({
    required String userId,
    required TimelineEventType type,
    required String title,
    String subtitle = '',
    String? referenceId,
    String? milestoneKey,
    DateTime? createdAt,
  }) async {
    final docId = milestoneKey ?? _timelineRef(userId).doc().id;

    if (milestoneKey != null) {
      final existing = await _timelineRef(userId).doc(milestoneKey).get();
      if (existing.exists) return;
    }

    final event = TimelineEvent(
      id: docId,
      userId: userId,
      type: type,
      title: title,
      subtitle: subtitle,
      referenceId: referenceId,
      milestoneKey: milestoneKey,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _timelineRef(userId).doc(docId).set(event.toFirestore());
  }

  Future<void> migrateTimelineIfNeeded(String userId) async {
    final version = await _timelineMigrationVersion(userId);
    if (version >= timelineMigrationVersion) return;

    final identity = await getIdentity(userId);
    final skillsSnap = await _skillsRef(userId).get();
    final proofsSnap = await _proofsRef(userId).get();

    final skills = skillsSnap.docs.map(SkillModel.fromFirestore).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final proofs = proofsSnap.docs.map(ProofModel.fromFirestore).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final rebuilt = TimelineRebuilder.rebuild(
      userId: userId,
      identity: identity,
      skills: skills,
      proofs: proofs,
    );

    await _clearTimeline(userId);
    await _writeTimelineEvents(userId, rebuilt);

    await _userRef(userId).set(
      {
        'timelineMigrationVersion': timelineMigrationVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<int> _timelineMigrationVersion(String userId) async {
    final doc = await _userRef(userId).get();
    return doc.data()?['timelineMigrationVersion'] as int? ?? 0;
  }

  Future<void> _clearTimeline(String userId) async {
    while (true) {
      final snap = await _timelineRef(userId).limit(400).get();
      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _writeTimelineEvents(
    String userId,
    List<TimelineEvent> events,
  ) async {
    for (var i = 0; i < events.length; i += 400) {
      final batch = _firestore.batch();
      final chunk = events.skip(i).take(400);
      for (final event in chunk) {
        batch.set(_timelineRef(userId).doc(event.id), event.toFirestore());
      }
      await batch.commit();
    }
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
