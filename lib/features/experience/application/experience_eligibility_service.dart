import 'package:proof/features/experience/application/experience_runtime_store.dart';
import 'package:proof/features/experience/data/experience_receipt_permission_probe.dart';
import 'package:proof/features/experience/data/experience_receipt_repository.dart';
import 'package:proof/features/experience/domain/experience_definition_registry.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';

class ExperienceEligibilityResult {
  const ExperienceEligibilityResult({
    required this.eligible,
    this.reason = '',
    this.existingReceipt,
  });

  final bool eligible;
  final String reason;
  final ExperienceReceipt? existingReceipt;

  static const blockedEngine =
      ExperienceEligibilityResult(eligible: false, reason: 'engine_off');
  static const blockedFlag =
      ExperienceEligibilityResult(eligible: false, reason: 'flag_off');
  static const blockedTerminal =
      ExperienceEligibilityResult(eligible: false, reason: 'already_terminal');
}

class ExperienceEligibilityService {
  ExperienceEligibilityService({
    required ExperienceReceiptRepository receipts,
    required ExperienceRuntimeStore runtime,
    ExperienceDefinitionRegistry? registry,
  })  : _receipts = receipts,
        _runtime = runtime,
        _registry = registry ?? ExperienceDefinitionRegistry();

  final ExperienceReceiptRepository _receipts;
  final ExperienceRuntimeStore _runtime;
  final ExperienceDefinitionRegistry _registry;

  Future<ExperienceEligibilityResult> check(ExperienceEvent event) async {
    final flags = _runtime.flags;
    if (!flags.experienceEngineEnabled && !flags.galleryMode) {
      return ExperienceEligibilityResult.blockedEngine;
    }
    if (!flags.isTypeEnabled(event.type.value) && !flags.galleryMode) {
      return ExperienceEligibilityResult.blockedFlag;
    }
    if (_registry.get(event.type) == null && !flags.galleryMode) {
      return const ExperienceEligibilityResult(
        eligible: false,
        reason: 'unknown_definition',
      );
    }

    ExperienceReceipt? existing;
    try {
      existing = await _receipts.get(event.ownerId, event.id);
    } on ExperienceReceiptFirestoreFailure catch (e) {
      // Permission denied on missing path usually means rules undeployed.
      // Treat as "no receipt" so claim can surface the same failure clearly.
      if (e.isPermissionDenied) {
        return ExperienceEligibilityResult(
          eligible: true,
          reason: 'receipt_get_permission_denied_treated_as_new',
        );
      }
      rethrow;
    }

    if (existing != null && existing.isTerminal) {
      return ExperienceEligibilityResult(
        eligible: false,
        reason: 'already_terminal',
        existingReceipt: existing,
      );
    }
    if (existing != null && existing.status.mayResume) {
      return ExperienceEligibilityResult(
        eligible: true,
        reason: 'resume',
        existingReceipt: existing,
      );
    }
    return ExperienceEligibilityResult(
      eligible: true,
      reason: 'new',
      existingReceipt: existing,
    );
  }
}
