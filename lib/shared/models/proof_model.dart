import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/core/utils/result_formatter.dart';
import 'package:proof/shared/models/proof_source.dart';

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
    this.notes = '',
    this.mediaUrl,
    this.originalResult,
    this.originalUnit,
    this.normalizedValue,
    this.location = '',
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
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? originalResult;
  final String? originalUnit;
  final double? normalizedValue;
  final String location;

  String get formattedResult => ResultFormatter.display(
        result.isNotEmpty ? result : (originalResult ?? title),
        unit.isNotEmpty ? unit : (originalUnit ?? ''),
      );

  factory ProofModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final legacyResult = data['originalResult'] as String? ?? '';
    final legacySource = data['source'] as String? ?? data['confidence'] as String?;

    return ProofModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      skillId: data['skillId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      result: data['result'] as String? ?? legacyResult,
      unit: data['unit'] as String? ?? data['originalUnit'] as String? ?? '',
      notes: data['notes'] as String? ?? data['description'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      proofSource: ProofSource.fromString(
        data['proofSource'] as String? ?? legacySource,
      ),
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
      'recordedAt': Timestamp.fromDate(recordedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'originalResult': originalResult ?? result,
      'originalUnit': originalUnit ?? unit,
      'normalizedValue': normalizedValue,
      'location': location,
    };
  }
}
