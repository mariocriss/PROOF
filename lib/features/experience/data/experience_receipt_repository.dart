import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/features/experience/domain/experience_status.dart';

abstract class ExperienceReceiptRepository {
  Future<ExperienceReceipt?> get(String ownerId, String eventId);

  /// Creates receipt only if absent. Returns existing if already present.
  Future<ExperienceReceipt> claimOrGet(ExperienceReceipt draft);

  Future<void> updateStatus({
    required String ownerId,
    required String eventId,
    required ExperienceStatus status,
    DateTime? shownAt,
    DateTime? completedAt,
    DateTime? dismissedAt,
  });

  /// Bounded pending query — does not listen to full receipt history.
  Future<List<ExperienceReceipt>> listResumable(String ownerId, {int limit = 20});
}

/// In-memory store for tests and the debug Experience Gallery.
class InMemoryExperienceReceiptRepository
    implements ExperienceReceiptRepository {
  final Map<String, ExperienceReceipt> _byKey = {};

  String _key(String ownerId, String eventId) => '$ownerId::$eventId';

  void clear() => _byKey.clear();

  Map<String, ExperienceReceipt> get debugSnapshot =>
      Map.unmodifiable(_byKey);

  @override
  Future<ExperienceReceipt?> get(String ownerId, String eventId) async {
    return _byKey[_key(ownerId, eventId)];
  }

  @override
  Future<ExperienceReceipt> claimOrGet(ExperienceReceipt draft) async {
    final key = _key(draft.ownerId, draft.id);
    final existing = _byKey[key];
    if (existing != null) return existing;
    _byKey[key] = draft;
    return draft;
  }

  @override
  Future<void> updateStatus({
    required String ownerId,
    required String eventId,
    required ExperienceStatus status,
    DateTime? shownAt,
    DateTime? completedAt,
    DateTime? dismissedAt,
  }) async {
    final key = _key(ownerId, eventId);
    final existing = _byKey[key];
    if (existing == null) return;
    _byKey[key] = existing.copyWith(
      status: status,
      shownAt: shownAt,
      completedAt: completedAt,
      dismissedAt: dismissedAt,
    );
  }

  @override
  Future<List<ExperienceReceipt>> listResumable(
    String ownerId, {
    int limit = 20,
  }) async {
    return _byKey.values
        .where((r) => r.ownerId == ownerId && r.status.mayResume)
        .take(limit)
        .toList();
  }
}
