import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/application/experience_eligibility_service.dart';
import 'package:proof/features/experience/application/experience_event_factory.dart';
import 'package:proof/features/experience/application/experience_queue.dart';
import 'package:proof/features/experience/application/experience_runtime_store.dart';
import 'package:proof/features/experience/application/experience_trigger_service.dart';
import 'package:proof/features/experience/data/experience_receipt_repository.dart';
import 'package:proof/features/experience/domain/experience_definition_registry.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_ids.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';
import 'package:proof/features/experience/domain/experience_importance.dart';
import 'package:proof/features/experience/domain/experience_message_resolver.dart';
import 'package:proof/features/experience/domain/experience_preferences.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/features/experience/domain/experience_status.dart';
import 'package:proof/features/experience/media/experience_haptic_service.dart';
import 'package:proof/features/experience/media/experience_sound_service.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/verification_status.dart';

void main() {
  late InMemoryExperienceReceiptRepository receipts;
  late ExperienceFeatureFlags flags;
  late ExperiencePreferences prefs;
  late List<ExperienceEvent> presented;
  late RecordingExperienceHapticService haptics;
  late List<ExperienceSoundKind> sounds;
  late ExperienceRuntimeStore runtime;
  late ExperienceCoordinator coordinator;
  late ExperienceTriggerService triggers;
  const factory = ExperienceEventFactory();

  ExperienceCoordinator buildCoordinator({
    ExperiencePresenter? presenter,
    bool writeReceipts = true,
  }) {
    return ExperienceCoordinator(
      runtime: runtime,
      receipts: receipts,
      eligibility: ExperienceEligibilityService(
        receipts: receipts,
        runtime: runtime,
        registry: ExperienceDefinitionRegistry(),
      ),
      registry: ExperienceDefinitionRegistry(),
      writeReceipts: writeReceipts,
      queue: ExperienceQueue(),
      presenter: presenter ??
          (request) async {
            presented.add(request.event);
            return ExperiencePresentationOutcome.completed;
          },
    );
  }

  ProofModel proof({
    String id = 'p1',
    String userId = 'u1',
    VerificationStatus status = VerificationStatus.selfReported,
    DateTime? verifiedAt,
    String? coachId,
  }) {
    final now = DateTime.utc(2026, 1, 15);
    return ProofModel(
      id: id,
      userId: userId,
      skillId: 's1',
      title: '10:00',
      result: '10:00',
      unit: 'min',
      proofSource: ProofSource.selfReported,
      verificationStatus: status,
      recordedAt: now,
      createdAt: now,
      verifiedAt: verifiedAt,
      verifiedByCoachId: coachId,
      coachId: coachId,
    );
  }

  setUp(() {
    receipts = InMemoryExperienceReceiptRepository();
    flags = const ExperienceFeatureFlags(
      experienceEngineEnabled: true,
      passportMotionEnabled: true,
      guideEnabled: true,
      soundsEnabled: true,
      hapticsEnabled: true,
      accountCreationExperienceEnabled: true,
      firstProofExperienceEnabled: true,
      coachVerificationExperienceEnabled: true,
    );
    prefs = const ExperiencePreferences();
    runtime = ExperienceRuntimeStore(flags: flags, preferences: prefs);
    presented = [];
    haptics = RecordingExperienceHapticService();
    sounds = [];
    coordinator = buildCoordinator();
    triggers = ExperienceTriggerService(
      coordinator: coordinator,
      factory: factory,
      runtime: runtime,
    );
  });

  group('event ids', () {
    test('deterministic onboarding and first proof ids', () {
      expect(
        ExperienceEventIds.onboardingCompleted('u1'),
        'onboardingCompleted:u1',
      );
      expect(
        ExperienceEventIds.firstProofCreated('u1'),
        'firstProofCreated:u1',
      );
    });

    test('coach verification version is stable from coach id', () {
      final v = ExperienceEventIds.verificationVersionFromProof(
        verifiedByCoachId: 'coach1',
      );
      expect(v, 'coach:coach1');
      expect(
        ExperienceEventIds.coachVerified('p1', v),
        'coachVerified:p1:coach:coach1',
      );
    });

    test('verification request id takes precedence when present', () {
      final v = ExperienceEventIds.verificationVersionFromProof(
        verifiedByCoachId: 'coach1',
        verificationRequestId: 'req-abc',
      );
      expect(v, 'request:req-abc');
    });
  });

  group('onboarding experience', () {
    test('generated once', () async {
      await triggers.onOnboardingCompleted(userId: 'u1');
      await triggers.onOnboardingCompleted(userId: 'u1');
      expect(presented, hasLength(1));
      expect(presented.first.type, ExperienceEventType.onboardingCompleted);
      final receipt = await receipts.get(
        'u1',
        ExperienceEventIds.onboardingCompleted('u1'),
      );
      expect(receipt?.status, ExperienceStatus.completed);
    });

    test('not replayed after restart (completed receipt)', () async {
      await triggers.onOnboardingCompleted(userId: 'u1');
      expect(presented, hasLength(1));

      // Simulate new session: new queue/coordinator, same receipts.
      presented.clear();
      triggers.clearSessionDedupe();
      coordinator = buildCoordinator();
      triggers = ExperienceTriggerService(
        coordinator: coordinator,
        factory: factory,
        runtime: runtime,
      );
      await triggers.onOnboardingCompleted(userId: 'u1');
      expect(presented, isEmpty);
    });
  });

  group('first proof', () {
    test('only for actual first proof', () async {
      final p = proof();
      await triggers.onProofCreated(
        userId: 'u1',
        proof: p,
        totalProofCountAfterCreate: 1,
      );
      expect(presented, hasLength(1));
      expect(presented.first.type, ExperienceEventType.firstProofCreated);
    });

    test('second proof does not replay', () async {
      await triggers.onProofCreated(
        userId: 'u1',
        proof: proof(id: 'p1'),
        totalProofCountAfterCreate: 1,
      );
      await triggers.onProofCreated(
        userId: 'u1',
        proof: proof(id: 'p2'),
        totalProofCountAfterCreate: 2,
      );
      expect(presented, hasLength(1));
    });
  });

  group('coach verification', () {
    test('generated once', () async {
      final verifiedAt = DateTime.utc(2026, 3, 1);
      final p = proof(
        status: VerificationStatus.coachVerified,
        verifiedAt: verifiedAt,
        coachId: 'coach1',
      );
      await triggers.onCoachVerifiedProofs(
        proofs: [p],
        coachNameResolver: (_) => 'Jordan',
      );
      await triggers.onCoachVerifiedProofs(
        proofs: [p],
        coachNameResolver: (_) => 'Jordan',
      );
      expect(presented, hasLength(1));
      expect(presented.first.type, ExperienceEventType.coachVerified);
    });

    test('offline approval becomes pending then presents once', () async {
      final verifiedAt = DateTime.utc(2026, 3, 2);
      final p = proof(
        status: VerificationStatus.coachVerified,
        verifiedAt: verifiedAt,
        coachId: 'coach1',
      );
      // Claim receipt as pending without presenting (interrupted).
      final event = factory.coachVerified(
        proof: p,
        context: const ExperienceContext(coachName: 'Jordan'),
      )!;
      await receipts.claimOrGet(
        ExperienceReceipt(
          id: event.id,
          ownerId: event.ownerId,
          eventType: event.type,
          sourceId: event.sourceId,
          importance: event.importance,
          status: ExperienceStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      triggers.clearSessionDedupe();
      await coordinator.resumePending(
        ownerId: 'u1',
        hydrate: (receipt) async {
          if (receipt.eventType != ExperienceEventType.coachVerified) {
            return null;
          }
          return event;
        },
      );
      expect(presented, hasLength(1));
    });

    test('missing coach name fallback copy', () {
      const resolver = ExperienceMessageResolver();
      final messages = resolver.resolve(
        type: ExperienceEventType.coachVerified,
        context: const ExperienceContext(),
      );
      expect(messages.primary, contains('Your coach verified this'));
    });
  });

  group('exact-once guards', () {
    test('duplicate callback does not duplicate receipt', () async {
      final event = factory.onboardingCompleted(
        userId: 'u1',
        context: const ExperienceContext(),
      );
      await coordinator.offer(event);
      await coordinator.offer(event);
      expect(presented, hasLength(1));
      expect(receipts.debugSnapshot, hasLength(1));
    });

    test('completed receipt does not replay', () async {
      final event = factory.onboardingCompleted(
        userId: 'u1',
        context: const ExperienceContext(),
      );
      await coordinator.offer(event);
      presented.clear();
      await coordinator.offer(event);
      expect(presented, isEmpty);
    });

    test('feature flag OFF prevents presentation', () async {
      flags = const ExperienceFeatureFlags(); // all off
      runtime.updateFlags(flags);
      await triggers.onOnboardingCompleted(userId: 'u1');
      expect(presented, isEmpty);
    });

    test('presentation failure does not clear receipt ownership', () async {
      coordinator = buildCoordinator(
        presenter: (_) async => ExperiencePresentationOutcome.failed,
      );
      triggers = ExperienceTriggerService(
        coordinator: coordinator,
        factory: factory,
        runtime: runtime,
      );
      await triggers.onOnboardingCompleted(userId: 'u1');
      final receipt = await receipts.get(
        'u1',
        ExperienceEventIds.onboardingCompleted('u1'),
      );
      expect(receipt?.status, ExperienceStatus.failed);
      // Domain would still be complete — experience only failed.
      expect(receipt, isNotNull);
    });
  });

  group('media gates', () {
    test('sound disabled prevents playback', () async {
      final gated = GatedExperienceSoundService(
        inner: _RecordingSound(sounds),
        enabled: () => false,
      );
      await gated.play(ExperienceSoundKind.stampSoft);
      expect(sounds, isEmpty);
    });

    test('haptics disabled prevents feedback', () async {
      final gated = GatedExperienceHapticService(
        inner: haptics,
        enabled: () => false,
      );
      await gated.play(ExperienceHapticKind.thud);
      expect(haptics.played, isEmpty);
    });

    test('optional asset failure falls back safely', () async {
      final gated = GatedExperienceSoundService(
        inner: _ThrowingSound(),
        enabled: () => true,
      );
      await gated.play(ExperienceSoundKind.binding);
    });
  });

  group('gallery', () {
    test('gallery mode writes no production receipts', () async {
      flags = ExperienceFeatureFlags.allOnForGallery;
      runtime.updateFlags(flags);
      coordinator = buildCoordinator(writeReceipts: false);
      triggers = ExperienceTriggerService(
        coordinator: coordinator,
        factory: factory,
        runtime: runtime,
      );
      final event = factory.galleryPreview(
        type: ExperienceEventType.firstProofCreated,
        importance: ExperienceImportance.t3Landmark,
        context: const ExperienceContext(displayName: 'Alex'),
      );
      await coordinator.offer(event);
      expect(presented, hasLength(1));
      expect(receipts.debugSnapshot, isEmpty);
    });
  });

  group('receipt semantics', () {
    test('skip maps to dismissed and does not replay', () async {
      coordinator = buildCoordinator(
        presenter: (_) async => ExperiencePresentationOutcome.dismissed,
      );
      final event = factory.onboardingCompleted(
        userId: 'u1',
        context: const ExperienceContext(),
      );
      await coordinator.offer(event);
      presented.clear();
      await coordinator.offer(event);
      expect(presented, isEmpty);
      final receipt = await receipts.get(
        'u1',
        ExperienceEventIds.onboardingCompleted('u1'),
      );
      expect(receipt?.status, ExperienceStatus.dismissed);
    });

    test('failed status allows resume', () async {
      coordinator = buildCoordinator(
        presenter: (_) async => ExperiencePresentationOutcome.failed,
      );
      final event = factory.onboardingCompleted(
        userId: 'u1',
        context: const ExperienceContext(),
      );
      await coordinator.offer(event);
      final receipt = await receipts.get(
        'u1',
        ExperienceEventIds.onboardingCompleted('u1'),
      );
      expect(receipt?.status, ExperienceStatus.failed);
      expect(receipt?.status.mayResume, isTrue);
    });
  });

  group('unrelated moments', () {
    test('factory does not auto-wire annual or import types', () {
      expect(
        factory.firstProofCreated(
          userId: 'u1',
          proof: proof(),
          isActualFirstProof: false,
          context: const ExperienceContext(),
        ),
        isNull,
      );
    });
  });

  group('message resolver', () {
    test('onboarding and first proof primary copy', () {
      const resolver = ExperienceMessageResolver();
      expect(
        resolver
            .resolve(
              type: ExperienceEventType.onboardingCompleted,
              context: const ExperienceContext(),
            )
            .primary,
        'Your physical identity record begins today.',
      );
      expect(
        resolver
            .resolve(
              type: ExperienceEventType.firstProofCreated,
              context: const ExperienceContext(),
            )
            .ctaLabel,
        'View My Passport',
      );
    });
  });

  group('reduced motion / guide prefs', () {
    test('presenter receives reduceMotion flag', () async {
      prefs = const ExperiencePreferences(
        motion: ExperienceMotionPreferences(reduceMotion: true),
      );
      runtime.updatePreferences(prefs);
      var sawReduce = false;
      coordinator = buildCoordinator(
        presenter: (request) async {
          sawReduce = request.reduceMotion;
          return ExperiencePresentationOutcome.completed;
        },
      );
      triggers = ExperienceTriggerService(
        coordinator: coordinator,
        factory: factory,
        runtime: runtime,
      );
      await triggers.onOnboardingCompleted(userId: 'u1');
      expect(sawReduce, isTrue);
    });

    test('guide disabled still completes experience', () async {
      prefs = const ExperiencePreferences(guideEnabled: false);
      runtime.updatePreferences(prefs);
      var guideFlag = true;
      coordinator = buildCoordinator(
        presenter: (request) async {
          guideFlag =
              request.flags.guideEnabled && request.preferences.guideEnabled;
          return ExperiencePresentationOutcome.completed;
        },
      );
      // flags.guideEnabled true, prefs false
      triggers = ExperienceTriggerService(
        coordinator: coordinator,
        factory: factory,
        runtime: runtime,
      );
      await triggers.onOnboardingCompleted(userId: 'u1');
      expect(guideFlag, isFalse);
      expect(presented, isEmpty); // custom presenter didn't push to list
    });
  });
}

class _RecordingSound implements ExperienceSoundService {
  _RecordingSound(this.log);
  final List<ExperienceSoundKind> log;

  @override
  Future<void> play(ExperienceSoundKind kind) async => log.add(kind);

  @override
  Future<void> dispose() async {}
}

class _ThrowingSound implements ExperienceSoundService {
  @override
  Future<void> play(ExperienceSoundKind kind) async {
    throw StateError('missing asset');
  }

  @override
  Future<void> dispose() async {}
}
