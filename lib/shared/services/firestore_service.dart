import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proof/core/constants/firestore_paths.dart';
import 'package:proof/core/utils/gym_verification_validator.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/core/utils/skill_badge_evaluator.dart';
import 'package:proof/core/utils/skill_stack_reconciler.dart';
import 'package:proof/core/utils/skill_uniqueness.dart';
import 'package:proof/core/utils/timeline_milestone_evaluator.dart';
import 'package:proof/core/utils/timeline_rebuilder.dart';
import 'package:proof/features/people/domain/friend_request_policy.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_badge.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/models/user_model.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/gym_model.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/onboarding_draft.dart';
import 'package:proof/shared/models/onboarding_step.dart';
import 'package:proof/shared/models/user_role.dart';
import 'package:proof/shared/models/verification_request_model.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/models/verification_status.dart';

class FirestoreService {
  FirestoreService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

  CollectionReference<Map<String, dynamic>> get _gyms =>
      _firestore.collection(FirestorePaths.gyms);

  CollectionReference<Map<String, dynamic>> get _gymMemberships =>
      _firestore.collection(FirestorePaths.gymMemberships);

  CollectionReference<Map<String, dynamic>> get _gymHandles =>
      _firestore.collection(FirestorePaths.gymHandles);

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _firestore.collection(FirestorePaths.publicProfiles);

  static const int timelineMigrationVersion = 2;
  static const int skillMergeVersion = 2;

  // ── User ──────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _userRef(user.id).set(user.toFirestore());
  }

  Future<void> deleteAllUserData(String userId) async {
    final user = await getUser(userId);

    final identity = await getIdentity(userId);
    if (identity != null) {
      await _handles.doc(identity.handle.toLowerCase()).delete();
    }

    final coachProfile = await getCoachProfile(userId);
    if (coachProfile != null && coachProfile.handle.isNotEmpty) {
      final handleDoc = await _handles.doc(coachProfile.handle.toLowerCase()).get();
      if (handleDoc.exists && handleDoc.data()?['userId'] == userId) {
        await _handles.doc(coachProfile.handle.toLowerCase()).delete();
      }
    }

    await _coachProfiles.doc(userId).delete();

    final memberships = await getMembershipsForUser(userId);
    for (final membership in memberships) {
      await _gymMemberships.doc(membership.id).delete();
    }

    if (user != null) {
      for (final gymId in user.managedGymIds) {
        final gym = await getGym(gymId);
        if (gym != null && gym.createdBy == userId) {
          final handleRef = _gymHandles.doc(gym.handle.toLowerCase());
          final handleDoc = await handleRef.get();
          if (handleDoc.exists) {
            await handleRef.delete();
          }
          await _gyms.doc(gymId).delete();
        }
      }
    }

    await _deleteCollection(_skillsRef(userId));
    await _deleteCollection(_proofsRef(userId));
    await _deleteCollection(_timelineRef(userId));
    await _identityRef(userId).delete();
    await _publicProfiles.doc(userId).delete();
    await _userRef(userId).delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    const batchSize = 100;
    while (true) {
      final snap = await collection.limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
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

  Future<bool> isHandleAvailableForUser(String handle, String userId) async {
    final doc = await _handles.doc(handle.toLowerCase()).get();
    if (!doc.exists) return true;
    return doc.data()?['userId'] == userId;
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
        'onboardingCompleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await syncPublicProfile(identity.userId);
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
    await syncPublicProfile(identity.userId);
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
    final skillsSnap = await _skillsRef(proof.userId).get();
    final skills = skillsSnap.docs.map(SkillModel.fromFirestore).toList();
    final skill = skills.where((s) => s.id == proof.skillId).firstOrNull;
    if (skill == null) return;

    final storedProof = _attachSkillVariant(proof, skill);
    await _proofsRef(proof.userId).doc(storedProof.id).set(storedProof.toFirestore());

    final allProofsSnap = await _proofsRef(proof.userId).get();
    final allProofs = allProofsSnap.docs.map(ProofModel.fromFirestore).toList();

    final stack = _stackContext(
      skill: skill,
      skills: skills,
      proofs: allProofs,
    );
    final priorStackProofs = stack.proofs
        .where((p) => p.id != storedProof.id)
        .toList();
    final previousConfidence =
        ProofStackCalculator.calculate(priorStackProofs);
    final newConfidence = ProofStackCalculator.calculate(stack.proofs);

    final priorBest = _bestNormalizedValue(skill, priorStackProofs);
    final isPersonalBest = storedProof.normalizedValue != null &&
        BestResultLogic.isBetter(
          candidate: storedProof.normalizedValue!,
          current: priorBest,
          performanceType: skill.performanceType,
        ) &&
        priorStackProofs.isNotEmpty;

    final hadGoalReachedBadge = stack.primary.earnedBadgeIds
        .contains(SkillBadgeId.goalReached.value);

    await _syncSkillEvidence(stack.primary, stack.proofs);

    final updatedSkill =
        await getSkill(proof.userId, stack.primary.id) ?? stack.primary;
    final personalBestCount = updatedSkill.personalBestCount +
        (isPersonalBest ? 1 : 0);
    final skillForBadges = updatedSkill.copyWith(
      personalBestCount: personalBestCount,
    );

    final newBadges = SkillBadgeEvaluator.newlyEarned(
      skill: skillForBadges,
      stackProofs: stack.proofs,
      allSkills: skills,
      allProofs: allProofs,
      isPersonalBest: isPersonalBest,
      personalBestCount: personalBestCount,
      confidence: newConfidence,
    );

    if (newBadges.isNotEmpty ||
        personalBestCount != updatedSkill.personalBestCount) {
      await _skillsRef(proof.userId).doc(stack.primary.id).update({
        'earnedBadgeIds': [
          ...updatedSkill.earnedBadgeIds,
          ...newBadges.map((badge) => badge.value),
        ],
        'personalBestCount': personalBestCount,
      });
    }

    final milestones = TimelineMilestoneEvaluator.evaluateProofAdded(
      proof: storedProof,
      skill: stack.primary,
      allProofs: allProofs,
      priorSkillProofs: priorStackProofs,
      previousConfidence: previousConfidence,
      newConfidence: newConfidence,
      isPersonalBest: isPersonalBest,
    );

    milestones.addAll(
      TimelineMilestoneEvaluator.evaluateBadgesEarned(
        skill: stack.primary,
        newBadges: newBadges,
      ),
    );
    milestones.addAll(
      TimelineMilestoneEvaluator.evaluateGoalReached(
        skill: skillForBadges,
        hadGoalReachedBadge: hadGoalReachedBadge,
      ),
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

  ProofModel _attachSkillVariant(ProofModel proof, SkillModel skill) {
    if (proof.variantId != null && proof.variantId!.isNotEmpty) {
      return proof;
    }
    return ProofModel(
      id: proof.id,
      userId: proof.userId,
      skillId: proof.skillId,
      title: proof.title,
      result: proof.result,
      unit: proof.unit,
      notes: proof.notes,
      mediaUrl: proof.mediaUrl,
      proofSource: proof.proofSource,
      verificationStatus: proof.verificationStatus,
      coachId: proof.coachId,
      rejectionNote: proof.rejectionNote,
      recordedAt: proof.recordedAt,
      createdAt: proof.createdAt,
      originalResult: proof.originalResult,
      originalUnit: proof.originalUnit,
      normalizedValue: proof.normalizedValue,
      location: proof.location,
      variantId: skill.variantId,
      variantName: skill.variantName,
    );
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

  Future<void> migrateOnboardingIfNeeded(String userId) async {
    final user = await getUser(userId);
    if (user == null || user.onboardingCompleted) return;

    final userDoc = await _userRef(userId).get();
    final data = userDoc.data();
    if (data == null || data.containsKey('onboardingCompleted')) return;

    final skillsSnap = await _skillsRef(userId).limit(1).get();
    final proofsSnap = await _proofsRef(userId).limit(1).get();
    if (skillsSnap.docs.isEmpty && proofsSnap.docs.isEmpty) return;

    await updateOnboardingProgress(
      userId: userId,
      onboardingCompleted: true,
      onboardingStep: OnboardingStep.completed,
    );
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
    await syncPublicProfile(userId);
    await _syncCoachProfileIfNeeded(userId);
  }

  // ── Public profiles (people discovery) ──────────────────────────────────

  Future<PublicProfileModel?> getPublicProfile(String userId) async {
    try {
      final doc = await _publicProfiles.doc(userId).get();
      if (!doc.exists) return null;
      return PublicProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  /// Loads a profile for friends/requests, falling back to identity when needed.
  Future<PublicProfileModel?> getFriendDisplayProfile(String userId) async {
    final publicProfile = await getPublicProfile(userId);
    if (publicProfile != null) return publicProfile;

    try {
      final identity = await getIdentity(userId);
      if (identity == null) return null;
      return PublicProfileModel.fromIdentity(identity);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Stream<List<PublicProfileModel>> watchSearchablePublicProfiles() {
    return _publicProfiles
        .where('searchable', isEqualTo: true)
        .limit(300)
        .snapshots()
        .map(
          (snap) => snap.docs.map(PublicProfileModel.fromFirestore).toList(),
        );
  }

  Future<List<PublicProfileModel>> searchPublicProfilesByHandlePrefix(
    String prefix,
  ) async {
    final normalized = prefix.trim().toLowerCase();
    if (normalized.length < 2) return [];

    final end = '$normalized\uf8ff';
    final results = <String, PublicProfileModel>{};

    Future<void> queryField(String field) async {
      final snap = await _publicProfiles
          .where('searchable', isEqualTo: true)
          .where(field, isGreaterThanOrEqualTo: normalized)
          .where(field, isLessThan: end)
          .limit(20)
          .get();
      for (final doc in snap.docs) {
        results[doc.id] = PublicProfileModel.fromFirestore(doc);
      }
    }

    await queryField('handleLowercase');
    await queryField('handle');

    final handleSnap = await _handles
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: normalized)
        .where(FieldPath.documentId, isLessThan: end)
        .limit(20)
        .get();

    for (final doc in handleSnap.docs) {
      final userId = doc.data()['userId'] as String?;
      if (userId == null || results.containsKey(userId)) continue;

      final profile = await getFriendDisplayProfile(userId);
      if (profile != null && profile.searchable) {
        results[userId] = profile;
      }
    }

    return results.values.toList()
      ..sort((a, b) {
        final aHandle =
            a.handleLowercase.isNotEmpty ? a.handleLowercase : a.handle.toLowerCase();
        final bHandle =
            b.handleLowercase.isNotEmpty ? b.handleLowercase : b.handle.toLowerCase();
        return aHandle.compareTo(bHandle);
      });
  }

  Future<PublicProfileModel?> lookupPublicProfileByHandle(String handle) async {
    final userId = await resolveUserIdByHandle(handle);
    if (userId == null) return null;
    return getFriendDisplayProfile(userId);
  }

  Future<void> syncPublicProfile(String userId) async {
    final identity = await getIdentity(userId);

    if (identity != null && identity.isPublic) {
      final skillsSnap = await _skillsRef(userId).get();
      final skills = skillsSnap.docs
          .map(SkillModel.fromFirestore)
          .where((s) => s.status == SkillStatus.active)
          .toList()
        ..sort((a, b) {
          final aConf = a.stackConfidence?.value ?? '';
          final bConf = b.stackConfidence?.value ?? '';
          return bConf.compareTo(aConf);
        });

      final topSkills = skills.take(3).map((skill) {
        final result = skill.formattedCurrentBest ?? skill.name;
        return PublicTopSkill(name: skill.name, resultLabel: result);
      }).toList();

      final identityStatus = skills.isEmpty
          ? 'Starting'
          : (skills.first.stackConfidence?.label ?? 'Developing');

      final profile = PublicProfileModel(
        userId: userId,
        displayName: identity.displayName,
        displayNameLowercase: identity.displayName.toLowerCase(),
        handle: identity.handle,
        handleLowercase: identity.handle.toLowerCase(),
        avatarUrl: identity.avatarUrl,
        city: identity.location,
        bio: identity.bio,
        identityStatus: identityStatus,
        publicTopSkills: topSkills,
        searchable: true,
        updatedAt: DateTime.now(),
      );

      await _publicProfiles.doc(userId).set(profile.toFirestore());
      return;
    }

    if (identity != null && !identity.isPublic) {
      await _publicProfiles.doc(userId).delete();
      return;
    }

    final coachProfile = await getCoachProfile(userId);
    if (coachProfile != null && coachProfile.handle.isNotEmpty) {
      await _publicProfiles
          .doc(userId)
          .set(PublicProfileModel.fromCoachProfile(coachProfile).toFirestore());
      return;
    }

    await _publicProfiles.doc(userId).delete();
  }

  Future<PublicProfileModel?> getOrSyncPublicProfileByHandle(
    String handle,
  ) async {
    final userId = await resolveUserIdByHandle(handle);
    if (userId == null) return null;

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == userId) {
      await syncPublicProfile(userId);
      return getPublicProfile(userId);
    }

    return getFriendDisplayProfile(userId);
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

  Future<RelationshipModel?> findFriendRelationship(
    String userIdA,
    String userIdB,
  ) async {
    // IMPORTANT:
    // 1) Never `.doc(id).get()` a relationship that may not exist — rules deny.
    // 2) Never query with `whereIn: [userIdA, userIdB]` — that can return docs
    //    the current user cannot read, and Firestore denies the whole query.
    // Only query relationships where the current user is a guaranteed participant.

    RelationshipModel? matchForPair(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
      for (final doc in docs) {
        final model = RelationshipModel.fromFirestore(doc);
        final matchesPair =
            (model.fromUserId == userIdA && model.toUserId == userIdB) ||
                (model.fromUserId == userIdB && model.toUserId == userIdA);
        if (matchesPair) return model;
      }
      return null;
    }

    final sent = await _relationships
        .where('type', isEqualTo: RelationshipType.friend.value)
        .where('fromUserId', isEqualTo: userIdA)
        .get();
    final sentMatch = matchForPair(sent.docs);
    if (sentMatch != null) return sentMatch;

    final received = await _relationships
        .where('type', isEqualTo: RelationshipType.friend.value)
        .where('toUserId', isEqualTo: userIdA)
        .get();
    return matchForPair(received.docs);
  }

  Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    final existing = await findFriendRelationship(fromUserId, toUserId);

    final reversePendingExists = existing == null
        ? (await _relationships
                .where('type', isEqualTo: RelationshipType.friend.value)
                .where('toUserId', isEqualTo: fromUserId)
                .where('status', isEqualTo: RelationshipStatus.pending.value)
                .get())
            .docs
            .any(
              (doc) =>
                  RelationshipModel.fromFirestore(doc).fromUserId == toUserId,
            )
        : false;

    final action = FriendRequestPolicy.decide(
      fromUserId: fromUserId,
      toUserId: toUserId,
      existing: existing,
      reversePendingExists: reversePendingExists,
    );

    switch (action) {
      case FriendRequestAction.none:
        return;
      case FriendRequestAction.acceptExisting:
        final relationshipId = existing?.id ??
            (await _relationships
                    .where('type', isEqualTo: RelationshipType.friend.value)
                    .where('toUserId', isEqualTo: fromUserId)
                    .where('status', isEqualTo: RelationshipStatus.pending.value)
                    .get())
                .docs
                .map(RelationshipModel.fromFirestore)
                .firstWhere((model) => model.fromUserId == toUserId)
                .id;
        await respondToRelationship(
          relationshipId: relationshipId,
          accept: true,
        );
        return;
      case FriendRequestAction.reopenDeclined:
        await _relationships.doc(existing!.id).update({
          'status': RelationshipStatus.pending.value,
          'createdAt': FieldValue.serverTimestamp(),
          'respondedAt': null,
          'requesterSeen': true,
          'recipientSeen': false,
        });
        return;
      case FriendRequestAction.createPending:
        final id = RelationshipModel.friendDocId(fromUserId, toUserId);
        await _relationships.doc(id).set(
          RelationshipModel(
            id: id,
            fromUserId: fromUserId,
            toUserId: toUserId,
            type: RelationshipType.friend,
            status: RelationshipStatus.pending,
            createdAt: DateTime.now(),
            requesterSeen: true,
            recipientSeen: false,
          ).toFirestore(),
        );
    }
  }

  Future<void> respondToRelationship({
    required String relationshipId,
    required bool accept,
  }) async {
    await _relationships.doc(relationshipId).update({
      'status': accept
          ? RelationshipStatus.accepted.value
          : RelationshipStatus.declined.value,
      'respondedAt': FieldValue.serverTimestamp(),
      'recipientSeen': true,
      'requesterSeen': false,
    });
  }

  Future<void> removeFriend(String relationshipId) async {
    await _relationships.doc(relationshipId).delete();
  }

  Future<void> blockUser({
    required String fromUserId,
    required String toUserId,
  }) async {
    final existing = await findFriendRelationship(fromUserId, toUserId);
    final id = existing?.id ?? RelationshipModel.friendDocId(fromUserId, toUserId);
    await _relationships.doc(id).set(
      RelationshipModel(
        id: id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
        status: RelationshipStatus.blocked,
        createdAt: existing?.createdAt ?? DateTime.now(),
        respondedAt: DateTime.now(),
        requesterSeen: true,
        recipientSeen: true,
      ).toFirestore(),
    );
  }

  Future<void> markIncomingFriendRequestsSeen(String userId) async {
    final snap = await _relationships
        .where('toUserId', isEqualTo: userId)
        .where('type', isEqualTo: RelationshipType.friend.value)
        .where('status', isEqualTo: RelationshipStatus.pending.value)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'recipientSeen': true});
    }
    await batch.commit();
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

  Future<void> ensureCoachProfile(String userId) async {
    await _syncCoachProfileIfNeeded(userId);
  }

  Future<void> _syncCoachProfileIfNeeded(String userId) async {
    final user = await getUser(userId);
    if (user == null || !user.isCoach) {
      await _coachProfiles.doc(userId).delete();
      return;
    }

    final identity = await getIdentity(userId);
    if (identity == null) {
      final existing = await _coachProfiles.doc(userId).get();
      if (!existing.exists) return;
      return;
    }

    final athletesSnap = await _relationships
        .where('toUserId', isEqualTo: userId)
        .get();
    final athleteCount = athletesSnap.docs
        .map(RelationshipModel.fromFirestore)
        .where(
          (relationship) =>
              relationship.type == RelationshipType.coach &&
              relationship.status == RelationshipStatus.accepted,
        )
        .length;

    final verifiedSnap = await _verificationRequests
        .where('coachId', isEqualTo: userId)
        .get();
    final verifiedProofCount = verifiedSnap.docs
        .map(VerificationRequestModel.fromFirestore)
        .where(
          (request) => request.status == VerificationRequestStatus.approved,
        )
        .length;

    final profile = CoachProfile(
      userId: userId,
      handle: identity.handle,
      displayName: identity.displayName,
      specialty: user.specialty.isNotEmpty ? user.specialty : 'Coach',
      bio: identity.bio,
      avatarUrl: identity.avatarUrl,
      athleteCount: athleteCount,
      verifiedProofCount: verifiedProofCount,
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
        .snapshots()
        .map((snap) => _sortVerificationRequests(
              snap.docs.map(VerificationRequestModel.fromFirestore).toList(),
            ));
  }

  Stream<List<VerificationRequestModel>> watchVerificationQueueForCoach(
    String coachId,
  ) {
    return _verificationRequests
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map((snap) => _sortVerificationRequests(
              snap.docs
                  .map(VerificationRequestModel.fromFirestore)
                  .where(
                    (request) =>
                        request.status ==
                        VerificationRequestStatus.pending,
                  )
                  .toList(),
            ));
  }

  Stream<List<VerificationRequestModel>> watchApprovedVerificationsForCoach(
    String coachId,
  ) {
    return _verificationRequests
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map((snap) => _sortVerificationRequests(
              snap.docs
                  .map(VerificationRequestModel.fromFirestore)
                  .where(
                    (request) =>
                        request.status ==
                        VerificationRequestStatus.approved,
                  )
                  .toList(),
            ));
  }

  List<VerificationRequestModel> _sortVerificationRequests(
    List<VerificationRequestModel> requests,
  ) {
    return requests
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addProofWithVerification({
    required ProofModel proof,
    String? coachId,
    String? gymId,
    String? verificationMessage,
  }) async {
    if (proof.verificationStatus == VerificationStatus.pendingVerification &&
        coachId != null &&
        gymId != null) {
      final athleteMembership = await getMembership(
        gymId: gymId,
        userId: proof.userId,
        type: GymMembershipType.athlete,
      );
      final coachMembership = await getMembership(
        gymId: gymId,
        userId: coachId,
        type: GymMembershipType.coach,
      );
      final validation = GymVerificationValidator.canRequestFromCoach(
        athleteMembership: athleteMembership,
        coachMembership: coachMembership,
        gymId: gymId,
        coachId: coachId,
      );
      if (!validation.isValid) {
        throw StateError(validation.reason ?? 'Invalid verification request');
      }

      final proofWithGym = ProofModel(
        id: proof.id,
        userId: proof.userId,
        skillId: proof.skillId,
        title: proof.title,
        result: proof.result,
        unit: proof.unit,
        notes: proof.notes,
        mediaUrl: proof.mediaUrl,
        proofSource: proof.proofSource,
        verificationStatus: proof.verificationStatus,
        coachId: coachId,
        requestedCoachId: coachId,
        verificationGymId: gymId,
        recordedAt: proof.recordedAt,
        createdAt: proof.createdAt,
        originalResult: proof.originalResult,
        originalUnit: proof.originalUnit,
        normalizedValue: proof.normalizedValue,
        location: proof.location,
        variantId: proof.variantId,
        variantName: proof.variantName,
      );

      await addProof(proofWithGym);

      final requestId = _verificationRequests.doc().id;
      final skill = await getSkill(proof.userId, proof.skillId);
      final variantLabel = skill?.variantName?.trim();
      final skillLabel = variantLabel != null && variantLabel.isNotEmpty
          ? '$variantLabel ${skill?.name ?? ''}'
          : skill?.name ?? '';

      try {
        await _verificationRequests.doc(requestId).set(
          VerificationRequestModel(
            id: requestId,
            proofId: proof.id,
            athleteId: proof.userId,
            coachId: coachId,
            gymId: gymId,
            skillId: proof.skillId,
            status: VerificationRequestStatus.pending,
            message: verificationMessage ?? '',
            createdAt: DateTime.now(),
            skillName: skillLabel,
            resultLabel: proof.formattedResult,
            mediaUrl: proof.mediaUrl,
            recordedAt: proof.recordedAt,
            location: proof.location,
            variantName: proof.variantName ?? '',
          ).toFirestore(),
        );
      } catch (e) {
        try {
          await _proofsRef(proof.userId).doc(proof.id).delete();
        } catch (_) {}
        rethrow;
      }
      return;
    }

    await addProof(proof);
  }

  Future<void> approveVerificationRequest(String requestId) async {
    final requestDoc = await _verificationRequests.doc(requestId).get();
    if (!requestDoc.exists) return;

    final request = VerificationRequestModel.fromFirestore(requestDoc);
    final coachMemberships =
        await getMembershipsForUser(request.coachId);
    final reviewCheck = GymVerificationValidator.canCoachReviewRequest(
      request: request,
      loggedInCoachId: request.coachId,
      coachMemberships: coachMemberships,
    );
    if (!reviewCheck.isValid) {
      throw StateError(reviewCheck.reason ?? 'Cannot approve request');
    }

    final proofDoc =
        await _proofsRef(request.athleteId).doc(request.proofId).get();
    if (!proofDoc.exists) return;

    final proof = ProofModel.fromFirestore(proofDoc);
    final now = DateTime.now();
    final updatedProof = proof.copyWith(
      proofSource: ProofSource.coach,
      verificationStatus: VerificationStatus.coachVerified,
      coachId: request.coachId,
      requestedCoachId: request.coachId,
      verificationGymId: request.gymId,
      verifiedByCoachId: request.coachId,
      verifiedAt: now,
    );

    await _proofsRef(request.athleteId)
        .doc(request.proofId)
        .update(updatedProof.toFirestore());

    await _verificationRequests.doc(requestId).update({
      'status': VerificationRequestStatus.approved.value,
      'reviewedAt': FieldValue.serverTimestamp(),
      'stackResynced': false,
    });

    try {
      await addTimelineEvent(
        userId: request.athleteId,
        type: TimelineEventType.coachVerified,
        title: 'Coach verification received',
        subtitle: request.skillName.isNotEmpty
            ? '${request.skillName} · ${request.resultLabel}'
            : request.resultLabel,
        referenceId: request.proofId,
      );
    } catch (_) {
      // Athlete can create the timeline event when the app finalizes locally.
    }

    await _syncCoachProfileIfNeeded(request.coachId);
  }

  Future<void> rejectVerificationRequest({
    required String requestId,
    String rejectionNote = '',
    required String coachId,
  }) async {
    final requestDoc = await _verificationRequests.doc(requestId).get();
    if (!requestDoc.exists) return;

    final request = VerificationRequestModel.fromFirestore(requestDoc);
    final coachMemberships = await getMembershipsForUser(coachId);
    final reviewCheck = GymVerificationValidator.canCoachReviewRequest(
      request: request,
      loggedInCoachId: coachId,
      coachMemberships: coachMemberships,
    );
    if (!reviewCheck.isValid) {
      throw StateError(reviewCheck.reason ?? 'Cannot decline request');
    }

    await _verificationRequests.doc(requestId).update({
      'status': VerificationRequestStatus.declined.value,
      'reviewedAt': FieldValue.serverTimestamp(),
      'declineReason': rejectionNote,
      'rejectionNote': rejectionNote,
      'stackResynced': false,
    });

    await _proofsRef(request.athleteId).doc(request.proofId).update({
      'verificationStatus': VerificationStatus.declined.value,
      'proofSource': ProofSource.selfReported.value,
      'rejectionNote': rejectionNote,
    });
  }

  /// Rebuilds proof-stack stats after coach decisions. Runs as the athlete so
  /// skill writes stay within Firestore rules.
  Future<void> syncVerificationStacksForAthlete(String userId) async {
    final snap = await _verificationRequests
        .where('athleteId', isEqualTo: userId)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['stackResynced'] == true) continue;

      final status = VerificationRequestStatus.fromString(
        data['status'] as String?,
      );
      if (status != VerificationRequestStatus.approved &&
          status != VerificationRequestStatus.declined) {
        continue;
      }

      final proofId = data['proofId'] as String?;
      if (proofId == null || proofId.isEmpty) continue;

      await _resyncProofStack(userId, proofId);
      await doc.reference.update({'stackResynced': true});
    }
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

  // ── Gyms & memberships ────────────────────────────────────────────────────

  Stream<List<GymModel>> watchActiveGyms() {
    return _gyms
        .where('status', isEqualTo: GymStatus.active.value)
        .snapshots()
        .map((snap) {
          final gyms = snap.docs.map(GymModel.fromFirestore).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          return gyms;
        });
  }

  Future<GymModel?> getGym(String gymId) async {
    final doc = await _gyms.doc(gymId).get();
    if (!doc.exists) return null;
    return GymModel.fromFirestore(doc);
  }

  Future<bool> isGymHandleAvailable(String handle) async {
    final doc = await _gymHandles.doc(handle.toLowerCase()).get();
    return !doc.exists;
  }

  Future<String> createGym({
    required String createdBy,
    required String name,
    required String handle,
    String description = '',
    String address = '',
    String country = '',
    String city = '',
    String website = '',
    String? logoUrl,
    String contactEmail = '',
    String managerName = '',
    String phone = '',
  }) async {
    final normalizedHandle = handle.trim().toLowerCase();
    if (!await isGymHandleAvailable(normalizedHandle)) {
      throw StateError('Gym handle is already taken');
    }

    final gymId = _gyms.doc().id;
    final now = DateTime.now();
    final gym = GymModel(
      id: gymId,
      name: name.trim(),
      handle: normalizedHandle,
      description: description.trim(),
      address: address.trim(),
      country: country.trim(),
      city: city.trim(),
      website: website.trim(),
      logoUrl: logoUrl,
      contactEmail: contactEmail.trim(),
      managerName: managerName.trim(),
      phone: phone.trim(),
      status: GymStatus.active,
      createdBy: createdBy,
      createdAt: now,
    );

    final managerId = GymMembershipModel.membershipDocId(
      gymId: gymId,
      userId: createdBy,
      type: GymMembershipType.manager,
    );
    final managerMembership = GymMembershipModel(
      id: managerId,
      gymId: gymId,
      userId: createdBy,
      membershipType: GymMembershipType.manager,
      status: GymMembershipStatus.approved,
      requestedAt: now,
      reviewedAt: now,
      reviewedBy: createdBy,
    );

    final batch = _firestore.batch();
    batch.set(_gyms.doc(gymId), gym.toFirestore());
    batch.set(_gymHandles.doc(normalizedHandle), {
      'gymId': gymId,
      'createdAt': Timestamp.fromDate(now),
    });
    await batch.commit();

    try {
      await _gymMemberships.doc(managerId).set(managerMembership.toFirestore());
    } catch (e) {
      await _gyms.doc(gymId).delete();
      await _gymHandles.doc(normalizedHandle).delete();
      rethrow;
    }

    return gymId;
  }

  Future<void> updateOnboardingProgress({
    required String userId,
    UserRole? accountType,
    UserRole? role,
    OnboardingStep? onboardingStep,
    bool? onboardingCompleted,
    String? physicalIdentityId,
    String? coachProfileId,
    List<String>? managedGymIds,
    String? primaryGymId,
    OnboardingDraft? onboardingDraft,
    bool? hasIdentity,
    String? specialty,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (accountType != null) updates['accountType'] = accountType.value;
    if (role != null) updates['role'] = role.value;
    if (specialty != null) updates['specialty'] = specialty;
    if (onboardingStep != null) updates['onboardingStep'] = onboardingStep.value;
    if (onboardingCompleted != null) {
      updates['onboardingCompleted'] = onboardingCompleted;
    }
    if (physicalIdentityId != null) {
      updates['physicalIdentityId'] = physicalIdentityId;
    }
    if (coachProfileId != null) updates['coachProfileId'] = coachProfileId;
    if (managedGymIds != null) updates['managedGymIds'] = managedGymIds;
    if (primaryGymId != null) updates['primaryGymId'] = primaryGymId;
    if (onboardingDraft != null) {
      updates['onboardingDraft'] = onboardingDraft.toMap();
    }
    if (hasIdentity != null) updates['hasIdentity'] = hasIdentity;
    await _userRef(userId).set(updates, SetOptions(merge: true));
  }

  Future<void> saveOnboardingDraft({
    required String userId,
    required OnboardingDraft draft,
  }) {
    return updateOnboardingProgress(userId: userId, onboardingDraft: draft);
  }

  Future<void> setAccountType({
    required String userId,
    required UserRole accountType,
  }) {
    return updateOnboardingProgress(
      userId: userId,
      accountType: accountType,
      role: accountType,
      onboardingStep: OnboardingStep.initialStepFor(accountType),
    );
  }

  Future<void> createPhysicalIdentityDuringOnboarding({
    required PhysicalIdentity identity,
    required UserRole accountType,
    String? selectedGymId,
  }) async {
    final user = await getUser(identity.userId);
    if (user == null) return;

    if (!user.hasIdentity) {
      final handle = identity.handle.toLowerCase();
      final batch = _firestore.batch();
      batch.set(_identityRef(identity.userId), identity.toFirestore());
      batch.set(_handles.doc(handle), {'userId': identity.userId});
      batch.set(
        _userRef(identity.userId),
        {
          'hasIdentity': true,
          'physicalIdentityId': identity.userId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      await syncPublicProfile(identity.userId);
      await _recordTimelineMilestones(
        identity.userId,
        TimelineMilestoneEvaluator.evaluateIdentityCreated(identity: identity),
      );
    } else {
      await updateIdentity(identity);
    }

    final nextStep = OnboardingStep.nextAfterPhysicalIdentity(accountType);
    await updateOnboardingProgress(
      userId: identity.userId,
      physicalIdentityId: identity.userId,
      hasIdentity: true,
      onboardingStep: nextStep ?? OnboardingStep.completed,
    );

    if (selectedGymId != null && selectedGymId.isNotEmpty) {
      await requestGymMembership(
        gymId: selectedGymId,
        userId: identity.userId,
        type: GymMembershipType.athlete,
      );
      await updateOnboardingProgress(
        userId: identity.userId,
        primaryGymId: selectedGymId,
      );
    }

    if (nextStep == OnboardingStep.completed) {
      await completeOnboarding(userId: identity.userId);
    }
  }

  Future<void> createCoachProfileDuringOnboarding({
    required String userId,
    required CoachProfile profile,
    required UserRole accountType,
    String? selectedGymId,
    bool reserveHandle = true,
  }) async {
    final user = await getUser(userId);
    if (user == null) return;

    final handle = profile.handle.toLowerCase();
    final existingProfile = await _coachProfiles.doc(userId).get();

    if (!existingProfile.exists) {
      final batch = _firestore.batch();
      batch.set(_coachProfiles.doc(userId), profile.toFirestore());
      if (reserveHandle && !user.hasIdentity) {
        batch.set(_handles.doc(handle), {'userId': userId});
      }
      await batch.commit();
    } else {
      await _coachProfiles.doc(userId).set(profile.toFirestore());
    }

    await syncPublicProfile(userId);

    final nextStep = OnboardingStep.nextAfterCoachProfile(accountType) ??
        (accountType == UserRole.athleteAndCoach
            ? OnboardingStep.selectGym
            : OnboardingStep.completed);
    await updateOnboardingProgress(
      userId: userId,
      coachProfileId: userId,
      role: accountType,
      accountType: accountType,
      specialty: profile.specialty,
      onboardingStep: nextStep,
    );

    if (selectedGymId != null &&
        selectedGymId.isNotEmpty &&
        accountType == UserRole.coach) {
      await requestGymMembership(
        gymId: selectedGymId,
        userId: userId,
        type: GymMembershipType.coach,
      );
      await updateOnboardingProgress(
        userId: userId,
        primaryGymId: selectedGymId,
      );
      await completeOnboarding(userId: userId);
    } else if (nextStep == OnboardingStep.completed) {
      await completeOnboarding(userId: userId);
    }
  }

  Future<String> completeGymOnboarding({
    required String createdBy,
    required GymModel gym,
  }) async {
    final existingGymId = (await getUser(createdBy))?.managedGymIds.firstOrNull;
    if (existingGymId != null) {
      final existing = await getGym(existingGymId);
      if (existing != null) {
        await updateOnboardingProgress(
          userId: createdBy,
          role: UserRole.gymManager,
          accountType: UserRole.gymManager,
          managedGymIds: [existingGymId],
          primaryGymId: existingGymId,
          onboardingStep: OnboardingStep.completed,
          onboardingCompleted: true,
        );
        return existingGymId;
      }
    }

    final gymId = await createGym(
      createdBy: createdBy,
      name: gym.name,
      handle: gym.handle,
      description: gym.description,
      address: gym.address,
      country: gym.country,
      city: gym.city,
      website: gym.website,
      logoUrl: gym.logoUrl,
      contactEmail: gym.contactEmail,
      managerName: gym.managerName,
      phone: gym.phone,
    );

    await updateOnboardingProgress(
      userId: createdBy,
      role: UserRole.gymManager,
      accountType: UserRole.gymManager,
      managedGymIds: [gymId],
      primaryGymId: gymId,
      onboardingStep: OnboardingStep.completed,
      onboardingCompleted: true,
    );

    return gymId;
  }

  Future<void> completeGymSelection({
    required String userId,
    required String gymId,
    required UserRole accountType,
  }) async {
    if (accountType.isAthlete) {
      await requestGymMembership(
        gymId: gymId,
        userId: userId,
        type: GymMembershipType.athlete,
      );
    }
    if (accountType.isCoach) {
      await requestGymMembership(
        gymId: gymId,
        userId: userId,
        type: GymMembershipType.coach,
      );
    }
    await updateOnboardingProgress(
      userId: userId,
      primaryGymId: gymId,
      onboardingStep: OnboardingStep.completed,
    );
    await completeOnboarding(userId: userId);
  }

  Future<void> completeOnboarding({required String userId}) async {
    await syncPublicProfile(userId);
    await updateOnboardingProgress(
      userId: userId,
      onboardingCompleted: true,
      onboardingStep: OnboardingStep.completed,
    );
  }

  Future<void> updateGym(GymModel gym) async {
    await _gyms.doc(gym.id).update(gym.toFirestore());
  }

  Future<void> updateUserProfile({
    required String userId,
    UserRole? role,
    String? specialty,
    String? primaryGymId,
    bool? onboardingCompleted,
  }) async {
    await updateOnboardingProgress(
      userId: userId,
      role: role,
      specialty: specialty,
      primaryGymId: primaryGymId,
      onboardingCompleted: onboardingCompleted,
      onboardingStep: onboardingCompleted == true
          ? OnboardingStep.completed
          : null,
    );
  }

  Future<List<GymMembershipModel>> getMembershipsForUser(String userId) async {
    final snap = await _gymMemberships
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs.map(GymMembershipModel.fromFirestore).toList();
  }

  Stream<List<GymMembershipModel>> watchMembershipsForUser(String userId) {
    return _gymMemberships
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(GymMembershipModel.fromFirestore).toList());
  }

  Stream<List<GymMembershipModel>> watchGymMemberships({
    required String gymId,
    GymMembershipType? type,
    GymMembershipStatus? status,
  }) {
    return _gymMemberships
        .where('gymId', isEqualTo: gymId)
        .snapshots()
        .map((snap) => _filterMemberships(
              snap.docs.map(GymMembershipModel.fromFirestore).toList(),
              type: type,
              status: status,
            ));
  }

  List<GymMembershipModel> _filterMemberships(
    List<GymMembershipModel> memberships, {
    GymMembershipType? type,
    GymMembershipStatus? status,
  }) {
    return memberships.where((membership) {
      if (type != null && membership.membershipType != type) return false;
      if (status != null && membership.status != status) return false;
      return true;
    }).toList();
  }

  Future<GymMembershipModel?> getMembership({
    required String gymId,
    required String userId,
    required GymMembershipType type,
  }) async {
    final id = GymMembershipModel.membershipDocId(
      gymId: gymId,
      userId: userId,
      type: type,
    );
    final doc = await _gymMemberships.doc(id).get();
    if (!doc.exists) return null;
    return GymMembershipModel.fromFirestore(doc);
  }

  Future<GymModel?> getGymByHandle(String handle) async {
    final normalized = handle.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
    if (normalized.isEmpty) return null;

    final doc = await _gymHandles.doc(normalized).get();
    if (!doc.exists) return null;

    final gymId = doc.data()?['gymId'] as String?;
    if (gymId == null || gymId.isEmpty) return null;

    return getGym(gymId);
  }

  Future<GymMembershipRequestResult> requestGymMembership({
    required String gymId,
    required String userId,
    required GymMembershipType type,
  }) async {
    final authUid = _auth.currentUser?.uid;
    if (authUid == null) {
      throw StateError('You must be signed in to request gym membership.');
    }
    if (authUid != userId) {
      throw StateError('Signed-in account does not match the active user.');
    }

    final id = GymMembershipModel.membershipDocId(
      gymId: gymId,
      userId: authUid,
      type: type,
    );
    final payload = GymMembershipModel(
      id: id,
      gymId: gymId,
      userId: authUid,
      membershipType: type,
      status: GymMembershipStatus.pending,
      requestedAt: DateTime.now(),
    ).toFirestore();

    DocumentSnapshot<Map<String, dynamic>>? existing;
    try {
      existing = await _gymMemberships.doc(id).get();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      existing = null;
    }

    if (existing?.exists == true) {
      final current = GymMembershipModel.fromFirestore(existing!);
      if (current.status == GymMembershipStatus.pending) {
        return GymMembershipRequestResult.alreadyPending;
      }
      if (current.status == GymMembershipStatus.approved) {
        return GymMembershipRequestResult.alreadyApproved;
      }

      await _gymMemberships.doc(id).update({
        ...payload,
        'requestedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.delete(),
        'reviewedBy': FieldValue.delete(),
      });
      return GymMembershipRequestResult.created;
    }

    await _gymMemberships.doc(id).set(payload);
    return GymMembershipRequestResult.created;
  }

  Future<void> reviewGymMembership({
    required String membershipId,
    required GymMembershipStatus status,
    required String reviewedBy,
  }) async {
    final doc = await _gymMemberships.doc(membershipId).get();
    if (!doc.exists) return;

    final membership = GymMembershipModel.fromFirestore(doc);
    await _gymMemberships.doc(membershipId).update({
      'status': status.value,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
    });

    if (status == GymMembershipStatus.removed ||
        status == GymMembershipStatus.rejected ||
        status == GymMembershipStatus.suspended) {
      await _cancelPendingVerificationsForMembership(membership);
    }
  }

  Future<void> _cancelPendingVerificationsForMembership(
    GymMembershipModel membership,
  ) async {
    Query<Map<String, dynamic>> query;
    if (membership.membershipType == GymMembershipType.athlete) {
      query = _verificationRequests.where(
        'athleteId',
        isEqualTo: membership.userId,
      );
    } else if (membership.membershipType == GymMembershipType.coach) {
      query = _verificationRequests.where(
        'coachId',
        isEqualTo: membership.userId,
      );
    } else {
      return;
    }

    final snap = await query.get();
    final pending = snap.docs
        .map(VerificationRequestModel.fromFirestore)
        .where(
          (request) =>
              request.status == VerificationRequestStatus.pending &&
              request.gymId == membership.gymId,
        )
        .toList();

    for (final request in pending) {
      await _verificationRequests.doc(request.id).update({
        'status': VerificationRequestStatus.cancelled.value,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      await _proofsRef(request.athleteId).doc(request.proofId).update({
        'verificationStatus': VerificationStatus.selfReported.value,
        'proofSource': ProofSource.selfReported.value,
      });
    }
  }

  Future<List<GymMembershipModel>> getApprovedCoachesForGym(
    String gymId,
  ) async {
    final snap = await _gymMemberships
        .where('gymId', isEqualTo: gymId)
        .where('membershipType', isEqualTo: GymMembershipType.coach.value)
        .where('status', isEqualTo: GymMembershipStatus.approved.value)
        .get();
    return snap.docs.map(GymMembershipModel.fromFirestore).toList();
  }

  Future<List<GymModel>> getGymsManagedByUser(String userId) async {
    final snap = await _gymMemberships
        .where('userId', isEqualTo: userId)
        .get();
    final managerMemberships = _filterMemberships(
      snap.docs.map(GymMembershipModel.fromFirestore).toList(),
      type: GymMembershipType.manager,
      status: GymMembershipStatus.approved,
    );
    final gyms = <GymModel>[];
    for (final membership in managerMemberships) {
      final gym = await getGym(membership.gymId);
      if (gym != null) gyms.add(gym);
    }
    gyms.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return gyms;
  }

  GymMembershipModel? approvedAthleteMembershipForGym({
    required List<GymMembershipModel> memberships,
    required String gymId,
  }) {
    for (final membership in memberships) {
      if (membership.gymId == gymId &&
          membership.membershipType == GymMembershipType.athlete &&
          membership.status == GymMembershipStatus.approved) {
        return membership;
      }
    }
    return null;
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
