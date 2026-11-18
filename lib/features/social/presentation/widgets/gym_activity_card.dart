import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/social/application/social_providers.dart';
import 'package:proof/features/social/domain/gym_activity.dart';
import 'package:proof/shared/models/verification_status.dart';
import 'package:proof/shared/providers/app_providers.dart';

class GymActivityCard extends ConsumerStatefulWidget {
  const GymActivityCard({
    super.key,
    required this.activity,
    required this.onOpen,
    this.onDeleted,
  });

  final GymActivity activity;
  final VoidCallback onOpen;
  final VoidCallback? onDeleted;

  @override
  ConsumerState<GymActivityCard> createState() => _GymActivityCardState();
}

class _GymActivityCardState extends ConsumerState<GymActivityCard> {
  bool? _likedOverride;
  bool _busy = false;

  SocialActivityRef get _ref => SocialActivityRef(
        gymId: widget.activity.gymId,
        activityId: widget.activity.id,
      );

  Future<void> _deletePost() async {
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null || userId != widget.activity.athleteId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'Remove this from your gym feed? It stays in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(firestoreServiceProvider).revokeProofShare(
            userId: userId,
            proofId: widget.activity.proofId,
            gymId: widget.activity.gymId,
          );
      widget.onDeleted?.call();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete this post. $error')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null || userId == widget.activity.athleteId) return;
    final server = ref.read(gymActivityLikedProvider(_ref)).valueOrNull ?? false;
    final current = _likedOverride ?? server;
    setState(() {
      _busy = true;
      _likedOverride = !current;
    });
    try {
      await ref.read(firestoreServiceProvider).toggleGymActivityLike(
            gymId: widget.activity.gymId,
            activityId: widget.activity.id,
            userId: userId,
          );
    } catch (error) {
      if (mounted) {
        setState(() => _likedOverride = current);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_likeError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final userId = ref.watch(currentAuthUidProvider);
    final own = userId != null && userId == activity.athleteId;
    final serverLiked =
        ref.watch(gymActivityLikedProvider(_ref)).valueOrNull ?? false;
    final liked = _likedOverride ?? serverLiked;
    final name = activity.displayName.trim().isEmpty
        ? 'Athlete'
        : activity.displayName.trim();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onOpen,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(name: name, url: activity.avatarUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (activity.discipline.trim().isNotEmpty)
                              activity.discipline.trim(),
                            ProofDateUtils.formatRelative(activity.recordedAt),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (own)
                    PopupMenuButton<String>(
                      tooltip: 'Post actions',
                      onSelected: (value) {
                        if (value == 'delete') _deletePost();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                activity.skillLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.inkSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.formattedResult,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (activity.verificationStatus !=
                  VerificationStatus.selfReported) ...[
                const SizedBox(height: 6),
                Text(
                  activity.verificationStatus.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _CountButton(
                    tooltip: liked ? 'Remove like' : 'Like',
                    icon: liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? AppColors.accent : AppColors.inkMuted,
                    count: activity.likeCount,
                    emphasized: liked,
                    onPressed: _toggleLike,
                  ),
                  const SizedBox(width: 8),
                  _CountButton(
                    tooltip: 'Comments',
                    icon: Icons.chat_bubble_outline,
                    color: AppColors.inkMuted,
                    count: activity.commentCount,
                    onPressed: widget.onOpen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _likeError(Object error) {
  final message = error.toString();
  if (message.contains('no longer shared')) {
    return 'This achievement is no longer shared.';
  }
  if (message.contains('own achievement')) {
    return 'You cannot like your own achievement.';
  }
  return 'Could not update your like.';
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.url});

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final image = url.startsWith('http') ? NetworkImage(url) : null;
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.surfaceElevated,
      backgroundImage: image,
      child: image == null
          ? Text(
              initial,
              style: const TextStyle(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.count,
    required this.onPressed,
    this.emphasized = false,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: color,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: onPressed,
        icon: AnimatedScale(
          scale: emphasized ? 1.08 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: Icon(icon, size: 18),
        ),
        label: Text('$count'),
      ),
    );
  }
}
