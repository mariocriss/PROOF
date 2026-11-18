import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/features/experience/domain/experience_status.dart';

class ExperienceReceipt {
  const ExperienceReceipt({
    required this.id,
    required this.ownerId,
    required this.eventType,
    required this.sourceId,
    required this.importance,
    required this.status,
    required this.createdAt,
    this.shownAt,
    this.completedAt,
    this.dismissedAt,
    this.schemaVersion = 1,
  });

  final String id;
  final String ownerId;
  final ExperienceEventType eventType;
  final String sourceId;
  final ExperienceImportance importance;
  final ExperienceStatus status;
  final DateTime createdAt;
  final DateTime? shownAt;
  final DateTime? completedAt;
  final DateTime? dismissedAt;
  final int schemaVersion;

  bool get isTerminal => status.isTerminal;

  ExperienceReceipt copyWith({
    ExperienceStatus? status,
    DateTime? shownAt,
    DateTime? completedAt,
    DateTime? dismissedAt,
  }) {
    return ExperienceReceipt(
      id: id,
      ownerId: ownerId,
      eventType: eventType,
      sourceId: sourceId,
      importance: importance,
      status: status ?? this.status,
      createdAt: createdAt,
      shownAt: shownAt ?? this.shownAt,
      completedAt: completedAt ?? this.completedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      schemaVersion: schemaVersion,
    );
  }

  factory ExperienceReceipt.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ExperienceReceipt(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      eventType: ExperienceEventType.fromString(data['eventType'] as String?),
      sourceId: data['sourceId'] as String? ?? '',
      importance: ExperienceImportance.fromString(data['importance'] as String?),
      status: ExperienceStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shownAt: (data['shownAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      dismissedAt: (data['dismissedAt'] as Timestamp?)?.toDate(),
      schemaVersion: data['schemaVersion'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'eventType': eventType.value,
      'sourceId': sourceId,
      'importance': importance.label,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      if (shownAt != null) 'shownAt': Timestamp.fromDate(shownAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (dismissedAt != null) 'dismissedAt': Timestamp.fromDate(dismissedAt!),
      'schemaVersion': schemaVersion,
    };
  }

  Map<String, dynamic> toCreateFirestore({required bool useServerTimestamp}) {
    return {
      'ownerId': ownerId,
      'eventType': eventType.value,
      'sourceId': sourceId,
      'importance': importance.label,
      'status': status.value,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'schemaVersion': schemaVersion,
    };
  }
}
