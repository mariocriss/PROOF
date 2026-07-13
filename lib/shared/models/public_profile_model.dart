import 'package:cloud_firestore/cloud_firestore.dart';

class PublicTopSkill {
  const PublicTopSkill({
    required this.name,
    required this.resultLabel,
  });

  final String name;
  final String resultLabel;

  factory PublicTopSkill.fromMap(Map<String, dynamic> data) {
    return PublicTopSkill(
      name: data['name'] as String? ?? '',
      resultLabel: data['resultLabel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'resultLabel': resultLabel,
    };
  }
}

class PublicProfileModel {
  const PublicProfileModel({
    required this.userId,
    required this.displayName,
    required this.handle,
    required this.updatedAt,
    this.displayNameLowercase = '',
    this.handleLowercase = '',
    this.avatarUrl,
    this.city = '',
    this.bio = '',
    this.identityStatus = 'Active',
    this.ageVisible = false,
    this.publicAge,
    this.publicTopSkills = const [],
    this.searchable = true,
  });

  final String userId;
  final String displayName;
  final String handle;
  final String displayNameLowercase;
  final String handleLowercase;
  final String? avatarUrl;
  final String city;
  final String bio;
  final String identityStatus;
  final bool ageVisible;
  final int? publicAge;
  final List<PublicTopSkill> publicTopSkills;
  final bool searchable;
  final DateTime updatedAt;

  factory PublicProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final skillsRaw = data['publicTopSkills'] as List<dynamic>? ?? [];
    return PublicProfileModel(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? '',
      handle: data['handle'] as String? ?? '',
      displayNameLowercase: data['displayNameLowercase'] as String? ?? '',
      handleLowercase: data['handleLowercase'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      city: data['city'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      identityStatus: data['identityStatus'] as String? ?? 'Active',
      ageVisible: data['ageVisible'] as bool? ?? false,
      publicAge: data['publicAge'] as int?,
      publicTopSkills: skillsRaw
          .whereType<Map<String, dynamic>>()
          .map(PublicTopSkill.fromMap)
          .toList(),
      searchable: data['searchable'] as bool? ?? true,
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'displayNameLowercase': displayNameLowercase,
      'handle': handle,
      'handleLowercase': handleLowercase,
      'avatarUrl': avatarUrl,
      'city': city,
      'bio': bio,
      'identityStatus': identityStatus,
      'ageVisible': ageVisible,
      'publicAge': publicAge,
      'publicTopSkills': publicTopSkills.map((s) => s.toMap()).toList(),
      'searchable': searchable,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
