import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/core/utils/result_formatter.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/verification_status.dart';

class ProofModel {
  const ProofModel({
    required this.id,
    required this.userId,
    required this.skillId,
    required this.title,
    required this.recordedAt,
    required this.createdAt,
    required this.result,
    required this.unit,
    required this.proofSource,
    this.verificationStatus = VerificationStatus.selfReported,
    this.coachId,
    this.requestedCoachId,
    this.verificationGymId,
    this.verifiedByCoachId,
    this.verifiedAt,
    this.rejectionNote = '',
    this.notes = '',
    this.mediaUrl,
    this.originalResult,
    this.originalUnit,
    this.normalizedValue,
    this.location = '',
    this.variantId,
    this.variantName,
  });

  final String id;
  final String userId;
  final String skillId;
  final String title;
  final String result;
  final String unit;
  final String notes;
  final String? mediaUrl;
  final ProofSource proofSource;
  final VerificationStatus verificationStatus;
  final String? coachId;
  final String? requestedCoachId;
  final String? verificationGymId;
  final String? verifiedByCoachId;
  final DateTime? verifiedAt;
  final String rejectionNote;
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? originalResult;
  final String? originalUnit;
  final double? normalizedValue;
  final String location;
  final String? variantId;
  final String? variantName;

  bool get isCoachVerifiedForStack {
    if (verificationStatus == VerificationStatus.coachVerified) return true;
    if (verificationStatus == VerificationStatus.pendingVerification ||
        verificationStatus == VerificationStatus.rejected ||
        verificationStatus == VerificationStatus.declined) {
      return false;
    }
    return proofSource == ProofSource.coach;
  }

  String get verificationLabel {
    if (verificationStatus == VerificationStatus.pendingVerification) {
      return 'Awaiting coach review';
    }
    if (verificationStatus == VerificationStatus.rejected ||
        verificationStatus == VerificationStatus.declined) {
      return 'Verification declined';
    }
    if (isCoachVerifiedForStack) return ProofSource.coach.label;
    return ProofSource.selfReported.label;
  }

  String get formattedResult => ResultFormatter.display(
        result.isNotEmpty ? result : (originalResult ?? title),
        unit.isNotEmpty ? unit : (originalUnit ?? ''),
      );

  factory ProofModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final legacyResult = data['originalResult'] as String? ?? '';
    final legacySource = data['source'] as String? ?? data['confidence'] as String?;
    final proofSource = ProofSource.fromString(
      data['proofSource'] as String? ?? legacySource,
    );
    final verificationStatus = VerificationStatus.fromString(
      data['verificationStatus'] as String?,
    );
    final resolvedStatus = data['verificationStatus'] == null &&
            proofSource == ProofSource.coach
        ? VerificationStatus.coachVerified
        : verificationStatus;

    return ProofModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      skillId: data['skillId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      result: data['result'] as String? ?? legacyResult,
      unit: data['unit'] as String? ?? data['originalUnit'] as String? ?? '',
      notes: data['notes'] as String? ?? data['description'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      proofSource: proofSource,
      verificationStatus: resolvedStatus,
      coachId: data['coachId'] as String?,
      requestedCoachId: data['requestedCoachId'] as String? ?? data['coachId'] as String?,
      verificationGymId: data['verificationGymId'] as String?,
      verifiedByCoachId: data['verifiedByCoachId'] as String?,
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      rejectionNote: data['rejectionNote'] as String? ?? '',
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      originalResult: data['originalResult'] as String? ?? legacyResult,
      originalUnit: data['originalUnit'] as String?,
      normalizedValue: (data['normalizedValue'] as num?)?.toDouble() ??
          (data['normalizedKg'] as num?)?.toDouble() ??
          (data['normalizedMetricValue'] as num?)?.toDouble(),
      location: data['location'] as String? ?? '',
      variantId: data['variantId'] as String?,
      variantName: data['variantName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'skillId': skillId,
      'title': title,
      'result': result,
      'unit': unit,
      'notes': notes,
      'mediaUrl': mediaUrl,
      'proofSource': proofSource.value,
      'verificationStatus': verificationStatus.value,
      'coachId': coachId,
      'requestedCoachId': requestedCoachId ?? coachId,
      'verificationGymId': verificationGymId,
      'verifiedByCoachId': verifiedByCoachId,
      'verifiedAt':
          verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'rejectionNote': rejectionNote,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'originalResult': originalResult ?? result,
      'originalUnit': originalUnit ?? unit,
      'normalizedValue': normalizedValue,
      'location': location,
      'variantId': variantId,
      'variantName': variantName,
    };
  }

  ProofModel copyWith({
    ProofSource? proofSource,
    VerificationStatus? verificationStatus,
    String? coachId,
    String? requestedCoachId,
    String? verificationGymId,
    String? verifiedByCoachId,
    DateTime? verifiedAt,
    String? rejectionNote,
  }) {
    return ProofModel(
      id: id,
      userId: userId,
      skillId: skillId,
      title: title,
      result: result,
      unit: unit,
      notes: notes,
      mediaUrl: mediaUrl,
      proofSource: proofSource ?? this.proofSource,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      coachId: coachId ?? this.coachId,
      requestedCoachId: requestedCoachId ?? this.requestedCoachId,
      verificationGymId: verificationGymId ?? this.verificationGymId,
      verifiedByCoachId: verifiedByCoachId ?? this.verifiedByCoachId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionNote: rejectionNote ?? this.rejectionNote,
      recordedAt: recordedAt,
      createdAt: createdAt,
      originalResult: originalResult,
      originalUnit: originalUnit,
      normalizedValue: normalizedValue,
      location: location,
      variantId: variantId,
      variantName: variantName,
    );
  }
}
