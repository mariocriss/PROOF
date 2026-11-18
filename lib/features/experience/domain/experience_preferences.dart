class ExperienceMotionPreferences {
  const ExperienceMotionPreferences({
    this.reduceMotion = false,
  });

  final bool reduceMotion;

  ExperienceMotionPreferences copyWith({bool? reduceMotion}) {
    return ExperienceMotionPreferences(
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}

class ExperiencePreferences {
  const ExperiencePreferences({
    this.guideEnabled = true,
    this.soundsEnabled = true,
    this.hapticsEnabled = true,
    this.motion = const ExperienceMotionPreferences(),
  });

  final bool guideEnabled;
  final bool soundsEnabled;
  final bool hapticsEnabled;
  final ExperienceMotionPreferences motion;

  bool get reduceMotion => motion.reduceMotion;

  ExperiencePreferences copyWith({
    bool? guideEnabled,
    bool? soundsEnabled,
    bool? hapticsEnabled,
    ExperienceMotionPreferences? motion,
  }) {
    return ExperiencePreferences(
      guideEnabled: guideEnabled ?? this.guideEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      motion: motion ?? this.motion,
    );
  }
}
