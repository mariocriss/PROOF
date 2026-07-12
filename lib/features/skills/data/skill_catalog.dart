import 'package:proof/core/constants/measurement_units.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/skill_catalog_entry.dart';
import 'package:proof/shared/models/skill_catalog_variant.dart';

class SkillCatalog {
  SkillCatalog._();

  static const String customSkillId = 'custom_skill';

  static const pushUpVariants = [
    SkillCatalogVariant(id: 'standard', name: 'Standard'),
    SkillCatalogVariant(id: 'knees', name: 'On Knees'),
    SkillCatalogVariant(id: 'diamond', name: 'Diamond'),
    SkillCatalogVariant(id: 'wide', name: 'Wide Grip'),
    SkillCatalogVariant(id: 'incline', name: 'Incline'),
    SkillCatalogVariant(id: 'decline', name: 'Decline'),
    SkillCatalogVariant(id: 'archer', name: 'Archer'),
    SkillCatalogVariant(id: 'one_arm', name: 'One Arm'),
  ];

  static const pullUpVariants = [
    SkillCatalogVariant(id: 'strict', name: 'Strict'),
    SkillCatalogVariant(id: 'chin_up', name: 'Chin-up'),
    SkillCatalogVariant(id: 'neutral', name: 'Neutral Grip'),
    SkillCatalogVariant(id: 'wide', name: 'Wide Grip'),
    SkillCatalogVariant(id: 'chest_to_bar', name: 'Chest-to-Bar'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'assisted', name: 'Assisted'),
  ];

  static const squatVariants = [
    SkillCatalogVariant(id: 'air', name: 'Air Squat'),
    SkillCatalogVariant(id: 'back', name: 'Back Squat'),
    SkillCatalogVariant(id: 'front', name: 'Front Squat'),
    SkillCatalogVariant(id: 'goblet', name: 'Goblet Squat'),
    SkillCatalogVariant(id: 'overhead', name: 'Overhead Squat'),
    SkillCatalogVariant(id: 'pistol', name: 'Pistol Squat'),
  ];

  static const plankVariants = [
    SkillCatalogVariant(id: 'front', name: 'Front Plank'),
    SkillCatalogVariant(id: 'side', name: 'Side Plank'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted Plank'),
    SkillCatalogVariant(id: 'high', name: 'High Plank'),
  ];

  static SkillCatalogEntry _entry(
    String discipline,
    String name,
    MeasurementType measurementType,
    PerformanceType performanceType,
    String defaultUnit,
    List<String> allowedUnits, {
    String summary = '',
    bool supportsVariants = false,
    List<SkillCatalogVariant> variants = const [],
  }) {
    return SkillCatalogEntry(
      id: _slug(discipline, name),
      name: name,
      discipline: discipline,
      summary: summary,
      defaultUnit: defaultUnit,
      allowedUnits: allowedUnits,
      measurementType: measurementType,
      performanceType: performanceType,
      supportsVariants: supportsVariants,
      variants: variants,
    );
  }

  static SkillCatalogEntry _reps(
    String discipline,
    String name, {
    String summary = '',
    bool supportsVariants = false,
    List<SkillCatalogVariant> variants = const [],
  }) =>
      _entry(
        discipline,
        name,
        MeasurementType.count,
        PerformanceType.maxReps,
        MeasurementUnits.reps,
        [MeasurementUnits.reps],
        summary: summary,
        supportsVariants: supportsVariants,
        variants: variants,
      );

  static SkillCatalogEntry _maxWeight(String discipline, String name, {String summary = ''}) =>
      _entry(
        discipline,
        name,
        MeasurementType.weight,
        PerformanceType.maxValue,
        MeasurementUnits.kg,
        [MeasurementUnits.kg, MeasurementUnits.lbs],
        summary: summary,
      );

  static SkillCatalogEntry _fastestTime(String discipline, String name, {String summary = ''}) =>
      _entry(
        discipline,
        name,
        MeasurementType.duration,
        PerformanceType.fastestTime,
        MeasurementUnits.time,
        [MeasurementUnits.time],
        summary: summary,
      );

  static SkillCatalogEntry _longestDuration(
    String discipline,
    String name, {
    String summary = '',
    bool supportsVariants = false,
    List<SkillCatalogVariant> variants = const [],
  }) =>
      _entry(
        discipline,
        name,
        MeasurementType.duration,
        PerformanceType.longestDuration,
        MeasurementUnits.time,
        [MeasurementUnits.time],
        summary: summary,
        supportsVariants: supportsVariants,
        variants: variants,
      );

  static SkillCatalogEntry _longestDistance(
    String discipline,
    String name, {
    String defaultUnit = MeasurementUnits.km,
    List<String>? allowedUnits,
    String summary = '',
  }) =>
      _entry(
        discipline,
        name,
        MeasurementType.distance,
        PerformanceType.longestDistance,
        defaultUnit,
        allowedUnits ?? [defaultUnit],
        summary: summary,
      );

  static SkillCatalogEntry _maxCalories(String discipline, String name, {String summary = ''}) =>
      _entry(
        discipline,
        name,
        MeasurementType.calories,
        PerformanceType.maxValue,
        MeasurementUnits.kcal,
        [MeasurementUnits.kcal],
        summary: summary,
      );

  static SkillCatalogEntry _highestScore(String discipline, String name, {String summary = ''}) =>
      _entry(
        discipline,
        name,
        MeasurementType.score,
        PerformanceType.highestScore,
        MeasurementUnits.points,
        [MeasurementUnits.points],
        summary: summary,
      );

  static String _slug(String discipline, String name) {
    return '${discipline.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_'
        '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
  }

  static final List<SkillCatalogEntry> all = [
    // Strength
    _reps(
      'Strength',
      'Push-ups',
      summary: 'Maximum consecutive push-ups.',
      supportsVariants: true,
      variants: pushUpVariants,
    ),
    _reps(
      'Strength',
      'Pull-ups',
      summary: 'Maximum consecutive pull-ups.',
      supportsVariants: true,
      variants: pullUpVariants,
    ),
    _reps(
      'Strength',
      'Squats',
      summary: 'Maximum consecutive squats for a given variation.',
      supportsVariants: true,
      variants: squatVariants,
    ),
    _reps('Strength', 'Chin-ups', summary: 'Maximum consecutive chin-ups.'),
    _maxWeight('Strength', 'Bench Press', summary: 'Heaviest successful bench press.'),
    _maxWeight('Strength', 'Deadlift', summary: 'Heaviest successful deadlift.'),
    _maxWeight('Strength', 'Back Squat', summary: 'Heaviest successful back squat.'),
    _maxWeight('Strength', 'Front Squat', summary: 'Heaviest successful front squat.'),
    _maxWeight('Strength', 'Overhead Press', summary: 'Heaviest successful overhead press.'),
    _maxWeight('Strength', 'Strict Press', summary: 'Heaviest strict press without leg drive.'),
    _maxWeight('Strength', 'Farmer Carry', summary: 'Heaviest farmer carry load documented.'),
    _maxWeight('Strength', 'Grip Strength', summary: 'Peak grip force or hold load.'),
    _maxWeight('Strength', 'Leg Press', summary: 'Heaviest successful leg press.'),

    // Gymnastics
    _reps('Gymnastics', 'Muscle-up', summary: 'Maximum consecutive muscle-ups.'),
    _reps('Gymnastics', 'Ring Muscle-up', summary: 'Maximum consecutive ring muscle-ups.'),
    _reps('Gymnastics', 'Bar Muscle-up', summary: 'Maximum consecutive bar muscle-ups.'),
    _longestDuration('Gymnastics', 'Handstand Hold', summary: 'Longest handstand hold.'),
    _longestDistance('Gymnastics', 'Handstand Walk', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Longest handstand walk distance.'),
    _reps('Gymnastics', 'Toes-to-Bar', summary: 'Maximum consecutive toes-to-bar.'),
    _longestDuration('Gymnastics', 'L-Sit', summary: 'Longest L-sit hold.'),
    _reps('Gymnastics', 'Rope Climb', summary: 'Maximum rope climbs in a set window.'),
    _reps('Gymnastics', 'Ring Dips', summary: 'Maximum consecutive ring dips.'),
    _reps('Gymnastics', 'Pistol Squat', summary: 'Maximum consecutive pistol squats.'),

    // Endurance
    _fastestTime('Endurance', '1 km Run', summary: 'Best 1 km run time.'),
    _fastestTime('Endurance', '3 km Run', summary: 'Best 3 km run time.'),
    _fastestTime('Endurance', '5 km Run', summary: 'Best 5 km run time.'),
    _fastestTime('Endurance', '10 km Run', summary: 'Best 10 km run time.'),
    _fastestTime('Endurance', 'Half Marathon', summary: 'Best half marathon time.'),
    _fastestTime('Endurance', 'Marathon', summary: 'Best marathon time.'),
    _longestDistance('Endurance', 'Cooper Test', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m, MeasurementUnits.km], summary: 'Distance covered in 12 minutes.'),
    _longestDistance('Endurance', 'Cycling Distance', defaultUnit: MeasurementUnits.km, allowedUnits: [MeasurementUnits.km, MeasurementUnits.mi], summary: 'Longest documented cycling distance.'),
    _longestDistance('Endurance', 'Swimming Distance', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m, MeasurementUnits.km], summary: 'Longest documented swim distance.'),
    _longestDistance('Endurance', 'Hiking Distance', defaultUnit: MeasurementUnits.km, allowedUnits: [MeasurementUnits.km, MeasurementUnits.mi], summary: 'Longest documented hike distance.'),

    // Conditioning
    _reps('Conditioning', 'Burpees', summary: 'Maximum burpees in a set window.'),
    _reps('Conditioning', 'Wall Balls', summary: 'Maximum wall balls in a set window.'),
    _reps('Conditioning', 'Air Squats', summary: 'Maximum air squats in a set window.'),
    _reps('Conditioning', 'Box Jumps', summary: 'Maximum box jumps in a set window.'),
    _reps('Conditioning', 'Double Unders', summary: 'Maximum consecutive double unders.'),
    _maxCalories('Conditioning', 'Assault Bike Calories', summary: 'Calories on assault bike in a set window.'),
    _maxCalories('Conditioning', 'Echo Bike Calories', summary: 'Calories on echo bike in a set window.'),
    _fastestTime('Conditioning', 'SkiErg 500m', summary: 'Best 500 m SkiErg time.'),
    _fastestTime('Conditioning', 'Row 500m', summary: 'Best 500 m row time.'),
    _fastestTime('Conditioning', 'Row 2K', summary: 'Best 2 km row time.'),

    // Speed
    _fastestTime('Speed', '40 m Sprint', summary: 'Best 40 m sprint time.'),
    _fastestTime('Speed', '100 m Sprint', summary: 'Best 100 m sprint time.'),
    _fastestTime('Speed', '200 m Sprint', summary: 'Best 200 m sprint time.'),
    _fastestTime('Speed', 'Shuttle Run', summary: 'Best shuttle run time.'),
    _fastestTime('Speed', 'Agility Test', summary: 'Best agility test time.'),
    _fastestTime('Speed', 'Reaction Sprint', summary: 'Best reaction sprint time.'),

    // Explosive Power
    _longestDistance('Explosive Power', 'Vertical Jump', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Highest vertical jump.'),
    _longestDistance('Explosive Power', 'Broad Jump', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Longest broad jump.'),
    _longestDistance('Explosive Power', 'Box Jump Height', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Highest box jump height.'),
    _longestDistance('Explosive Power', 'Medicine Ball Throw', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Longest medicine ball throw.'),
    _longestDistance('Explosive Power', 'Standing Long Jump', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Longest standing long jump.'),

    // Mobility
    _longestDuration('Mobility', 'Deep Squat Hold', summary: 'Longest deep squat hold.'),
    _highestScore('Mobility', 'Shoulder Mobility', summary: 'Shoulder mobility assessment score.'),
    _longestDistance('Mobility', 'Hamstring Flexibility', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Sit-and-reach or equivalent measure.'),
    _highestScore('Mobility', 'Hip Mobility', summary: 'Hip mobility assessment score.'),
    _highestScore('Mobility', 'Ankle Mobility', summary: 'Ankle mobility assessment score.'),
    _highestScore('Mobility', 'Thoracic Rotation', summary: 'Thoracic rotation assessment score.'),

    // Balance & Coordination
    _longestDuration('Balance & Coordination', 'Single Leg Balance', summary: 'Longest single-leg balance.'),
    _longestDistance('Balance & Coordination', 'Y Balance Test', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Y balance test reach distance.'),
    _longestDistance('Balance & Coordination', 'Balance Beam Walk', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Balance beam walk distance.'),
    _highestScore('Balance & Coordination', 'Coordination Drill', summary: 'Coordination drill score.'),

    // Core
    _longestDuration(
      'Core',
      'Plank',
      summary: 'Longest plank hold.',
      supportsVariants: true,
      variants: plankVariants,
    ),
    _longestDuration('Core', 'Side Plank', summary: 'Longest side plank hold.'),
    _longestDuration('Core', 'Hollow Hold', summary: 'Longest hollow hold.'),
    _longestDuration('Core', 'Superman Hold', summary: 'Longest superman hold.'),
    _reps('Core', 'Hanging Leg Raise', summary: 'Maximum hanging leg raises.'),
    _longestDuration('Core', 'V-Sit Hold', summary: 'Longest V-sit hold.'),

    // Swimming
    _fastestTime('Swimming', '50 m Freestyle', summary: 'Best 50 m freestyle time.'),
    _fastestTime('Swimming', '100 m Freestyle', summary: 'Best 100 m freestyle time.'),
    _fastestTime('Swimming', '400 m Swim', summary: 'Best 400 m swim time.'),
    _longestDuration('Swimming', 'Tread Water', summary: 'Longest tread water duration.'),

    // Climbing
    _highestScore('Climbing', 'Bouldering Grade', summary: 'Highest bouldering grade sent.'),
    _highestScore('Climbing', 'Sport Climbing Grade', summary: 'Highest sport climbing grade sent.'),
    _longestDistance('Climbing', 'Rope Climb Height', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Highest rope climb height.'),
    _longestDuration('Climbing', 'Hang Time', summary: 'Longest climbing hang time.'),

    // Functional
    _maxWeight('Functional', 'Sandbag Carry', summary: 'Heaviest sandbag carry load.'),
    _longestDistance('Functional', 'Sled Push', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Sled push distance or course completion.'),
    _longestDistance('Functional', 'Sled Pull', defaultUnit: MeasurementUnits.m, allowedUnits: [MeasurementUnits.m], summary: 'Sled pull distance or course completion.'),
    _reps('Functional', 'Tire Flip', summary: 'Maximum tire flips in a set window.'),
    _maxWeight('Functional', 'Loaded Carry', summary: 'Heaviest loaded carry documented.'),
    _fastestTime('Functional', 'Stair Climb', summary: 'Best stair climb time.'),

    // Tactical
    _fastestTime('Tactical', 'Loaded March', summary: 'Best loaded march time.'),
    _fastestTime('Tactical', 'Obstacle Course', summary: 'Best obstacle course time.'),
    _fastestTime('Tactical', 'Firefighter Stair Test', summary: 'Best firefighter stair test time.'),
    _fastestTime('Tactical', 'Casualty Drag', summary: 'Best casualty drag time.'),
    _fastestTime('Tactical', 'Dummy Carry', summary: 'Best dummy carry time.'),
    _fastestTime('Tactical', 'Rope Traverse', summary: 'Best rope traverse time.'),

    // Other
    const SkillCatalogEntry(
      id: customSkillId,
      name: 'Custom Skill',
      discipline: 'Other',
      summary: 'Define your own physical capability and measurement.',
      defaultUnit: MeasurementUnits.reps,
      allowedUnits: MeasurementUnits.all,
      measurementType: MeasurementType.count,
      performanceType: PerformanceType.maxReps,
    ),
  ];

  static const disciplines = [
    'Strength',
    'Endurance',
    'Gymnastics',
    'Conditioning',
    'Speed',
    'Explosive Power',
    'Mobility',
    'Balance & Coordination',
    'Core',
    'Swimming',
    'Climbing',
    'Functional',
    'Tactical',
    'Other',
  ];

  static List<String> get catalogDisciplines {
    return all.map((e) => e.discipline).toSet().toList()..sort();
  }

  static SkillCatalogEntry? findById(String id) {
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  static List<SkillCatalogEntry> search({
    String query = '',
    String? discipline,
  }) {
    final q = query.trim().toLowerCase();
    return all.where((entry) {
      if (discipline != null && entry.discipline != discipline) return false;
      if (q.isEmpty) return true;
      return entry.name.toLowerCase().contains(q) ||
          entry.discipline.toLowerCase().contains(q) ||
          entry.summary.toLowerCase().contains(q);
    }).toList();
  }
}
