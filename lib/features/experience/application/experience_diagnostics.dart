import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debug pipeline events for Experience Engine QA.
enum ExperienceDiagnosticKind {
  eventCreated('EVENT CREATED'),
  eventEligible('EVENT ELIGIBLE'),
  eventRejected('EVENT REJECTED'),
  receiptClaimed('RECEIPT CLAIMED'),
  eventQueued('EVENT QUEUED'),
  presentationRequested('PRESENTATION REQUESTED'),
  overlayShown('OVERLAY SHOWN'),
  receiptCompleted('RECEIPT COMPLETED'),
  receiptDismissed('RECEIPT DISMISSED'),
  receiptFailed('RECEIPT FAILED'),
  pipelineFailure('PIPELINE FAILURE');

  const ExperienceDiagnosticKind(this.label);
  final String label;
}

class ExperiencePipelineFailure {
  const ExperiencePipelineFailure({
    required this.at,
    required this.stage,
    required this.eventId,
    required this.error,
    required this.stackTrace,
  });

  final DateTime at;
  final String stage;
  final String eventId;
  final Object error;
  final StackTrace stackTrace;
}

class ExperienceDiagnosticEntry {
  const ExperienceDiagnosticEntry({
    required this.at,
    required this.kind,
    this.eventId = '',
    this.detail = '',
  });

  final DateTime at;
  final ExperienceDiagnosticKind kind;
  final String eventId;
  final String detail;

  String get timeLabel {
    final t = at.toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class ExperienceDiagnostics extends ChangeNotifier {
  final List<ExperienceDiagnosticEntry> _entries = [];
  ExperiencePipelineFailure? lastFailure;

  List<ExperienceDiagnosticEntry> get entries => List.unmodifiable(_entries);

  void log(
    ExperienceDiagnosticKind kind, {
    String eventId = '',
    String detail = '',
  }) {
    _entries.insert(
      0,
      ExperienceDiagnosticEntry(
        at: DateTime.now(),
        kind: kind,
        eventId: eventId,
        detail: detail,
      ),
    );
    if (_entries.length > 120) {
      _entries.removeRange(120, _entries.length);
    }
    if (kDebugMode) {
      debugPrint(
        '[Experience] ${kind.label}'
        '${eventId.isNotEmpty ? ' · $eventId' : ''}'
        '${detail.isNotEmpty ? ' · $detail' : ''}',
      );
    }
    notifyListeners();
  }

  void reportPipelineFailure({
    required String stage,
    required String eventId,
    required Object error,
    required StackTrace stackTrace,
  }) {
    lastFailure = ExperiencePipelineFailure(
      at: DateTime.now(),
      stage: stage,
      eventId: eventId,
      error: error,
      stackTrace: stackTrace,
    );
    log(
      ExperienceDiagnosticKind.pipelineFailure,
      eventId: eventId,
      detail: '$stage · $error',
    );
    log(
      ExperienceDiagnosticKind.eventRejected,
      eventId: eventId,
      detail: 'offer_failed:$stage · $error',
    );
    if (kDebugMode) {
      debugPrint(
        '[Experience] PIPELINE FAILURE at $stage · $eventId · $error',
      );
      debugPrintStack(stackTrace: stackTrace, label: 'Experience pipeline');
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    lastFailure = null;
    notifyListeners();
  }

  void dismissFailureBanner() {
    lastFailure = null;
    notifyListeners();
  }
}

final experienceDiagnosticsProvider =
    ChangeNotifierProvider<ExperienceDiagnostics>((ref) {
  ref.keepAlive();
  return ExperienceDiagnostics();
});
