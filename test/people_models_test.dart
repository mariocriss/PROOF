import 'package:flutter_test/flutter_test.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/models/relationship_model.dart';

void main() {
  group('RelationshipModel', () {
    test('friendDocId is deterministic regardless of argument order', () {
      expect(
        RelationshipModel.friendDocId('user-b', 'user-a'),
        RelationshipModel.friendDocId('user-a', 'user-b'),
      );
      expect(
        RelationshipModel.friendDocId('user-a', 'user-b'),
        'friend_user-a_user-b',
      );
    });

    test('toFirestore writes canonical relationship fields', () {
      final model = RelationshipModel(
        id: 'friend_a_b',
        fromUserId: 'a',
        toUserId: 'b',
        type: RelationshipType.friend,
        status: RelationshipStatus.pending,
        createdAt: DateTime(2026, 3, 1),
        requesterSeen: true,
        recipientSeen: false,
      );

      final data = model.toFirestore();
      expect(data['fromUserId'], 'a');
      expect(data['toUserId'], 'b');
      expect(data['requesterUserId'], 'a');
      expect(data['recipientUserId'], 'b');
      expect(data['type'], 'friend');
      expect(data['status'], 'pending');
      expect(data['requesterSeen'], isTrue);
      expect(data['recipientSeen'], isFalse);
    });

    test('terminal statuses are marked correctly', () {
      expect(RelationshipStatus.pending.isTerminal, isFalse);
      expect(RelationshipStatus.accepted.isTerminal, isTrue);
      expect(RelationshipStatus.declined.isTerminal, isTrue);
      expect(RelationshipStatus.blocked.isTerminal, isTrue);
    });

    test('fromString falls back safely', () {
      expect(RelationshipStatus.fromString(null), RelationshipStatus.pending);
      expect(RelationshipStatus.fromString('unknown'), RelationshipStatus.pending);
      expect(RelationshipType.fromString('coach'), RelationshipType.coach);
    });
  });

  group('PublicProfileModel', () {
    test('toFirestore stores searchable lowercase fields and skills', () {
      final profile = PublicProfileModel(
        userId: 'u1',
        displayName: 'Mario Rossi',
        displayNameLowercase: 'mario rossi',
        handle: 'mario',
        handleLowercase: 'mario',
        city: 'Rotterdam',
        bio: 'Strength athlete',
        identityStatus: 'Developing',
        publicTopSkills: const [
          PublicTopSkill(name: 'Pull-ups', resultLabel: '16 reps'),
        ],
        searchable: true,
        updatedAt: DateTime(2026, 3, 1),
      );

      final data = profile.toFirestore();
      expect(data['displayNameLowercase'], 'mario rossi');
      expect(data['handleLowercase'], 'mario');
      expect(data['searchable'], isTrue);
      expect(data['publicTopSkills'], hasLength(1));
    });

    test('PublicTopSkill round-trips through map', () {
      const skill = PublicTopSkill(name: 'Push-ups', resultLabel: '35 reps');
      final restored = PublicTopSkill.fromMap(skill.toMap());
      expect(restored.name, 'Push-ups');
      expect(restored.resultLabel, '35 reps');
    });
  });
}
