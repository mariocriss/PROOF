import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/people/domain/people_relationship_queries.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/user_role.dart';

void main() {
  group('blockedUserIds', () {
    test('includes the other party when recipient blocked sender', () {
      final a = 'userA';
      final b = 'userB';
      final relationships = [
        RelationshipModel(
          id: RelationshipModel.friendDocId(a, b),
          fromUserId: a,
          toUserId: b,
          type: RelationshipType.friend,
          status: RelationshipStatus.blocked,
          createdAt: DateTime(2026),
          blockedByUserId: b,
        ),
      ];

      expect(blockedUserIds(relationships, a), {b});
      expect(blockedUserIds(relationships, b), {a});
    });
  });

  group('updateCoachPreference role matrix', () {
    test('preserves gymManager and coach-only roles', () {
      expect(
        _nextCoachRole(UserRole.gymManager, enableCoach: false),
        UserRole.gymManager,
      );
      expect(
        _nextCoachRole(UserRole.coach, enableCoach: false),
        UserRole.coach,
      );
      expect(
        _nextCoachRole(UserRole.athlete, enableCoach: true),
        UserRole.athleteAndCoach,
      );
      expect(
        _nextCoachRole(UserRole.athleteAndCoach, enableCoach: false),
        UserRole.athlete,
      );
    });
  });
}

/// Mirrors [FirestoreService.updateCoachPreference] role selection.
UserRole _nextCoachRole(UserRole currentRole, {required bool enableCoach}) {
  return switch (currentRole) {
    UserRole.athlete when enableCoach => UserRole.athleteAndCoach,
    UserRole.athleteAndCoach when !enableCoach => UserRole.athlete,
    _ => currentRole,
  };
}
