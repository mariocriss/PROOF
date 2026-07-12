import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/gym_verification_validator.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/verification_request_model.dart';

void main() {
  GymMembershipModel membership({
    required String gymId,
    required String userId,
    required GymMembershipType type,
    GymMembershipStatus status = GymMembershipStatus.approved,
  }) {
    return GymMembershipModel(
      id: GymMembershipModel.membershipDocId(
        gymId: gymId,
        userId: userId,
        type: type,
      ),
      gymId: gymId,
      userId: userId,
      membershipType: type,
      status: status,
      requestedAt: DateTime(2026, 1, 1),
    );
  }

  test('athlete needs approved membership for coach verification', () {
    final result = GymVerificationValidator.canAthleteRequestCoachVerification(
      athleteMemberships: [
        membership(
          gymId: 'g1',
          userId: 'a1',
          type: GymMembershipType.athlete,
          status: GymMembershipStatus.pending,
        ),
      ],
      gymId: 'g1',
    );
    expect(result.isValid, isFalse);
  });

  test('coach must be approved at same gym', () {
    final result = GymVerificationValidator.canRequestFromCoach(
      athleteMembership: membership(
        gymId: 'g1',
        userId: 'a1',
        type: GymMembershipType.athlete,
      ),
      coachMembership: membership(
        gymId: 'g1',
        userId: 'c1',
        type: GymMembershipType.coach,
      ),
      gymId: 'g1',
      coachId: 'c1',
    );
    expect(result.isValid, isTrue);
  });

  test('coach from another gym is rejected', () {
    final result = GymVerificationValidator.canRequestFromCoach(
      athleteMembership: membership(
        gymId: 'g1',
        userId: 'a1',
        type: GymMembershipType.athlete,
      ),
      coachMembership: membership(
        gymId: 'g2',
        userId: 'c2',
        type: GymMembershipType.coach,
      ),
      gymId: 'g1',
      coachId: 'c2',
    );
    expect(result.isValid, isFalse);
  });

  test('coach review requires matching gym membership', () {
    final request = VerificationRequestModel(
      id: 'r1',
      proofId: 'p1',
      athleteId: 'a1',
      coachId: 'c1',
      gymId: 'g1',
      skillId: 's1',
      status: VerificationRequestStatus.pending,
      createdAt: DateTime(2026, 1, 1),
    );

    final valid = GymVerificationValidator.canCoachReviewRequest(
      request: request,
      loggedInCoachId: 'c1',
      coachMemberships: [
        membership(gymId: 'g1', userId: 'c1', type: GymMembershipType.coach),
      ],
    );
    expect(valid.isValid, isTrue);
  });
}
