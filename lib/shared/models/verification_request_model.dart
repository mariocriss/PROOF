import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationRequestStatus {
  pending('pending'),
  approved('approved'),
  declined('declined'),
  cancelled('cancelled'),
  rejected('rejected');

  const VerificationRequestStatus(this.value);

  final String value;

  static VerificationRequestStatus fromString(String? value) {
    if (value == null || value.isEmpty) {
      return VerificationRequestStatus.pending;
    }
    return VerificationRequestStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => VerificationRequestStatus.pending,
    );
  }

  bool get isTerminal => switch (this) {
        VerificationRequestStatus.approved ||
        VerificationRequestStatus.declined ||
        VerificationRequestStatus.cancelled ||
        VerificationRequestStatus.rejected =>
          true,
        _ => false,
      };
}

class VerificationRequestModel {
  const VerificationRequestModel({
    required this.id,
    required this.proofId,
    required this.athleteId,
    required this.coachId,
    required this.gymId,
    required this.skillId,
    required this.status,
    required this.createdAt,
    this.message = '',
    this.reviewedAt,
    this.declineReason = '',
    this.rejectionNote = '',
    this.skillName = '',
    this.resultLabel = '',
    this.mediaUrl,
    this.recordedAt,
    this.location = '',
    this.variantName = '',
  });

  final String id;
  final String proofId;
  final String athleteId;
  final String coachId;
  final String gymId;
  final String skillId;
  final VerificationRequestStatus status;
  final String message;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String declineReason;
  final String rejectionNote;
  final String skillName;
  final String resultLabel;
  final String? mediaUrl;
  final DateTime? recordedAt;
  final String location;
  final String variantName;

  String get displayDeclineReason =>
      declineReason.isNotEmpty ? declineReason : rejectionNote;

  factory VerificationRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return VerificationRequestModel(
      id: doc.id,
      proofId: data['proofId'] as String? ?? '',
      athleteId: data['athleteId'] as String? ?? '',
      coachId: data['coachId'] as String? ?? '',
      gymId: data['gymId'] as String? ?? '',
      skillId: data['skillId'] as String? ?? '',
      status: VerificationRequestStatus.fromString(data['status'] as String?),
      message: data['message'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      declineReason: data['declineReason'] as String? ??
          data['rejectionNote'] as String? ??
          '',
      rejectionNote: data['rejectionNote'] as String? ?? '',
      skillName: data['skillName'] as String? ?? '',
      resultLabel: data['resultLabel'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate(),
      location: data['location'] as String? ?? '',
      variantName: data['variantName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'proofId': proofId,
      'athleteId': athleteId,
      'coachId': coachId,
      'gymId': gymId,
      'skillId': skillId,
      'status': status.value,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'declineReason': declineReason,
      'rejectionNote': rejectionReasonFallback,
      'skillName': skillName,
      'resultLabel': resultLabel,
      'mediaUrl': mediaUrl,
      'recordedAt':
          recordedAt != null ? Timestamp.fromDate(recordedAt!) : null,
      'location': location,
      'variantName': variantName,
    };
  }

  String get rejectionReasonFallback =>
      declineReason.isNotEmpty ? declineReason : rejectionNote;
}
