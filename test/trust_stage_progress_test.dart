import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/trust_stage_progress.dart';

void main() {
  test('stage max rolls into next stage when a milestone is completed', () {
    expect(TrustStageProgress.stageMaxFor(3), 10);
    expect(TrustStageProgress.stageMaxFor(9), 10);
    expect(TrustStageProgress.stageMaxFor(10), 20);
    expect(TrustStageProgress.stageMaxFor(11), 20);
    expect(TrustStageProgress.stageMaxFor(19), 20);
    expect(TrustStageProgress.stageMaxFor(20), 100);
    expect(TrustStageProgress.stageMaxFor(21), 100);
    expect(TrustStageProgress.stageMaxFor(100), 500);
    expect(TrustStageProgress.stageMaxFor(101), 500);
  });

  test('filled segments scale within each stage', () {
    expect(TrustStageProgress.filledSegmentsFor(3), 3);
    expect(TrustStageProgress.filledSegmentsFor(9), 9);
    expect(TrustStageProgress.filledSegmentsFor(10), 5);
    expect(TrustStageProgress.filledSegmentsFor(11), 6);
    expect(TrustStageProgress.filledSegmentsFor(20), 2);
    expect(TrustStageProgress.filledSegmentsFor(21), 2);
    expect(TrustStageProgress.filledSegmentsFor(100), 2);
  });
}
