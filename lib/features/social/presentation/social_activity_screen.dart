import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/social/application/social_providers.dart';
import 'package:proof/features/social/domain/social_comment.dart';
import 'package:proof/features/social/domain/social_comment_policy.dart';
import 'package:proof/features/social/presentation/widgets/gym_activity_card.dart';
import 'package:proof/shared/models/user_report_model.dart';
import 'package:proof/shared/models/verification_status.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

/// Shared achievement. Personal notes and private attachments are not loaded.
class SocialActivityScreen extends ConsumerStatefulWidget {
  const SocialActivityScreen({
    super.key,
    required this.gymId,
    required this.activityId,
  });

  final String gymId;
  final String activityId;

  @override
  ConsumerState<SocialActivityScreen> createState() =>
      _SocialActivityScreenState();
}

class _SocialActivityScreenState extends ConsumerState<SocialActivityScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;

  SocialActivityRef get _ref => SocialActivityRef(
        gymId: widget.gymId,
        activityId: widget.activityId,
      );

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    final check = SocialCommentPolicy.check(_commentController.text);
    if (!check.isValid || check.text == null) {
      final message = check.rejection == SocialCommentRejection.tooLong
          ? 'Comments are limited to ${SocialCommentPolicy.maxLength} characters.'
          : 'Enter a comment before posting.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again before commenting.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final identity = await service.getIdentity(userId);
      if (identity == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add your profile name before commenting.'),
            ),
          );
        }
        return;
      }
      await service.addGymActivityComment(
            gymId: widget.gymId,
            activityId: widget.activityId,
            userId: userId,
            text: check.text!,
            displayName: identity.displayName,
            avatarUrl: identity.avatarUrl ?? '',
          );
      _commentController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_commentError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(gymActivityProvider(_ref));
    final viewerId = ref.watch(currentAuthUidProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Achievement',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: activity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _Unavailable(
          message: 'Could not open this achievement.',
        ),
        data: (item) {
          if (item == null) {
            return const _Unavailable(
              message: 'This achievement is no longer shared.',
            );
          }
          final own = viewerId != null && viewerId == item.athleteId;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    GymActivityCard(
                      activity: item,
                      onOpen: () {},
                      onDeleted: () {
                        if (context.mounted) context.pop();
                      },
                    ),
                    if (item.verificationStatus ==
                        VerificationStatus.coachVerified) ...[
                      const SizedBox(height: 8),
                      Text(
                        ProofDateUtils.formatDateTime(item.recordedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _Comments(
                      activityRef: _ref,
                      viewerId: viewerId,
                      onReport: _report,
                      onBlock: _block,
                      onDelete: _delete,
                    ),
                  ],
                ),
              ),
              if (!own) _Composer(
                controller: _commentController,
                sending: _sending,
                onSubmit: _submit,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(SocialComment comment) async {
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null) return;
    try {
      await ref.read(firestoreServiceProvider).deleteGymActivityComment(
            gymId: widget.gymId,
            activityId: widget.activityId,
            commentId: comment.id,
            userId: userId,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_commentError(error))),
        );
      }
    }
  }

  Future<void> _report(SocialComment comment) async {
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null || userId == comment.authorId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report comment?'),
        content: const Text(
          'Report this comment for review. The message stays in place until it is handled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(firestoreServiceProvider).submitUserReport(
            reporterUserId: userId,
            reportedUserId: comment.authorId,
            reportedHandle: comment.displayName,
            reason: UserReportReason.inappropriate,
            details:
                'gym activity comment ${widget.gymId}/${widget.activityId}/${comment.id}',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send the report. $error')),
        );
      }
    }
  }

  Future<void> _block(SocialComment comment) async {
    final userId = ref.read(currentAuthUidProvider);
    if (userId == null || userId == comment.authorId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this member?'),
        content: const Text(
          'You will no longer see their activity or comments in your gym feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(firestoreServiceProvider).blockUser(
            fromUserId: userId,
            toUserId: comment.authorId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member blocked.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not block this member. $error')),
        );
      }
    }
  }
}

class _Comments extends ConsumerWidget {
  const _Comments({
    required this.activityRef,
    required this.viewerId,
    required this.onReport,
    required this.onBlock,
    required this.onDelete,
  });

  final SocialActivityRef activityRef;
  final String? viewerId;
  final ValueChanged<SocialComment> onReport;
  final ValueChanged<SocialComment> onBlock;
  final ValueChanged<SocialComment> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(gymActivityCommentsProvider(activityRef));
    final blocked = ref.watch(socialBlockedUserIdsProvider);
    return comments.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => const Text('Could not load comments.'),
      data: (items) {
        final visible = items
            .where((comment) => !blocked.contains(comment.authorId))
            .toList();
        final pageSize = ref.watch(socialCommentPageSizeProvider(activityRef));
        if (visible.isEmpty) {
          return Text(
            'No comments yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          );
        }
        return Column(
          children: [
            for (final comment in visible)
              _CommentTile(
                comment: comment,
                mine: viewerId != null && viewerId == comment.authorId,
                onReport: () => onReport(comment),
                onBlock: () => onBlock(comment),
                onDelete: () => onDelete(comment),
              ),
            if (items.length >= pageSize)
              TextButton(
                onPressed: () {
                  ref
                      .read(socialCommentPageSizeProvider(activityRef).notifier)
                      .state = pageSize + 40;
                },
                child: const Text('Load more comments'),
              ),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.mine,
    required this.onReport,
    required this.onBlock,
    required this.onDelete,
  });

  final SocialComment comment;
  final bool mine;
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = comment.displayName.trim().isEmpty
        ? 'Athlete'
        : comment.displayName.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.surfaceElevated,
            backgroundImage: comment.avatarUrl.startsWith('http')
                ? NetworkImage(comment.avatarUrl)
                : null,
            child: comment.avatarUrl.startsWith('http')
                ? null
                : Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(comment.text),
                const SizedBox(height: 2),
                Text(
                  ProofDateUtils.formatRelative(comment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Comment actions',
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  onDelete();
                case 'report':
                  onReport();
                case 'block':
                  onBlock();
              }
            },
            itemBuilder: (context) => [
              if (mine)
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              if (!mine) ...[
                const PopupMenuItem(value: 'report', child: Text('Report')),
                const PopupMenuItem(value: 'block', child: Text('Block')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: SocialCommentPolicy.maxLength,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: sending ? null : (_) => onSubmit(),
                decoration: const InputDecoration(
                  hintText: 'Add a comment',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Post comment',
              onPressed: sending ? null : onSubmit,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.inkSecondary,
              ),
        ),
      ),
    );
  }
}

String _commentError(Object error) {
  final message = error.toString();
  if (message.contains('wait a moment')) {
    return 'Please wait a moment before commenting again.';
  }
  if (message.contains('limited to')) {
    return 'Comments are limited to ${SocialCommentPolicy.maxLength} characters.';
  }
  if (message.contains('Enter a comment')) {
    return 'Enter a comment before posting.';
  }
  if (message.contains('own')) {
    return 'You cannot comment on your own achievement.';
  }
  if (message.contains('no longer')) {
    return 'This achievement is no longer shared.';
  }
  if (message.contains('only delete')) {
    return 'You can only delete your own comments.';
  }
  return 'Could not update comments.';
}
