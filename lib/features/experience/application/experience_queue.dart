import 'dart:collection';

import 'package:proof/features/experience/domain/experience_event.dart';

/// Serial presentation queue — one experience at a time.
class ExperienceQueue {
  final Queue<ExperienceEvent> _pending = Queue<ExperienceEvent>();
  ExperienceEvent? _active;
  final Set<String> _seenIds = {};

  ExperienceEvent? get active => _active;

  bool get isEmpty => _pending.isEmpty && _active == null;

  int get length => _pending.length + (_active == null ? 0 : 1);

  /// Enqueue if not already queued/active. Duplicate IDs are ignored.
  bool enqueue(ExperienceEvent event) {
    if (_seenIds.contains(event.id)) return false;
    if (_active?.id == event.id) return false;
    if (_pending.any((e) => e.id == event.id)) return false;
    _seenIds.add(event.id);
    _pending.add(event);
    return true;
  }

  ExperienceEvent? dequeueNext() {
    if (_active != null) return null;
    if (_pending.isEmpty) return null;
    _active = _pending.removeFirst();
    return _active;
  }

  void clearActive() {
    _active = null;
  }

  void clearAll() {
    _pending.clear();
    _active = null;
    _seenIds.clear();
  }

  /// Allow re-queue after gallery reset (removes id from seen set).
  void forget(String eventId) {
    _seenIds.remove(eventId);
    _pending.removeWhere((e) => e.id == eventId);
    if (_active?.id == eventId) _active = null;
  }
}
