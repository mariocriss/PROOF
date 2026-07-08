import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/features/proof_stack/domain/performance_chart_data.dart';
import 'package:proof/features/proof_stack/presentation/widgets/confidence_explanation_sheet.dart';
import 'package:proof/features/proof_stack/presentation/widgets/performance_trend_chart.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';
import 'package:proof/shared/widgets/unit_selector.dart';

class SkillProofStackScreen extends ConsumerWidget {
  const SkillProofStackScreen({super.key, required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);
    final proofsAsync = ref.watch(proofsProvider);

    return skillsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: ProofAppBar(
          title: 'Proof Stack',
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (skills) {
        final skill = skills.where((s) => s.id == skillId).firstOrNull;
        if (skill == null) {
          return Scaffold(
            appBar: ProofAppBar(
              title: 'Proof Stack',
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: const EmptyState(
              title: 'Skill not found',
              message: 'This capability may have been removed.',
            ),
          );
        }

        final allProofs = proofsAsync.valueOrNull ?? [];
        final primary = ProofStackMerge.resolvePrimary(
          skill: skill,
          allSkills: skills,
          allProofs: allProofs,
        );
        final proofs = ProofStackMerge.proofsForSkillGroup(
          skill: skill,
          allSkills: skills,
          allProofs: allProofs,
        );
        final detail = SkillProofStackDetail.build(skill: primary, proofs: proofs);
        final performanceChart = PerformanceChartView.build(
          skill: primary,
          proofs: proofs,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ProofAppBar(
            title: primary.name,
            leading: BackButton(onPressed: () => context.pop()),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/proofs/add?skillId=${primary.id}'),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Proof'),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrustHeader(
                  detail: detail,
                  onConfidenceTap: () => ConfidenceExplanationSheet.show(
                    context,
                    confidence: detail.summary.confidence,
                    proofCount: detail.summary.totalProofs,
                    selfReportedCount: detail.summary.selfReportedCount,
                    coachVerifiedCount: detail.summary.coachVerifiedCount,
                  ),
                ),
                const SizedBox(height: 40),
                const _SectionLabel('Proof Stack'),
                const SizedBox(height: 16),
                ...detail.verificationGroups.map(
                  (group) => _VerificationGroupSection(
                    group: group,
                    onDeleteProof: (proofId) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete proof?'),
                          content: const Text(
                            'Remove this proof from your proof stack? Current best and confidence will be recalculated.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      final user = ref.read(authServiceProvider).currentUser!;
                      await ref.read(firestoreServiceProvider).deleteProof(
                            userId: user.uid,
                            proofId: proofId,
                          );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                const _SectionLabel('Performance Trend'),
                const SizedBox(height: 16),
                PerformanceTrendSection(chart: performanceChart),
                const SizedBox(height: 40),
                _ProgressSectionHeader(
                  onEditTarget: () => _ProgressSection.showEditTarget(
                    context,
                    ref,
                    primary,
                  ),
                ),
                const SizedBox(height: 16),
                _ProgressSection(detail: detail),
                if (detail.milestones.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  const _SectionLabel('Milestones'),
                  const SizedBox(height: 16),
                  _MilestonesSection(milestones: detail.milestones),
                ],
                if (primary.description.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  const _SectionLabel('Personal Notes'),
                  const SizedBox(height: 12),
                  Text(
                    primary.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.inkSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrustHeader extends StatelessWidget {
  const _TrustHeader({
    required this.detail,
    required this.onConfidenceTap,
  });

  final SkillProofStackDetail detail;
  final VoidCallback onConfidenceTap;

  @override
  Widget build(BuildContext context) {
    final skill = detail.summary.skill;
    final trust = detail.trustProfile;
    final confidence = detail.summary.confidence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          skill.name,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.ink,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (skill.formattedCurrentBest != null) ...[
          const SizedBox(height: 28),
          Text(
            'CURRENT BEST',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.inkMuted,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            skill.formattedCurrentBest!,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
          ),
        ],
        const SizedBox(height: 28),
        Text(
          'CONFIDENCE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: AppColors.inkMuted,
              ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onConfidenceTap,
          child: Row(
            children: [
              ConfidenceBadge(
                label: confidence.label,
                color: confidence.color,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.info_outline, size: 18, color: AppColors.inkMuted),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TrustProgressBar(
          filledSegments: trust.filledSegments,
          totalSegments: trust.totalSegments,
          color: confidence.color,
          statusMessage: trust.statusMessage,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            color: AppColors.inkSecondary,
          ),
    );
  }
}

class _VerificationGroupSection extends StatefulWidget {
  const _VerificationGroupSection({
    required this.group,
    required this.onDeleteProof,
  });

  final VerificationGroup group;
  final Future<void> Function(String proofId) onDeleteProof;

  @override
  State<_VerificationGroupSection> createState() =>
      _VerificationGroupSectionState();
}

class _VerificationGroupSectionState extends State<_VerificationGroupSection> {
  static const _collapsedLimit = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final proofs = group.proofs;
    final hiddenCount = proofs.length - _collapsedLimit;
    final visibleProofs = !_expanded && proofs.length > _collapsedLimit
        ? proofs.sublist(proofs.length - _collapsedLimit)
        : proofs;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            group.source.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          if (group.isEmpty)
            Text(
              'No proofs yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            )
          else ...[
            if (!_expanded && hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Showing latest $_collapsedLimit of ${proofs.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              ),
            ...visibleProofs.map(
              (proof) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ProofDateUtils.formatDate(proof.recordedAt),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            proof.formattedResult,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (proof.location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              proof.location,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.inkSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.inkMuted,
                      ),
                      onPressed: () => widget.onDeleteProof(proof.id),
                      tooltip: 'Delete proof',
                    ),
                  ],
                ),
              ),
            ),
            if (proofs.length > _collapsedLimit)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded
                      ? 'Show latest $_collapsedLimit'
                      : 'Show all ${proofs.length} proofs',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgressSectionHeader extends StatelessWidget {
  const _ProgressSectionHeader({required this.onEditTarget});

  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _SectionLabel('Progress')),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppColors.inkMuted,
          onPressed: onEditTarget,
          tooltip: 'Edit personal target',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
}

class _ProgressSection extends ConsumerWidget {
  const _ProgressSection({required this.detail});

  final SkillProofStackDetail detail;

  static Future<void> showEditTarget(
    BuildContext context,
    WidgetRef ref,
    SkillModel skill,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditTargetSheet(skill: skill),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skill = detail.summary.skill;
    final remaining = SkillProofStackDetail.remainingProgressFor(skill);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ProgressRow(
            label: 'Current best',
            value: skill.formattedCurrentBest ?? '—',
          ),
          const Divider(height: 28, color: AppColors.divider),
          _ProgressRow(
            label: 'Personal target',
            value: skill.formattedTarget ?? 'Not set',
          ),
          if (remaining != null) ...[
            const Divider(height: 28, color: AppColors.divider),
            _ProgressRow(
              label: 'Remaining',
              value: remaining,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _EditTargetSheet extends ConsumerStatefulWidget {
  const _EditTargetSheet({required this.skill});

  final SkillModel skill;

  @override
  ConsumerState<_EditTargetSheet> createState() => _EditTargetSheetState();
}

class _EditTargetSheetState extends ConsumerState<_EditTargetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _targetController;
  late String _targetUnit;
  bool _isLoading = false;

  SkillModel get skill => widget.skill;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(text: skill.targetValue ?? '');
    _targetUnit = skill.targetUnit ?? skill.defaultUnit;
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      await ref.read(firestoreServiceProvider).updateSkillTarget(
            userId: user.uid,
            skillId: skill.id,
            targetValue: _targetController.text.trim(),
            targetUnit: _targetUnit,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      await ref.read(firestoreServiceProvider).updateSkillTarget(
            userId: user.uid,
            skillId: skill.id,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Personal target',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set a goal for ${skill.name}. Progress is measured against your calculated current best.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              ResultInputField(
                controller: _targetController,
                measurementType: skill.measurementType,
                unit: _targetUnit,
                label: 'Target',
              ),
              const SizedBox(height: 16),
              UnitSelector(
                label: 'Target unit',
                allowedUnits: skill.allowedUnits,
                selectedUnit: _targetUnit,
                onChanged: (u) => setState(() => _targetUnit = u),
              ),
              const SizedBox(height: 28),
              ProofButton(
                label: 'Save target',
                isLoading: _isLoading,
                onPressed: _save,
              ),
              if (skill.formattedTarget != null) ...[
                const SizedBox(height: 12),
                ProofButton(
                  label: 'Clear target',
                  isOutlined: true,
                  isLoading: _isLoading,
                  onPressed: _clear,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: highlight ? AppColors.accent : null,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection({required this.milestones});

  final List<SkillStackMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: milestones.map((milestone) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestone.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  ProofDateUtils.formatDate(milestone.date),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
