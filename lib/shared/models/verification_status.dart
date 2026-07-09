enum VerificationStatus {
  selfReported('self_reported'),
  pendingVerification('pending_verification'),
  coachVerified('coach_verified'),
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
        VerificationStatus.pendingVerification => 'Pending verification',
        VerificationStatus.coachVerified => 'Coach verified',
        VerificationStatus.rejected => 'Rejected',
      };

  bool get countsAsCoachVerified => this == VerificationStatus.coachVerified;
}
