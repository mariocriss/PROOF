enum PerformanceType {
  maxValue('max_value'),
  maxReps('max_reps'),
  fastestTime('fastest_time'),
  longestDuration('longest_duration'),
  longestDistance('longest_distance'),
  highestScore('highest_score');

  const PerformanceType(this.value);
  final String value;

  static PerformanceType fromString(String? value) {
    return PerformanceType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => PerformanceType.maxValue,
    );
  }

  bool get higherIsBetter {
    switch (this) {
      case PerformanceType.fastestTime:
        return false;
      case PerformanceType.maxValue:
      case PerformanceType.maxReps:
      case PerformanceType.longestDuration:
      case PerformanceType.longestDistance:
      case PerformanceType.highestScore:
        return true;
    }
  }

  String get label {
    switch (this) {
      case PerformanceType.maxValue:
        return 'Max value';
      case PerformanceType.maxReps:
        return 'Max reps';
      case PerformanceType.fastestTime:
        return 'Fastest time';
      case PerformanceType.longestDuration:
        return 'Longest duration';
      case PerformanceType.longestDistance:
        return 'Longest distance';
      case PerformanceType.highestScore:
        return 'Highest score';
    }
  }
}
