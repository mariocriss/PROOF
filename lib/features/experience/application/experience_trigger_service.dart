import 'package:flutter/foundation.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/application/experience_diagnostics.dart';
import 'package:proof/features/experience/application/experience_event_factory.dart';
import 'package:proof/features/experience/application/experience_runtime_store.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/verification_status.dart';

/// Thin trigger layer after successful domain writes.
/// Never blocks or rolls back domain success.
class ExperienceTriggerService {
  ExperienceTriggerService({
    required ExperienceCoordinator coordinator,
    required ExperienceEventFactory factory,
    required ExperienceRuntimeStore runtime,
    ExperienceDiagnostics? diagnostics,
  })  : _coordinator = coordinator,
        _factory = factory,
        _runtime = runtime,
        _diagnostics = diagnostics;

  final ExperienceCoordinator _coordinator;
  final ExperienceEventFactory _factory;
  final ExperienceRuntimeStore _runtime;
  final ExperienceDiagnostics? _diagnostics;
  final Set<String> _sessionOfferedIds = {};

  /// Test helper — clears session dedupe.
  @visibleForTesting
  void clearSessionDedupe() => _sessionOfferedIds.clear();

  Future<void> onOnboardingCompleted({
    required String userId,
    PhysicalIdentity? identity,
  }) async {
    final flags = _runtime.flags;
    if (!_enabled(flags)) {
      _reject('engine_off', '', flags: flags);
      return;
    }
    if (!flags.accountCreationExperienceEnabled && !flags.galleryMode) {
      _reject('flag_off:account_creation', '', flags: flags);
      return;
    }

    final event = _factory.onboardingCompleted(
      userId: userId,
      context: ExperienceContext(
        userId: userId,
        displayName: identity?.displayName ?? '',
        handle: identity?.handle ?? '',
        sourceId: userId,
      ),
    );
    await _safeOffer(event, flags);
  }

  Future<void> onProofCreated({
    required String userId,
    required ProofModel proof,
    required int totalProofCountAfterCreate,
    String skillName = '',
  }) async {
    final flags = _runtime.flags;
    if (!_enabled(flags)) {
      _reject('engine_off', proof.id, flags: flags);
      return;
    }
    if (!flags.firstProofExperienceEnabled && !flags.galleryMode) {
      _reject('flag_off:first_proof', proof.id, flags: flags);
      return;
    }

    final isFirst = totalProofCountAfterCreate == 1;
    final event = _factory.firstProofCreated(
      userId: userId,
      proof: proof,
      isActualFirstProof: isFirst,
      context: ExperienceContext(
        userId: userId,
        skillName: skillName,
        proofId: proof.id,
        proofResult: proof.result,
        proofUnit: proof.unit,
        proofDate: proof.recordedAt,
        sourceId: proof.id,
      ),
    );
    if (event == null) {
      _reject(
        'not_first_proof',
        proof.id,
        detail: 'count=$totalProofCountAfterCreate',
        flags: flags,
      );
      return;
    }
    await _safeOffer(event, flags);
  }

  Future<void> onCoachVerifiedProofs({
    required List<ProofModel> proofs,
    String Function(String coachId)? coachNameResolver,
  }) async {
    final flags = _runtime.flags;
    if (!_enabled(flags)) {
      _reject('engine_off', '', flags: flags);
      return;
    }
    if (!flags.coachVerificationExperienceEnabled && !flags.galleryMode) {
      _reject('flag_off:coach_verify', '', flags: flags);
      return;
    }

    for (final proof in proofs) {
      if (proof.verificationStatus != VerificationStatus.coachVerified &&
          !proof.isCoachVerifiedForStack) {
        continue;
      }
      final coachId = proof.verifiedByCoachId ?? proof.coachId ?? '';
      final coachName =
          coachId.isNotEmpty ? (coachNameResolver?.call(coachId) ?? '') : '';
      final event = _factory.coachVerified(
        proof: proof,
        context: ExperienceContext(
          userId: proof.userId,
          proofId: proof.id,
          proofResult: proof.result,
          proofUnit: proof.unit,
          proofDate: proof.recordedAt,
          coachName: coachName,
          coachInitials: _initials(coachName),
          verificationDate: proof.verifiedAt,
          sourceId: proof.id,
        ),
      );
      if (event == null) continue;
      await _safeOffer(event, flags);
    }
  }

  bool _enabled(ExperienceFeatureFlags flags) {
    return flags.experienceEngineEnabled || flags.galleryMode;
  }

  void _reject(
    String reason,
    String eventId, {
    String detail = '',
    required ExperienceFeatureFlags flags,
  }) {
    final flagsDetail =
        'engine=${flags.experienceEngineEnabled} issuance=${flags.accountCreationExperienceEnabled} '
        'first=${flags.firstProofExperienceEnabled} coach=${flags.coachVerificationExperienceEnabled}';
    _diagnostics?.log(
      ExperienceDiagnosticKind.eventRejected,
      eventId: eventId,
      detail: detail.isEmpty
          ? '$reason · $flagsDetail'
          : '$reason · $detail · $flagsDetail',
    );
  }

  Future<void> _safeOffer(
    ExperienceEvent event,
    ExperienceFeatureFlags flags,
  ) async {
    if (!_sessionOfferedIds.add(event.id)) {
      _diagnostics?.log(
        ExperienceDiagnosticKind.eventRejected,
        eventId: event.id,
        detail: 'session_dedupe',
      );
      return;
    }
    try {
      final queued = await _coordinator.offer(event);
      if (!queued) {
        _sessionOfferedIds.remove(event.id);
      }
    } catch (e, stack) {
      _sessionOfferedIds.remove(event.id);
      _diagnostics?.reportPipelineFailure(
        stage: 'trigger_safe_offer',
        eventId: event.id,
        error: e,
        stackTrace: stack,
      );
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length.clamp(0, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
