import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/constants/app_constants.dart';
import 'package:proof/core/utils/confidence_progress_segments.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/core/constants/measurement_units.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/unit_helpers.dart';
import 'package:proof/core/utils/skill_uniqueness.dart';
import 'package:proof/core/utils/validators.dart';
import 'package:proof/features/skills/data/skill_catalog.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/skill_catalog_entry.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/confidence_block_progress.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';
import 'package:proof/shared/widgets/unit_selector.dart';
import 'package:uuid/uuid.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  String? _disciplineFilter;

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillsProvider);
    final proofsAsync = ref.watch(proofsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: skillsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (skills) {
            final visibleSkills = skills
                .where((s) => s.status != SkillStatus.archived)
                .toList();
            final proofs = proofsAsync.valueOrNull ?? [];
            final summaries = ProofStackMerge.buildSummaries(
              skills: skills,
              proofs: proofs,
            );
            final disciplines = List<String>.from(SkillCatalog.disciplines);
            final filteredSummaries = _disciplineFilter == null
                ? summaries
                : summaries
                    .where(
                      (s) =>
                          s.skill.discipline.toLowerCase() ==
                          _disciplineFilter!.toLowerCase(),
                    )
                    .toList();

            if (visibleSkills.isEmpty) {
              return _SkillsScrollContent(
                children: [
                  _SkillsHeader(onAdd: () => context.push('/skills/add')),
                  const SizedBox(height: 32),
                  _SkillsEmptyState(
                    onAdd: () => context.push('/skills/add'),
                  ),
                  const SizedBox(height: 40),
                  const _SkillsFooter(),
                ],
              );
            }

            return _SkillsScrollContent(
              children: [
                _SkillsHeader(onAdd: () => context.push('/skills/add')),
                const SizedBox(height: 24),
                _SkillsDisciplineFilters(
                  disciplines: disciplines,
                  selected: _disciplineFilter,
                  onSelected: (value) => setState(() => _disciplineFilter = value),
                ),
                const SizedBox(height: 24),
                if (filteredSummaries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No skills in this discipline yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...filteredSummaries.map(
                    (summary) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _SkillsPremiumCard(
                        summary: summary,
                        onTap: () =>
                            context.push('/skills/${summary.skill.id}'),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const _SkillsTipCard(),
                const SizedBox(height: 24),
                _SkillsTrackNewCard(
                  onTap: () => context.push('/skills/add'),
                ),
                const SizedBox(height: 40),
                const _SkillsFooter(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SkillsScrollContent extends StatelessWidget {
  const _SkillsScrollContent({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _SkillsHeader extends StatelessWidget {
  const _SkillsHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skills',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Every capability you track has one Proof Stack.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Material(
          color: AppColors.accent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onAdd,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillsDisciplineFilters extends StatelessWidget {
  const _SkillsDisciplineFilters({
    required this.disciplines,
    required this.selected,
    required this.onSelected,
  });

  final List<String> disciplines;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Stack(
        children: [
          ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 34),
            children: [
              _SkillsFilterChip(
                label: 'All Skills',
                selected: selected == null,
                onTap: () => onSelected(null),
              ),
              ...disciplines.map(
                (discipline) => _SkillsFilterChip(
                  label: discipline,
                  selected: selected == discipline,
                  onTap: () => onSelected(discipline),
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 34,
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.background.withValues(alpha: 0),
                      AppColors.background,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsFilterChip extends StatelessWidget {
  const _SkillsFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.accent : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? Colors.white : AppColors.inkSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillsPremiumCard extends StatelessWidget {
  const _SkillsPremiumCard({
    required this.summary,
    required this.onTap,
  });

  final ProofStackSkillSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skill = summary.skill;
    final confidence = summary.confidence;
    final filled = ConfidenceProgressSegments.filledFor(confidence);
    final trendStyle = _trendStyle(summary.trend);
    final bestParts = _splitBest(skill.formattedCurrentBest);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current best',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.inkMuted,
                                  ),
                        ),
                        if (bestParts == null)
                          Text(
                            '—',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          )
                        else
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.accent,
                                  ),
                              children: [
                                TextSpan(
                                  text: bestParts.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${bestParts.$2}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (skill.formattedTarget != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Target: ${skill.formattedTarget}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RightSummaryRail(
                    confidenceLabel: confidence.label,
                    filled: filled,
                    proofCount: summary.totalProofs,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    trendStyle.icon,
                    size: 16,
                    color: trendStyle.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trendStyle.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: trendStyle.color,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    ProofDateUtils.formatSkillUpdated(summary.lastUpdated),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TrendStyle _trendStyle(ProofStackTrend trend) {
    return switch (trend) {
      ProofStackTrend.improving => const _TrendStyle(
          icon: Icons.trending_up_rounded,
          label: 'Improving',
          color: AppColors.accent,
        ),
      ProofStackTrend.stable => const _TrendStyle(
          icon: Icons.trending_flat_rounded,
          label: 'Stable',
          color: AppColors.inkSecondary,
        ),
      ProofStackTrend.declining => const _TrendStyle(
          icon: Icons.trending_down_rounded,
          label: 'Declining',
          color: AppColors.error,
        ),
      ProofStackTrend.inactive => const _TrendStyle(
          icon: Icons.schedule_outlined,
          label: 'Inactive',
          color: AppColors.inkMuted,
        ),
      ProofStackTrend.notEnoughEvidence => const _TrendStyle(
          icon: Icons.trending_flat_rounded,
          label: 'Not enough evidence',
          color: AppColors.inkMuted,
        ),
    };
  }

  (String, String)? _splitBest(String? formatted) {
    if (formatted == null || formatted.trim().isEmpty) return null;
    final parts = formatted.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    if (parts.length == 1) return (parts.first, '');
    final value = parts.first;
    final unit = parts.sublist(1).join(' ');
    return (value, unit);
  }
}

class _TrendStyle {
  const _TrendStyle({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class _RightSummaryRail extends StatelessWidget {
  const _RightSummaryRail({
    required this.confidenceLabel,
    required this.filled,
    required this.proofCount,
  });

  final String confidenceLabel;
  final int filled;
  final int proofCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              confidenceLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            ConfidenceBlockProgress(
              filled: filled,
              total: ConfidenceProgressSegments.segmentCount,
              segmentWidth: 10,
              height: 7,
              gap: 4,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$proofCount',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              proofCount == 1 ? 'Proof' : 'Proofs',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right,
          size: 20,
          color: AppColors.inkMuted,
        ),
      ],
    );
  }
}

class _SkillsTipCard extends StatelessWidget {
  const _SkillsTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consistency builds trust. Keep adding proofs over time.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsTrackNewCard extends StatelessWidget {
  const _SkillsTrackNewCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.playlist_add_outlined,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Track a new capability',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Add a skill to start building your Proof Stack.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillsEmptyState extends StatelessWidget {
  const _SkillsEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.playlist_add_outlined,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Track a new capability',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a skill to begin building your first Proof Stack.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ProofButton(
            label: '+ Add Skill',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _SkillsFooter extends StatelessWidget {
  const _SkillsFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.divider),
        const SizedBox(height: 32),
        const ProofMotto(),
        const SizedBox(height: 16),
        Text(
          '${AppConstants.appName} · Physical Identity',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class AddSkillScreen extends ConsumerStatefulWidget {
  const AddSkillScreen({super.key});

  @override
  ConsumerState<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends ConsumerState<AddSkillScreen> {
  SkillCatalogEntry? _selectedEntry;
  final _searchController = TextEditingController();
  String? _disciplineFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedEntry != null) {
      return _SkillFormScreen(
        entry: _selectedEntry!,
        onBack: () => setState(() => _selectedEntry = null),
      );
    }

    final results = SkillCatalog.search(
      query: _searchController.text,
      discipline: _disciplineFilter,
    );

    return Scaffold(
      appBar: ProofAppBar(
        title: 'Add skill',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Choose a capability from the catalog, or create a custom skill.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search skills…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _DisciplineChip(
                  label: 'All',
                  selected: _disciplineFilter == null,
                  onTap: () => setState(() => _disciplineFilter = null),
                ),
                ...SkillCatalog.disciplines.map(
                  (d) => _DisciplineChip(
                    label: d,
                    selected: _disciplineFilter == d,
                    onTap: () => setState(() => _disciplineFilter = d),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = results[index];
                return Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedEntry = entry),
                    borderRadius: BorderRadius.circular(12),
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
                              Expanded(
                                child: Text(
                                  entry.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                entry.discipline.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          if (entry.summary.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              entry.summary,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            '${entry.performanceType.label} · ${MeasurementUnits.label(entry.defaultUnit)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DisciplineChip extends StatelessWidget {
  const _DisciplineChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.accent.withValues(alpha: 0.15),
        checkmarkColor: AppColors.accent,
      ),
    );
  }
}

class _SkillFormScreen extends ConsumerStatefulWidget {
  const _SkillFormScreen({
    required this.entry,
    required this.onBack,
  });

  final SkillCatalogEntry entry;
  final VoidCallback onBack;

  @override
  ConsumerState<_SkillFormScreen> createState() => _SkillFormScreenState();
}

class _SkillFormScreenState extends ConsumerState<_SkillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _disciplineController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _resultController;
  late final TextEditingController _targetController;

  late MeasurementType _measurementType;
  late PerformanceType _performanceType;
  late List<String> _allowedUnits;
  late String _selectedUnit;
  late String _targetUnit;
  bool _isLoading = false;

  bool get _isCustom => widget.entry.isCustom;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.entry.isCustom ? '' : widget.entry.name,
    );
    _disciplineController = TextEditingController(
      text: widget.entry.isCustom ? 'Other' : widget.entry.discipline,
    );
    _descriptionController = TextEditingController();
    _resultController = TextEditingController();
    _targetController = TextEditingController();
    _measurementType = widget.entry.measurementType;
    _performanceType = widget.entry.performanceType;
    if (widget.entry.isCustom) {
      _allowedUnits = unitsForMeasurementType(_measurementType);
      _selectedUnit = defaultUnitForMeasurementType(_measurementType);
    } else {
      _allowedUnits = List.from(widget.entry.allowedUnits);
      _selectedUnit = widget.entry.defaultUnit;
    }
    _targetUnit = _selectedUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _disciplineController.dispose();
    _descriptionController.dispose();
    _resultController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _onMeasurementTypeChanged(MeasurementType type) {
    setState(() {
      _measurementType = type;
      _performanceType = defaultPerformanceFor(type);
      _allowedUnits = unitsForMeasurementType(type);
      _selectedUnit = defaultUnitForMeasurementType(type);
      _targetUnit = _selectedUnit;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final resultRaw = _resultController.text.trim();
      final targetRaw = _targetController.text.trim();

      final skill = SkillModel(
        id: const Uuid().v4(),
        userId: user.uid,
        name: _nameController.text.trim(),
        discipline: _disciplineController.text.trim(),
        description: _descriptionController.text.trim(),
        defaultUnit: _selectedUnit,
        allowedUnits: _allowedUnits,
        measurementType: _measurementType,
        performanceType: _performanceType,
        catalogId: _isCustom ? null : widget.entry.id,
        targetValue: targetRaw.isEmpty ? null : targetRaw,
        targetUnit: targetRaw.isEmpty ? null : _targetUnit,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).addSkill(skill);
      if (!mounted) return;

      context.pushReplacement(
        Uri(
          path: '/proofs/add',
          queryParameters: {
            'skillId': skill.id,
            'result': resultRaw,
            'unit': _selectedUnit,
            'first': 'true',
          },
        ).toString(),
      );
    } on DuplicateSkillException catch (e) {
      if (mounted) {
        await _showDuplicateSkillDialog(context, e.existing);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProofAppBar(
        title: _isCustom ? 'Custom skill' : widget.entry.name,
        leading: BackButton(onPressed: widget.onBack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isCustom && widget.entry.summary.isNotEmpty) ...[
                Text(
                  widget.entry.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
                const SizedBox(height: 24),
              ],
              if (!_isCustom) ...[
                _ReadOnlyField(label: 'Skill name', value: _nameController.text),
                const SizedBox(height: 16),
                _ReadOnlyField(label: 'Discipline', value: _disciplineController.text),
              ] else ...[
                ProofTextField(
                  controller: _nameController,
                  label: 'Skill name',
                  validator: (v) => Validators.required(v, field: 'Skill name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _disciplineController.text,
                  decoration: const InputDecoration(labelText: 'Discipline'),
                  items: SkillCatalog.disciplines
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _disciplineController.text = v;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MeasurementType>(
                  initialValue: _measurementType,
                  decoration: const InputDecoration(labelText: 'Measurement type'),
                  items: MeasurementType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _onMeasurementTypeChanged(v);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PerformanceType>(
                  initialValue: _performanceType,
                  decoration: const InputDecoration(labelText: 'Performance type'),
                  items: PerformanceType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _performanceType = v);
                  },
                ),
              ],
              const SizedBox(height: 16),
              ProofTextField(
                controller: _descriptionController,
                label: 'Personal notes',
                hint: 'Optional — e.g. Strict form only. Training for HYROX.',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text('Target (optional)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ResultInputField(
                controller: _targetController,
                measurementType: _measurementType,
                unit: _targetUnit,
                label: 'Target',
              ),
              const SizedBox(height: 16),
              UnitSelector(
                label: 'Target unit',
                allowedUnits: _allowedUnits,
                selectedUnit: _targetUnit,
                onChanged: (u) => setState(() => _targetUnit = u),
              ),
              const SizedBox(height: 24),
              Text('First result', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                'Your first recorded performance — not your all-time best.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: 8),
              ResultInputField(
                controller: _resultController,
                measurementType: _measurementType,
                unit: _selectedUnit,
                label: 'First result',
                validator: (v) => Validators.required(v, field: 'First result'),
              ),
              const SizedBox(height: 16),
              UnitSelector(
                allowedUnits: _allowedUnits,
                selectedUnit: _selectedUnit,
                onChanged: (u) => setState(() => _selectedUnit = u),
              ),
              const SizedBox(height: 32),
              ProofButton(
                label: 'Add skill',
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showDuplicateSkillDialog(
  BuildContext context,
  SkillModel existing,
) async {
  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('You already track this skill'),
      content: const Text(
        'Every capability has one Proof Stack.\n'
        'Record a new Proof to continue building your history.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'stack'),
          child: const Text('View Proof Stack'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'proof'),
          child: const Text('Add Proof'),
        ),
      ],
    ),
  );

  if (!context.mounted || action == null || action == 'cancel') return;

  switch (action) {
    case 'proof':
      context.push('/proofs/add?skillId=${existing.id}');
    case 'stack':
      context.push('/proof-stack/${existing.id}');
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceElevated,
      ),
      child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class SkillDetailScreen extends ConsumerWidget {
  const SkillDetailScreen({super.key, required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);

    return skillsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: ProofAppBar(
          title: 'Skill',
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (skills) {
        final skill = skills.where((s) => s.id == skillId).firstOrNull;
        if (skill == null) {
          return Scaffold(
            appBar: ProofAppBar(
              title: 'Skill',
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: const EmptyState(
              title: 'Skill not found',
              message: 'This skill may have been deleted.',
            ),
          );
        }
        return _SkillDetailBody(skill: skill);
      },
    );
  }
}

class _SkillDetailBody extends ConsumerStatefulWidget {
  const _SkillDetailBody({required this.skill});

  final SkillModel skill;

  @override
  ConsumerState<_SkillDetailBody> createState() => _SkillDetailBodyState();
}

class _SkillDetailBodyState extends ConsumerState<_SkillDetailBody> {
  bool _isLoading = false;

  SkillModel get skill => widget.skill;

  Future<void> _setStatus(SkillStatus status) async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      await ref.read(firestoreServiceProvider).updateSkillStatus(
            userId: user.uid,
            skillId: skill.id,
            status: status,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Skill marked as ${status.label.toLowerCase()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete skill?'),
        content: Text(
          'Remove "${skill.name}" from your identity? Proofs linked to this skill will remain but the skill will be gone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      await ref.read(firestoreServiceProvider).deleteSkill(
            userId: user.uid,
            skillId: skill.id,
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProofAppBar(
        title: skill.name,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    skill.discipline.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    skill.status.label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                ),
              ],
            ),
            if (skill.formattedCurrentBest != null) ...[
              const SizedBox(height: 24),
              Text('Current best', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                skill.formattedCurrentBest!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.accent,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Calculated from your proof stack',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
            ],
            if (skill.formattedTarget != null) ...[
              const SizedBox(height: 16),
              Text('Target', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(skill.formattedTarget!, style: Theme.of(context).textTheme.titleMedium),
            ],
            if (skill.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Personal notes', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(skill.description, style: Theme.of(context).textTheme.bodyLarge),
            ],
            const SizedBox(height: 32),
            ProofButton(
              label: 'View Proof Stack',
              onPressed: () => context.push('/proof-stack/${skill.id}'),
            ),
            const SizedBox(height: 12),
            ProofButton(
              label: 'Add proof',
              isOutlined: true,
              onPressed: () => context.push('/proofs/add?skillId=${skill.id}'),
            ),
            const SizedBox(height: 16),
            Text('Manage skill', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            if (skill.status != SkillStatus.active)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ProofButton(
                  label: 'Mark as active',
                  isLoading: _isLoading,
                  onPressed: () => _setStatus(SkillStatus.active),
                ),
              ),
            if (skill.status != SkillStatus.paused)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ProofButton(
                  label: 'Pause skill',
                  isOutlined: true,
                  isLoading: _isLoading,
                  onPressed: () => _setStatus(SkillStatus.paused),
                ),
              ),
            if (skill.status != SkillStatus.archived)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ProofButton(
                  label: 'Archive skill',
                  isOutlined: true,
                  isLoading: _isLoading,
                  onPressed: () => _setStatus(SkillStatus.archived),
                ),
              ),
            ProofButton(
              label: 'Delete skill',
              isOutlined: true,
              isLoading: _isLoading,
              onPressed: _delete,
            ),
          ],
        ),
      ),
    );
  }
}
