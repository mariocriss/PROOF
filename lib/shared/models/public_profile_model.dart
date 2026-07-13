import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/physical_identity.dart';

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
    final handle = data['handle'] as String? ?? '';
    final displayName = data['displayName'] as String? ?? '';
    return PublicProfileModel(
      userId: doc.id,
      displayName: displayName,
      handle: handle,
      displayNameLowercase:
          data['displayNameLowercase'] as String? ?? displayName.toLowerCase(),
      handleLowercase:
          data['handleLowercase'] as String? ?? handle.toLowerCase(),
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

  factory PublicProfileModel.fromIdentity(PhysicalIdentity identity) {
    return PublicProfileModel(
      userId: identity.userId,
      displayName: identity.displayName,
      displayNameLowercase: identity.displayName.toLowerCase(),
      handle: identity.handle,
      handleLowercase: identity.handle.toLowerCase(),
      avatarUrl: identity.avatarUrl,
      city: identity.location,
      bio: identity.bio,
      searchable: identity.isPublic,
      updatedAt: identity.updatedAt,
    );
  }

  factory PublicProfileModel.fromCoachProfile(CoachProfile coach) {
    return PublicProfileModel(
      userId: coach.userId,
      displayName: coach.displayName,
      displayNameLowercase: coach.displayName.toLowerCase(),
      handle: coach.handle,
      handleLowercase: coach.handle.toLowerCase(),
      avatarUrl: coach.avatarUrl,
      city: coach.country,
      bio: coach.bio,
      identityStatus: coach.specialty,
      searchable: true,
      updatedAt: coach.updatedAt,
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
