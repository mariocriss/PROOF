import 'package:proof/shared/models/skill_catalog_variant.dart';

/// Shared variant lists for the PROOF skill catalog.
///
/// Variant IDs are stable. Display names may change later.
class SkillCatalogVariants {
  SkillCatalogVariants._();

  static const pushUps = [
    SkillCatalogVariant(id: 'standard', name: 'Standard'),
    SkillCatalogVariant(id: 'knees', name: 'Knee'),
    SkillCatalogVariant(id: 'incline', name: 'Incline'),
    SkillCatalogVariant(id: 'decline', name: 'Decline'),
    SkillCatalogVariant(id: 'diamond', name: 'Diamond'),
    SkillCatalogVariant(id: 'wide', name: 'Wide Grip'),
    SkillCatalogVariant(id: 'hand_release', name: 'Hand Release'),
    SkillCatalogVariant(id: 'deficit', name: 'Deficit'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'ring', name: 'Ring'),
    SkillCatalogVariant(id: 'tempo', name: 'Strict Tempo'),
    SkillCatalogVariant(id: 'clapping', name: 'Clapping'),
    SkillCatalogVariant(id: 'archer', name: 'Archer'),
    SkillCatalogVariant(id: 'one_arm', name: 'One Arm'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
    SkillCatalogVariant(id: 'max_1_min', name: 'Max in 1 Minute'),
    SkillCatalogVariant(id: 'max_2_min', name: 'Max in 2 Minutes'),
  ];

  static const pullUps = [
    SkillCatalogVariant(id: 'strict', name: 'Strict'),
    SkillCatalogVariant(id: 'kipping', name: 'Kipping'),
    SkillCatalogVariant(id: 'butterfly', name: 'Butterfly'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'chest_to_bar', name: 'Chest-to-Bar'),
    SkillCatalogVariant(id: 'wide', name: 'Wide Grip'),
    SkillCatalogVariant(id: 'close_grip', name: 'Close Grip'),
    SkillCatalogVariant(id: 'neutral', name: 'Neutral Grip'),
    SkillCatalogVariant(id: 'chin_up', name: 'Chin-up'),
    SkillCatalogVariant(id: 'towel', name: 'Towel'),
    SkillCatalogVariant(id: 'l_sit', name: 'L-Sit'),
    SkillCatalogVariant(id: 'assisted', name: 'Assisted'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
    SkillCatalogVariant(id: 'max_1_min', name: 'Max in 1 Minute'),
  ];

  static const chinUps = [
    SkillCatalogVariant(id: 'strict', name: 'Strict'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'assisted', name: 'Assisted'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
  ];

  static const dips = [
    SkillCatalogVariant(id: 'parallel_bar', name: 'Parallel Bar'),
    SkillCatalogVariant(id: 'bench', name: 'Bench'),
    SkillCatalogVariant(id: 'ring', name: 'Ring'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'assisted', name: 'Assisted'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
  ];

  static const squats = [
    SkillCatalogVariant(id: 'air', name: 'Air Squat'),
    SkillCatalogVariant(id: 'goblet', name: 'Goblet Squat'),
    SkillCatalogVariant(id: 'front', name: 'Front Squat'),
    SkillCatalogVariant(id: 'back', name: 'Back Squat'),
    SkillCatalogVariant(id: 'overhead', name: 'Overhead Squat'),
    SkillCatalogVariant(id: 'box', name: 'Box Squat'),
    SkillCatalogVariant(id: 'tempo', name: 'Tempo Squat'),
    SkillCatalogVariant(id: 'pause', name: 'Pause Squat'),
    SkillCatalogVariant(id: 'jump', name: 'Jump Squat'),
    SkillCatalogVariant(id: 'pistol', name: 'Pistol Squat'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
  ];

  static const pistolSquats = [
    SkillCatalogVariant(id: 'bodyweight', name: 'Bodyweight'),
    SkillCatalogVariant(id: 'assisted', name: 'Assisted'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
  ];

  static const lunges = [
    SkillCatalogVariant(id: 'walking', name: 'Walking'),
    SkillCatalogVariant(id: 'reverse', name: 'Reverse'),
    SkillCatalogVariant(id: 'forward', name: 'Forward'),
    SkillCatalogVariant(id: 'jumping', name: 'Jumping'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
  ];

  static const handstandPushUps = [
    SkillCatalogVariant(id: 'kipping', name: 'Kipping'),
    SkillCatalogVariant(id: 'strict', name: 'Strict'),
    SkillCatalogVariant(id: 'deficit', name: 'Deficit'),
    SkillCatalogVariant(id: 'wall', name: 'Wall'),
    SkillCatalogVariant(id: 'freestanding', name: 'Freestanding'),
  ];

  static const benchPress = [
    SkillCatalogVariant(id: 'flat', name: 'Flat'),
    SkillCatalogVariant(id: 'incline', name: 'Incline'),
    SkillCatalogVariant(id: 'decline', name: 'Decline'),
    SkillCatalogVariant(id: 'close_grip', name: 'Close Grip'),
    SkillCatalogVariant(id: 'wide', name: 'Wide Grip'),
    SkillCatalogVariant(id: 'paused', name: 'Paused'),
    SkillCatalogVariant(id: 'touch_and_go', name: 'Touch and Go'),
    SkillCatalogVariant(id: 'barbell', name: 'Barbell'),
    SkillCatalogVariant(id: 'dumbbell', name: 'Dumbbell'),
    SkillCatalogVariant(id: '1rm', name: 'One Rep Max'),
    SkillCatalogVariant(id: '3rm', name: 'Three Rep Max'),
    SkillCatalogVariant(id: '5rm', name: 'Five Rep Max'),
    SkillCatalogVariant(id: 'max_reps', name: 'Max Repetitions'),
  ];

  static const deadlift = [
    SkillCatalogVariant(id: 'conventional', name: 'Conventional'),
    SkillCatalogVariant(id: 'sumo', name: 'Sumo'),
    SkillCatalogVariant(id: 'romanian', name: 'Romanian'),
    SkillCatalogVariant(id: 'trap_bar', name: 'Trap Bar'),
    SkillCatalogVariant(id: 'deficit', name: 'Deficit'),
    SkillCatalogVariant(id: 'rack_pull', name: 'Rack Pull'),
    SkillCatalogVariant(id: 'snatch_grip', name: 'Snatch Grip'),
    SkillCatalogVariant(id: 'paused', name: 'Paused'),
    SkillCatalogVariant(id: 'touch_and_go', name: 'Touch and Go'),
    SkillCatalogVariant(id: '1rm', name: 'One Rep Max'),
    SkillCatalogVariant(id: '3rm', name: 'Three Rep Max'),
    SkillCatalogVariant(id: '5rm', name: 'Five Rep Max'),
  ];

  static const backSquat = [
    SkillCatalogVariant(id: 'high_bar', name: 'High Bar'),
    SkillCatalogVariant(id: 'low_bar', name: 'Low Bar'),
    SkillCatalogVariant(id: 'paused', name: 'Paused'),
    SkillCatalogVariant(id: 'tempo', name: 'Tempo'),
    SkillCatalogVariant(id: '1rm', name: 'One Rep Max'),
    SkillCatalogVariant(id: '3rm', name: 'Three Rep Max'),
    SkillCatalogVariant(id: '5rm', name: 'Five Rep Max'),
  ];

  static const frontSquat = [
    SkillCatalogVariant(id: 'standard', name: 'Standard'),
    SkillCatalogVariant(id: 'paused', name: 'Paused'),
    SkillCatalogVariant(id: '1rm', name: 'One Rep Max'),
    SkillCatalogVariant(id: '3rm', name: 'Three Rep Max'),
    SkillCatalogVariant(id: '5rm', name: 'Five Rep Max'),
  ];

  static const overheadPress = [
    SkillCatalogVariant(id: 'strict', name: 'Strict'),
    SkillCatalogVariant(id: 'push_press', name: 'Push Press'),
    SkillCatalogVariant(id: 'seated', name: 'Seated'),
    SkillCatalogVariant(id: '1rm', name: 'One Rep Max'),
  ];

  static const barbellRow = [
    SkillCatalogVariant(id: 'bent_over', name: 'Bent Over'),
    SkillCatalogVariant(id: 'pendlay', name: 'Pendlay'),
    SkillCatalogVariant(id: 'underhand', name: 'Underhand'),
    SkillCatalogVariant(id: '1rm', name: 'One Rep Max'),
  ];

  static const clean = [
    SkillCatalogVariant(id: 'full', name: 'Full Clean'),
    SkillCatalogVariant(id: 'power', name: 'Power Clean'),
    SkillCatalogVariant(id: 'hang', name: 'Hang Clean'),
    SkillCatalogVariant(id: 'from_blocks', name: 'From Blocks'),
    SkillCatalogVariant(id: '1rm', name: 'One Rep Max'),
  ];

  static const snatch = [
    SkillCatalogVariant(id: 'full', name: 'Full Snatch'),
    SkillCatalogVariant(id: 'power', name: 'Power Snatch'),
    SkillCatalogVariant(id: 'hang', name: 'Hang Snatch'),
    SkillCatalogVariant(id: 'from_blocks', name: 'From Blocks'),
    SkillCatalogVariant(id: '1rm', name: 'One Rep Max'),
  ];

  static const kettlebellSwing = [
    SkillCatalogVariant(id: 'russian', name: 'Russian'),
    SkillCatalogVariant(id: 'american', name: 'American'),
    SkillCatalogVariant(id: 'single', name: 'Single Arm'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
  ];

  static const farmerCarry = [
    SkillCatalogVariant(id: 'distance', name: 'Distance'),
    SkillCatalogVariant(id: 'time', name: 'Time'),
    SkillCatalogVariant(id: 'max_weight', name: 'Maximum Weight'),
    SkillCatalogVariant(id: 'one_hand', name: 'One Hand'),
    SkillCatalogVariant(id: 'two_hand', name: 'Two Hand'),
  ];

  static const suitcaseCarry = [
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
    SkillCatalogVariant(id: 'distance', name: 'Distance'),
    SkillCatalogVariant(id: 'time', name: 'Time'),
  ];

  static const loadedCarry = [
    SkillCatalogVariant(id: 'distance', name: 'Distance'),
    SkillCatalogVariant(id: 'time', name: 'Time'),
    SkillCatalogVariant(id: 'max_weight', name: 'Maximum Weight'),
    SkillCatalogVariant(id: 'bear_hug', name: 'Bear Hug'),
    SkillCatalogVariant(id: 'shoulder', name: 'Shoulder'),
    SkillCatalogVariant(id: 'front_rack', name: 'Front Rack'),
    SkillCatalogVariant(id: 'overhead', name: 'Overhead'),
  ];

  static const gripStrength = [
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
    SkillCatalogVariant(id: 'both', name: 'Both'),
    SkillCatalogVariant(id: 'device', name: 'Device Measured'),
  ];

  static const deadHang = [
    SkillCatalogVariant(id: 'two_hand', name: 'Two Hand'),
    SkillCatalogVariant(id: 'one_hand', name: 'One Hand'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'max_time', name: 'Maximum Time'),
  ];

  static const muscleUp = [
    SkillCatalogVariant(id: 'bar', name: 'Bar'),
    SkillCatalogVariant(id: 'ring', name: 'Ring'),
    SkillCatalogVariant(id: 'strict', name: 'Strict'),
    SkillCatalogVariant(id: 'kipping', name: 'Kipping'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
    SkillCatalogVariant(id: 'max_1_min', name: 'Max in 1 Minute'),
  ];

  static const handstandHold = [
    SkillCatalogVariant(id: 'wall_facing', name: 'Wall Facing'),
    SkillCatalogVariant(id: 'back_to_wall', name: 'Back to Wall'),
    SkillCatalogVariant(id: 'freestanding', name: 'Freestanding'),
    SkillCatalogVariant(id: 'one_arm', name: 'One Arm'),
    SkillCatalogVariant(id: 'parallettes', name: 'Parallettes'),
    SkillCatalogVariant(id: 'max_time', name: 'Maximum Time'),
  ];

  static const handstandWalk = [
    SkillCatalogVariant(id: 'max_distance', name: 'Maximum Distance'),
    SkillCatalogVariant(id: 'fastest_10m', name: 'Fastest 10 m'),
    SkillCatalogVariant(id: 'fastest_25m', name: 'Fastest 25 m'),
    SkillCatalogVariant(id: 'unbroken', name: 'Unbroken Distance'),
  ];

  static const toesToBar = [
    SkillCatalogVariant(id: 'strict', name: 'Strict'),
    SkillCatalogVariant(id: 'kipping', name: 'Kipping'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
  ];

  static const ropeClimb = [
    SkillCatalogVariant(id: 'with_legs', name: 'With Legs'),
    SkillCatalogVariant(id: 'legless', name: 'Legless'),
    SkillCatalogVariant(id: 'seated_start', name: 'Seated Start'),
    SkillCatalogVariant(id: 'l_sit', name: 'L-Sit'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'height', name: 'Height'),
    SkillCatalogVariant(id: 'fastest', name: 'Fastest Time'),
    SkillCatalogVariant(id: 'max_reps', name: 'Maximum Repetitions'),
  ];

  static const leverSkill = [
    SkillCatalogVariant(id: 'tuck', name: 'Tuck'),
    SkillCatalogVariant(id: 'advanced_tuck', name: 'Advanced Tuck'),
    SkillCatalogVariant(id: 'one_leg', name: 'One Leg'),
    SkillCatalogVariant(id: 'full', name: 'Full'),
    SkillCatalogVariant(id: 'max_time', name: 'Maximum Time'),
  ];

  static const running = [
    SkillCatalogVariant(id: 'road', name: 'Road'),
    SkillCatalogVariant(id: 'trail', name: 'Trail'),
    SkillCatalogVariant(id: 'track', name: 'Track'),
    SkillCatalogVariant(id: 'treadmill', name: 'Treadmill'),
    SkillCatalogVariant(id: 'indoor', name: 'Indoor'),
    SkillCatalogVariant(id: 'outdoor', name: 'Outdoor'),
    SkillCatalogVariant(id: 'flat', name: 'Flat'),
    SkillCatalogVariant(id: 'hilly', name: 'Hilly'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'unweighted', name: 'Unweighted'),
    SkillCatalogVariant(id: 'official_race', name: 'Official Race'),
    SkillCatalogVariant(id: 'training', name: 'Training'),
  ];

  static const cycling = [
    SkillCatalogVariant(id: 'road', name: 'Road'),
    SkillCatalogVariant(id: 'indoor', name: 'Indoor'),
    SkillCatalogVariant(id: 'mountain', name: 'Mountain Bike'),
    SkillCatalogVariant(id: 'gravel', name: 'Gravel'),
    SkillCatalogVariant(id: 'time_trial', name: 'Time Trial'),
    SkillCatalogVariant(id: 'official_race', name: 'Official Race'),
    SkillCatalogVariant(id: 'training', name: 'Training'),
  ];

  static const burpees = [
    SkillCatalogVariant(id: 'standard', name: 'Standard'),
    SkillCatalogVariant(id: 'chest_to_floor', name: 'Chest-to-Floor'),
    SkillCatalogVariant(id: 'bar_facing', name: 'Bar Facing'),
    SkillCatalogVariant(id: 'lateral_bar', name: 'Lateral Bar'),
    SkillCatalogVariant(id: 'box_jump', name: 'Burpee Box Jump'),
    SkillCatalogVariant(id: 'box_jump_over', name: 'Burpee Box Jump Over'),
    SkillCatalogVariant(id: 'broad_jump', name: 'Burpee Broad Jump'),
    SkillCatalogVariant(id: 'max_1_min', name: 'Max in 1 Minute'),
    SkillCatalogVariant(id: 'max_5_min', name: 'Max in 5 Minutes'),
    SkillCatalogVariant(id: 'fastest_50', name: 'Fastest 50'),
    SkillCatalogVariant(id: 'fastest_100', name: 'Fastest 100'),
  ];

  static const wallBalls = [
    SkillCatalogVariant(id: 'standard', name: 'Standard'),
    SkillCatalogVariant(id: 'unbroken', name: 'Unbroken Repetitions'),
    SkillCatalogVariant(id: 'max_1_min', name: 'Max in 1 Minute'),
    SkillCatalogVariant(id: 'total_reps', name: 'Total Repetitions'),
    SkillCatalogVariant(id: 'workout', name: 'Workout Result'),
  ];

  static const boxJumps = [
    SkillCatalogVariant(id: 'standard', name: 'Standard'),
    SkillCatalogVariant(id: 'step_up', name: 'Step-up'),
    SkillCatalogVariant(id: 'rebound', name: 'Rebound'),
    SkillCatalogVariant(id: 'over', name: 'Box Jump Over'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
  ];

  static const doubleUnders = [
    SkillCatalogVariant(id: 'max_unbroken', name: 'Maximum Unbroken'),
    SkillCatalogVariant(id: 'max_1_min', name: 'Max in 1 Minute'),
    SkillCatalogVariant(id: 'fastest_100', name: 'Fastest 100'),
    SkillCatalogVariant(id: 'fastest_500', name: 'Fastest 500'),
    SkillCatalogVariant(id: 'crossover', name: 'Crossover'),
    SkillCatalogVariant(id: 'triple_under', name: 'Triple Under'),
  ];

  static const bikeCalories = [
    SkillCatalogVariant(id: 'assault', name: 'Assault Bike'),
    SkillCatalogVariant(id: 'echo', name: 'Echo Bike'),
    SkillCatalogVariant(id: 'bikeerg', name: 'BikeErg'),
    SkillCatalogVariant(id: 'max_30s', name: 'Max Calories in 30 Seconds'),
    SkillCatalogVariant(id: 'max_1_min', name: 'Max Calories in 1 Minute'),
    SkillCatalogVariant(id: 'max_5_min', name: 'Max Calories in 5 Minutes'),
    SkillCatalogVariant(id: 'time_10', name: 'Time to 10 Calories'),
    SkillCatalogVariant(id: 'time_50', name: 'Time to 50 Calories'),
    SkillCatalogVariant(id: 'time_100', name: 'Time to 100 Calories'),
  ];

  static const thrusters = [
    SkillCatalogVariant(id: 'barbell', name: 'Barbell'),
    SkillCatalogVariant(id: 'dumbbell', name: 'Dumbbell'),
    SkillCatalogVariant(id: 'wall_ball', name: 'Wall Ball Style'),
    SkillCatalogVariant(id: 'max_unbroken', name: 'Max Unbroken'),
  ];

  static const sled = [
    SkillCatalogVariant(id: 'distance', name: 'Distance'),
    SkillCatalogVariant(id: 'time', name: 'Time'),
    SkillCatalogVariant(id: 'weight', name: 'Weight'),
    SkillCatalogVariant(id: 'high_handle', name: 'High Handle'),
    SkillCatalogVariant(id: 'low_handle', name: 'Low Handle'),
  ];

  static const sprint = [
    SkillCatalogVariant(id: 'standing', name: 'Standing Start'),
    SkillCatalogVariant(id: 'three_point', name: 'Three-Point Start'),
    SkillCatalogVariant(id: 'blocks', name: 'Blocks'),
    SkillCatalogVariant(id: 'flying', name: 'Flying Start'),
    SkillCatalogVariant(id: 'indoor', name: 'Indoor'),
    SkillCatalogVariant(id: 'outdoor', name: 'Outdoor'),
    SkillCatalogVariant(id: 'track', name: 'Track'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'unweighted', name: 'Unweighted'),
  ];

  static const shuttleRun = [
    SkillCatalogVariant(id: '5_10_5', name: '5-10-5'),
    SkillCatalogVariant(id: '10x10', name: '10 x 10 m'),
    SkillCatalogVariant(id: '20m', name: '20 m Shuttle'),
    SkillCatalogVariant(id: 'beep', name: 'Beep Test'),
    SkillCatalogVariant(id: 'suicide', name: 'Suicide Sprint'),
    SkillCatalogVariant(id: 'custom', name: 'Custom Distance'),
  ];

  static const verticalJump = [
    SkillCatalogVariant(id: 'standing', name: 'Standing'),
    SkillCatalogVariant(id: 'countermovement', name: 'Countermovement'),
    SkillCatalogVariant(id: 'no_arm', name: 'No Arm Swing'),
    SkillCatalogVariant(id: 'arm_swing', name: 'Arm Swing'),
    SkillCatalogVariant(id: 'approach', name: 'Approach Jump'),
    SkillCatalogVariant(id: 'single_leg', name: 'Single Leg'),
    SkillCatalogVariant(id: 'device', name: 'Device Measured'),
    SkillCatalogVariant(id: 'wall', name: 'Wall Measured'),
  ];

  static const medicineBallThrow = [
    SkillCatalogVariant(id: 'chest', name: 'Chest'),
    SkillCatalogVariant(id: 'overhead', name: 'Overhead'),
    SkillCatalogVariant(id: 'backward', name: 'Backward'),
    SkillCatalogVariant(id: 'rotational', name: 'Rotational'),
    SkillCatalogVariant(id: 'scoop', name: 'Scoop'),
    SkillCatalogVariant(id: 'seated', name: 'Seated'),
    SkillCatalogVariant(id: 'kneeling', name: 'Kneeling'),
  ];

  static const shoulderMobility = [
    SkillCatalogVariant(id: 'flexion', name: 'Flexion'),
    SkillCatalogVariant(id: 'extension', name: 'Extension'),
    SkillCatalogVariant(id: 'internal', name: 'Internal Rotation'),
    SkillCatalogVariant(id: 'external', name: 'External Rotation'),
    SkillCatalogVariant(id: 'overhead', name: 'Overhead Reach'),
    SkillCatalogVariant(id: 'apley', name: 'Apley Scratch Test'),
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
  ];

  static const hipMobility = [
    SkillCatalogVariant(id: 'internal', name: 'Internal Rotation'),
    SkillCatalogVariant(id: 'external', name: 'External Rotation'),
    SkillCatalogVariant(id: 'flexion', name: 'Flexion'),
    SkillCatalogVariant(id: 'extension', name: 'Extension'),
    SkillCatalogVariant(id: 'abduction', name: 'Abduction'),
    SkillCatalogVariant(id: 'adduction', name: 'Adduction'),
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
  ];

  static const ankleMobility = [
    SkillCatalogVariant(id: 'knee_to_wall', name: 'Knee-to-Wall'),
    SkillCatalogVariant(id: 'dorsiflexion', name: 'Dorsiflexion Angle'),
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
    SkillCatalogVariant(id: 'loaded', name: 'Loaded'),
    SkillCatalogVariant(id: 'unloaded', name: 'Unloaded'),
  ];

  static const singleLegBalance = [
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
    SkillCatalogVariant(id: 'eyes_open', name: 'Eyes Open'),
    SkillCatalogVariant(id: 'eyes_closed', name: 'Eyes Closed'),
    SkillCatalogVariant(id: 'stable', name: 'Stable Surface'),
    SkillCatalogVariant(id: 'unstable', name: 'Unstable Surface'),
    SkillCatalogVariant(id: 'max_time', name: 'Maximum Time'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
  ];

  static const yBalance = [
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
    SkillCatalogVariant(id: 'anterior', name: 'Anterior'),
    SkillCatalogVariant(id: 'posteromedial', name: 'Posteromedial'),
    SkillCatalogVariant(id: 'posterolateral', name: 'Posterolateral'),
    SkillCatalogVariant(id: 'composite', name: 'Composite Score'),
  ];

  static const plank = [
    SkillCatalogVariant(id: 'front', name: 'Forearm'),
    SkillCatalogVariant(id: 'high', name: 'High Plank'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'long_lever', name: 'Long Lever'),
    SkillCatalogVariant(id: 'rkc', name: 'RKC'),
    SkillCatalogVariant(id: 'one_arm', name: 'One Arm'),
    SkillCatalogVariant(id: 'one_leg', name: 'One Leg'),
    SkillCatalogVariant(id: 'max_time', name: 'Maximum Time'),
  ];

  static const sidePlank = [
    SkillCatalogVariant(id: 'left', name: 'Left'),
    SkillCatalogVariant(id: 'right', name: 'Right'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'star', name: 'Star'),
    SkillCatalogVariant(id: 'copenhagen', name: 'Copenhagen'),
    SkillCatalogVariant(id: 'max_time', name: 'Maximum Time'),
  ];

  static const hangingLegRaise = [
    SkillCatalogVariant(id: 'bent_knee', name: 'Bent Knee'),
    SkillCatalogVariant(id: 'straight_leg', name: 'Straight Leg'),
    SkillCatalogVariant(id: 'toes_to_bar', name: 'Toes-to-Bar'),
    SkillCatalogVariant(id: 'strict', name: 'Strict'),
    SkillCatalogVariant(id: 'kipping', name: 'Kipping'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'max_reps', name: 'Max Repetitions'),
  ];

  static const swimming = [
    SkillCatalogVariant(id: 'pool', name: 'Pool'),
    SkillCatalogVariant(id: 'open_water', name: 'Open Water'),
    SkillCatalogVariant(id: 'freestyle', name: 'Freestyle'),
    SkillCatalogVariant(id: 'breaststroke', name: 'Breaststroke'),
    SkillCatalogVariant(id: 'backstroke', name: 'Backstroke'),
    SkillCatalogVariant(id: 'butterfly', name: 'Butterfly'),
    SkillCatalogVariant(id: 'im', name: 'Individual Medley'),
    SkillCatalogVariant(id: 'fins', name: 'With Fins'),
    SkillCatalogVariant(id: 'no_fins', name: 'Without Fins'),
    SkillCatalogVariant(id: 'official_race', name: 'Official Race'),
    SkillCatalogVariant(id: 'training', name: 'Training'),
  ];

  static const treadWater = [
    SkillCatalogVariant(id: 'hands', name: 'Hands Allowed'),
    SkillCatalogVariant(id: 'no_hands', name: 'No Hands'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'max_time', name: 'Maximum Time'),
  ];

  static const climbingGrade = [
    SkillCatalogVariant(id: 'font', name: 'Fontainebleau'),
    SkillCatalogVariant(id: 'v_scale', name: 'V Scale'),
    SkillCatalogVariant(id: 'french', name: 'French Sport'),
    SkillCatalogVariant(id: 'yds', name: 'Yosemite Decimal System'),
    SkillCatalogVariant(id: 'uiaa', name: 'UIAA'),
    SkillCatalogVariant(id: 'british', name: 'British Trad'),
    SkillCatalogVariant(id: 'custom', name: 'Custom Grade'),
  ];

  static const hangTime = [
    SkillCatalogVariant(id: 'two_hand', name: 'Two Hand'),
    SkillCatalogVariant(id: 'one_hand', name: 'One Hand'),
    SkillCatalogVariant(id: 'bar', name: 'Bar'),
    SkillCatalogVariant(id: 'jug', name: 'Jug'),
    SkillCatalogVariant(id: 'crimp', name: 'Crimp'),
    SkillCatalogVariant(id: 'sloper', name: 'Sloper'),
    SkillCatalogVariant(id: 'pinch', name: 'Pinch'),
    SkillCatalogVariant(id: 'weighted', name: 'Weighted'),
    SkillCatalogVariant(id: 'bodyweight', name: 'Bodyweight'),
  ];

  static const tireFlip = [
    SkillCatalogVariant(id: 'reps', name: 'Repetitions'),
    SkillCatalogVariant(id: 'distance', name: 'Distance'),
    SkillCatalogVariant(id: 'time', name: 'Time'),
  ];

  static const loadedMarch = [
    SkillCatalogVariant(id: 'distance', name: 'Distance'),
    SkillCatalogVariant(id: 'time', name: 'Time'),
    SkillCatalogVariant(id: 'load', name: 'Load'),
    SkillCatalogVariant(id: 'official', name: 'Official Test'),
    SkillCatalogVariant(id: 'training', name: 'Training'),
  ];

  static const casualtyDrag = [
    SkillCatalogVariant(id: 'distance', name: 'Distance'),
    SkillCatalogVariant(id: 'time', name: 'Time'),
    SkillCatalogVariant(id: 'one_person', name: 'One Person'),
    SkillCatalogVariant(id: 'team', name: 'Team'),
  ];

  static const firefighterStair = [
    SkillCatalogVariant(id: 'weighted_vest', name: 'Weighted Vest'),
    SkillCatalogVariant(id: 'equipment', name: 'Equipment Load'),
    SkillCatalogVariant(id: 'stepmill', name: 'StepMill'),
    SkillCatalogVariant(id: 'real_stairs', name: 'Real Stairs'),
  ];

  static const hyrox = [
    SkillCatalogVariant(id: 'open', name: 'Open'),
    SkillCatalogVariant(id: 'pro', name: 'Pro'),
    SkillCatalogVariant(id: 'doubles', name: 'Doubles'),
    SkillCatalogVariant(id: 'mixed_doubles', name: 'Mixed Doubles'),
    SkillCatalogVariant(id: 'relay', name: 'Relay'),
    SkillCatalogVariant(id: 'age_group', name: 'Age Group'),
  ];

  static const crossfitBenchmark = [
    SkillCatalogVariant(id: 'rx', name: 'RX'),
    SkillCatalogVariant(id: 'scaled', name: 'Scaled'),
    SkillCatalogVariant(id: 'beginner', name: 'Beginner'),
    SkillCatalogVariant(id: 'intermediate', name: 'Intermediate'),
    SkillCatalogVariant(id: 'masters', name: 'Masters'),
    SkillCatalogVariant(id: 'team', name: 'Team'),
    SkillCatalogVariant(id: 'custom', name: 'Custom'),
  ];

  static const powerlifting = [
    SkillCatalogVariant(id: 'raw', name: 'Raw'),
    SkillCatalogVariant(id: 'equipped', name: 'Equipped'),
    SkillCatalogVariant(id: 'wraps', name: 'Wraps'),
    SkillCatalogVariant(id: 'sleeves', name: 'Sleeves'),
    SkillCatalogVariant(id: 'training', name: 'Training'),
    SkillCatalogVariant(id: 'competition', name: 'Competition'),
  ];
}
