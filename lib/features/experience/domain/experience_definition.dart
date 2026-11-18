import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';
import 'package:proof/features/experience/domain/passport_stamp.dart';
import 'package:proof/features/experience/media/experience_haptic_service.dart';
import 'package:proof/features/experience/media/experience_sound_service.dart';

typedef ExperienceMessageBuilder = String Function(ExperienceContext context);

class ExperienceDefinition {
  const ExperienceDefinition({
    required this.type,
    required this.importance,
    required this.primaryMessage,
    required this.duration,
    this.secondaryMessage,
    this.ctaLabel = 'Continue',
    this.secondaryCtaLabel,
    this.sound = ExperienceSoundKind.none,
    this.haptic = ExperienceHapticKind.none,
    this.stampDefinition,
    this.skippable = true,
    this.featureFlagKey,
  });

  final ExperienceEventType type;
  final ExperienceImportance importance;
  final ExperienceMessageBuilder primaryMessage;
  final ExperienceMessageBuilder? secondaryMessage;
  final String ctaLabel;
  final String? secondaryCtaLabel;
  final ExperienceTimingPreset duration;
  final ExperienceSoundKind sound;
  final ExperienceHapticKind haptic;
  final PassportStampDefinition? stampDefinition;
  final bool skippable;
  final String? featureFlagKey;
}
