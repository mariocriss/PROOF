import 'package:intl/intl.dart';
import 'package:proof/shared/models/timeline_event.dart';

enum TimelineFilter {
  all('All'),
  proofs('Proofs'),
  milestones('Milestones'),
  verifications('Verifications');

  const TimelineFilter(this.label);
  final String label;
}

class TimelineMonthGroup {
  const TimelineMonthGroup({
    required this.label,
    required this.events,
  });

  final String label;
  final List<TimelineEvent> events;
}

class TimelineViewData {
  TimelineViewData._();

  static List<TimelineEvent> filter(
    List<TimelineEvent> events,
    TimelineFilter filter,
  ) {
    final sorted = List<TimelineEvent>.from(events)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return switch (filter) {
      TimelineFilter.all => sorted,
      TimelineFilter.proofs =>
        sorted.where((e) => e.type == TimelineEventType.personalBest).toList(),
      TimelineFilter.milestones => sorted
          .where(
            (e) =>
                e.type == TimelineEventType.milestone ||
                e.type == TimelineEventType.achievement ||
                e.type == TimelineEventType.identity ||
                e.type == TimelineEventType.confidence,
          )
          .toList(),
      TimelineFilter.verifications => sorted
          .where((e) => e.type == TimelineEventType.coachVerified)
          .toList(),
    };
  }

  static List<TimelineMonthGroup> groupByMonth(List<TimelineEvent> events) {
    if (events.isEmpty) return const [];

    final groups = <TimelineMonthGroup>[];
    final monthFormat = DateFormat('MMMM yyyy');

    List<TimelineEvent> currentEvents = [];
    String? currentLabel;

    for (final event in events) {
      final label = monthFormat.format(event.createdAt);
      if (label != currentLabel) {
        if (currentLabel != null && currentEvents.isNotEmpty) {
          groups.add(
            TimelineMonthGroup(label: currentLabel, events: currentEvents),
          );
        }
        currentLabel = label;
        currentEvents = [event];
      } else {
        currentEvents.add(event);
      }
    }

    if (currentLabel != null && currentEvents.isNotEmpty) {
      groups.add(TimelineMonthGroup(label: currentLabel, events: currentEvents));
    }

    return groups;
  }

  static bool isMajorEvent(TimelineEvent event) {
    switch (event.type) {
      case TimelineEventType.identity:
      case TimelineEventType.personalBest:
      case TimelineEventType.coachVerified:
      case TimelineEventType.confidence:
        return true;
      case TimelineEventType.achievement:
        return true;
      case TimelineEventType.milestone:
        return event.milestoneKey == 'first_proof' ||
            event.milestoneKey == 'first_skill' ||
            event.title.toLowerCase().contains('started tracking');
      case TimelineEventType.competition:
        return true;
    }
  }

  static bool subtitleUsesAccent(TimelineEvent event) {
    if (event.subtitle.isEmpty) return false;
    return event.type == TimelineEventType.personalBest ||
        event.type == TimelineEventType.coachVerified ||
        event.subtitle.contains('reps') ||
        event.subtitle.contains('kg') ||
        event.subtitle.contains('lbs');
  }
}
