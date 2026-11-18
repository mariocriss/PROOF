import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/experience/application/experience_direct_present.dart';
import 'package:proof/features/experience/application/experience_debug_service.dart';
import 'package:proof/features/experience/application/experience_providers.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/features/experience/domain/experience_playback_settings.dart';
import 'package:proof/features/experience/domain/experience_preferences.dart';
import 'package:proof/features/experience/presentation/experience_overlay_controller.dart';
import 'package:proof/features/experience/presentation/gallery/experience_diagnostics_panel.dart';
import 'package:proof/features/experience/presentation/gallery/experience_test_mode_panel.dart';

/// Debug-only gallery. Never writes production receipts, proofs, or analytics.
class ExperienceGalleryScreen extends ConsumerStatefulWidget {
  const ExperienceGalleryScreen({super.key});

  @override
  ConsumerState<ExperienceGalleryScreen> createState() =>
      _ExperienceGalleryScreenState();
}

class _ExperienceGalleryScreenState
    extends ConsumerState<ExperienceGalleryScreen> {
  String _name = 'Alex Rivera';
  String _skill = '5K Run';
  String _result = '24:10';
  String _coach = 'Jordan Lee';
  bool _localReduce = false;
  bool _localGuide = true;
  bool _localSound = false;
  bool _localHaptics = false;
  bool _autoOpenPassport = false;
  int _silentMs = 550;
  double _animSpeed = 1.0;
  double _textScale = 1.0;
  double? _deviceWidth;
  ExperienceBackgroundPreset _bg = ExperienceBackgroundPreset.neutral;
  bool _showSemantics = false;
  bool _showBounds = false;
  bool _showDiagnostics = false;
  bool _simulateSoundFail = false;
  bool _simulateMissing = false;
  bool _simulateException = false;
  String _lastEventId = '';

  ExperienceContext get _context => ExperienceContext(
        displayName: _name,
        skillName: _skill,
        proofResult: _result,
        proofUnit: '',
        proofId: 'gallery-proof',
        coachName: _coach,
        verificationDate: DateTime.now(),
        proofDate: DateTime.now(),
      );

  void _applyPlayback() {
    ref.read(experiencePlaybackSettingsProvider.notifier).state =
        ExperiencePlaybackSettings(
      silentMomentMs: _silentMs,
      animationSpeed: _animSpeed,
      showSemanticLabels: _showSemantics,
      showAnimationBounds: _showBounds,
      showEventDiagnostics: _showDiagnostics,
      simulateSoundFailure: _simulateSoundFail,
      simulateSourceMissing: _simulateMissing,
      simulatePresentationException: _simulateException,
      backgroundPreset: _bg,
      deviceWidth: _deviceWidth,
      textScale: _textScale,
    );
  }

  void _applyLocalPrefs() {
    ref.read(experiencePreferencesProvider.notifier).state =
        ExperiencePreferences(
      guideEnabled: _localGuide,
      soundsEnabled: _localSound,
      hapticsEnabled: _localHaptics,
      motion: ExperienceMotionPreferences(reduceMotion: _localReduce),
    );
    ref.read(experienceFeatureFlagsProvider.notifier).state =
        ExperienceFeatureFlags.allOnForGallery.copyWith(
      guideEnabled: _localGuide,
      soundsEnabled: _localSound,
      hapticsEnabled: _localHaptics,
      passportMotionEnabled: !_localReduce,
    );
    _applyPlayback();
  }

  Future<void> _runThroughEngine(ExperienceEventType type) async {
    assert(kDebugMode, 'Gallery is debug-only');
    _applyLocalPrefs();
    final factory = ref.read(experienceEventFactoryProvider);
    final coordinator = ref.read(experienceGalleryCoordinatorProvider);
    coordinator.resetGalleryQueue();

    final importance = switch (type) {
      ExperienceEventType.silentMoment => ExperienceImportance.t0Silent,
      ExperienceEventType.whisper => ExperienceImportance.t1Whisper,
      ExperienceEventType.momentDemo => ExperienceImportance.t2Moment,
      ExperienceEventType.landmarkDemo => ExperienceImportance.t3Landmark,
      _ => ExperienceImportance.t3Landmark,
    };

    final event = factory.galleryPreview(
      type: type,
      importance: importance,
      context: _context,
    );
    setState(() => _lastEventId = event.id);

    if (_autoOpenPassport &&
        type == ExperienceEventType.onboardingCompleted &&
        !_localReduce) {
      await coordinator.offer(event);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } else {
      await coordinator.offer(event);
    }
  }

  Future<void> _renderStageDirectly(ExperienceEventType type) async {
    assert(kDebugMode);
    _applyLocalPrefs();
    final factory = ref.read(experienceEventFactoryProvider);
    final event = factory.galleryPreview(
      type: type,
      importance: ExperienceImportance.t3Landmark,
      context: _context,
    );
    setState(() => _lastEventId = '${event.id} (direct)');

    final overlay = ref.read(experienceOverlayControllerProvider);
    final sound = ref.read(experienceSoundServiceProvider);
    final haptics = ref.read(experienceHapticServiceProvider);
    final runtime = ref.read(experienceGalleryRuntimeStoreProvider);

    await presentExperienceDirectly(
      overlay: overlay,
      sound: sound,
      haptics: haptics,
      runtime: runtime,
      event: event,
      registry: ref.read(experienceDefinitionRegistryProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode);
    final overlayActive =
        ref.watch(experienceOverlayControllerProvider).request != null;

    if (overlayActive) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Experience Gallery'),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: () => context.push('/debug/experience-test'),
            child: const Text('Test Controls'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Debug only — no production receipts or proofs.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
          if (_lastEventId.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              'Last event: $_lastEventId',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ],
          const SizedBox(height: 16),
          const ExperienceTestModePanel(compact: true),
          const SizedBox(height: 12),
          const ExperienceDiagnosticsPanel(compact: true),
          const SizedBox(height: 16),
          _field('Name', _name, (v) => setState(() => _name = v)),
          _field('Skill', _skill, (v) => setState(() => _skill = v)),
          _field('Result', _result, (v) => setState(() => _result = v)),
          _field('Coach', _coach, (v) => setState(() => _coach = v)),
          const Divider(height: 32),
          Text('Playback', style: Theme.of(context).textTheme.titleSmall),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 400, label: Text('400ms')),
              ButtonSegment(value: 550, label: Text('550ms')),
              ButtonSegment(value: 700, label: Text('700ms')),
            ],
            selected: {_silentMs},
            onSelectionChanged: (s) => setState(() => _silentMs = s.first),
          ),
          const SizedBox(height: 8),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 0.5, label: Text('0.5×')),
              ButtonSegment(value: 1.0, label: Text('1×')),
              ButtonSegment(value: 1.5, label: Text('1.5×')),
            ],
            selected: {_animSpeed},
            onSelectionChanged: (s) => setState(() => _animSpeed = s.first),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<double?>(
            initialValue: _deviceWidth,
            decoration: const InputDecoration(labelText: 'Device width'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Full width')),
              DropdownMenuItem(value: 320, child: Text('Small (320)')),
              DropdownMenuItem(value: 390, child: Text('Phone (390)')),
              DropdownMenuItem(value: 420, child: Text('Max (420)')),
            ],
            onChanged: (v) => setState(() => _deviceWidth = v),
          ),
          DropdownButtonFormField<double>(
            initialValue: _textScale,
            decoration: const InputDecoration(labelText: 'Text scale'),
            items: const [
              DropdownMenuItem(value: 1.0, child: Text('1.0×')),
              DropdownMenuItem(value: 1.3, child: Text('1.3×')),
              DropdownMenuItem(value: 1.6, child: Text('1.6×')),
            ],
            onChanged: (v) => setState(() => _textScale = v ?? 1.0),
          ),
          DropdownButtonFormField<ExperienceBackgroundPreset>(
            initialValue: _bg,
            decoration: const InputDecoration(labelText: 'Background context'),
            items: ExperienceBackgroundPreset.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _bg = v ?? _bg),
          ),
          SwitchListTile(
            title: const Text('Reduced motion'),
            value: _localReduce,
            onChanged: (v) => setState(() => _localReduce = v),
          ),
          SwitchListTile(
            title: const Text('Guide'),
            value: _localGuide,
            onChanged: (v) => setState(() => _localGuide = v),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            value: _localSound,
            onChanged: (v) => setState(() => _localSound = v),
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: _localHaptics,
            onChanged: (v) => setState(() => _localHaptics = v),
          ),
          SwitchListTile(
            title: const Text('Auto-open passport (gallery only)'),
            subtitle: const Text('Production remains user-initiated'),
            value: _autoOpenPassport,
            onChanged: (v) => setState(() => _autoOpenPassport = v),
          ),
          SwitchListTile(
            title: const Text('Show semantic labels'),
            value: _showSemantics,
            onChanged: (v) => setState(() => _showSemantics = v),
          ),
          SwitchListTile(
            title: const Text('Show animation bounds'),
            value: _showBounds,
            onChanged: (v) => setState(() => _showBounds = v),
          ),
          SwitchListTile(
            title: const Text('Show event diagnostics'),
            value: _showDiagnostics,
            onChanged: (v) => setState(() => _showDiagnostics = v),
          ),
          SwitchListTile(
            title: const Text('Simulate sound failure'),
            value: _simulateSoundFail,
            onChanged: (v) => setState(() => _simulateSoundFail = v),
          ),
          SwitchListTile(
            title: const Text('Simulate source missing'),
            value: _simulateMissing,
            onChanged: (v) => setState(() => _simulateMissing = v),
          ),
          SwitchListTile(
            title: const Text('Simulate presentation exception'),
            value: _simulateException,
            onChanged: (v) => setState(() => _simulateException = v),
          ),
          const Divider(height: 32),
          Text('Reference moments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Run through engine — full pipeline (eligibility, queue, receipts off in gallery).\n'
            'Render stage directly — visuals only, no pipeline.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
          const SizedBox(height: 8),
          _btn('Passport Issuance (engine)', () => _runThroughEngine(ExperienceEventType.onboardingCompleted)),
          _btn('First Proof (engine)', () => _runThroughEngine(ExperienceEventType.firstProofCreated)),
          _btn('Coach Verification (engine)', () => _runThroughEngine(ExperienceEventType.coachVerified)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _renderStageDirectly(ExperienceEventType.onboardingCompleted),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Render stage directly — Passport Issuance'),
            ),
          ),
          OutlinedButton(
            onPressed: () => _renderStageDirectly(ExperienceEventType.firstProofCreated),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Render stage directly — First Proof'),
            ),
          ),
          OutlinedButton(
            onPressed: () => _renderStageDirectly(ExperienceEventType.coachVerified),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Render stage directly — Coach Verification'),
            ),
          ),
          _btn('Coach (missing name)', () async {
            setState(() => _coach = '');
            await _runThroughEngine(ExperienceEventType.coachVerified);
          }),
          const SizedBox(height: 16),
          Text('Stress cases', style: Theme.of(context).textTheme.titleMedium),
          _btn('Long name / skill / result', () async {
            setState(() {
              _name = 'Alexandra María del Carmen Rivera-Montgomery III';
              _skill = 'Ultra-endurance multi-day alpine trail traverse';
              _result = '126.4 km · 18h 42m';
            });
            await _runThroughEngine(ExperienceEventType.firstProofCreated);
          }),
          OutlinedButton(
            onPressed: () {
              ref.read(experienceOverlayControllerProvider).skip();
              ref.read(experienceGalleryCoordinatorProvider).resetGalleryQueue();
              setState(() => _lastEventId = '');
            },
            child: const Text('Skip / Reset overlay'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  Widget _btn(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
      ),
    );
  }
}
