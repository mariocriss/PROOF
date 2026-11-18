import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/social/domain/gym_activity.dart';
import 'package:proof/features/social/domain/social_comment_policy.dart';
import 'package:proof/features/social/presentation/widgets/share_with_others_field.dart';
import 'package:proof/shared/models/verification_status.dart';

void main() {
  test('sharing starts unchecked for every upload', () {
    expect(ShareWithOthersField.initialValue, isFalse);
  });

  test('comments reject empty and oversized text', () {
    expect(SocialCommentPolicy.check('   ').isValid, isFalse);
    expect(
      SocialCommentPolicy.check('   ').rejection,
      SocialCommentRejection.empty,
    );
    expect(
      SocialCommentPolicy.check('a' * 301).rejection,
      SocialCommentRejection.tooLong,
    );
    expect(SocialCommentPolicy.check('  nice split  ').text, 'nice split');
  });

  test('gym feed keeps the viewer and hides blocked athletes', () {
    final activity = [
      _activity(id: 'mine', athleteId: 'me'),
      _activity(id: 'theirs', athleteId: 'bob'),
      _activity(id: 'blocked', athleteId: 'carol'),
      _activity(id: 'revoked', athleteId: 'dave', status: 'revoked'),
    ];

    final visible = visibleGymActivity(
      activity: activity,
      blockedUserIds: {'carol'},
    );

    expect(visible.map((item) => item.id), ['mine', 'theirs']);
  });
}

GymActivity _activity({
  required String id,
  required String athleteId,
  String status = GymActivity.activeStatus,
}) {
  final when = DateTime.utc(2026, 3, 1);
  return GymActivity(
    id: id,
    gymId: 'gym-a',
    proofId: id,
    athleteId: athleteId,
    skillId: 'skill',
    skillName: '5K',
    discipline: 'Running',
    result: '20:00',
    unit: 'time',
    recordedAt: when,
    sharedAt: when,
    verificationStatus: VerificationStatus.coachVerified,
    displayName: athleteId,
    status: status,
  );
}
