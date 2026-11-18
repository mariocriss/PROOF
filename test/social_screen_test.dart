import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/social/application/social_providers.dart';
import 'package:proof/features/social/domain/gym_activity.dart';
import 'package:proof/features/social/presentation/social_screen.dart';
import 'package:proof/features/social/presentation/widgets/share_with_others_field.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/verification_status.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';

void main() {
  testWidgets('social empty state without a gym invites the user to join', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userGymMembershipsProvider.overrideWith(
            (ref) => Stream.value(const <GymMembershipModel>[]),
          ),
        ],
        child: const MaterialApp(home: SocialScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Social'), findsOneWidget);
    expect(
      find.text('Join a gym to see activity from athletes there.'),
      findsOneWidget,
    );
    expect(find.text('Your gym activity will appear here.'), findsNothing);
  });

  testWidgets('social empty state with a gym does not invent activity', (
    tester,
  ) async {
    await tester.pumpWidget(_gymApp(const []));
    await tester.pump();
    await tester.pump();

    expect(find.text('Your gym activity will appear here.'), findsOneWidget);
    expect(find.text('Find a gym'), findsNothing);
  });

  testWidgets('social feed shows your own share and other gym members', (
    tester,
  ) async {
    final when = DateTime.utc(2026, 3, 1);
    final activity = [
      _activity(id: 'mine', athleteId: 'u1', name: 'Me', when: when),
      _activity(id: 'theirs', athleteId: 'u2', name: 'Other Athlete', when: when),
    ];

    await tester.pumpWidget(_gymApp(activity));
    await tester.pump();
    await tester.pump();

    expect(find.text('Other Athlete'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    expect(find.text('5K'), findsWidgets);
    expect(find.text('20:00'), findsWidgets);
    expect(find.text('Coach verified'), findsWidgets);
  });

  testWidgets('share with others starts unchecked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareWithOthersField(
            value: ShareWithOthersField.initialValue,
            enabled: true,
            onChanged: _ignore,
          ),
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(find.text('Share with others'), findsOneWidget);
    expect(
      find.text('Share this achievement with other members of your gym.'),
      findsOneWidget,
    );
  });

  testWidgets('sharing without a gym explains membership and stays off', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShareWithOthersField(
            value: true,
            enabled: false,
          ),
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(
      find.textContaining('Sharing requires an approved gym membership'),
      findsOneWidget,
    );
  });
}

void _ignore(bool value) {}

Widget _gymApp(List<GymActivity> activity) {
  final membership = GymMembershipModel(
    id: 'm1',
    gymId: 'g1',
    userId: 'u1',
    membershipType: GymMembershipType.athlete,
    status: GymMembershipStatus.approved,
    requestedAt: DateTime.utc(2026, 1, 1),
  );
  return ProviderScope(
    overrides: [
      userGymMembershipsProvider.overrideWith(
        (ref) => Stream.value([membership]),
      ),
      currentAuthUidProvider.overrideWith((ref) => 'u1'),
      socialBlockedUserIdsProvider.overrideWith((ref) => <String>{}),
      gymActivityFeedProvider.overrideWith(
        (ref, gymId) => Stream.value(activity),
      ),
      gymActivityLikedProvider.overrideWith(
        (ref, activity) => Stream.value(false),
      ),
    ],
    child: const MaterialApp(home: SocialScreen()),
  );
}

GymActivity _activity({
  required String id,
  required String athleteId,
  required String name,
  required DateTime when,
}) {
  return GymActivity(
    id: id,
    gymId: 'g1',
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
    displayName: name,
  );
}
