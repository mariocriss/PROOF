import 'package:proof/shared/models/deleted_account_markers.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/user_report_model.dart';
import 'package:proof/shared/models/verification_status.dart';

/// Pure anonymization helpers for account-deletion retention cases.
class AccountDeletionAnonymization {
  AccountDeletionAnonymization._();

  /// Minimizes personal data on a report *about* a deleted user.
  ///
  /// Keeps [UserReportModel.reportedUserId] as the internal moderation subject
  /// id. Clears the public handle and marks the account deleted.
  static UserReportModel anonymizeReportAboutDeletedUser(UserReportModel report) {
    return UserReportModel(
      id: report.id,
      reporterUserId: report.reporterUserId,
      reportedUserId: report.reportedUserId,
      reason: report.reason,
      createdAt: report.createdAt,
      details: report.details,
      reportedHandle: DeletedAccountMarkers.reportedHandle,
      reportedAccountDeleted: true,
    );
  }

  /// Firestore field patch for report subject anonymization.
  static Map<String, Object?> reportAnonymizationUpdate() {
    return {
      'reportedHandle': DeletedAccountMarkers.reportedHandle,
      'reportedAccountDeleted': true,
    };
  }

  /// Preserves historical coach verification without retaining a live coach UID.
  static ProofModel anonymizeDeletedCoachOnProof(ProofModel proof) {
    final historicallyVerified = proof.isCoachVerifiedForStack;
    final wasPending =
        proof.verificationStatus == VerificationStatus.pendingVerification;

    return ProofModel(
      id: proof.id,
      userId: proof.userId,
      skillId: proof.skillId,
      title: proof.title,
      recordedAt: proof.recordedAt,
      createdAt: proof.createdAt,
      result: proof.result,
      unit: proof.unit,
      proofSource: historicallyVerified
          ? ProofSource.coach
          : (wasPending ? ProofSource.selfReported : proof.proofSource),
      verificationStatus: historicallyVerified
          ? VerificationStatus.coachVerified
          : (wasPending
              ? VerificationStatus.selfReported
              : proof.verificationStatus),
      coachId: null,
      requestedCoachId: null,
      verificationGymId: proof.verificationGymId,
      verifiedByCoachId: null,
      verifiedAt: proof.verifiedAt,
      rejectionNote: proof.rejectionNote,
      notes: proof.notes,
      mediaUrl: proof.mediaUrl,
      originalResult: proof.originalResult,
      originalUnit: proof.originalUnit,
      normalizedValue: proof.normalizedValue,
      location: proof.location,
      variantId: proof.variantId,
      variantName: proof.variantName,
      coachAccountDeleted: historicallyVerified,
    );
  }

  /// Firestore field patch applied to athlete proofs when the coach deletes.
  static Map<String, Object?> coachProofAnonymizationUpdate(ProofModel proof) {
    final anonymized = anonymizeDeletedCoachOnProof(proof);
    return {
      'coachId': null,
      'requestedCoachId': null,
      'verifiedByCoachId': null,
      'coachAccountDeleted': anonymized.coachAccountDeleted,
      'verificationStatus': anonymized.verificationStatus.value,
      'proofSource': anonymized.proofSource.value,
    };
  }
}
