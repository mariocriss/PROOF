enum UserRole {
  athlete('athlete'),
  coach('coach'),
  both('both');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.athlete,
    );
  }

  bool get isCoach => this == UserRole.coach || this == UserRole.both;
}
