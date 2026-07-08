enum ProofSource {
  selfReported('self_reported', 'Self-reported'),
  coach('coach', 'Coach verified');

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
