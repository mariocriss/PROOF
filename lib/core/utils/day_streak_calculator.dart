import 'package:proof/shared/models/proof_model.dart';

class DayStreakCalculator {
  DayStreakCalculator._();

  static int calculate(List<ProofModel> proofs) {
    if (proofs.isEmpty) return 0;

    final dates = proofs.map((p) => _dateOnly(p.recordedAt)).toSet();
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (!dates.contains(today) && !dates.contains(yesterday)) {
      return 0;
    }

    var streak = 0;
    var cursor = dates.contains(today) ? today : yesterday;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
