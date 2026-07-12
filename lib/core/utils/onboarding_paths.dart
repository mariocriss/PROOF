import 'package:proof/shared/models/onboarding_step.dart';
import 'package:proof/shared/models/user_role.dart';

class OnboardingPaths {
  OnboardingPaths._();

  static const accountType = '/onboarding/account-type';
  static const athleteIdentity = '/onboarding/athlete-identity';
  static const coachProfile = '/onboarding/coach-profile';
  static const gymProfile = '/onboarding/gym-profile';
  static const selectGym = '/onboarding/select-gym';

  static bool isOnboardingRoute(String location) {
    return location.startsWith('/onboarding');
  }

  static String routeForStep(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.chooseAccountType => accountType,
      OnboardingStep.createPhysicalIdentity => athleteIdentity,
      OnboardingStep.createCoachProfile => coachProfile,
      OnboardingStep.createGymProfile => gymProfile,
      OnboardingStep.selectGym => selectGym,
      OnboardingStep.completed => accountType,
    };
  }

  static String? previousRoute({
    required OnboardingStep step,
    required UserRole role,
  }) {
    final previous = OnboardingStep.previousFor(step, role);
    if (previous == null) return null;
    return routeForStep(previous);
  }

  static String routeForUser({
    required OnboardingStep step,
    required bool onboardingCompleted,
    UserRole? role,
    String? managedGymId,
  }) {
    if (onboardingCompleted) {
      if (role == UserRole.gymManager && managedGymId != null) {
        return '/gym-manager/$managedGymId';
      }
      return '/dashboard';
    }
    if (step == OnboardingStep.completed) {
      if (role == UserRole.gymManager && managedGymId != null) {
        return '/gym-manager/$managedGymId';
      }
      return '/dashboard';
    }
    return routeForStep(step);
  }
}
