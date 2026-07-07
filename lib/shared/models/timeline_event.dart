import 'package:cloud_firestore/cloud_firestore.dart';

enum TimelineEventType {
  identityCreated('identity_created'),
  skillAdded('skill_added'),
  proofAdded('proof_added'),
  profileUpdated('profile_updated');

  const TimelineEventType(this.value);
  final String value;

  static TimelineEventType fromString(String value) {
    return TimelineEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TimelineEventType.proofAdded,
    );
  }
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.createdAt,
    this.subtitle = '',
    this.referenceId,
  });

  final String id;
  final String userId;
  final TimelineEventType type;
  final String title;
  final String subtitle;
  final String? referenceId;
  final DateTime createdAt;

  factory TimelineEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return TimelineEvent(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: TimelineEventType.fromString(data['type'] as String? ?? ''),
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      referenceId: data['referenceId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.value,
      'title': title,
      'subtitle': subtitle,
      'referenceId': referenceId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
