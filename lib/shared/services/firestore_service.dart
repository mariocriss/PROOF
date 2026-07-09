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
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/models/user_model.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/user_role.dart';
import 'package:proof/shared/models/verification_request_model.dart';
import 'package:proof/shared/models/verification_status.dart';

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

  CollectionReference<Map<String, dynamic>> get _relationships =>
      _firestore.collection(FirestorePaths.relationships);

  CollectionReference<Map<String, dynamic>> get _verificationRequests =>
      _firestore.collection(FirestorePaths.verificationRequests);

  CollectionReference<Map<String, dynamic>> get _coachProfiles =>
      _firestore.collection(FirestorePaths.coachProfiles);

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

    final skillsSnap = await _skillsRef(proof.userId).get();
    final skills = skillsSnap.docs.map(SkillModel.fromFirestore).toList();

    final skill = skills.where((s) => s.id == proof.skillId).firstOrNull;
    if (skill == null) return;

    final stack = _stackContext(
      skill: skill,
      skills: skills,
      proofs: allProofs,
    );
    final priorStackProofs = stack.proofs
        .where((p) => p.id != proof.id)
        .toList();
    final previousConfidence =
        ProofStackCalculator.calculate(priorStackProofs);
    final newConfidence = ProofStackCalculator.calculate(stack.proofs);

    final priorBest = _bestNormalizedValue(skill, priorStackProofs);
    final isPersonalBest = proof.normalizedValue != null &&
        BestResultLogic.isBetter(
          candidate: proof.normalizedValue!,
          current: priorBest,
          performanceType: skill.performanceType,
        ) &&
        priorStackProofs.isNotEmpty;

    await _syncSkillEvidence(stack.primary, stack.proofs);

    final milestones = TimelineMilestoneEvaluator.evaluateProofAdded(
      proof: proof,
      skill: stack.primary,
      allProofs: allProofs,
      priorSkillProofs: priorStackProofs,
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

    await _proofsRef(userId).doc(proofId).delete();

    final skillsSnap = await _skillsRef(userId).get();
    final skills = skillsSnap.docs.map(SkillModel.fromFirestore).toList();
    final proofsSnap = await _proofsRef(userId).get();
    final proofs = proofsSnap.docs.map(ProofModel.fromFirestore).toList();

    final skill = skills.where((s) => s.id == proof.skillId).firstOrNull;
    if (skill == null) return;

    final stack = _stackContext(skill: skill, skills: skills, proofs: proofs);
    await _syncSkillEvidence(stack.primary, stack.proofs);
  }

  _SkillStackContext _stackContext({
    required SkillModel skill,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
  }) {
    final siblings = ProofStackMerge.siblingSkills(
      skill: skill,
      allSkills: skills,
    );
    final primary = ProofStackMerge.pickPrimarySkill(siblings, proofs);
    final skillIds = siblings.map((s) => s.id).toSet();
    final stackProofs = proofs.where((p) => skillIds.contains(p.skillId)).toList();

    return _SkillStackContext(primary: primary, proofs: stackProofs);
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
    await _syncCoachProfileIfNeeded(userId);
  }

  // ── Relationships ─────────────────────────────────────────────────────────

  Stream<List<RelationshipModel>> watchRelationshipsForUser(String userId) {
    return _relationships
        .where(
          Filter.or(
            Filter('fromUserId', isEqualTo: userId),
            Filter('toUserId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .map(
          (snap) => snap.docs.map(RelationshipModel.fromFirestore).toList(),
        );
  }

  Future<void> sendCoachRequest({
    required String athleteId,
    required String coachId,
  }) async {
    if (athleteId == coachId) return;

    final existing = await _relationships
        .where('fromUserId', isEqualTo: athleteId)
        .where('toUserId', isEqualTo: coachId)
        .where('type', isEqualTo: RelationshipType.coach.value)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    final id = _relationships.doc().id;
    await _relationships.doc(id).set(
      RelationshipModel(
        id: id,
        fromUserId: athleteId,
        toUserId: coachId,
        type: RelationshipType.coach,
        status: RelationshipStatus.pending,
        createdAt: DateTime.now(),
      ).toFirestore(),
    );
  }

  Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;

    final existing = await _relationships
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('type', isEqualTo: RelationshipType.friend.value)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    final id = _relationships.doc().id;
    await _relationships.doc(id).set(
      RelationshipModel(
        id: id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
        status: RelationshipStatus.pending,
        createdAt: DateTime.now(),
      ).toFirestore(),
    );
  }

  Future<void> respondToRelationship({
    required String relationshipId,
    required bool accept,
  }) async {
    await _relationships.doc(relationshipId).update({
      'status': accept
          ? RelationshipStatus.accepted.value
          : RelationshipStatus.rejected.value,
    });
  }

  // ── Coach profiles ────────────────────────────────────────────────────────

  Stream<List<CoachProfile>> watchCoachProfiles() {
    return _coachProfiles
        .orderBy('displayName')
        .snapshots()
        .map((snap) => snap.docs.map(CoachProfile.fromFirestore).toList());
  }

  Future<CoachProfile?> getCoachProfile(String userId) async {
    final doc = await _coachProfiles.doc(userId).get();
    if (!doc.exists) return null;
    return CoachProfile.fromFirestore(doc);
  }

  Stream<CoachProfile?> watchCoachProfile(String userId) {
    return _coachProfiles.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CoachProfile.fromFirestore(doc);
    });
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
    String specialty = '',
  }) async {
    await _userRef(userId).set(
      {
        'role': role.value,
        'specialty': specialty,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _syncCoachProfileIfNeeded(userId);
  }

  Future<void> _syncCoachProfileIfNeeded(String userId) async {
    final user = await getUser(userId);
    if (user == null || !user.isCoach) {
      await _coachProfiles.doc(userId).delete();
      return;
    }

    final identity = await getIdentity(userId);
    if (identity == null) return;

    final athletesSnap = await _relationships
        .where('toUserId', isEqualTo: userId)
        .where('type', isEqualTo: RelationshipType.coach.value)
        .where('status', isEqualTo: RelationshipStatus.accepted.value)
        .get();

    final verifiedSnap = await _verificationRequests
        .where('coachId', isEqualTo: userId)
        .where('status', isEqualTo: VerificationRequestStatus.approved.value)
        .get();

    final profile = CoachProfile(
      userId: userId,
      handle: identity.handle,
      displayName: identity.displayName,
      specialty: user.specialty.isNotEmpty ? user.specialty : 'Coach',
      bio: identity.bio,
      avatarUrl: identity.avatarUrl,
      athleteCount: athletesSnap.docs.length,
      verifiedProofCount: verifiedSnap.docs.length,
      updatedAt: DateTime.now(),
    );

    await _coachProfiles.doc(userId).set(profile.toFirestore());
  }

  Future<void> syncCoachProfile(String userId) =>
      _syncCoachProfileIfNeeded(userId);

  Future<String?> resolveUserIdByHandle(String handle) async {
    final doc = await _handles.doc(handle.toLowerCase()).get();
    if (!doc.exists) return null;
    return doc.data()?['userId'] as String?;
  }

  // ── Verification requests ─────────────────────────────────────────────────

  Stream<List<VerificationRequestModel>> watchVerificationRequestsForAthlete(
    String athleteId,
  ) {
    return _verificationRequests
        .where('athleteId', isEqualTo: athleteId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(VerificationRequestModel.fromFirestore).toList());
  }

  Stream<List<VerificationRequestModel>> watchVerificationQueueForCoach(
    String coachId,
  ) {
    return _verificationRequests
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: VerificationRequestStatus.pending.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(VerificationRequestModel.fromFirestore).toList());
  }

  Stream<List<VerificationRequestModel>> watchApprovedVerificationsForCoach(
    String coachId,
  ) {
    return _verificationRequests
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: VerificationRequestStatus.approved.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(VerificationRequestModel.fromFirestore).toList());
  }

  Future<void> addProofWithVerification({
    required ProofModel proof,
    String? coachId,
    String? verificationMessage,
  }) async {
    if (proof.verificationStatus == VerificationStatus.pendingVerification &&
        coachId != null) {
      await addProof(proof);

      final requestId = _verificationRequests.doc().id;
      final skill = await getSkill(proof.userId, proof.skillId);
      await _verificationRequests.doc(requestId).set(
        VerificationRequestModel(
          id: requestId,
          proofId: proof.id,
          athleteId: proof.userId,
          coachId: coachId,
          skillId: proof.skillId,
          status: VerificationRequestStatus.pending,
          message: verificationMessage ?? '',
          createdAt: DateTime.now(),
          skillName: skill?.name ?? '',
          resultLabel: proof.formattedResult,
          mediaUrl: proof.mediaUrl,
          recordedAt: proof.recordedAt,
        ).toFirestore(),
      );
      return;
    }

    await addProof(proof);
  }

  Future<void> approveVerificationRequest(String requestId) async {
    final requestDoc = await _verificationRequests.doc(requestId).get();
    if (!requestDoc.exists) return;

    final request = VerificationRequestModel.fromFirestore(requestDoc);
    final proofDoc =
        await _proofsRef(request.athleteId).doc(request.proofId).get();
    if (!proofDoc.exists) return;

    final proof = ProofModel.fromFirestore(proofDoc);
    final updatedProof = proof.copyWith(
      proofSource: ProofSource.coach,
      verificationStatus: VerificationStatus.coachVerified,
      coachId: request.coachId,
    );

    await _proofsRef(request.athleteId)
        .doc(request.proofId)
        .update(updatedProof.toFirestore());

    await _verificationRequests.doc(requestId).update({
      'status': VerificationRequestStatus.approved.value,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    await _resyncProofStack(request.athleteId, request.proofId);

    await addTimelineEvent(
      userId: request.athleteId,
      type: TimelineEventType.coachVerified,
      title: 'Coach verification received',
      subtitle: request.skillName.isNotEmpty
          ? '${request.skillName} · ${request.resultLabel}'
          : request.resultLabel,
      referenceId: request.proofId,
    );

    await _syncCoachProfileIfNeeded(request.coachId);
  }

  Future<void> rejectVerificationRequest({
    required String requestId,
    String rejectionNote = '',
  }) async {
    final requestDoc = await _verificationRequests.doc(requestId).get();
    if (!requestDoc.exists) return;

    final request = VerificationRequestModel.fromFirestore(requestDoc);

    await _verificationRequests.doc(requestId).update({
      'status': VerificationRequestStatus.rejected.value,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionNote': rejectionNote,
    });

    await _proofsRef(request.athleteId).doc(request.proofId).update({
      'verificationStatus': VerificationStatus.rejected.value,
      'proofSource': ProofSource.selfReported.value,
      'rejectionNote': rejectionNote,
    });

    await _resyncProofStack(request.athleteId, request.proofId);
  }

  Future<void> _resyncProofStack(String userId, String proofId) async {
    final proofDoc = await _proofsRef(userId).doc(proofId).get();
    if (!proofDoc.exists) return;

    final proof = ProofModel.fromFirestore(proofDoc);
    final allProofsSnap = await _proofsRef(userId).get();
    final allProofs = allProofsSnap.docs.map(ProofModel.fromFirestore).toList();
    final skillsSnap = await _skillsRef(userId).get();
    final skills = skillsSnap.docs.map(SkillModel.fromFirestore).toList();
    final skill = skills.where((s) => s.id == proof.skillId).firstOrNull;
    if (skill == null) return;

    final stack = _stackContext(skill: skill, skills: skills, proofs: allProofs);
    await _syncSkillEvidence(stack.primary, stack.proofs);
  }
}

class _SkillStackContext {
  const _SkillStackContext({
    required this.primary,
    required this.proofs,
  });

  final SkillModel primary;
  final List<ProofModel> proofs;
}
