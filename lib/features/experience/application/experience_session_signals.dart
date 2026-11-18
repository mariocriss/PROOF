import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot signal from onboarding to present issuance over the dashboard.
final pendingIssuanceExperienceProvider = StateProvider<String?>((ref) => null);

/// One-shot signal after first proof save — presentation should occur before nav.
final pendingFirstProofExperienceProvider =
    StateProvider<PendingFirstProofSignal?>((ref) => null);

class PendingFirstProofSignal {
  const PendingFirstProofSignal({
    required this.userId,
    required this.proofId,
  });

  final String userId;
  final String proofId;
}

/// Tracks coach-verified state per proof to detect transitions only.
final coachVerificationBaselineProvider =
    StateProvider<Map<String, bool>>((ref) => {});

/// Ensures pending receipt resume runs once per signed-in user per session.
final experienceResumeGuardProvider = StateProvider<String?>((ref) => null);