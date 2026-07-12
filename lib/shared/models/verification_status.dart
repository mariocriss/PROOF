enum VerificationStatus {
  selfReported('self_reported'),
  pendingVerification('pending_verification'),
  coachVerified('coach_verified'),
  declined('declined'),
  rejected('rejected');

  const VerificationStatus(this.value);

  final String value;

  static VerificationStatus fromString(String? value) {
    if (value == null || value.isEmpty) {
      return VerificationStatus.selfReported;
    }
    return VerificationStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => VerificationStatus.selfReported,
    );
  }

  String get label => switch (this) {
        VerificationStatus.selfReported => 'Self-reported',
        VerificationStatus.pendingVerification => 'Awaiting coach review',
        VerificationStatus.coachVerified => 'Coach verified',
        VerificationStatus.declined => 'Verification declined',
        VerificationStatus.rejected => 'Verification declined',
      };

  bool get countsAsCoachVerified => this == VerificationStatus.coachVerified;

  bool get isAwaitingCoachReview =>
      this == VerificationStatus.pendingVerification;
}
