import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.hasIdentity = false,
  });

  final String id;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasIdentity;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasIdentity: data['hasIdentity'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'hasIdentity': hasIdentity,
    };
  }

  UserModel copyWith({
    String? email,
    DateTime? updatedAt,
    bool? hasIdentity,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasIdentity: hasIdentity ?? this.hasIdentity,
    );
  }
}
