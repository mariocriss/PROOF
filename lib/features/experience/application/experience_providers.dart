import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/features/experience/application/experience_analytics.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/application/experience_diagnostics.dart';
import 'package:proof/features/experience/application/experience_eligibility_service.dart';
import 'package:proof/features/experience/application/experience_event_factory.dart';
import 'package:proof/features/experience/application/experience_runtime_providers.dart';
import 'package:proof/features/experience/application/experience_runtime_store.dart';
import 'package:proof/features/experience/application/experience_trigger_service.dart';
import 'package:proof/features/experience/data/experience_receipt_repository.dart';
import 'package:proof/features/experience/data/firestore_experience_receipt_repository.dart';
import 'package:proof/features/experience/domain/experience_definition_registry.dart';
import 'package:proof/features/experience/domain/experience_playback_settings.dart';
import 'package:proof/features/experience/media/experience_haptic_service.dart';
import 'package:proof/features/experience/media/experience_sound_service.dart';
import 'package:proof/features/experience/presentation/experience_overlay_controller.dart';
import 'package:proof/shared/providers/app_providers.dart';

export 'experience_runtime_providers.dart'
    show
        experienceDebugTestModePersistenceProvider,
        experienceFeatureFlagsProvider,
        experiencePreferencesProvider,
        experienceRuntimeStoreProvider,
        experienceGalleryRuntimeStoreProvider;

/// Debug-only QA tuning (Gallery / test controls).
final experiencePlaybackSettingsProvider =
    StateProvider<ExperiencePlaybackSettings>((ref) {
  if (kDebugMode) ref.keepAlive();
  return const ExperiencePlaybackSettings();
});

final experienceDefinitionRegistryProvider =
    Provider<ExperienceDefinitionRegistry>((ref) {
  ref.keepAlive();
  return ExperienceDefinitionRegistry();
});

final experienceEventFactoryProvider = Provider<ExperienceEventFactory>((ref) {
  ref.keepAlive();
  return const ExperienceEventFactory();
});

final experienceReceiptRepositoryProvider =
    Provider<ExperienceReceiptRepository>((ref) {
  ref.keepAlive();
  return FirestoreExperienceReceiptRepository(ref.read(firestoreProvider));
});

final experienceSoundServiceProvider = Provider<ExperienceSoundService>((ref) {
  ref.keepAlive();
  final store = ref.watch(experienceRuntimeStoreProvider);
  return GatedExperienceSoundService(
    inner: PlaceholderExperienceSoundService(),
    enabled: () =>
        store.flags.soundsEnabled && store.preferences.soundsEnabled,
  );
});

final experienceHapticServiceProvider =
    Provider<ExperienceHapticService>((ref) {
  ref.keepAlive();
  final store = ref.watch(experienceRuntimeStoreProvider);
  return GatedExperienceHapticService(
    inner: const PlatformExperienceHapticService(),
    enabled: () =>
        store.flags.hapticsEnabled && store.preferences.hapticsEnabled,
  );
});

final experienceOverlayControllerProvider =
    ChangeNotifierProvider<ExperienceOverlayController>((ref) {
  ref.keepAlive();
  return ExperienceOverlayController();
});

ExperienceCoordinator _buildCoordinator({
  required ExperienceRuntimeStore runtime,
  required ExperienceReceiptRepository receipts,
  required ExperienceDefinitionRegistry registry,
  required ExperienceOverlayController overlay,
  required ExperienceSoundService sound,
  required ExperienceHapticService haptics,
  required ExperienceDiagnostics diagnostics,
  required bool writeReceipts,
}) {
  return ExperienceCoordinator(
    runtime: runtime,
    receipts: receipts,
    eligibility: ExperienceEligibilityService(
      receipts: receipts,
      runtime: runtime,
      registry: registry,
    ),
    registry: registry,
    diagnostics: diagnostics,
    analytics: const NoOpExperienceAnalytics(),
    writeReceipts: writeReceipts,
    presenter: (request) {
      return overlay.present(
        request: request,
        sound: sound,
        haptics: haptics,
      );
    },
  );
}

final experienceCoordinatorProvider = Provider<ExperienceCoordinator>((ref) {
  ref.keepAlive();
  return _buildCoordinator(
    runtime: ref.read(experienceRuntimeStoreProvider),
    receipts: ref.read(experienceReceiptRepositoryProvider),
    registry: ref.read(experienceDefinitionRegistryProvider),
    overlay: ref.read(experienceOverlayControllerProvider),
    sound: ref.read(experienceSoundServiceProvider),
    haptics: ref.read(experienceHapticServiceProvider),
    diagnostics: ref.read(experienceDiagnosticsProvider),
    writeReceipts: true,
  );
});

final experienceTriggerServiceProvider = Provider<ExperienceTriggerService>((ref) {
  ref.keepAlive();
  return ExperienceTriggerService(
    coordinator: ref.read(experienceCoordinatorProvider),
    factory: ref.read(experienceEventFactoryProvider),
    runtime: ref.read(experienceRuntimeStoreProvider),
    diagnostics: ref.read(experienceDiagnosticsProvider),
  );
});

/// Debug-only gallery coordinator that never writes production receipts.
final experienceGalleryCoordinatorProvider =
    Provider<ExperienceCoordinator>((ref) {
  ref.keepAlive();
  final memory = InMemoryExperienceReceiptRepository();
  return _buildCoordinator(
    runtime: ref.read(experienceGalleryRuntimeStoreProvider),
    receipts: memory,
    registry: ref.read(experienceDefinitionRegistryProvider),
    overlay: ref.read(experienceOverlayControllerProvider),
    sound: ref.read(experienceSoundServiceProvider),
    haptics: ref.read(experienceHapticServiceProvider),
    diagnostics: ref.read(experienceDiagnosticsProvider),
    writeReceipts: false,
  );
});

bool get experienceGalleryRouteEnabled => kDebugMode;
