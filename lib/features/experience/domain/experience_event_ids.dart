/// Deterministic receipt / event document IDs.
class ExperienceEventIds {
  ExperienceEventIds._();

  static String onboardingCompleted(String uid) => 'onboardingCompleted:$uid';

  static String firstProofCreated(String uid) => 'firstProofCreated:$uid';

  /// [verificationVersion] must be stable across Firestore re-reads.
  /// Prefer coach identity over timestamps (timestamps may be absent locally
  /// before sync, or normalize differently).
  static String coachVerified(String proofId, String verificationVersion) =>
      'coachVerified:$proofId:$verificationVersion';

  /// Stable version from an approved coach verification on a proof.
  ///
  /// Uses [verifiedByCoachId] because it is immutable after approval.
  /// [verifiedAt] is intentionally NOT used — it can be null on first local
  /// read and may differ if client/server clocks diverge during write.
  static String verificationVersionFromProof({
    required String? verifiedByCoachId,
    String? verificationRequestId,
  }) {
    final requestId = verificationRequestId?.trim() ?? '';
    if (requestId.isNotEmpty) return 'request:$requestId';
    final coach = verifiedByCoachId?.trim() ?? '';
    if (coach.isNotEmpty) return 'coach:$coach';
    return 'approved';
  }
}
