import 'package:proof/shared/models/user_role.dart';

enum OnboardingStep {
  chooseAccountType('choose_account_type'),
  createPhysicalIdentity('create_physical_identity'),
  createCoachProfile('create_coach_profile'),
  createGymProfile('create_gym_profile'),
  selectGym('select_gym'),
  completed('completed');

  const OnboardingStep(this.value);

  final String value;

  static OnboardingStep fromString(String? value) {
    if (value == null || value.isEmpty) {
      return OnboardingStep.chooseAccountType;
    }
    return OnboardingStep.values.firstWhere(
      (s) => s.value == value,
      orElse: () => OnboardingStep.chooseAccountType,
    );
  }

  static OnboardingStep initialStepFor(UserRole role) {
    return switch (role) {
      UserRole.athlete => OnboardingStep.createPhysicalIdentity,
      UserRole.coach => OnboardingStep.createCoachProfile,
      UserRole.gymManager => OnboardingStep.createGymProfile,
      UserRole.athleteAndCoach => OnboardingStep.createPhysicalIdentity,
    };
  }

  static OnboardingStep? nextAfterPhysicalIdentity(UserRole role) {
    return switch (role) {
      UserRole.athlete || UserRole.athleteAndCoach => OnboardingStep.selectGym,
      _ => OnboardingStep.completed,
    };
  }

  static OnboardingStep? nextAfterCoachProfile(UserRole role) {
    return switch (role) {
      UserRole.coach => OnboardingStep.selectGym,
      _ => null,
    };
  }

  static OnboardingStep? previousFor(OnboardingStep step, UserRole role) {
    return switch (step) {
      OnboardingStep.createPhysicalIdentity => OnboardingStep.chooseAccountType,
      OnboardingStep.createCoachProfile => OnboardingStep.chooseAccountType,
      OnboardingStep.selectGym => switch (role) {
          UserRole.coach => OnboardingStep.createCoachProfile,
          UserRole.athlete || UserRole.athleteAndCoach =>
            OnboardingStep.createPhysicalIdentity,
          _ => OnboardingStep.chooseAccountType,
        },
      OnboardingStep.createGymProfile => OnboardingStep.chooseAccountType,
      _ => null,
    };
  }
}
