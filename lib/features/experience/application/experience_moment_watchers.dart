import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/constants/firestore_paths.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/application/experience_event_factory.dart';
import 'package:proof/features/experience/application/experience_providers.dart';
import 'package:proof/features/experience/application/experience_session_signals.dart';
import 'package:proof/features/experience/application/experience_trigger_service.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/verification_status.dart';
import 'package:proof/shared/providers/app_providers.dart';

/// Dashboard + lifecycle hooks for real-flow experience triggers.
void watchExperienceMoments(WidgetRef ref) {
  watchIssuanceExperience(ref);
  watchCoachVerificationExperiences(ref);
  resumePendingExperiences(ref);
}

void watchIssuanceExperience(WidgetRef ref) {
  final flags = ref.watch(experienceFeatureFlagsProvider);
  if (!flags.experienceEngineEnabled ||
      !flags.accountCreationExperienceEnabled) {
    return;
  }

  ref.listen(pendingIssuanceExperienceProvider, (previous, userId) {
    if (userId == null || userId.isEmpty) return;

    final trigger = ref.read(experienceTriggerServiceProvider);
    final firestore = ref.read(firestoreServiceProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(pendingIssuanceExperienceProvider.notifier).state = null;
      try {
        final identity = await firestore.getIdentity(userId);
        await trigger.onOnboardingCompleted(
          userId: userId,
          identity: identity,
        );
      } catch (_) {}
    });
  });
}

void resumePendingExperiences(WidgetRef ref) {
  final flags = ref.watch(experienceFeatureFlagsProvider);
  if (!flags.experienceEngineEnabled) return;

  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return;

  final lastResumed = ref.watch(experienceResumeGuardProvider);
  if (lastResumed == uid) return;

  final coordinator = ref.read(experienceCoordinatorProvider);
  final factory = ref.read(experienceEventFactoryProvider);
  final firestoreDb = ref.read(firestoreProvider);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (ref.read(experienceResumeGuardProvider) == uid) return;
    ref.read(experienceResumeGuardProvider.notifier).state = uid;
    try {
      await coordinator.resumePending(
        ownerId: uid,
        hydrate: (receipt) => _hydrateReceipt(
          receipt: receipt,
          factory: factory,
          firestore: firestoreDb,
        ),
      );
    } catch (_) {}
  });
}

Future<ExperienceEvent?> _hydrateReceipt({
  required ExperienceReceipt receipt,
  required ExperienceEventFactory factory,
  required FirebaseFirestore firestore,
}) async {
  final uid = receipt.ownerId;

  switch (receipt.eventType) {
    case ExperienceEventType.onboardingCompleted:
      return factory.onboardingCompleted(
        userId: uid,
        context: ExperienceContext(userId: uid, sourceId: uid),
      );
    case ExperienceEventType.firstProofCreated:
      final proofId = receipt.sourceId;
      if (proofId.isEmpty) return null;
      final proof = await _loadProof(firestore, uid, proofId);
      if (proof == null) return null;
      return factory.firstProofCreated(
        userId: uid,
        proof: proof,
        isActualFirstProof: true,
        context: ExperienceContext(
          userId: uid,
          proofId: proof.id,
          proofResult: proof.result,
          proofUnit: proof.unit,
          proofDate: proof.recordedAt,
          sourceId: proof.id,
        ),
      );
    case ExperienceEventType.coachVerified:
      final proofId = receipt.sourceId;
      if (proofId.isEmpty) return null;
      final proof = await _loadProof(firestore, uid, proofId);
      if (proof == null) return null;
      return factory.coachVerified(
        proof: proof,
        context: ExperienceContext(
          userId: uid,
          proofId: proof.id,
          proofResult: proof.result,
          proofUnit: proof.unit,
          proofDate: proof.recordedAt,
          verificationDate: proof.verifiedAt,
          sourceId: proof.id,
        ),
      );
    default:
      return null;
  }
}

void watchCoachVerificationExperiences(WidgetRef ref) {
  final flags = ref.watch(experienceFeatureFlagsProvider);
  if (!flags.experienceEngineEnabled ||
      !flags.coachVerificationExperienceEnabled) {
    return;
  }

  ref.listen(proofsProvider, (previous, next) {
    final proofs = next.valueOrNull;
    if (proofs == null || proofs.isEmpty) return;

    final baseline = Map<String, bool>.from(
      ref.read(coachVerificationBaselineProvider),
    );
    final isFirstSnapshot = baseline.isEmpty;
    final newlyVerified = <ProofModel>[];

    for (final proof in proofs) {
      final verified = _isCoachVerified(proof);
      final wasVerified = baseline[proof.id] ?? false;
      baseline[proof.id] = verified;
      if (!isFirstSnapshot && verified && !wasVerified) {
        newlyVerified.add(proof);
      }
    }

    ref.read(coachVerificationBaselineProvider.notifier).state = baseline;
    if (newlyVerified.isEmpty) return;

    final trigger = ref.read(experienceTriggerServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await trigger.onCoachVerifiedProofs(proofs: newlyVerified);
      } catch (_) {}
    });
  });
}

bool _isCoachVerified(ProofModel proof) {
  return proof.verificationStatus == VerificationStatus.coachVerified ||
      proof.isCoachVerifiedForStack;
}

Future<ProofModel?> _loadProof(
  FirebaseFirestore firestore,
  String uid,
  String proofId,
) async {
  final doc = await firestore
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.proofs)
      .doc(proofId)
      .get();
  if (!doc.exists) return null;
  return ProofModel.fromFirestore(doc);
}
