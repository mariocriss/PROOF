import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';

/// Presentation context — never stores private proof body content.
class ExperienceContext {
  const ExperienceContext({
    this.userId = '',
    this.displayName = '',
    this.handle = '',
    this.skillName = '',
    this.proofId = '',
    this.proofResult = '',
    this.proofUnit = '',
    this.proofDate,
    this.coachName = '',
    this.coachInitials = '',
    this.verificationDate,
    this.verificationRequestId = '',
    this.sourceId = '',
    this.extra = const {},
  });

  final String userId;
  final String displayName;
  final String handle;
  final String skillName;
  final String proofId;
  final String proofResult;
  final String proofUnit;
  final DateTime? proofDate;
  final String coachName;
  final String coachInitials;
  final DateTime? verificationDate;
  final String verificationRequestId;
  final String sourceId;
  final Map<String, String> extra;

  String get formattedResult {
    final r = proofResult.trim();
    final u = proofUnit.trim();
    if (r.isEmpty) return '';
    if (u.isEmpty) return r;
    return '$r $u';
  }

  ExperienceContext copyWith({
    String? userId,
    String? displayName,
    String? handle,
    String? skillName,
    String? proofId,
    String? proofResult,
    String? proofUnit,
    DateTime? proofDate,
    String? coachName,
    String? coachInitials,
    DateTime? verificationDate,
    String? verificationRequestId,
    String? sourceId,
    Map<String, String>? extra,
  }) {
    return ExperienceContext(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      skillName: skillName ?? this.skillName,
      proofId: proofId ?? this.proofId,
      proofResult: proofResult ?? this.proofResult,
      proofUnit: proofUnit ?? this.proofUnit,
      proofDate: proofDate ?? this.proofDate,
      coachName: coachName ?? this.coachName,
      coachInitials: coachInitials ?? this.coachInitials,
      verificationDate: verificationDate ?? this.verificationDate,
      verificationRequestId:
          verificationRequestId ?? this.verificationRequestId,
      sourceId: sourceId ?? this.sourceId,
      extra: extra ?? this.extra,
    );
  }
}

class ExperienceEvent {
  const ExperienceEvent({
    required this.id,
    required this.type,
    required this.importance,
    required this.ownerId,
    required this.sourceId,
    required this.context,
    this.createdAt,
  });

  final String id;
  final ExperienceEventType type;
  final ExperienceImportance importance;
  final String ownerId;
  final String sourceId;
  final ExperienceContext context;
  final DateTime? createdAt;
}
