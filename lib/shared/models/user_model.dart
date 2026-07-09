import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/shared/models/user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.hasIdentity = false,
    this.role = UserRole.athlete,
    this.specialty = '',
  });

  final String id;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasIdentity;
  final UserRole role;
  final String specialty;

  bool get isCoach => role.isCoach;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasIdentity: data['hasIdentity'] as bool? ?? false,
      role: UserRole.fromString(data['role'] as String?),
      specialty: data['specialty'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'hasIdentity': hasIdentity,
      'role': role.value,
      'specialty': specialty,
    };
  }

  UserModel copyWith({
    String? email,
    DateTime? updatedAt,
    bool? hasIdentity,
    UserRole? role,
    String? specialty,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasIdentity: hasIdentity ?? this.hasIdentity,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
    );
  }
}
