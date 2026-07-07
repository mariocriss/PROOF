import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/constants/measurement_units.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/core/utils/unit_helpers.dart';
import 'package:proof/core/utils/validators.dart';
import 'package:proof/features/skills/data/skill_catalog.dart';
import 'package:proof/shared/models/measurement_type.dart';
import 'package:proof/shared/models/performance_type.dart';
import 'package:proof/shared/models/skill_catalog_entry.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';
import 'package:proof/shared/widgets/unit_selector.dart';
import 'package:uuid/uuid.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: ProofAppBar(
        title: 'Skills',
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/skills/add'),
          ),
        ],
      ),
      body: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (skills) {
          if (skills.isEmpty) {
            return EmptyState(
              title: 'No skills yet',
              message: 'Skills represent physical capabilities you can prove.',
              action: ProofButton(
                label: 'Add skill',
                onPressed: () => context.push('/skills/add'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: skills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _SkillCard(
              skill: skills[index],
              onTap: () => context.push('/skills/${skills[index].id}'),
            ),
          );
        },
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill, required this.onTap});

  final SkillModel skill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
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
                      skill.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (skill.status != SkillStatus.active)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        skill.status.label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      skill.discipline.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.inkMuted, size: 20),
                ],
              ),
              if (skill.formattedCurrentBest != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Personal best: ${skill.formattedCurrentBest}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              if (skill.formattedTarget != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Target: ${skill.formattedTarget}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (skill.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(skill.description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
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
  late final TextEditingController _currentBestController;
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
    _currentBestController = TextEditingController();
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
    _currentBestController.dispose();
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
      final bestRaw = _currentBestController.text.trim();
      final targetRaw = _targetController.text.trim();
      NormalizedResult? normalized;

      if (bestRaw.isNotEmpty) {
        normalized = ResultNormalizer.normalize(
          rawValue: bestRaw,
          unit: _selectedUnit,
          measurementType: _measurementType,
        );
      }

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
        currentBest: bestRaw.isEmpty ? null : bestRaw,
        currentBestUnit: bestRaw.isEmpty ? null : _selectedUnit,
        normalizedBestValue: normalized?.normalizedValue,
        targetValue: targetRaw.isEmpty ? null : targetRaw,
        targetUnit: targetRaw.isEmpty ? null : _targetUnit,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).addSkill(skill);
      if (mounted) context.pop();
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
                label: 'Description',
                hint: 'e.g. Strict form only. Training for HYROX.',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text('Current best', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ResultInputField(
                controller: _currentBestController,
                measurementType: _measurementType,
                unit: _selectedUnit,
                label: 'Current best',
              ),
              const SizedBox(height: 16),
              UnitSelector(
                allowedUnits: _allowedUnits,
                selectedUnit: _selectedUnit,
                onChanged: (u) => setState(() {
                  _selectedUnit = u;
                  _targetUnit = u;
                }),
              ),
              const SizedBox(height: 24),
              Text('Target (optional)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ResultInputField(
                controller: _targetController,
                measurementType: _measurementType,
                unit: _targetUnit,
                label: 'Target value',
              ),
              const SizedBox(height: 16),
              UnitSelector(
                label: 'Target unit',
                allowedUnits: _allowedUnits,
                selectedUnit: _targetUnit,
                onChanged: (u) => setState(() => _targetUnit = u),
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
              Text('Personal best', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                skill.formattedCurrentBest!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.accent,
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
              Text('Description', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(skill.description, style: Theme.of(context).textTheme.bodyLarge),
            ],
            const SizedBox(height: 32),
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
            const SizedBox(height: 16),
            ProofButton(
              label: 'Add proof',
              onPressed: () => context.push('/proofs/add'),
            ),
          ],
        ),
      ),
    );
  }
}
