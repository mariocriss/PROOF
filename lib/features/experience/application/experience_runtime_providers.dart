import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/constants/app_features.dart';
import 'package:proof/features/experience/application/experience_runtime_store.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/features/experience/domain/experience_preferences.dart';

/// Debug test-mode override that survives sign-out, navigation, and provider rebuilds.
final experienceDebugTestModePersistenceProvider =
    Provider<ExperienceDebugTestModePersistence>((ref) {
  ref.keepAlive();
  return ExperienceDebugTestModePersistence();
});

/// UI-writable feature flags. Kept alive in debug so overrides survive auth changes.
final experienceFeatureFlagsProvider =
    StateProvider<ExperienceFeatureFlags>((ref) {
  if (kDebugMode) {
    ref.keepAlive();
    final persisted = ref.read(experienceDebugTestModePersistenceProvider);
    return persisted.resolve(AppFeatures.experienceFlags);
  }
  return AppFeatures.experienceFlags;
});

final experiencePreferencesProvider =
    StateProvider<ExperiencePreferences>((ref) {
  if (kDebugMode) ref.keepAlive();
  return const ExperiencePreferences();
});

/// Live synchronous snapshots for async pipeline code — no Ref after await.
final experienceRuntimeStoreProvider = Provider<ExperienceRuntimeStore>((ref) {
  ref.keepAlive();
  final store = ExperienceRuntimeStore(
    flags: ref.read(experienceFeatureFlagsProvider),
    preferences: ref.read(experiencePreferencesProvider),
  );
  ref.listen(experienceFeatureFlagsProvider, (_, next) {
    store.updateFlags(next);
  });
  ref.listen(experiencePreferencesProvider, (_, next) {
    store.updatePreferences(next);
  });
  return store;
});

/// Gallery coordinator reads flags through this store (galleryMode forced on).
final experienceGalleryRuntimeStoreProvider =
    Provider<ExperienceRuntimeStore>((ref) {
  ref.keepAlive();
  final base = ref.watch(experienceRuntimeStoreProvider);
  return ExperienceRuntimeStore(
    flags: base.flags,
    preferences: base.preferences,
    forceGalleryMode: true,
  );
});
