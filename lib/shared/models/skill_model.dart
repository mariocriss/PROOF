import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/skill_status.dart';

class SkillModel {
  const SkillModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.discipline,
    required this.createdAt,
    required this.defaultUnit,
    required this.allowedUnits,
    required this.measurementType,
    required this.performanceType,
    this.description = '',
    this.catalogId,
    this.currentBest,
    this.currentBestUnit,
    this.normalizedBestValue,
    this.targetValue,
    this.targetUnit,
    this.status = SkillStatus.active,
    this.aliases = const [],
    this.tags = const [],
    this.isFeatured = false,
    this.stackConfidence,
  });

  final String id;
  final String userId;
  final String name;
  final String discipline;
  final String description;
  final String defaultUnit;
  final List<String> allowedUnits;
  final MeasurementType measurementType;
  final PerformanceType performanceType;
  final String? catalogId;
  final String? currentBest;
  final String? currentBestUnit;
  final double? normalizedBestValue;
  final String? targetValue;
  final String? targetUnit;
  final SkillStatus status;
  final List<String> aliases;
  final List<String> tags;
  final bool isFeatured;
  final StackConfidence? stackConfidence;
  final DateTime createdAt;

  bool get hasMultipleUnits => allowedUnits.length > 1;

  String? get formattedCurrentBest {
    if (currentBest == null || currentBest!.isEmpty) return null;
    final unit = currentBestUnit ?? defaultUnit;
    return '$currentBest $unit';
  }

  String? get formattedTarget {
    if (targetValue == null || targetValue!.isEmpty) return null;
    final unit = targetUnit ?? defaultUnit;
    return '$targetValue $unit';
  }

  factory SkillModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SkillModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      discipline: data['discipline'] as String? ??
          data['category'] as String? ??
          'Other',
      description: data['description'] as String? ?? '',
      defaultUnit: data['defaultUnit'] as String? ?? 'reps',
      allowedUnits: List<String>.from(
        data['allowedUnits'] as List? ?? ['reps'],
      ),
      measurementType: MeasurementType.fromString(
        data['measurementType'] as String? ?? data['resultType'] as String?,
      ),
      performanceType: PerformanceType.fromString(
        data['performanceType'] as String?,
      ),
      catalogId: data['catalogId'] as String?,
      currentBest: data['currentBest'] as String?,
      currentBestUnit: data['currentBestUnit'] as String?,
      normalizedBestValue: (data['normalizedBestValue'] as num?)?.toDouble() ??
          (data['normalizedKg'] as num?)?.toDouble() ??
          (data['normalizedMetricValue'] as num?)?.toDouble(),
      targetValue: data['targetValue'] as String?,
      targetUnit: data['targetUnit'] as String?,
      status: SkillStatus.fromString(data['status'] as String?),
      aliases: List<String>.from(data['aliases'] as List? ?? []),
      tags: List<String>.from(data['tags'] as List? ?? []),
      isFeatured: data['isFeatured'] as bool? ?? false,
      stackConfidence: data['stackConfidence'] != null
          ? StackConfidence.fromString(data['stackConfidence'] as String?)
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'discipline': discipline,
      'description': description,
      'defaultUnit': defaultUnit,
      'allowedUnits': allowedUnits,
      'measurementType': measurementType.value,
      'performanceType': performanceType.value,
      'catalogId': catalogId,
      'currentBest': currentBest,
      'currentBestUnit': currentBestUnit,
      'normalizedBestValue': normalizedBestValue,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'status': status.value,
      'aliases': aliases,
      'tags': tags,
      'isFeatured': isFeatured,
      'stackConfidence': stackConfidence?.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SkillModel copyWith({
    String? currentBest,
    String? currentBestUnit,
    double? normalizedBestValue,
    SkillStatus? status,
    StackConfidence? stackConfidence,
  }) {
    return SkillModel(
      id: id,
      userId: userId,
      name: name,
      discipline: discipline,
      description: description,
      defaultUnit: defaultUnit,
      allowedUnits: allowedUnits,
      measurementType: measurementType,
      performanceType: performanceType,
      catalogId: catalogId,
      currentBest: currentBest ?? this.currentBest,
      currentBestUnit: currentBestUnit ?? this.currentBestUnit,
      normalizedBestValue: normalizedBestValue ?? this.normalizedBestValue,
      targetValue: targetValue,
      targetUnit: targetUnit,
      status: status ?? this.status,
      aliases: aliases,
      tags: tags,
      isFeatured: isFeatured,
      stackConfidence: stackConfidence ?? this.stackConfidence,
      createdAt: createdAt,
    );
  }
}
