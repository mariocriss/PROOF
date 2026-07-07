enum ProofSource {
  selfReported('self_reported', 'Self-reported'),
  coach('coach', 'Coach verified');

  const ProofSource(this.value, this.label);

  final String value;
  final String label;

  static ProofSource fromString(String? value) {
    return ProofSource.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ProofSource.selfReported,
    );
  }

  bool get isTrusted => this == ProofSource.coach;
}
