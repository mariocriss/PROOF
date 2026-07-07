class MeasurementUnits {
  MeasurementUnits._();

  static const reps = 'reps';
  static const kg = 'kg';
  static const lbs = 'lbs';
  static const m = 'm';
  static const km = 'km';
  static const mi = 'mi';
  static const time = 'time';
  static const kcal = 'kcal';
  static const points = 'points';
  static const percent = 'percent';

  static const all = [
    reps,
    kg,
    lbs,
    m,
    km,
    mi,
    time,
    kcal,
    points,
    percent,
  ];

  static String label(String unit) {
    switch (unit) {
      case reps:
        return 'reps';
      case kg:
        return 'kg';
      case lbs:
        return 'lbs';
      case m:
        return 'm';
      case km:
        return 'km';
      case mi:
        return 'mi';
      case time:
        return 'time (hh:mm:ss)';
      case kcal:
        return 'kcal';
      case points:
        return 'points';
      case percent:
        return '%';
      default:
        return unit;
    }
  }

  static bool isTimeUnit(String unit) => unit == time;
}
