enum ProofSource {
  selfReported('self_reported', 'Self Reported'),
  coach('coach', 'Coach Verified');

  const ProofSource(this.value, this.label);

  final String value;
  final String label;

  static ProofSource fromString(String? value) {
    if (value == coach.value) return ProofSource.coach;
    return ProofSource.selfReported;
  }

  bool get isTrusted => this == ProofSource.coach;

  static const List<ProofSource> selectable = [
    selfReported,
    coach,
  ];
}
