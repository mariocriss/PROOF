import 'package:cloud_firestore/cloud_firestore.dart';

class CoachProfile {
  const CoachProfile({
    required this.userId,
    required this.handle,
    required this.displayName,
    required this.specialty,
    required this.updatedAt,
    this.bio = '',
    this.avatarUrl,
    this.country = '',
    this.qualifications = '',
    this.athleteCount = 0,
    this.verifiedProofCount = 0,
  });

  final String userId;
  final String handle;
  final String displayName;
  final String specialty;
  final String bio;
  final String? avatarUrl;
  final String country;
  final String qualifications;
  final int athleteCount;
  final int verifiedProofCount;
  final DateTime updatedAt;

  factory CoachProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CoachProfile(
      userId: doc.id,
      handle: data['handle'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      specialty: data['specialty'] as String? ?? 'Coach',
      bio: data['bio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      country: data['country'] as String? ?? '',
      qualifications: data['qualifications'] as String? ?? '',
      athleteCount: data['athleteCount'] as int? ?? 0,
      verifiedProofCount: data['verifiedProofCount'] as int? ?? 0,
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'handle': handle,
      'displayName': displayName,
      'specialty': specialty,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'country': country,
      'qualifications': qualifications,
      'athleteCount': athleteCount,
      'verifiedProofCount': verifiedProofCount,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
