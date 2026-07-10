import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/dashboard/domain/dashboard_view_data.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/features/proof_stack/presentation/widgets/confidence_explanation_sheet.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/confidence_block_progress.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(physicalIdentityProvider);
    final skillsAsync = ref.watch(skillsProvider);
    final proofsAsync = ref.watch(proofsProvider);
    final timelineAsync = ref.watch(timelineProvider);

    return identityAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e')),
      ),
      data: (identity) {
        if (identity == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final skills = skillsAsync.valueOrNull ?? [];
        final proofs = proofsAsync.valueOrNull ?? [];
        final timeline = timelineAsync.valueOrNull ?? [];

        final data = DashboardViewData.build(
          identity: identity,
          skills: skills,
          proofs: proofs,
          timeline: timeline,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.inkMuted,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _DashboardHeader(data: data),
                  const SizedBox(height: 28),
                  _PhysicalIdentityCard(data: data),
                  const SizedBox(height: 20),
                  ProofButton(
                    label: '+ Add Proof',
                    onPressed: () => context.push('/proofs/add'),
                  ),
                  const SizedBox(height: 32),
                  _SectionTitle(
                    title: 'FOCUS SKILL',
                    actionLabel: 'View all skills',
                    onAction: () => context.go('/skills'),
                  ),
                  const SizedBox(height: 12),
                  if (data.focusSkill != null)
                    _FocusSkillCard(
                      summary: data.focusSkill!,
                      onTap: () =>
                          context.push('/skills/${data.focusSkill!.skill.id}'),
                    )
                  else
                    _EmptyFocusCard(
                      onAddSkill: () => context.push('/skills/add'),
                    ),
                  const SizedBox(height: 16),
                  _TipCard(message: data.tipText),
                  const SizedBox(height: 32),
                  _SectionTitle(
                    title: 'RECENT ACTIVITY',
                    actionLabel: 'View all',
                    onAction: () => context.go('/timeline'),
                  ),
                  const SizedBox(height: 12),
                  _RecentActivityList(
                    events: data.recentActivity.take(3).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.data});

  final DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final confidence = data.identityConfidence;
    final progress =
        data.identityFilledSegments / DashboardViewData.identityTotalSegments;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DashboardScreen.greeting(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data.identity.displayName.toLowerCase(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your identity is built by proof.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          children: [
            _IdentityAvatarWithProgress(
              progress: progress,
              avatarUrl: data.identity.avatarUrl,
              displayName: data.identity.displayName,
            ),
            const SizedBox(height: 8),
            ConfidenceBadge(label: confidence.label, color: AppColors.accent),
          ],
        ),
      ],
    );
  }
}

class _IdentityAvatarWithProgress extends StatelessWidget {
  const _IdentityAvatarWithProgress({
    required this.progress,
    required this.avatarUrl,
    required this.displayName,
  });

  final double progress;
  final String? avatarUrl;
  final String displayName;

  static const _size = 62.0;
  static const _strokeWidth = 3.5;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = (_size - _strokeWidth * 2 - 8) / 2;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _size,
            height: _size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: _strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.accent.withValues(alpha: 0.14),
              color: AppColors.accent,
            ),
          ),
          IdentityAvatar(
            avatarUrl: avatarUrl,
            displayName: displayName,
            radius: avatarRadius,
          ),
        ],
      ),
    );
  }
}

class _PhysicalIdentityCard extends StatelessWidget {
  const _PhysicalIdentityCard({required this.data});

  final DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final confidence = data.identityConfidence;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PHYSICAL IDENTITY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      confidence.label,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.identityHelperText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkSecondary,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 156,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => ConfidenceExplanationSheet.show(
                        context,
                        confidence: confidence,
                        proofCount: data.proofsCount,
                        selfReportedCount: data.selfReportedCount,
                        coachVerifiedCount: data.coachVerifiedCount,
                        isIdentityLevel: true,
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Confidence',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConfidenceBlockProgress(
                      filled: data.identityFilledSegments,
                      total: DashboardViewData.identityTotalSegments,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      confidence.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.fitness_center_outlined,
                  value: '${data.skillsCount}',
                  label: 'Skills',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.verified_outlined,
                  value: '${data.proofsCount}',
                  label: 'Proofs',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.gps_fixed,
                  value: '${data.coachVerifiedCount}',
                  label: 'Coach Verified',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.calendar_today_outlined,
                  value: '${data.dayStreak}',
                  label: 'Day Streak',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 20,
          width: double.infinity,
          child: Center(
            child: Icon(icon, size: 18, color: AppColors.inkMuted),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 28,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkMuted,
                letterSpacing: 1.2,
              ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.inkSecondary,
                    ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FocusSkillCard extends StatelessWidget {
  const _FocusSkillCard({
    required this.summary,
    required this.onTap,
  });

  final ProofStackSkillSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skill = summary.skill;
    final confidence = summary.confidence;
    final filled = DashboardViewData.focusFilledSegments(
      confidence,
      proofCount: summary.totalProofs,
    );

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_gymnastics_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Current best',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                    ),
                    Text(
                      skill.formattedCurrentBest ?? '—',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Confidence',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                  Text(
                    confidence.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 80,
                    child: ConfidenceBlockProgress(
                      filled: filled,
                      total: DashboardViewData.focusTotalSegments,
                      segmentWidth: 7,
                      height: 5,
                      gap: 2.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${summary.totalProofs} Proofs',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.inkMuted,
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

class _EmptyFocusCard extends StatelessWidget {
  const _EmptyFocusCard({required this.onAddSkill});

  final VoidCallback onAddSkill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No skills yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a skill to start building your physical identity.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onAddSkill,
            child: const Text('Add skill'),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 18,
            color: AppColors.accent.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.4,
                    ),
                children: [
                  TextSpan(
                    text: 'Tip ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Your timeline will appear here as you add proofs and milestones.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSecondary,
                height: 1.4,
              ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            if (i > 0) const Divider(color: AppColors.divider, height: 1),
            _ActivityRow(event: events[i]),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final accent = event.type.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(event.type.icon, size: 18, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (event.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ProofDateUtils.formatActivityDate(event.createdAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ],
      ),
    );
  }
}