import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:proof/features/experience/application/experience_analytics.dart';
import 'package:proof/features/experience/application/experience_diagnostics.dart';
import 'package:proof/features/experience/application/experience_eligibility_service.dart';
import 'package:proof/features/experience/application/experience_queue.dart';
import 'package:proof/features/experience/application/experience_runtime_store.dart';
import 'package:proof/features/experience/data/experience_receipt_repository.dart';
import 'package:proof/features/experience/domain/experience_definition.dart';
import 'package:proof/features/experience/domain/experience_definition_registry.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/features/experience/domain/experience_preferences.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/features/experience/domain/experience_status.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';

typedef ExperiencePresenter = Future<ExperiencePresentationOutcome> Function(
  ExperiencePresentationRequest request,
);

enum ExperiencePresentationOutcome {
  completed,
  dismissed,
  failed,
}

class ExperiencePresentationRequest {
  const ExperiencePresentationRequest({
    required this.event,
    required this.definition,
    required this.preferences,
    required this.flags,
    required this.reduceMotion,
  });

  final ExperienceEvent event;
  final ExperienceDefinition definition;
  final ExperiencePreferences preferences;
  final ExperienceFeatureFlags flags;
  final bool reduceMotion;
}

/// Coordinates eligibility → receipt claim → queue → presentation → completion.
/// Domain state is never rolled back on presentation failure.
class ExperienceCoordinator {
  ExperienceCoordinator({
    required ExperienceRuntimeStore runtime,
    required ExperienceReceiptRepository receipts,
    required ExperienceEligibilityService eligibility,
    required ExperienceDefinitionRegistry registry,
    required ExperiencePresenter presenter,
    ExperienceAnalytics analytics = const NoOpExperienceAnalytics(),
    ExperienceDiagnostics? diagnostics,
    ExperienceQueue? queue,
    bool writeReceipts = true,
  })  : _runtime = runtime,
        _receipts = receipts,
        _eligibility = eligibility,
        _registry = registry,
        _presenter = presenter,
        _analytics = analytics,
        _diagnostics = diagnostics,
        _queue = queue ?? ExperienceQueue(),
        _writeReceipts = writeReceipts;

  final ExperienceRuntimeStore _runtime;
  final ExperienceReceiptRepository _receipts;
  final ExperienceEligibilityService _eligibility;
  final ExperienceDefinitionRegistry _registry;
  final ExperiencePresenter _presenter;
  final ExperienceAnalytics _analytics;
  final ExperienceDiagnostics? _diagnostics;
  final ExperienceQueue _queue;
  final bool _writeReceipts;

  bool _draining = false;
  final Set<String> _inFlightClaims = {};

  ExperienceQueue get queue => _queue;

  void _log(
    ExperienceDiagnosticKind kind, {
    String eventId = '',
    String detail = '',
  }) {
    _diagnostics?.log(kind, eventId: eventId, detail: detail);
  }

  /// Offer an event after a successful domain operation.
  /// Returns true when the event was queued for presentation.
  Future<bool> offer(ExperienceEvent event) async {
    final flagsSnapshot = _runtime.flags;
    _log(
      ExperienceDiagnosticKind.eventCreated,
      eventId: event.id,
      detail: _flagsDetail(flagsSnapshot),
    );

    final eligibility = await _eligibility.check(event);
    if (!eligibility.eligible) {
      _log(
        ExperienceDiagnosticKind.eventRejected,
        eventId: event.id,
        detail: eligibility.reason,
      );
      return false;
    }
    _log(
      ExperienceDiagnosticKind.eventEligible,
      eventId: event.id,
      detail: eligibility.reason,
    );

    var receiptBypassed = false;
    if (_writeReceipts && !flagsSnapshot.galleryMode) {
      if (_inFlightClaims.contains(event.id)) {
        _log(
          ExperienceDiagnosticKind.eventRejected,
          eventId: event.id,
          detail: 'claim_in_flight',
        );
        return false;
      }
      _inFlightClaims.add(event.id);
      try {
        final draft = ExperienceReceipt(
          id: event.id,
          ownerId: event.ownerId,
          eventType: event.type,
          sourceId: event.sourceId,
          importance: event.importance,
          status: ExperienceStatus.pending,
          createdAt: DateTime.now(),
        );
        final claimed = await _receipts.claimOrGet(draft);
        if (claimed.isTerminal) {
          _log(
            ExperienceDiagnosticKind.eventRejected,
            eventId: event.id,
            detail: 'receipt_terminal:${claimed.status.value}',
          );
          return false;
        }
        _log(ExperienceDiagnosticKind.receiptClaimed, eventId: event.id);
      } catch (e, stack) {
        if (kDebugMode) {
          _diagnostics?.reportPipelineFailure(
            stage: 'receipt_claim',
            eventId: event.id,
            error: e,
            stackTrace: stack,
          );
          // Presentation may continue in debug when rules are undeployed.
          receiptBypassed = true;
        } else {
          return false;
        }
      } finally {
        _inFlightClaims.remove(event.id);
      }
    }

    _queue.enqueue(event);
    _log(ExperienceDiagnosticKind.eventQueued, eventId: event.id);
    if (receiptBypassed) {
      _log(
        ExperienceDiagnosticKind.presentationRequested,
        eventId: event.id,
        detail: 'debug_receipt_bypass',
      );
    }
    await drain();
    return true;
  }

  /// Resume any pending receipts (e.g. offline coach approval).
  Future<void> resumePending({
    required String ownerId,
    required Future<ExperienceEvent?> Function(ExperienceReceipt receipt)
        hydrate,
  }) async {
    final flagsSnapshot = _runtime.flags;
    if (!flagsSnapshot.experienceEngineEnabled && !flagsSnapshot.galleryMode) {
      return;
    }
    try {
      final pending = await _receipts.listResumable(ownerId);
      for (final receipt in pending) {
        final event = await hydrate(receipt);
        if (event != null) {
          _queue.enqueue(event);
        }
      }
      await drain();
    } catch (e, stack) {
      _diagnostics?.reportPipelineFailure(
        stage: 'resume_pending',
        eventId: ownerId,
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (true) {
        final next = _queue.dequeueNext();
        if (next == null) break;
        await _present(next);
        _queue.clearActive();
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _present(ExperienceEvent event) async {
    final flagsSnapshot = _runtime.flags;
    final prefsSnapshot = _runtime.preferences;
    final definition = _registry.get(event.type);
    if (definition == null) {
      await _mark(event, ExperienceStatus.failed, flagsSnapshot);
      return;
    }

    final reduceMotion =
        prefsSnapshot.reduceMotion || !flagsSnapshot.passportMotionEnabled;

    if (_writeReceipts && !flagsSnapshot.galleryMode) {
      try {
        await _receipts.updateStatus(
          ownerId: event.ownerId,
          eventId: event.id,
          status: ExperienceStatus.presenting,
          shownAt: DateTime.now(),
        );
      } catch (_) {}
    }

    _analytics.trackPresented(type: event.type, eventId: event.id);
    _log(ExperienceDiagnosticKind.presentationRequested, eventId: event.id);

    ExperiencePresentationOutcome outcome;
    try {
      outcome = await _presenter(
        ExperiencePresentationRequest(
          event: event,
          definition: definition,
          preferences: prefsSnapshot,
          flags: flagsSnapshot,
          reduceMotion: reduceMotion,
        ),
      ).timeout(
        ExperienceTokens.safeAnimationTimeout,
        onTimeout: () => ExperiencePresentationOutcome.dismissed,
      );
    } catch (e, stack) {
      _diagnostics?.reportPipelineFailure(
        stage: 'presenter',
        eventId: event.id,
        error: e,
        stackTrace: stack,
      );
      outcome = ExperiencePresentationOutcome.failed;
    }

    switch (outcome) {
      case ExperiencePresentationOutcome.completed:
        await _mark(event, ExperienceStatus.completed, flagsSnapshot);
        _analytics.trackCompleted(type: event.type, eventId: event.id);
        _log(ExperienceDiagnosticKind.receiptCompleted, eventId: event.id);
      case ExperiencePresentationOutcome.dismissed:
        await _mark(event, ExperienceStatus.dismissed, flagsSnapshot);
        _analytics.trackDismissed(type: event.type, eventId: event.id);
        _log(ExperienceDiagnosticKind.receiptDismissed, eventId: event.id);
      case ExperiencePresentationOutcome.failed:
        await _mark(event, ExperienceStatus.failed, flagsSnapshot);
        _analytics.trackFailed(type: event.type, eventId: event.id);
        _log(ExperienceDiagnosticKind.receiptFailed, eventId: event.id);
    }
  }

  Future<void> _mark(
    ExperienceEvent event,
    ExperienceStatus status,
    ExperienceFeatureFlags flagsSnapshot,
  ) async {
    if (!_writeReceipts || flagsSnapshot.galleryMode) return;
    try {
      await _receipts.updateStatus(
        ownerId: event.ownerId,
        eventId: event.id,
        status: status,
        completedAt:
            status == ExperienceStatus.completed ? DateTime.now() : null,
        dismissedAt:
            status == ExperienceStatus.dismissed ? DateTime.now() : null,
      );
    } catch (_) {}
  }

  void resetGalleryQueue() {
    _queue.clearAll();
  }

  String _flagsDetail(ExperienceFeatureFlags flags) {
    return 'engine=${flags.experienceEngineEnabled} '
        'issuance=${flags.accountCreationExperienceEnabled} '
        'first=${flags.firstProofExperienceEnabled} '
        'coach=${flags.coachVerificationExperienceEnabled} '
        'gallery=${flags.galleryMode}';
  }
}
