import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:proof/core/constants/firestore_paths.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/features/experience/domain/experience_status.dart';

/// Structured context for a failed experience receipt Firestore operation.
class ExperienceReceiptFirestoreFailure implements Exception {
  ExperienceReceiptFirestoreFailure({
    required this.operation,
    required this.path,
    required this.authUid,
    required this.ownerId,
    required this.eventId,
    required this.cause,
    this.payloadSummary = const {},
    this.hint = '',
  });

  final String operation;
  final String path;
  final String authUid;
  final String ownerId;
  final String eventId;
  final Object cause;
  final Map<String, String> payloadSummary;
  final String hint;

  String get code {
    if (cause is FirebaseException) {
      return (cause as FirebaseException).code;
    }
    return 'unknown';
  }

  bool get isPermissionDenied => code == 'permission-denied';

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('Receipt $operation denied')
      ..writeln('Operation: $operation')
      ..writeln('Path: $path')
      ..writeln('Auth uid: ${maskUid(authUid)}')
      ..writeln('Payload ownerId: ${maskUid(ownerId)}')
      ..writeln('Event id: $eventId')
      ..writeln('Code: $code');
    if (hint.isNotEmpty) buf.writeln('Hint: $hint');
    if (payloadSummary.isNotEmpty) {
      buf.writeln('Payload: $payloadSummary');
    }
    buf.write('Cause: $cause');
    return buf.toString();
  }

  static String maskUid(String uid) {
    if (uid.isEmpty) return '(none)';
    if (uid.length <= 8) return uid;
    return '${uid.substring(0, 4)}…${uid.substring(uid.length - 4)}';
  }

  static String hintFor(FirebaseException e) {
    if (e.code != 'permission-denied') return '';
    return 'Likely undeployed experienceReceipts rules, '
        'auth/path mismatch, or ownerId mismatch. '
        'Deploy: firebase deploy --only firestore:rules --project proof-e913a';
  }
}

/// Result of the debug receipt permission self-test.
class ExperienceReceiptPermissionTestResult {
  ExperienceReceiptPermissionTestResult({
    required this.path,
    required this.authUid,
    required this.steps,
  });

  final String path;
  final String authUid;
  final List<ExperienceReceiptPermissionStep> steps;

  bool get allPassed => steps.every((s) => s.ok);

  String get report {
    final lines = <String>[
      'Receipt permission self-test',
      'Path: $path',
      'Auth uid: ${ExperienceReceiptFirestoreFailure.maskUid(authUid)}',
      ...steps.map(
        (s) =>
            '${s.ok ? 'OK' : 'FAIL'}  ${s.operation}${s.error != null ? ' — ${s.error}' : ''}',
      ),
      allPassed ? 'RESULT: all operations succeeded' : 'RESULT: failed',
    ];
    return lines.join('\n');
  }
}

class ExperienceReceiptPermissionStep {
  const ExperienceReceiptPermissionStep({
    required this.operation,
    required this.ok,
    this.error,
  });

  final String operation;
  final bool ok;
  final String? error;
}

/// Debug-only permission probe for experience receipts.
Future<ExperienceReceiptPermissionTestResult> runExperienceReceiptPermissionTest({
  required FirebaseFirestore firestore,
  required FirebaseAuth auth,
}) async {
  assert(kDebugMode);
  final user = auth.currentUser;
  if (user == null) {
    return ExperienceReceiptPermissionTestResult(
      path: '(no auth)',
      authUid: '',
      steps: const [
        ExperienceReceiptPermissionStep(
          operation: 'auth',
          ok: false,
          error: 'No authenticated user',
        ),
      ],
    );
  }

  final uid = user.uid;
  final eventId = 'debugPermissionTest:${DateTime.now().millisecondsSinceEpoch}';
  final path =
      '${FirestorePaths.users}/$uid/${FirestorePaths.experienceReceipts}/$eventId';
  final ref = firestore
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.experienceReceipts)
      .doc(eventId);

  final steps = <ExperienceReceiptPermissionStep>[];

  Future<bool> step(String name, Future<void> Function() action) async {
    try {
      await action();
      steps.add(ExperienceReceiptPermissionStep(operation: name, ok: true));
      return true;
    } catch (e) {
      steps.add(
        ExperienceReceiptPermissionStep(
          operation: name,
          ok: false,
          error: e.toString(),
        ),
      );
      return false;
    }
  }

  final created = await step('create', () async {
    final draft = ExperienceReceipt(
      id: eventId,
      ownerId: uid,
      eventType: ExperienceEventType.onboardingCompleted,
      sourceId: 'debug-permission-test',
      importance: ExperienceImportance.t3Landmark,
      status: ExperienceStatus.pending,
      createdAt: DateTime.now(),
    );
    await ref.set(draft.toCreateFirestore(useServerTimestamp: true));
  });

  if (created) {
    await step('read', () async {
      final snap = await ref.get();
      if (!snap.exists) throw StateError('created doc missing on read');
    });
    await step('update', () async {
      await ref.update({'status': ExperienceStatus.dismissed.value});
    });
    await step('delete', () async {
      await ref.delete();
    });
  }

  // Best-effort cleanup if create succeeded but later steps failed.
  if (created && steps.any((s) => !s.ok)) {
    try {
      await ref.delete();
    } catch (_) {}
  }

  return ExperienceReceiptPermissionTestResult(
    path: path,
    authUid: uid,
    steps: steps,
  );
}
