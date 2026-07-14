import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/people/domain/friend_connection_state.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class PeopleSectionLabel extends StatelessWidget {
  const PeopleSectionLabel({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.inkMuted,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class MoreMenuCard extends StatelessWidget {
  const MoreMenuCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class MoreMenuRow extends StatelessWidget {
  const MoreMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (badge != null && badge! > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badge',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right, size: 20, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class CoachListCard extends StatelessWidget {
  const CoachListCard({
    super.key,
    required this.profile,
    this.identity,
    required this.onTap,
    this.trailing,
  });

  final CoachProfile profile;
  final PhysicalIdentity? identity;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final name = identity?.displayName ?? profile.displayName;
    final handle = identity?.handle ?? profile.handle;
    final avatarUrl = identity?.avatarUrl ?? profile.avatarUrl;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '@$handle',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.specialty,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniStat(value: '${profile.athleteCount}', label: 'Athletes'),
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: AppColors.divider,
                        ),
                        _MiniStat(
                          value: '${profile.verifiedProofCount}',
                          label: 'Verified Proofs',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkMuted,
              ),
        ),
      ],
    );
  }
}

class PeopleSegmentTabs extends StatelessWidget {
  const PeopleSegmentTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.tabBadges = const {},
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Map<int, int> tabBadges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == selectedIndex;
          final badge = tabBadges[index];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        tabs[index],
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color:
                                  selected ? Colors.white : AppColors.inkSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (badge != null && badge > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.22)
                              : AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: selected ? Colors.white : AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class IdentityBannerCard extends StatelessWidget {
  const IdentityBannerCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Identity. Your Standard.',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep building. Keep proving.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PublicProfileAvatar extends StatelessWidget {
  const PublicProfileAvatar({super.key, required this.profile, this.radius = 24});

  final PublicProfileModel profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceElevated,
      backgroundImage:
          profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
      child: profile.avatarUrl == null
          ? Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName[0].toUpperCase()
                  : '?',
            )
          : null,
    );
  }
}

class FriendConnectionButton extends ConsumerWidget {
  const FriendConnectionButton({
    super.key,
    required this.profile,
    required this.connection,
    required this.userId,
    this.compact = false,
  });

  final PublicProfileModel profile;
  final FriendConnection connection;
  final String? userId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null || userId == profile.userId) {
      return const SizedBox.shrink();
    }

    switch (connection.state) {
      case FriendConnectionState.accepted:
        return _FriendActionChip(label: 'Friends', enabled: false);
      case FriendConnectionState.outgoingPending:
        return _FriendActionChip(label: 'Request Sent', enabled: false);
      case FriendConnectionState.incomingPending:
        return compact
            ? _FriendActionChip(
                label: 'Respond',
                enabled: true,
                onTap: () => context.push('/people/${profile.handle}'),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProofButton(
                    label: 'Accept',
                    onPressed: () => _respond(ref, accept: true),
                  ),
                  const SizedBox(width: 8),
                  ProofButton(
                    label: 'Decline',
                    isOutlined: true,
                    onPressed: () => _respond(ref, accept: false),
                  ),
                ],
              );
      case FriendConnectionState.blocked:
        return _FriendActionChip(label: 'Blocked', enabled: false);
      case FriendConnectionState.declined:
      case FriendConnectionState.none:
        return compact
            ? _FriendActionChip(
                label: 'Add Friend',
                enabled: true,
                onTap: () => _sendRequest(context, ref),
              )
            : ProofButton(
                label: 'Add Friend',
                onPressed: () => _sendRequest(context, ref),
              );
    }
  }

  Future<void> _sendRequest(BuildContext context, WidgetRef ref) async {
    final fromUserId = userId;
    if (fromUserId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait… signing you in.')),
        );
      }
      return;
    }

    try {
      await ref.read(firestoreServiceProvider).sendFriendRequest(
            fromUserId: fromUserId,
            toUserId: profile.userId,
          );
    } on FirebaseException catch (e) {
      if (context.mounted) {
        final message = e.message?.isNotEmpty == true ? e.message! : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send request (${e.code}): $message')),
        );
      }
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send request: $e')),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${profile.displayName}')),
      );
    }
  }

  Future<void> _respond(WidgetRef ref, {required bool accept}) async {
    final relationship = connection.relationship;
    if (relationship == null) return;
    await ref.read(firestoreServiceProvider).respondToRelationship(
          relationshipId: relationship.id,
          accept: accept,
        );
  }
}

class _FriendActionChip extends StatelessWidget {
  const _FriendActionChip({
    required this.label,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.accent : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: enabled ? Colors.white : AppColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
