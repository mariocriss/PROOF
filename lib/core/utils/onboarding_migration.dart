import 'package:proof/shared/models/onboarding_step.dart';
import 'package:proof/shared/models/user_model.dart';

class OnboardingMigration {
  const OnboardingMigration._();

  static OnboardingStep resolveNext(
    UserModel user, {
    required bool hasIdentity,
    required bool hasCoachProfile,
  }) {
    if (user.onboardingCompleted) return OnboardingStep.completed;
    if (user.role.needsPhysicalIdentity && !hasIdentity) {
      return OnboardingStep.createPhysicalIdentity;
    }
    if (user.role.isCoach && !hasCoachProfile) {
      return OnboardingStep.createCoachProfile;
    }
    if (user.role.isGymManager && user.managedGymIds.isEmpty) {
      return OnboardingStep.createGymProfile;
    }
    if ((user.role.isAthlete || user.role.isCoach) &&
        !user.gymSelectionCompleted) {
      return OnboardingStep.selectGym;
    }
    return OnboardingStep.completed;
  }
}
