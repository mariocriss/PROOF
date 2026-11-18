import 'package:flutter/foundation.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/application/experience_runtime_store.dart';
import 'package:proof/features/experience/domain/experience_definition_registry.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/media/experience_haptic_service.dart';
import 'package:proof/features/experience/media/experience_sound_service.dart';
import 'package:proof/features/experience/presentation/experience_overlay_controller.dart';

/// Debug-only direct overlay presentation — bypasses receipts, eligibility, and auth.
Future<ExperiencePresentationOutcome> presentExperienceDirectly({
  required ExperienceOverlayController overlay,
  required ExperienceSoundService sound,
  required ExperienceHapticService haptics,
  required ExperienceRuntimeStore runtime,
  required ExperienceEvent event,
  ExperienceDefinitionRegistry? registry,
}) {
  assert(kDebugMode);
  final defs = registry ?? ExperienceDefinitionRegistry();
  final definition = defs.get(event.type);
  if (definition == null) {
    return Future.value(ExperiencePresentationOutcome.failed);
  }
  final flags = runtime.flags;
  final prefs = runtime.preferences;
  final reduceMotion = prefs.reduceMotion || !flags.passportMotionEnabled;
  return overlay.present(
    request: ExperiencePresentationRequest(
      event: event,
      definition: definition,
      preferences: prefs,
      flags: flags,
      reduceMotion: reduceMotion,
    ),
    sound: sound,
    haptics: haptics,
  );
}
