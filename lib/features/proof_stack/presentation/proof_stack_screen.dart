import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/features/proof_stack/presentation/widgets/confidence_explanation_sheet.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class ProofStackScreen extends ConsumerWidget {
  const ProofStackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);
    final proofsAsync = ref.watch(proofsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Proof Stack',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (skills) {
          final activeSkills =
              skills.where((s) => s.status == SkillStatus.active).toList();

          if (activeSkills.isEmpty) {
            return EmptyState(
              title: 'Build your evidence',
              message:
                  'Every skill you track becomes one proof stack — a living record of why your physical claims deserve trust.',
              action: ProofButton(
                label: 'Add skill',
                onPressed: () => context.push('/skills/add'),
              ),
            );
          }

          final proofs = proofsAsync.valueOrNull ?? [];

          final summaries = ProofStackMerge.buildSummaries(
            skills: skills,
            proofs: proofs,
          );

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            itemCount: summaries.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 20 : 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _ProofStackTagline();
              }

              final summary = summaries[index - 1];
              return _ProofStackSkillCard(
                summary: summary,
                onTap: () => context.push('/proof-stack/${summary.skill.id}'),
                onConfidenceTap: () => _showConfidence(context, summary),
              );
            },
          );
        },
      ),
    );
  }

  void _showConfidence(BuildContext context, ProofStackSkillSummary summary) {
    ConfidenceExplanationSheet.show(
      context,
      confidence: summary.confidence,
      proofCount: summary.totalProofs,
      selfReportedCount: summary.selfReportedCount,
      coachVerifiedCount: summary.coachVerifiedCount,
    );
  }
}

class _ProofStackTagline extends StatelessWidget {
  const _ProofStackTagline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your evidence.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                letterSpacing: -0.2,
                color: AppColors.inkSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'Built over time.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.accent,
                letterSpacing: -0.2,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProofStackSkillCard extends StatelessWidget {
  const _ProofStackSkillCard({
    required this.summary,
    required this.onTap,
    required this.onConfidenceTap,
  });

  final ProofStackSkillSummary summary;
  final VoidCallback onTap;
  final VoidCallback onConfidenceTap;

  @override
  Widget build(BuildContext context) {
    final skill = summary.skill;
    final trendColor = switch (summary.trend) {
      ProofStackTrend.improving => AppColors.confidenceEstablished,
      ProofStackTrend.stable => AppColors.inkSecondary,
      ProofStackTrend.declining => AppColors.error,
      ProofStackTrend.inactive => AppColors.inkMuted,
      ProofStackTrend.notEnoughEvidence => AppColors.inkMuted,
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                skill.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (skill.formattedCurrentBest != null) ...[
                const SizedBox(height: 20),
                _MetaRow(
                  label: 'Current Best',
                  value: skill.formattedCurrentBest!,
                  valueColor: AppColors.accent,
                  emphasize: true,
                ),
              ],
              const SizedBox(height: 14),
              _MetaRow(
                label: 'Confidence',
                value: summary.confidence.label,
                trailing: GestureDetector(
                  onTap: onConfidenceTap,
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _MetaRow(
                label: 'Proof Stack',
                value: summary.proofStackLabel,
              ),
              const SizedBox(height: 10),
              _VerifiedBySection(
                selfReportedCount: summary.selfReportedCount,
                coachVerifiedCount: summary.coachVerifiedCount,
              ),
              const SizedBox(height: 10),
              _MetaRow(
                label: 'Trend',
                value: summary.trend.label,
                valueColor: trendColor,
              ),
              const SizedBox(height: 10),
              _MetaRow(
                label: 'Last Updated',
                value: summary.lastUpdated != null
                    ? ProofDateUtils.formatDate(summary.lastUpdated!)
                    : 'No proofs yet',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBySection extends StatelessWidget {
  const _VerifiedBySection({
    required this.selfReportedCount,
    required this.coachVerifiedCount,
  });

  final int selfReportedCount;
  final int coachVerifiedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            'Verified By',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _VerificationRow(
                icon: Icons.person_outline,
                label: 'Self Reported',
                count: selfReportedCount,
              ),
              const SizedBox(height: 8),
              _VerificationRow(
                icon: Icons.school_outlined,
                label: 'Coach Verified',
                count: coachVerifiedCount,
                highlight: coachVerifiedCount > 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({
    required this.icon,
    required this.label,
    required this.count,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? AppColors.confidenceStrong : AppColors.inkSecondary;

    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                ),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: count > 0 ? AppColors.ink : AppColors.inkMuted,
              ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: (emphasize
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
              color: valueColor ?? AppColors.ink,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
