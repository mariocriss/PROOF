import 'package:proof/features/experience/domain/experience_definition.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';
import 'package:proof/features/experience/domain/passport_stamp.dart';
import 'package:proof/features/experience/media/experience_haptic_service.dart';
import 'package:proof/features/experience/media/experience_sound_service.dart';

class ExperienceDefinitionRegistry {
  ExperienceDefinitionRegistry({
    Map<ExperienceEventType, ExperienceDefinition>? overrides,
  }) : _defs = {
          ..._defaults,
          ...?overrides,
        };

  final Map<ExperienceEventType, ExperienceDefinition> _defs;

  ExperienceDefinition? get(ExperienceEventType type) => _defs[type];

  Iterable<ExperienceDefinition> get all => _defs.values;

  static final Map<ExperienceEventType, ExperienceDefinition> _defaults = {
    ExperienceEventType.onboardingCompleted: ExperienceDefinition(
      type: ExperienceEventType.onboardingCompleted,
      importance: ExperienceImportance.t3Landmark,
      primaryMessage: (_) => 'Your physical identity record begins today.',
      secondaryMessage: (_) =>
          'You do not need to record everything. Only what deserves to be remembered.',
      ctaLabel: 'Build My Identity',
      duration: ExperienceTimingPreset.moment,
      sound: ExperienceSoundKind.binding,
      haptic: ExperienceHapticKind.pulse,
      featureFlagKey: 'accountCreationExperienceEnabled',
    ),
    ExperienceEventType.firstProofCreated: ExperienceDefinition(
      type: ExperienceEventType.firstProofCreated,
      importance: ExperienceImportance.t3Landmark,
      primaryMessage: (_) =>
          'Your first proof. Everything else builds from here.',
      secondaryMessage: (_) =>
          'The first piece of evidence is now on your record.',
      ctaLabel: 'View My Passport',
      duration: ExperienceTimingPreset.moment,
      sound: ExperienceSoundKind.stampSoft,
      haptic: ExperienceHapticKind.thud,
      stampDefinition: PassportStampDefinition.selfReportedCircle,
      featureFlagKey: 'firstProofExperienceEnabled',
    ),
    ExperienceEventType.coachVerified: ExperienceDefinition(
      type: ExperienceEventType.coachVerified,
      importance: ExperienceImportance.t3Landmark,
      primaryMessage: (ctx) {
        final name = ctx.coachName.trim();
        if (name.isEmpty) {
          return 'Your coach verified this. It is witnessed now.';
        }
        return '$name verified this. It is witnessed now.';
      },
      secondaryMessage: (_) =>
          'Someone else believes this belongs in your story.',
      ctaLabel: 'View Verified Proof',
      secondaryCtaLabel: 'Share This Chapter',
      duration: ExperienceTimingPreset.chapter,
      sound: ExperienceSoundKind.stampDeep,
      haptic: ExperienceHapticKind.doubleThud,
      stampDefinition: PassportStampDefinition.coachWitnessed,
      featureFlagKey: 'coachVerificationExperienceEnabled',
    ),
    ExperienceEventType.silentMoment: ExperienceDefinition(
      type: ExperienceEventType.silentMoment,
      importance: ExperienceImportance.t0Silent,
      primaryMessage: (_) => '',
      duration: ExperienceTimingPreset.breath,
      skippable: true,
    ),
    ExperienceEventType.whisper: ExperienceDefinition(
      type: ExperienceEventType.whisper,
      importance: ExperienceImportance.t1Whisper,
      primaryMessage: (ctx) => ctx.extra['whisper'] ?? 'A quiet note.',
      duration: ExperienceTimingPreset.tick,
      haptic: ExperienceHapticKind.tap,
    ),
    ExperienceEventType.momentDemo: ExperienceDefinition(
      type: ExperienceEventType.momentDemo,
      importance: ExperienceImportance.t2Moment,
      primaryMessage: (_) => 'A moment worth pausing for.',
      secondaryMessage: (_) => 'Gallery preview only.',
      duration: ExperienceTimingPreset.moment,
      sound: ExperienceSoundKind.stampSoft,
      haptic: ExperienceHapticKind.thud,
    ),
    ExperienceEventType.landmarkDemo: ExperienceDefinition(
      type: ExperienceEventType.landmarkDemo,
      importance: ExperienceImportance.t3Landmark,
      primaryMessage: (_) => 'A landmark in your physical life.',
      secondaryMessage: (_) => 'Gallery preview only.',
      duration: ExperienceTimingPreset.chapter,
      sound: ExperienceSoundKind.binding,
      haptic: ExperienceHapticKind.pulse,
    ),
  };
}
