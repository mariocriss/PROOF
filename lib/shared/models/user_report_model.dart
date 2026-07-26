import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/shared/models/deleted_account_markers.dart';

enum UserReportReason {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment'),
  impersonation('impersonation', 'Impersonation'),
  inappropriate('inappropriate', 'Inappropriate content'),
  other('other', 'Other');

  const UserReportReason(this.value, this.label);

  final String value;
  final String label;

  static UserReportReason fromString(String? raw) {
    return UserReportReason.values.firstWhere(
      (reason) => reason.value == raw,
      orElse: () => UserReportReason.other,
    );
  }
}

class UserReportModel {
  const UserReportModel({
    required this.id,
    required this.reporterUserId,
    required this.reportedUserId,
    required this.reason,
    required this.createdAt,
    this.details = '',
    this.reportedHandle = '',
    this.reportedAccountDeleted = false,
  });

  final String id;
  final String reporterUserId;

  /// Internal moderation subject id (Firebase Auth UID). Not a public profile
  /// field. Retained after account deletion for abuse-correlation only.
  final String reportedUserId;

  /// Public handle snapshot. After subject deletion this is
  /// [DeletedAccountMarkers.reportedHandle], never a live handle/email/name.
  final String reportedHandle;
  final UserReportReason reason;
  final String details;
  final DateTime createdAt;
  final bool reportedAccountDeleted;

  factory UserReportModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserReportModel(
      id: doc.id,
      reporterUserId: data['reporterUserId'] as String? ?? '',
      reportedUserId: data['reportedUserId'] as String? ?? '',
      reportedHandle: data['reportedHandle'] as String? ?? '',
      reason: UserReportReason.fromString(data['reason'] as String?),
      details: data['details'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedAccountDeleted: data['reportedAccountDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterUserId': reporterUserId,
      'reportedUserId': reportedUserId,
      'reportedHandle': reportedAccountDeleted
          ? DeletedAccountMarkers.reportedHandle
          : reportedHandle,
      'reason': reason.value,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
      'reportedAccountDeleted': reportedAccountDeleted,
    };
  }
}
