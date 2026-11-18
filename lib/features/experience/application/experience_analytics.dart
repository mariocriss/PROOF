import 'package:proof/features/experience/domain/experience_event_type.dart';

/// Lightweight analytics hook — no-op in production until wired.
abstract class ExperienceAnalytics {
  void trackPresented({
    required ExperienceEventType type,
    required String eventId,
  });

  void trackCompleted({
    required ExperienceEventType type,
    required String eventId,
  });

  void trackDismissed({
    required ExperienceEventType type,
    required String eventId,
  });

  void trackFailed({
    required ExperienceEventType type,
    required String eventId,
    String? reason,
  });
}

class NoOpExperienceAnalytics implements ExperienceAnalytics {
  const NoOpExperienceAnalytics();

  @override
  void trackPresented({
    required ExperienceEventType type,
    required String eventId,
  }) {}

  @override
  void trackCompleted({
    required ExperienceEventType type,
    required String eventId,
  }) {}

  @override
  void trackDismissed({
    required ExperienceEventType type,
    required String eventId,
  }) {}

  @override
  void trackFailed({
    required ExperienceEventType type,
    required String eventId,
    String? reason,
  }) {}
}
