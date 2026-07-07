import 'package:cloud_firestore/cloud_firestore.dart';

/// Core product object: a person's verified physical identity.
class PhysicalIdentity {
  const PhysicalIdentity({
    required this.userId,
    required this.displayName,
    required this.handle,
    required this.createdAt,
    required this.updatedAt,
    this.bio = '',
    this.location = '',
    this.avatarUrl,
    this.isPublic = true,
  });

  final String userId;
  final String displayName;
  final String handle;
  final String bio;
  final String location;
  final String? avatarUrl;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PhysicalIdentity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PhysicalIdentity(
      userId: data['userId'] as String? ?? doc.reference.parent.parent!.id,
      displayName: data['displayName'] as String? ?? '',
      handle: data['handle'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      location: data['location'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      isPublic: data['isPublic'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'handle': handle,
      'bio': bio,
      'location': location,
      'avatarUrl': avatarUrl,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PhysicalIdentity copyWith({
    String? displayName,
    String? handle,
    String? bio,
    String? location,
    String? avatarUrl,
    bool? isPublic,
    DateTime? updatedAt,
  }) {
    return PhysicalIdentity(
      userId: userId,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
