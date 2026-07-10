import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/confidence_progress_segments.dart';
import 'package:proof/shared/models/confidence_level.dart';

void main() {
  test('returns zero filled segments when there are no proofs', () {
    expect(
      ConfidenceProgressSegments.filledFor(
        StackConfidence.limitedEvidence,
        proofCount: 0,
      ),
      0,
    );
    expect(
      ConfidenceProgressSegments.filledFor(
        StackConfidence.trusted,
        proofCount: 0,
      ),
      0,
    );
  });

  test('fills segments from confidence when proofs exist', () {
    expect(
      ConfidenceProgressSegments.filledFor(
        StackConfidence.limitedEvidence,
        proofCount: 1,
      ),
      2,
    );
    expect(
      ConfidenceProgressSegments.filledFor(
        StackConfidence.developing,
        proofCount: 3,
      ),
      4,
    );
  });
}
