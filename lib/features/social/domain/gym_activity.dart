import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/core/utils/result_formatter.dart';
import 'package:proof/shared/models/verification_status.dart';

/// Public projection of one explicitly shared proof.
///
/// Stored at `gyms/{gymId}/activity/{proofId}`. The proof document remains
/// the source of truth. Personal notes and private attachments are never
/// copied here.
class GymActivity {
  const GymActivity({
    required this.id,
    required this.gymId,
    required this.proofId,
    required this.athleteId,
    required this.skillId,
    required this.skillName,
    required this.discipline,
    required this.result,
    required this.unit,
    required this.recordedAt,
    required this.sharedAt,
    required this.verificationStatus,
    required this.displayName,
    this.variantName = '',
    this.avatarUrl = '',
    this.status = activeStatus,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  static const String activeStatus = 'active';

  final String id;
  final String gymId;
  final String proofId;
  final String athleteId;
  final String skillId;
  final String skillName;
  final String discipline;
  final String variantName;
  final String result;
  final String unit;
  final DateTime recordedAt;
  final DateTime sharedAt;
  final VerificationStatus verificationStatus;
  final String displayName;
  final String avatarUrl;
  final String status;
  final int likeCount;
  final int commentCount;

  bool get isActive => status == activeStatus;

  String get formattedResult => ResultFormatter.display(result, unit);

  String get skillLabel {
    final variant = variantName.trim();
    if (variant.isEmpty) return skillName;
    return '$variant $skillName'.trim();
  }

  factory GymActivity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final recordedAt = (data['recordedAt'] as Timestamp?)?.toDate() ??
        (data['sharedAt'] as Timestamp?)?.toDate() ??
        DateTime.now();
    return GymActivity(
      id: doc.id,
      gymId: data['gymId'] as String? ?? '',
      proofId: data['proofId'] as String? ?? doc.id,
      athleteId: data['athleteId'] as String? ?? '',
      skillId: data['skillId'] as String? ?? '',
      skillName: data['skillName'] as String? ?? '',
      discipline: data['discipline'] as String? ?? '',
      variantName: data['variantName'] as String? ?? '',
      result: data['result'] as String? ?? '',
      unit: data['unit'] as String? ?? '',
      recordedAt: recordedAt,
      sharedAt: (data['sharedAt'] as Timestamp?)?.toDate() ?? recordedAt,
      verificationStatus: VerificationStatus.fromString(
        data['verificationStatus'] as String?,
      ),
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      status: data['status'] as String? ?? activeStatus,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Shared achievements visible in one gym feed, including the viewer's own.
///
/// Blocked athletes are omitted. Inactive shares are omitted.
List<GymActivity> visibleGymActivity({
  required List<GymActivity> activity,
  required Set<String> blockedUserIds,
}) {
  return activity.where((item) {
    if (!item.isActive) return false;
    if (blockedUserIds.contains(item.athleteId)) return false;
    return true;
  }).toList();
}

/// Why the Social tab has nothing to show yet.
enum SocialFeedState {
  /// Memberships are still loading.
  loading,

  /// The signed-in user has no approved gym membership.
  noGym,

  /// The user belongs to a gym. The feed may still be empty.
  ready,
}
