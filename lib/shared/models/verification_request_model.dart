import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const VerificationRequestStatus(this.value);

  final String value;

  static VerificationRequestStatus fromString(String? value) {
    return VerificationRequestStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => VerificationRequestStatus.pending,
    );
  }
}

class VerificationRequestModel {
  const VerificationRequestModel({
    required this.id,
    required this.proofId,
    required this.athleteId,
    required this.coachId,
    required this.skillId,
    required this.status,
    required this.createdAt,
    this.message = '',
    this.reviewedAt,
    this.rejectionNote = '',
    this.skillName = '',
    this.resultLabel = '',
    this.mediaUrl,
    this.recordedAt,
  });

  final String id;
  final String proofId;
  final String athleteId;
  final String coachId;
  final String skillId;
  final VerificationRequestStatus status;
  final String message;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String rejectionNote;
  final String skillName;
  final String resultLabel;
  final String? mediaUrl;
  final DateTime? recordedAt;

  factory VerificationRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return VerificationRequestModel(
      id: doc.id,
      proofId: data['proofId'] as String? ?? '',
      athleteId: data['athleteId'] as String? ?? '',
      coachId: data['coachId'] as String? ?? '',
      skillId: data['skillId'] as String? ?? '',
      status: VerificationRequestStatus.fromString(data['status'] as String?),
      message: data['message'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      rejectionNote: data['rejectionNote'] as String? ?? '',
      skillName: data['skillName'] as String? ?? '',
      resultLabel: data['resultLabel'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'proofId': proofId,
      'athleteId': athleteId,
      'coachId': coachId,
      'skillId': skillId,
      'status': status.value,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionNote': rejectionNote,
      'skillName': skillName,
      'resultLabel': resultLabel,
      'mediaUrl': mediaUrl,
      'recordedAt':
          recordedAt != null ? Timestamp.fromDate(recordedAt!) : null,
    };
  }
}
