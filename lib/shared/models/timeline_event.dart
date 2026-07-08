import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';

enum TimelineEventType {
  identity('identity'),
  milestone('milestone'),
  personalBest('personal_best'),
  coachVerified('coach_verified'),
  competition('competition'),
  confidence('confidence'),
  achievement('achievement');

  const TimelineEventType(this.value);

  final String value;

  static TimelineEventType fromString(String value) {
    final normalized = value.trim().toLowerCase();
    for (final type in TimelineEventType.values) {
      if (type.value == normalized) return type;
    }
    return _legacyType(normalized);
  }

  static TimelineEventType _legacyType(String value) {
    switch (value) {
      case 'identity_created':
        return TimelineEventType.identity;
      case 'skill_added':
        return TimelineEventType.milestone;
      case 'proof_added':
        return TimelineEventType.personalBest;
      case 'profile_updated':
        return TimelineEventType.milestone;
      default:
        return TimelineEventType.milestone;
    }
  }

  IconData get icon {
    switch (this) {
      case TimelineEventType.identity:
        return Icons.badge_outlined;
      case TimelineEventType.milestone:
        return Icons.flag_outlined;
      case TimelineEventType.personalBest:
        return Icons.trending_up_rounded;
      case TimelineEventType.coachVerified:
        return Icons.verified_outlined;
      case TimelineEventType.competition:
        return Icons.emoji_events_outlined;
      case TimelineEventType.confidence:
        return Icons.insights_outlined;
      case TimelineEventType.achievement:
        return Icons.military_tech_outlined;
    }
  }

  Color get accentColor {
    switch (this) {
      case TimelineEventType.identity:
        return AppColors.accent;
      case TimelineEventType.milestone:
        return AppColors.inkSecondary;
      case TimelineEventType.personalBest:
        return AppColors.accent;
      case TimelineEventType.coachVerified:
        return AppColors.confidenceStrong;
      case TimelineEventType.competition:
        return AppColors.confidenceTrusted;
      case TimelineEventType.confidence:
        return AppColors.confidenceEstablished;
      case TimelineEventType.achievement:
        return AppColors.confidenceDeveloping;
    }
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
    this.milestoneKey,
  });

  final String id;
  final String userId;
  final TimelineEventType type;
  final String title;
  final String subtitle;
  final String? referenceId;
  final String? milestoneKey;
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
      milestoneKey: data['milestoneKey'] as String?,
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
      'milestoneKey': milestoneKey,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
