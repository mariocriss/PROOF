import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/verification_request_model.dart';

class GymVerificationValidation {
  const GymVerificationValidation({required this.isValid, this.reason});

  final bool isValid;
  final String? reason;
}

class GymVerificationValidator {
  GymVerificationValidator._();

  static GymVerificationValidation canAthleteRequestCoachVerification({
    required List<GymMembershipModel> athleteMemberships,
    required String gymId,
  }) {
    final membership = athleteMemberships.where(
      (m) =>
          m.gymId == gymId &&
          m.membershipType == GymMembershipType.athlete &&
          m.status == GymMembershipStatus.approved,
    );
    if (membership.isEmpty) {
      return const GymVerificationValidation(
        isValid: false,
        reason:
            'You need approved gym membership before requesting coach verification.',
      );
    }
    return const GymVerificationValidation(isValid: true);
  }

  static GymVerificationValidation canRequestFromCoach({
    required GymMembershipModel? athleteMembership,
    required GymMembershipModel? coachMembership,
    required String gymId,
    required String coachId,
  }) {
    if (athleteMembership == null ||
        athleteMembership.gymId != gymId ||
        athleteMembership.membershipType != GymMembershipType.athlete ||
        athleteMembership.status != GymMembershipStatus.approved) {
      return const GymVerificationValidation(
        isValid: false,
        reason:
            'You need approved gym membership before requesting coach verification.',
      );
    }

    if (coachMembership == null ||
        coachMembership.gymId != gymId ||
        coachMembership.userId != coachId ||
        coachMembership.membershipType != GymMembershipType.coach ||
        coachMembership.status != GymMembershipStatus.approved) {
      return const GymVerificationValidation(
        isValid: false,
        reason: 'This coach is not approved at your gym.',
      );
    }

    return const GymVerificationValidation(isValid: true);
  }

  static GymVerificationValidation canCoachReviewRequest({
    required VerificationRequestModel request,
    required String loggedInCoachId,
    required List<GymMembershipModel> coachMemberships,
  }) {
    if (request.coachId != loggedInCoachId) {
      return const GymVerificationValidation(
        isValid: false,
        reason: 'This request is assigned to another coach.',
      );
    }
    if (request.status != VerificationRequestStatus.pending) {
      return const GymVerificationValidation(
        isValid: false,
        reason: 'This request is no longer pending.',
      );
    }
    if (request.gymId.isEmpty) {
      return const GymVerificationValidation(
        isValid: false,
        reason: 'Missing gym context for this verification request.',
      );
    }

    final approved = coachMemberships.any(
      (m) =>
          m.gymId == request.gymId &&
          m.userId == loggedInCoachId &&
          m.membershipType == GymMembershipType.coach &&
          m.status == GymMembershipStatus.approved,
    );
    if (!approved) {
      return const GymVerificationValidation(
        isValid: false,
        reason: 'You are not an approved coach at this gym.',
      );
    }
    return const GymVerificationValidation(isValid: true);
  }
}
