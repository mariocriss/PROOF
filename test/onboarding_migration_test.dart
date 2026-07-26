import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/utils/onboarding_migration.dart';
import 'package:proof/shared/models/onboarding_step.dart';
import 'package:proof/shared/models/user_model.dart';
import 'package:proof/shared/models/user_role.dart';

UserModel user(UserRole role, {bool gymSelectionCompleted = false}) =>
    UserModel(
      id: 'u',
      email: 'u@example.com',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      role: role,
      gymSelectionCompleted: gymSelectionCompleted,
    );

void main() {
  test('does not complete onboarding merely because identity exists', () {
    expect(
      OnboardingMigration.resolveNext(
        user(UserRole.athlete),
        hasIdentity: true,
        hasCoachProfile: false,
      ),
      OnboardingStep.selectGym,
    );
  });

  test('preserves already completed onboarding', () {
    final completed = UserModel(
      id: 'u',
      email: 'u@example.com',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      role: UserRole.athlete,
      onboardingCompleted: true,
      gymSelectionCompleted: false,
    );
    expect(
      OnboardingMigration.resolveNext(
        completed,
        hasIdentity: true,
        hasCoachProfile: false,
      ),
      OnboardingStep.completed,
    );
  });

  test('routes interrupted athlete without identity to identity step', () {
    expect(
      OnboardingMigration.resolveNext(
        user(UserRole.athlete),
        hasIdentity: false,
        hasCoachProfile: false,
      ),
      OnboardingStep.createPhysicalIdentity,
    );
  });
}
