import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/timeline/domain/timeline_view_data.dart';
import 'package:proof/shared/models/timeline_event.dart';

void main() {
  TimelineEvent event({
    required String id,
    required TimelineEventType type,
    required DateTime createdAt,
    String title = 'Event',
  }) {
    return TimelineEvent(
      id: id,
      userId: 'u1',
      type: type,
      title: title,
      createdAt: createdAt,
    );
  }

  test('filter proofs returns only personal bests', () {
    final events = [
      event(
        id: '1',
        type: TimelineEventType.personalBest,
        createdAt: DateTime(2026, 7, 8),
      ),
      event(
        id: '2',
        type: TimelineEventType.coachVerified,
        createdAt: DateTime(2026, 7, 7),
      ),
    ];

    final filtered =
        TimelineViewData.filter(events, TimelineFilter.proofs);

    expect(filtered.length, 1);
    expect(filtered.first.type, TimelineEventType.personalBest);
  });

  test('groupByMonth creates month headings', () {
    final events = [
      event(id: '1', type: TimelineEventType.milestone, createdAt: DateTime(2026, 7, 8)),
      event(id: '2', type: TimelineEventType.milestone, createdAt: DateTime(2026, 6, 20)),
    ];

    final groups = TimelineViewData.groupByMonth(events);

    expect(groups.length, 2);
    expect(groups.first.label, 'July 2026');
    expect(groups.last.label, 'June 2026');
  });

  test('isMajorEvent marks personal bests as major', () {
    final pb = event(
      id: '1',
      type: TimelineEventType.personalBest,
      createdAt: DateTime.now(),
    );

    expect(TimelineViewData.isMajorEvent(pb), isTrue);
  });
}
