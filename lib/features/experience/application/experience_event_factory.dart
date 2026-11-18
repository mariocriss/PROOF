import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_ids.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/verification_status.dart';

/// Builds experience events from successful domain operations.
/// Never the source of truth — domain writes must succeed independently.
class ExperienceEventFactory {
  const ExperienceEventFactory();

  ExperienceEvent onboardingCompleted({
    required String userId,
    required ExperienceContext context,
  }) {
    return ExperienceEvent(
      id: ExperienceEventIds.onboardingCompleted(userId),
      type: ExperienceEventType.onboardingCompleted,
      importance: ExperienceImportance.t3Landmark,
      ownerId: userId,
      sourceId: userId,
      context: context.copyWith(userId: userId, sourceId: userId),
      createdAt: DateTime.now(),
    );
  }

  ExperienceEvent? firstProofCreated({
    required String userId,
    required ProofModel proof,
    required bool isActualFirstProof,
    required ExperienceContext context,
  }) {
    if (!isActualFirstProof) return null;
    return ExperienceEvent(
      id: ExperienceEventIds.firstProofCreated(userId),
      type: ExperienceEventType.firstProofCreated,
      importance: ExperienceImportance.t3Landmark,
      ownerId: userId,
      sourceId: proof.id,
      context: context.copyWith(
        userId: userId,
        proofId: proof.id,
        proofResult: proof.result,
        proofUnit: proof.unit,
        proofDate: proof.recordedAt,
        sourceId: proof.id,
      ),
      createdAt: DateTime.now(),
    );
  }

  ExperienceEvent? coachVerified({
    required ProofModel proof,
    required ExperienceContext context,
  }) {
    if (proof.verificationStatus != VerificationStatus.coachVerified &&
        !proof.isCoachVerifiedForStack) {
      return null;
    }
    final version = ExperienceEventIds.verificationVersionFromProof(
      verifiedByCoachId: proof.verifiedByCoachId ?? proof.coachId,
      verificationRequestId: context.verificationRequestId,
    );
    return ExperienceEvent(
      id: ExperienceEventIds.coachVerified(proof.id, version),
      type: ExperienceEventType.coachVerified,
      importance: ExperienceImportance.t3Landmark,
      ownerId: proof.userId,
      sourceId: proof.id,
      context: context.copyWith(
        userId: proof.userId,
        proofId: proof.id,
        proofResult: proof.result,
        proofUnit: proof.unit,
        proofDate: proof.recordedAt,
        verificationDate: proof.verifiedAt,
        sourceId: proof.id,
      ),
      createdAt: DateTime.now(),
    );
  }

  /// Gallery / debug events — never write production receipts when galleryMode.
  ExperienceEvent galleryPreview({
    required ExperienceEventType type,
    required ExperienceImportance importance,
    required ExperienceContext context,
    String ownerId = 'gallery',
  }) {
    return ExperienceEvent(
      id: 'gallery:${type.value}:${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      importance: importance,
      ownerId: ownerId,
      sourceId: 'gallery',
      context: context.copyWith(userId: ownerId, sourceId: 'gallery'),
      createdAt: DateTime.now(),
    );
  }
}
