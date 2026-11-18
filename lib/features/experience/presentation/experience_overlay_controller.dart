import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/media/experience_haptic_service.dart';
import 'package:proof/features/experience/media/experience_sound_service.dart';

/// Holds the active presentation request for [ExperienceOverlayHost].
class ExperienceOverlayController extends ChangeNotifier {
  ExperiencePresentationRequest? _request;
  Completer<ExperiencePresentationOutcome>? _completer;
  ExperienceSoundService? _sound;
  ExperienceHapticService? _haptics;

  ExperiencePresentationRequest? get request => _request;
  ExperienceSoundService? get sound => _sound;
  ExperienceHapticService? get haptics => _haptics;

  Future<ExperiencePresentationOutcome> present({
    required ExperiencePresentationRequest request,
    required ExperienceSoundService sound,
    required ExperienceHapticService haptics,
  }) {
    // Replace any stuck presentation safely.
    if (_completer != null && !(_completer!.isCompleted)) {
      _completer!.complete(ExperiencePresentationOutcome.failed);
    }
    _request = request;
    _sound = sound;
    _haptics = haptics;
    _completer = Completer<ExperiencePresentationOutcome>();
    notifyListeners();
    return _completer!.future;
  }

  void complete(ExperiencePresentationOutcome outcome) {
    if (_completer == null || _completer!.isCompleted) {
      _request = null;
      notifyListeners();
      return;
    }
    _completer!.complete(outcome);
    _request = null;
    _sound = null;
    _haptics = null;
    notifyListeners();
  }

  void skip() => complete(ExperiencePresentationOutcome.dismissed);

  @override
  void dispose() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(ExperiencePresentationOutcome.failed);
    }
    super.dispose();
  }
}
