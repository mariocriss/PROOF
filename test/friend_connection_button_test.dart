import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/people/domain/friend_connection_state.dart';
import 'package:proof/features/people/presentation/widgets/people_widgets.dart';
import 'package:proof/shared/models/public_profile_model.dart';

void main() {
  PublicProfileModel profile({required String userId}) {
    return PublicProfileModel(
      userId: userId,
      displayName: 'Mario Rossi',
      handle: 'mario',
      displayNameLowercase: 'mario rossi',
      handleLowercase: 'mario',
      updatedAt: DateTime(2026),
    );
  }

  Future<void> pumpButton(
    WidgetTester tester, {
    required FriendConnection connection,
    required String? userId,
    bool compact = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FriendConnectionButton(
              profile: profile(userId: 'other'),
              connection: connection,
              userId: userId,
              compact: compact,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows Add Friend when there is no relationship', (tester) async {
    await pumpButton(
      tester,
      connection: const FriendConnection(state: FriendConnectionState.none),
      userId: 'me',
      compact: true,
    );

    expect(find.text('Add Friend'), findsOneWidget);
  });

  testWidgets('shows Request Sent for outgoing pending requests', (tester) async {
    await pumpButton(
      tester,
      connection: const FriendConnection(
        state: FriendConnectionState.outgoingPending,
      ),
      userId: 'me',
      compact: true,
    );

    expect(find.text('Request Sent'), findsOneWidget);
  });

  testWidgets('shows Friends for accepted relationships', (tester) async {
    await pumpButton(
      tester,
      connection: const FriendConnection(
        state: FriendConnectionState.accepted,
      ),
      userId: 'me',
      compact: true,
    );

    expect(find.text('Friends'), findsOneWidget);
  });

  testWidgets('shows Accept and Decline for incoming requests', (tester) async {
    await pumpButton(
      tester,
      connection: const FriendConnection(
        state: FriendConnectionState.incomingPending,
      ),
      userId: 'me',
    );

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });
}
