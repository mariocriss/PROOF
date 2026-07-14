import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';

Future<void> confirmRemoveGymMembership(
  BuildContext context,
  WidgetRef ref, {
  required GymMembershipModel membership,
  required String personName,
  required String gymName,
}) async {
  final roleLabel = membership.membershipType.label.toLowerCase();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Remove $roleLabel?'),
      content: Text(
        'Remove $personName from $gymName? They can request to join again later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final managerId = ref.read(authStateProvider).valueOrNull?.uid;
  if (managerId == null) return;

  await ref.read(firestoreServiceProvider).reviewGymMembership(
        membershipId: membership.id,
        status: GymMembershipStatus.removed,
        reviewedBy: managerId,
      );

  ref.invalidate(gymMembershipsForGymProvider(membership.gymId));

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$personName removed from $gymName')),
    );
  }
}
