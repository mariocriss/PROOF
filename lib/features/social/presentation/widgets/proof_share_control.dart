import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/social/application/social_providers.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';

/// Owner control for publishing or revoking one proof.
///
/// Sharing is never inferred from an earlier upload or from coach verification.
class ProofShareControl extends ConsumerStatefulWidget {
  const ProofShareControl({super.key, required this.proof});

  final ProofModel proof;

  @override
  ConsumerState<ProofShareControl> createState() => _ProofShareControlState();
}

class _ProofShareControlState extends ConsumerState<ProofShareControl> {
  bool _reconciled = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final memberships = ref.watch(userGymMembershipsProvider).valueOrNull;
    final shareGyms = approvedAthleteShareGymIds(memberships ?? const []);
    final sharedGymId = widget.proof.sharedWithGymId;
    final stillMember = sharedGymId != null && shareGyms.contains(sharedGymId);

    if (memberships != null &&
        sharedGymId != null &&
        !stillMember &&
        !_reconciled) {
      _reconciled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _revoke(sharedGymId, quiet: true);
      });
    }

    if (sharedGymId != null) {
      return _Row(
        text: 'Shared with your gym. Personal notes stay private.',
        action: 'Stop sharing',
        busy: _busy,
        onPressed: () => _confirmRevoke(sharedGymId),
      );
    }

    if (shareGyms.isEmpty) {
      return Text(
        'Sharing requires an approved gym membership.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
              height: 1.4,
            ),
      );
    }

    return _Row(
      text: 'Share this achievement with other members of your gym.',
      action: 'Share with others',
      busy: _busy,
      onPressed: () => _confirmShare(shareGyms),
    );
  }

  Future<void> _confirmShare(List<String> gymIds) async {
    var gymId = gymIds.length == 1 ? gymIds.first : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share with others'),
        content: Text(
          gymIds.length == 1
              ? 'Share this achievement with other members of your gym. Personal notes stay private.'
              : 'Choose a gym. This achievement will be visible to its members. Personal notes stay private.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (gymId == null) {
      gymId = await _pickGym(gymIds);
      if (gymId == null || !mounted) return;
    }
    await _share(gymId);
  }

  Future<String?> _pickGym(List<String> gymIds) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a gym'),
        children: [
          for (final gymId in gymIds)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, gymId),
              child: Text(gymId),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(String gymId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop sharing?'),
        content: const Text(
          'Members of your gym will no longer see this achievement. It stays in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop sharing'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _revoke(gymId);
  }

  Future<void> _share(String gymId) async {
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(firestoreServiceProvider).shareProofWithGym(
            userId: userId,
            proofId: widget.proof.id,
            gymId: gymId,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(String gymId, {bool quiet = false}) async {
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null) return;
    if (!quiet) setState(() => _busy = true);
    try {
      await ref.read(firestoreServiceProvider).revokeProofShare(
            userId: userId,
            proofId: widget.proof.id,
            gymId: gymId,
          );
    } catch (error) {
      if (mounted && !quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not stop sharing. $error')),
        );
      }
    } finally {
      if (mounted && !quiet) setState(() => _busy = false);
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.text,
    required this.action,
    required this.onPressed,
    required this.busy,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
                height: 1.4,
              ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: busy ? null : onPressed,
            child: Text(action),
          ),
        ),
      ],
    );
  }
}
