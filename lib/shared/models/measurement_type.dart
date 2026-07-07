enum MeasurementType {
  count('count'),
  weight('weight'),
  distance('distance'),
  duration('duration'),
  score('score'),
  calories('calories'),
  percentage('percentage');

  const MeasurementType(this.value);
  final String value;

  static MeasurementType fromString(String? value) {
    return MeasurementType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => MeasurementType.count,
    );
  }

  String get label {
    switch (this) {
      case MeasurementType.count:
        return 'Count';
      case MeasurementType.weight:
        return 'Weight';
      case MeasurementType.distance:
        return 'Distance';
      case MeasurementType.duration:
        return 'Duration';
      case MeasurementType.score:
        return 'Score';
      case MeasurementType.calories:
        return 'Calories';
      case MeasurementType.percentage:
        return 'Percentage';
    }
  }
}
