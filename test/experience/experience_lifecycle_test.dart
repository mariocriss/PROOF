import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/application/experience_diagnostics.dart';
import 'package:proof/features/experience/application/experience_eligibility_service.dart';
import 'package:proof/features/experience/application/experience_event_factory.dart';
import 'package:proof/features/experience/application/experience_providers.dart';
import 'package:proof/features/experience/presentation/experience_overlay_controller.dart';
import 'package:proof/features/experience/application/experience_queue.dart';
import 'package:proof/features/experience/application/experience_runtime_store.dart';
import 'package:proof/features/experience/application/experience_trigger_service.dart';
import 'package:proof/features/experience/data/experience_receipt_repository.dart';
import 'package:proof/features/experience/domain/experience_definition_registry.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/features/experience/domain/experience_preferences.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/features/experience/domain/experience_status.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/verification_status.dart';

void main() {
  const factory = ExperienceEventFactory();

  group('async pipeline lifecycle', () {
    test('offer completes after flags change during receipt await', () async {
      final gate = Completer<void>();
      final receipts = _PausableReceiptRepository(gate);
      final flags = ExperienceFeatureFlags.allOnForGallery;
      final runtime = ExperienceRuntimeStore(flags: flags, preferences: const ExperiencePreferences());
      final presented = <ExperienceEvent>[];

      final coordinator = ExperienceCoordinator(
        runtime: runtime,
        receipts: receipts,
        eligibility: ExperienceEligibilityService(
          receipts: receipts,
          runtime: runtime,
        ),
        registry: ExperienceDefinitionRegistry(),
        writeReceipts: true,
        queue: ExperienceQueue(),
        presenter: (request) async {
          presented.add(request.event);
          return ExperiencePresentationOutcome.completed;
        },
      );

      final event = factory.galleryPreview(
        type: ExperienceEventType.onboardingCompleted,
        importance: ExperienceImportance.t3Landmark,
        context: const ExperienceContext(displayName: 'Alex'),
        ownerId: 'u1',
      );

      final offerFuture = coordinator.offer(event);
      runtime.updateFlags(const ExperienceFeatureFlags());
      gate.complete();
      final queued = await offerFuture;

      expect(queued, isTrue);
      expect(presented, hasLength(1));
      expect(presented.first.id, event.id);
    });

    test('trigger service survives runtime flag change during offer', () async {
      final gate = Completer<void>();
      final receipts = _PausableReceiptRepository(gate);
      final runtime = ExperienceRuntimeStore(
        flags: const ExperienceFeatureFlags(
          experienceEngineEnabled: true,
          accountCreationExperienceEnabled: true,
          firstProofExperienceEnabled: true,
          coachVerificationExperienceEnabled: true,
        ),
        preferences: const ExperiencePreferences(),
      );
      final presented = <ExperienceEvent>[];

      final coordinator = ExperienceCoordinator(
        runtime: runtime,
        receipts: receipts,
        eligibility: ExperienceEligibilityService(
          receipts: receipts,
          runtime: runtime,
        ),
        registry: ExperienceDefinitionRegistry(),
        presenter: (request) async {
          presented.add(request.event);
          return ExperiencePresentationOutcome.completed;
        },
      );

      final triggers = ExperienceTriggerService(
        coordinator: coordinator,
        factory: factory,
        runtime: runtime,
      );

      final offerFuture = triggers.onProofCreated(
        userId: 'u1',
        proof: _proof(),
        totalProofCountAfterCreate: 1,
      );
      runtime.updateFlags(const ExperienceFeatureFlags());
      gate.complete();
      await offerFuture;

      expect(presented, hasLength(1));
    });

    test('gallery engine preview via ProviderContainer does not assert', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      ExperienceTestMode.enableAllReferences(container);
      final coordinator = container.read(experienceGalleryCoordinatorProvider);
      final event = container.read(experienceEventFactoryProvider).galleryPreview(
            type: ExperienceEventType.onboardingCompleted,
            importance: ExperienceImportance.t3Landmark,
            context: const ExperienceContext(displayName: 'Alex'),
          );

      final offerFuture = coordinator.offer(event);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(experienceOverlayControllerProvider).request, isNotNull);
      container.read(experienceOverlayControllerProvider).skip();
      await expectLater(offerFuture, completion(isTrue));
    });

    test('test mode persistence survives flag provider re-read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      ExperienceTestMode.enableAllReferences(container);
      final first = container.read(experienceFeatureFlagsProvider);
      expect(first.experienceEngineEnabled, isTrue);

      container.read(experienceDebugTestModePersistenceProvider).override =
          const ExperienceFeatureFlags(
        experienceEngineEnabled: true,
        firstProofExperienceEnabled: true,
      );
      final second = container.read(experienceFeatureFlagsProvider);
      expect(second.experienceEngineEnabled, isTrue);
      expect(second.firstProofExperienceEnabled, isTrue);
    });

    test('second proof rejected with count=2', () async {
      final receipts = InMemoryExperienceReceiptRepository();
      final runtime = ExperienceRuntimeStore(
        flags: const ExperienceFeatureFlags(
          experienceEngineEnabled: true,
          firstProofExperienceEnabled: true,
        ),
        preferences: const ExperiencePreferences(),
      );
      final diagnostics = ExperienceDiagnostics();
      final presented = <ExperienceEvent>[];

      final coordinator = ExperienceCoordinator(
        runtime: runtime,
        receipts: receipts,
        eligibility: ExperienceEligibilityService(
          receipts: receipts,
          runtime: runtime,
        ),
        registry: ExperienceDefinitionRegistry(),
        diagnostics: diagnostics,
        presenter: (request) async {
          presented.add(request.event);
          return ExperiencePresentationOutcome.completed;
        },
      );

      final triggers = ExperienceTriggerService(
        coordinator: coordinator,
        factory: factory,
        runtime: runtime,
        diagnostics: diagnostics,
      );

      await triggers.onProofCreated(
        userId: 'u1',
        proof: _proof(id: 'p1'),
        totalProofCountAfterCreate: 1,
      );
      expect(presented, hasLength(1));

      await triggers.onProofCreated(
        userId: 'u1',
        proof: _proof(id: 'p2'),
        totalProofCountAfterCreate: 2,
      );
      expect(presented, hasLength(1));
      expect(
        diagnostics.entries.any(
          (e) => e.detail.contains('not_first_proof') && e.detail.contains('count=2'),
        ),
        isTrue,
      );
    });
  });
}

class _PausableReceiptRepository implements ExperienceReceiptRepository {
  _PausableReceiptRepository(this._gate);

  final Completer<void> _gate;
  final Map<String, ExperienceReceipt> _store = {};

  String _key(String ownerId, String eventId) => '$ownerId::$eventId';

  @override
  Future<ExperienceReceipt?> get(String ownerId, String eventId) async {
    await _gate.future;
    return _store[_key(ownerId, eventId)];
  }

  @override
  Future<ExperienceReceipt> claimOrGet(ExperienceReceipt draft) async {
    await _gate.future;
    final key = _key(draft.ownerId, draft.id);
    return _store.putIfAbsent(key, () => draft);
  }

  @override
  Future<void> updateStatus({
    required String ownerId,
    required String eventId,
    required ExperienceStatus status,
    DateTime? shownAt,
    DateTime? completedAt,
    DateTime? dismissedAt,
  }) async {
    await _gate.future;
    final key = _key(ownerId, eventId);
    final existing = _store[key];
    if (existing == null) return;
    _store[key] = ExperienceReceipt(
      id: existing.id,
      ownerId: existing.ownerId,
      eventType: existing.eventType,
      sourceId: existing.sourceId,
      importance: existing.importance,
      status: status,
      createdAt: existing.createdAt,
      shownAt: shownAt ?? existing.shownAt,
      completedAt: completedAt ?? existing.completedAt,
      dismissedAt: dismissedAt ?? existing.dismissedAt,
    );
  }

  @override
  Future<List<ExperienceReceipt>> listResumable(String ownerId, {int limit = 20}) async {
    await _gate.future;
    return _store.values
        .where((r) => r.ownerId == ownerId && r.status.mayResume)
        .take(limit)
        .toList();
  }
}

ProofModel _proof({String id = 'p1'}) {
  final now = DateTime.utc(2026, 1, 15);
  return ProofModel(
    id: id,
    userId: 'u1',
    skillId: 's1',
    title: '10:00',
    result: '10:00',
    unit: 'min',
    proofSource: ProofSource.selfReported,
    verificationStatus: VerificationStatus.selfReported,
    recordedAt: now,
    createdAt: now,
  );
}

/// Test helper mirroring panel API without WidgetRef.
class ExperienceTestMode {
  static void enableAllReferences(ProviderContainer container) {
    container.read(experienceDebugTestModePersistenceProvider).override =
        const ExperienceFeatureFlags(
      experienceEngineEnabled: true,
      passportMotionEnabled: true,
      guideEnabled: true,
      soundsEnabled: false,
      hapticsEnabled: true,
      accountCreationExperienceEnabled: true,
      firstProofExperienceEnabled: true,
      coachVerificationExperienceEnabled: true,
    );
    container.read(experienceFeatureFlagsProvider.notifier).state =
        container.read(experienceDebugTestModePersistenceProvider).override!;
    container.read(experienceRuntimeStoreProvider).updateFlags(
          container.read(experienceFeatureFlagsProvider),
        );
  }
}
