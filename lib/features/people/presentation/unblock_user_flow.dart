import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/providers/app_providers.dart';

/// Shows confirmation and deletes the blocked relationship when confirmed.
///
/// Returns `true` when the relationship document was deleted successfully.
Future<bool> confirmAndUnblockUser({
  required BuildContext context,
  required WidgetRef ref,
  required String currentUserId,
  required RelationshipModel relationship,
  required String displayName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _UnblockConfirmDialog(
        displayName: displayName,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () async {
          try {
            await ref
                .read(firestoreServiceProvider)
                .unblockUser(
                  currentUserId: currentUserId,
                  relationshipId: relationship.id,
                );
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(true);
            }
          } catch (error) {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(false);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_unblockErrorMessage(error))),
              );
            }
          }
        },
      );
    },
  );

  if (confirmed == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$displayName has been unblocked')));
    return true;
  }
  return false;
}

String _unblockErrorMessage(Object error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'You do not have permission to unblock this user.';
    }
    if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
      return 'Network error. Check your connection and try again.';
    }
    final detail = error.message?.trim();
    if (detail != null && detail.isNotEmpty) {
      return 'Could not unblock ($detail).';
    }
    return 'Could not unblock (${error.code}).';
  }
  if (error is StateError) {
    return error.message;
  }
  return 'Could not unblock. Please try again.';
}

class _UnblockConfirmDialog extends StatefulWidget {
  const _UnblockConfirmDialog({
    required this.displayName,
    required this.onCancel,
    required this.onConfirm,
  });

  final String displayName;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  @override
  State<_UnblockConfirmDialog> createState() => _UnblockConfirmDialogState();
}

class _UnblockConfirmDialogState extends State<_UnblockConfirmDialog> {
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onConfirm();
    if (mounted && _busy) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Unblock ${widget.displayName}?'),
      content: const Text(
        'They will be able to find and interact with you again. '
        'You won\'t automatically become friends.',
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : widget.onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _confirm,
          child: Text(_busy ? 'Unblocking…' : 'Unblock'),
        ),
      ],
    );
  }
}
