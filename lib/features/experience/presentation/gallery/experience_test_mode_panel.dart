import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/experience/application/experience_debug_service.dart';
import 'package:proof/features/experience/application/experience_providers.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/features/experience/domain/experience_preferences.dart';

/// Debug-only local flag overrides for emulator / internal QA.
/// Production [AppFeatures] defaults remain OFF; release builds hide this UI.
class ExperienceTestMode {
  ExperienceTestMode._();

  /// Engine + motion + guide + haptics + all three reference moments. Sounds OFF.
  static const ExperienceFeatureFlags allReferencesOn = ExperienceFeatureFlags(
    experienceEngineEnabled: true,
    passportMotionEnabled: true,
    guideEnabled: true,
    soundsEnabled: false,
    hapticsEnabled: true,
    accountCreationExperienceEnabled: true,
    firstProofExperienceEnabled: true,
    coachVerificationExperienceEnabled: true,
  );

  static const ExperienceFeatureFlags allOff = ExperienceFeatureFlags();

  static bool isAllReferencesEnabled(ExperienceFeatureFlags flags) {
    return flags.experienceEngineEnabled &&
        flags.passportMotionEnabled &&
        flags.guideEnabled &&
        flags.hapticsEnabled &&
        flags.accountCreationExperienceEnabled &&
        flags.firstProofExperienceEnabled &&
        flags.coachVerificationExperienceEnabled &&
        !flags.soundsEnabled;
  }

  static void applyFlags(WidgetRef ref, ExperienceFeatureFlags flags) {
    assert(kDebugMode);
    ref.read(experienceDebugTestModePersistenceProvider).override = flags;
    ref.read(experienceFeatureFlagsProvider.notifier).state = flags;
    ref.read(experiencePreferencesProvider.notifier).state =
        ExperiencePreferences(
      guideEnabled: flags.guideEnabled,
      hapticsEnabled: flags.hapticsEnabled,
      soundsEnabled: flags.soundsEnabled,
      motion: ExperienceMotionPreferences(
        reduceMotion: !flags.passportMotionEnabled,
      ),
    );
    ref.read(experienceRuntimeStoreProvider).updateFlags(flags);
    ref.read(experienceRuntimeStoreProvider).updatePreferences(
          ref.read(experiencePreferencesProvider),
        );
  }

  static void enableAllReferences(WidgetRef ref) {
    applyFlags(ref, allReferencesOn);
  }

  static void disableAll(WidgetRef ref) {
    ref.read(experienceDebugTestModePersistenceProvider).override = null;
    applyFlags(ref, allOff);
  }

  static void patchFlags(
    WidgetRef ref,
    ExperienceFeatureFlags Function(ExperienceFeatureFlags current) patch,
  ) {
    final next = patch(ref.read(experienceFeatureFlagsProvider));
    applyFlags(ref, next);
  }
}

/// Shared debug panel — embed in Gallery and Test Controls.
class ExperienceTestModePanel extends ConsumerWidget {
  const ExperienceTestModePanel({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(kDebugMode);
    final flags = ref.watch(experienceFeatureFlagsProvider);
    final allOn = ExperienceTestMode.isAllReferencesEnabled(flags);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Experience Test Mode',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                'Local debug overrides only. Release builds cannot access this. '
                'Sounds stay optional (no assets yet).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All three reference experiences'),
              subtitle: const Text(
                'Engine, motion, guide, haptics, issuance, first proof, coach verify',
              ),
              value: allOn,
              onChanged: (on) {
                if (on) {
                  ExperienceTestMode.enableAllReferences(ref);
                } else {
                  ExperienceTestMode.disableAll(ref);
                }
              },
            ),
            const Divider(height: 16),
            Text(
              'Infrastructure',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
            _flagSwitch(
              ref: ref,
              flags: flags,
              label: 'experienceEngineEnabled',
              value: flags.experienceEngineEnabled,
              onChanged: (v) => ExperienceTestMode.patchFlags(
                ref,
                (f) => f.copyWith(experienceEngineEnabled: v),
              ),
            ),
            _flagSwitch(
              ref: ref,
              flags: flags,
              label: 'passportMotionEnabled',
              value: flags.passportMotionEnabled,
              onChanged: (v) => ExperienceTestMode.patchFlags(
                ref,
                (f) => f.copyWith(passportMotionEnabled: v),
              ),
            ),
            _flagSwitch(
              ref: ref,
              flags: flags,
              label: 'guideEnabled',
              value: flags.guideEnabled,
              onChanged: (v) => ExperienceTestMode.patchFlags(
                ref,
                (f) => f.copyWith(guideEnabled: v),
              ),
            ),
            _flagSwitch(
              ref: ref,
              flags: flags,
              label: 'hapticsEnabled',
              value: flags.hapticsEnabled,
              onChanged: (v) => ExperienceTestMode.patchFlags(
                ref,
                (f) => f.copyWith(hapticsEnabled: v),
              ),
            ),
            _flagSwitch(
              ref: ref,
              flags: flags,
              label: 'soundsEnabled (optional — silent placeholder)',
              value: flags.soundsEnabled,
              onChanged: (v) => ExperienceTestMode.patchFlags(
                ref,
                (f) => f.copyWith(soundsEnabled: v),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reference moments',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
            _flagSwitch(
              ref: ref,
              flags: flags,
              label: 'accountCreationExperienceEnabled',
              value: flags.accountCreationExperienceEnabled,
              onChanged: (v) => ExperienceTestMode.patchFlags(
                ref,
                (f) => f.copyWith(accountCreationExperienceEnabled: v),
              ),
            ),
            _flagSwitch(
              ref: ref,
              flags: flags,
              label: 'firstProofExperienceEnabled',
              value: flags.firstProofExperienceEnabled,
              onChanged: (v) => ExperienceTestMode.patchFlags(
                ref,
                (f) => f.copyWith(firstProofExperienceEnabled: v),
              ),
            ),
            _flagSwitch(
              ref: ref,
              flags: flags,
              label: 'coachVerificationExperienceEnabled',
              value: flags.coachVerificationExperienceEnabled,
              onChanged: (v) => ExperienceTestMode.patchFlags(
                ref,
                (f) => f.copyWith(coachVerificationExperienceEnabled: v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flagSwitch({
    required WidgetRef ref,
    required ExperienceFeatureFlags flags,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
    );
  }
}
