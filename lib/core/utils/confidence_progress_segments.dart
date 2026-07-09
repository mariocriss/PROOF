import 'package:proof/shared/models/confidence_level.dart';

class ConfidenceProgressSegments {
  ConfidenceProgressSegments._();

  static const segmentCount = 8;

  static int filledFor(StackConfidence confidence) {
    return switch (confidence) {
      StackConfidence.limitedEvidence => 2,
      StackConfidence.developing => 4,
      StackConfidence.established => 5,
      StackConfidence.strong => 7,
      StackConfidence.trusted => 8,
    };
  }
}
