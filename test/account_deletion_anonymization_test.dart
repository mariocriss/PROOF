import 'package:flutter_test/flutter_test.dart';
import 'package:proof/shared/models/deleted_account_markers.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/user_report_model.dart';
import 'package:proof/shared/models/verification_status.dart';
import 'package:proof/shared/services/account_deletion_anonymization.dart';

void main() {
  group('reports about deleted user', () {
    final original = UserReportModel(
      id: 'r1',
      reporterUserId: 'reporter-1',
      reportedUserId: 'deleted-user-1',
      reason: UserReportReason.harassment,
      createdAt: DateTime.utc(2026, 1, 15),
      details: 'Abusive messages in profile bio context',
      reportedHandle: 'badactor',
    );

    test('retains only opaque subject UID and clears public handle', () {
      final anonymized =
          AccountDeletionAnonymization.anonymizeReportAboutDeletedUser(original);

      expect(anonymized.reportedUserId, 'deleted-user-1');
      expect(anonymized.reportedHandle, DeletedAccountMarkers.reportedHandle);
      expect(anonymized.reportedAccountDeleted, isTrue);
      expect(anonymized.reporterUserId, original.reporterUserId);
      expect(anonymized.reason, original.reason);
      expect(anonymized.details, original.details);
      expect(anonymized.createdAt, original.createdAt);
    });

    test('anonymized report Firestore payload has no live handle or profile fields',
        () {
      final anonymized =
          AccountDeletionAnonymization.anonymizeReportAboutDeletedUser(original);
      final payload = anonymized.toFirestore();

      expect(payload.keys, isNot(contains('email')));
      expect(payload.keys, isNot(contains('displayName')));
      expect(payload.keys, isNot(contains('avatarUrl')));
      expect(payload.keys, isNot(contains('profileUrl')));
      expect(payload['reportedHandle'], DeletedAccountMarkers.reportedHandle);
      expect(payload['reportedUserId'], 'deleted-user-1');
      expect(payload['reportedAccountDeleted'], isTrue);
    });

    test('report anonymization update patch is minimal', () {
      expect(
        AccountDeletionAnonymization.reportAnonymizationUpdate(),
        {
          'reportedHandle': DeletedAccountMarkers.reportedHandle,
          'reportedAccountDeleted': true,
        },
      );
    });
  });

  group('proofs referencing deleted coach', () {
    ProofModel baseProof({
      VerificationStatus status = VerificationStatus.coachVerified,
      ProofSource source = ProofSource.coach,
      String? coachId = 'coach-live-1',
    }) {
      final now = DateTime.utc(2026, 2, 1);
      return ProofModel(
        id: 'p1',
        userId: 'athlete-1',
        skillId: 'skill-1',
        title: '100kg squat',
        recordedAt: now,
        createdAt: now,
        result: '100',
        unit: 'kg',
        proofSource: source,
        verificationStatus: status,
        coachId: coachId,
        requestedCoachId: coachId,
        verifiedByCoachId: coachId,
        verifiedAt: now,
      );
    }

    test('keeps historical verification without live coach UID', () {
      final anonymized =
          AccountDeletionAnonymization.anonymizeDeletedCoachOnProof(baseProof());

      expect(anonymized.isCoachVerifiedForStack, isTrue);
      expect(anonymized.coachAccountDeleted, isTrue);
      expect(anonymized.coachId, isNull);
      expect(anonymized.requestedCoachId, isNull);
      expect(anonymized.verifiedByCoachId, isNull);
      expect(anonymized.hasActiveCoachReference, isFalse);
      expect(
        anonymized.verificationLabel,
        DeletedAccountMarkers.coachUnavailableLabel,
      );
      expect(anonymized.userId, 'athlete-1');
      expect(anonymized.result, '100');
    });

    test('pending coach request becomes self-reported without active coach link',
        () {
      final anonymized = AccountDeletionAnonymization.anonymizeDeletedCoachOnProof(
        baseProof(status: VerificationStatus.pendingVerification),
      );

      expect(anonymized.isCoachVerifiedForStack, isFalse);
      expect(anonymized.coachAccountDeleted, isFalse);
      expect(anonymized.verificationStatus, VerificationStatus.selfReported);
      expect(anonymized.coachId, isNull);
      expect(anonymized.hasActiveCoachReference, isFalse);
      expect(
        anonymized.verificationLabel,
        isNot(DeletedAccountMarkers.coachUnavailableLabel),
      );
    });

    test('does not present deleted coach as an active account reference', () {
      final anonymized =
          AccountDeletionAnonymization.anonymizeDeletedCoachOnProof(baseProof());
      final payload = anonymized.toFirestore();

      expect(payload['coachId'], isNull);
      expect(payload['verifiedByCoachId'], isNull);
      expect(payload['requestedCoachId'], isNull);
      expect(payload['coachAccountDeleted'], isTrue);
      expect(anonymized.hasActiveCoachReference, isFalse);
    });
  });
}
