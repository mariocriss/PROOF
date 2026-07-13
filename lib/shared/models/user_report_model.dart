import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String id;
  final String reporterUserId;
  final String reportedUserId;
  final String reportedHandle;
  final UserReportReason reason;
  final String details;
  final DateTime createdAt;

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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterUserId': reporterUserId,
      'reportedUserId': reportedUserId,
      'reportedHandle': reportedHandle,
      'reason': reason.value,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
