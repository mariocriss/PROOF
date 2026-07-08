/// Staged trust bar: 10 segments always, max proof count per stage scales up.
class TrustStageProgress {
  TrustStageProgress._();

  static const segmentCount = 10;
  static const stages = [10, 20, 100, 500, 1000];

  /// When [proofCount] exactly completes a stage, progress rolls into the next stage.
  static int stageMaxFor(int proofCount) {
    if (proofCount <= 0) return stages.first;

    for (var i = 0; i < stages.length; i++) {
      final stage = stages[i];
      if (proofCount < stage) return stage;
      if (proofCount == stage) {
        return i + 1 < stages.length ? stages[i + 1] : stage * 10;
      }
    }

    var max = stages.last;
    while (proofCount > max) {
      final next = max * 10;
      if (proofCount < next) return next;
      if (proofCount == max) return next;
      max = next;
    }
    return max;
  }

  static int filledSegmentsFor(int proofCount) {
    if (proofCount <= 0) return 0;

    final stageMax = stageMaxFor(proofCount);
    return ((proofCount / stageMax) * segmentCount).round().clamp(0, segmentCount);
  }
}
