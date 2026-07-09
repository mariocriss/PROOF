import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/passport/domain/passport_view_data.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class PassportScreen extends ConsumerWidget {
  const PassportScreen({
    super.key,
    required this.handle,
    this.showBackButton = true,
  });

  final String handle;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityByHandleProvider(handle));

    return identityAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _PassportScaffold(
        showBackButton: showBackButton,
        child: Center(child: Text('Error: $e')),
      ),
      data: (identity) {
        if (identity == null) {
          return _PassportScaffold(
            showBackButton: showBackButton,
            child: const EmptyState(
              title: 'Identity not found',
              message: 'No public passport exists for this handle.',
            ),
          );
        }

        if (!identity.isPublic) {
          return _PassportScaffold(
            showBackButton: showBackButton,
            child: const EmptyState(
              title: 'Private identity',
              message: 'This physical identity is not publicly visible.',
            ),
          );
        }

        return _PassportContent(
          identity: identity,
          showBackButton: showBackButton,
        );
      },
    );
  }
}

class _PassportScaffold extends StatelessWidget {
  const _PassportScaffold({
    required this.child,
    this.showBackButton = true,
  });

  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Passport',
        leading: showBackButton
            ? BackButton(onPressed: () => context.pop())
            : null,
      ),
      body: child,
    );
  }
}

class _PassportContent extends ConsumerStatefulWidget {
  const _PassportContent({
    required this.identity,
    this.showBackButton = true,
  });

  final PhysicalIdentity identity;
  final bool showBackButton;

  @override
  ConsumerState<_PassportContent> createState() => _PassportContentState();
}

class _PassportContentState extends ConsumerState<_PassportContent> {
  String? _expandedSection;

  void _toggle(String section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(publicSkillsProvider(widget.identity.userId));
    final proofsAsync = ref.watch(publicProofsProvider(widget.identity.userId));
    final timelineAsync =
        ref.watch(publicTimelineProvider(widget.identity.userId));

    final isLoading = skillsAsync.isLoading ||
        proofsAsync.isLoading ||
        timelineAsync.isLoading;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = PassportViewData.build(
      identity: widget.identity,
      skills: skillsAsync.valueOrNull ?? [],
      proofs: proofsAsync.valueOrNull ?? [],
      timeline: timelineAsync.valueOrNull ?? [],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Passport',
        leading: widget.showBackButton
            ? BackButton(onPressed: () => context.pop())
            : null,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PassportCard(identity: widget.identity, confidence: data.overallConfidence),
            const SizedBox(height: 28),
            _PassportMenuTile(
              id: 'confidence',
              icon: Icons.verified_outlined,
              title: 'Identity Confidence',
              subtitle: data.overallConfidence.label,
              expanded: _expandedSection == 'confidence',
              onTap: () => _toggle('confidence'),
              child: _OverallConfidenceSection(confidence: data.overallConfidence),
            ),
            _PassportMenuTile(
              id: 'summary',
              icon: Icons.grid_view_outlined,
              title: 'Identity Summary',
              subtitle:
                  '${data.statistics.totalSkills} skills · ${data.statistics.totalProofs} proofs',
              expanded: _expandedSection == 'summary',
              onTap: () => _toggle('summary'),
              child: _IdentitySummarySection(data: data),
            ),
            if (data.topSkills.isNotEmpty)
              _PassportMenuTile(
                id: 'skills',
                icon: Icons.psychology_outlined,
                title: 'Top Skills',
                subtitle: '${data.topSkills.length} capabilities',
                expanded: _expandedSection == 'skills',
                onTap: () => _toggle('skills'),
                child: _TopSkillsSection(skills: data.topSkills),
              ),
            if (data.recentMilestones.isNotEmpty)
              _PassportMenuTile(
                id: 'milestones',
                icon: Icons.emoji_events_outlined,
                title: 'Recent Milestones',
                subtitle: '${data.recentMilestones.length} results',
                expanded: _expandedSection == 'milestones',
                onTap: () => _toggle('milestones'),
                child: _MilestonesSection(milestones: data.recentMilestones),
              ),
            if (data.recentTimeline.isNotEmpty)
              _PassportMenuTile(
                id: 'timeline',
                icon: Icons.timeline_outlined,
                title: 'Recent Activity',
                subtitle: '${data.recentTimeline.length} events',
                expanded: _expandedSection == 'timeline',
                onTap: () => _toggle('timeline'),
                child: _TimelineSection(events: data.recentTimeline),
              ),
            _PassportMenuTile(
              id: 'stats',
              icon: Icons.bar_chart_outlined,
              title: 'Proof Statistics',
              subtitle: '${data.statistics.totalProofs} proofs documented',
              expanded: _expandedSection == 'stats',
              onTap: () => _toggle('stats'),
              child: _StatisticsSection(stats: data.statistics),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({
    required this.identity,
    required this.confidence,
  });

  final PhysicalIdentity identity;
  final StackConfidence confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'PHYSICAL IDENTITY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'A lifelong record of verified physical capability.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          IdentityAvatar(
            avatarUrl: identity.avatarUrl,
            displayName: identity.displayName,
            radius: 56,
          ),
          const SizedBox(height: 20),
          Text(
            identity.displayName,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '@${identity.handle}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                ),
          ),
          const SizedBox(height: 20),
          ConfidenceBadge(
            label: confidence.label,
            color: confidence.color,
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            'Member since ${ProofDateUtils.formatDate(identity.createdAt)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _PassportMenuTile extends StatelessWidget {
  const _PassportMenuTile({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.accent, size: 22),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
                if (expanded) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverallConfidenceSection extends StatelessWidget {
  const _OverallConfidenceSection({required this.confidence});

  final StackConfidence confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: confidence.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: confidence.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'OVERALL IDENTITY CONFIDENCE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.inkMuted,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            confidence.label,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  color: confidence.color,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Derived from documented proof across all capabilities.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IdentitySummarySection extends StatelessWidget {
  const _IdentitySummarySection({required this.data});

  final PassportViewData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '${data.statistics.totalSkills}',
                label: 'Skills',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                value: '${data.statistics.totalProofs}',
                label: 'Proofs',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '${data.statistics.disciplines}',
                label: 'Disciplines',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                value: ProofDateUtils.formatDate(data.statistics.memberSince),
                label: 'Member since',
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.value,
    required this.label,
    this.compact = false,
  });

  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: (compact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.headlineMedium)
                ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TopSkillsSection extends StatelessWidget {
  const _TopSkillsSection({required this.skills});

  final List<PassportSkillEntry> skills;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: skills.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.skill.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.skill.discipline,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (entry.skill.formattedCurrentBest != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.skill.formattedCurrentBest!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConfidenceBadge(
                      label: entry.confidence.label,
                      color: entry.confidence.color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${entry.proofCount} proofs',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection({required this.milestones});

  final List<PassportMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: milestones.map((m) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PassportListRow(
            title: m.title,
            subtitle: m.subtitle,
            trailing: ProofDateUtils.formatDate(m.date),
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PassportListRow(
            title: event.title,
            subtitle: event.subtitle,
            trailing: ProofDateUtils.formatRelative(event.createdAt),
          ),
        );
      }).toList(),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({required this.stats});

  final PassportStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _StatRow(label: 'Total proofs documented', value: '${stats.totalProofs}'),
          const _StatDivider(),
          _StatRow(label: 'Skills with evidence', value: '${stats.skillsWithProofs}'),
          const _StatDivider(),
          _StatRow(label: 'Coach-verified proofs', value: '${stats.coachVerified}'),
          const _StatDivider(),
          _StatRow(label: 'Disciplines represented', value: '${stats.disciplines}'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.divider);
  }
}

class _PassportListRow extends StatelessWidget {
  const _PassportListRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(trailing, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
