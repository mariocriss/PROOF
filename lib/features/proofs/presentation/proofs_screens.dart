import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proof/core/constants/measurement_units.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/core/utils/result_formatter.dart';
import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/core/utils/validators.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/verification_status.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';
import 'package:proof/shared/widgets/readonly_fields.dart';
import 'package:proof/shared/widgets/unit_selector.dart';
import 'package:uuid/uuid.dart';

class ProofsScreen extends ConsumerWidget {
  const ProofsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofsAsync = ref.watch(proofsProvider);
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: ProofAppBar(
        title: 'Proofs',
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/proofs/add'),
          ),
        ],
      ),
      body: proofsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (proofs) {
          if (proofs.isEmpty) {
            return EmptyState(
              title: 'No proofs yet',
              message:
                  'Every skill starts with a single proof.\n'
                  'Document your first result to begin building your physical identity.',
              action: ProofButton(
                label: 'Add First Proof',
                onPressed: () => context.push('/proofs/add'),
              ),
            );
          }

          final skills = skillsAsync.valueOrNull ?? [];
          final skillMap = {for (final s in skills) s.id: s};

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: proofs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final proof = proofs[index];
              final skill = skillMap[proof.skillId];
              return _ProofCard(
                proof: proof,
                skillName: skill?.name ?? 'Unknown skill',
              );
            },
          );
        },
      ),
    );
  }
}

class _ProofCard extends ConsumerWidget {
  const _ProofCard({required this.proof, required this.skillName});

  final ProofModel proof;
  final String skillName;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete proof?'),
        content: Text(
          'Remove this proof from your proof stack? Current best and confidence will be recalculated.',
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

    if (confirmed != true || !context.mounted) return;

    final user = ref.read(authServiceProvider).currentUser!;
    await ref.read(firestoreServiceProvider).deleteProof(
          userId: user.uid,
          proofId: proof.id,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proof.formattedResult,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.accent,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(skillName, style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
              ConfidenceBadge(
                label: proof.verificationLabel,
                color: AppColors.accent,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.inkMuted),
                onPressed: () => _delete(context, ref),
                tooltip: 'Delete proof',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ProofDateUtils.formatDateTime(proof.recordedAt),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (proof.location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Location: ${proof.location}', style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (proof.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(proof.notes, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class AddProofScreen extends ConsumerStatefulWidget {
  const AddProofScreen({
    super.key,
    this.skillId,
    this.initialResult,
    this.initialUnit,
    this.isFirstProof = false,
  });

  final String? skillId;
  final String? initialResult;
  final String? initialUnit;
  final bool isFirstProof;

  @override
  ConsumerState<AddProofScreen> createState() => _AddProofScreenState();
}

class _AddProofScreenState extends ConsumerState<AddProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late final TextEditingController _resultController;
  SkillModel? _selectedSkill;
  late String _selectedUnit;
  DateTime? _recordedAt;
  ProofSource _proofSource = ProofSource.selfReported;
  String? _selectedCoachId;
  File? _mediaFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resultController = TextEditingController(text: widget.initialResult ?? '');
    _selectedUnit = widget.initialUnit ?? '';
    if (widget.isFirstProof) {
      _recordedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _onSkillChanged(SkillModel? skill) {
    setState(() {
      _selectedSkill = skill;
      if (skill != null) {
        if (widget.isFirstProof &&
            widget.initialUnit != null &&
            widget.initialUnit!.isNotEmpty) {
          _selectedUnit = widget.initialUnit!;
        } else {
          _selectedUnit = skill.defaultUnit;
          if (!widget.isFirstProof) {
            _resultController.clear();
          }
        }
        _recordedAt ??= DateTime.now();
      }
    });
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _mediaFile = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final skill = _selectedSkill;
    if (skill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill')),
      );
      return;
    }

    final resultRaw = _resultController.text.trim();
    if (resultRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a result')),
      );
      return;
    }

    if (_proofSource == ProofSource.coach && _selectedCoachId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a coach')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final unit = _selectedUnit.isNotEmpty ? _selectedUnit : skill.defaultUnit;
      final recordedAt = _recordedAt ?? DateTime.now();
      final normalized = ResultNormalizer.normalize(
        rawValue: resultRaw,
        unit: unit,
        measurementType: skill.measurementType,
      );
      final proofId = const Uuid().v4();
      String? mediaUrl;

      if (_mediaFile != null) {
        try {
          mediaUrl = await ref.read(storageServiceProvider).uploadProofMedia(
                userId: user.uid,
                proofId: proofId,
                file: _mediaFile!,
              );
        } catch (_) {}
      }

      final title = ResultFormatter.display(resultRaw, unit);

      final verificationStatus = _proofSource == ProofSource.coach
          ? VerificationStatus.pendingVerification
          : VerificationStatus.selfReported;
      final storedSource = _proofSource == ProofSource.coach
          ? ProofSource.selfReported
          : _proofSource;

      final proof = ProofModel(
        id: proofId,
        userId: user.uid,
        skillId: skill.id,
        title: title,
        result: resultRaw,
        unit: unit,
        notes: _notesController.text.trim(),
        mediaUrl: mediaUrl,
        proofSource: storedSource,
        verificationStatus: verificationStatus,
        coachId: _selectedCoachId,
        recordedAt: recordedAt,
        createdAt: DateTime.now(),
        originalResult: resultRaw,
        originalUnit: unit,
        normalizedValue: normalized.normalizedValue,
      );

      await ref.read(firestoreServiceProvider).addProofWithVerification(
            proof: proof,
            coachId: _selectedCoachId,
            verificationMessage: _notesController.text.trim(),
          );
      if (!mounted) return;

      if (widget.isFirstProof) {
        context.go('/skills/${skill.id}');
      } else {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillsProvider);
    final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final connectedCoaches = userId == null
        ? <RelationshipModel>[]
        : myCoaches(relationships, userId);

    return Scaffold(
      appBar: ProofAppBar(
        title: widget.isFirstProof ? 'First proof' : 'Add proof',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (skills) {
          final activeSkills =
              skills.where((s) => s.status == SkillStatus.active).toList();

          if (activeSkills.isEmpty && !widget.isFirstProof) {
            return EmptyState(
              title: 'Add a skill first',
              message:
                  'Proofs document performance for a capability you already track. Start by adding a skill.',
              action: ProofButton(
                label: 'Add skill',
                onPressed: () => context.push('/skills/add'),
              ),
            );
          }

          final targetSkillId = widget.skillId;
          if (targetSkillId != null && _selectedSkill == null) {
            final match = activeSkills
                .where((s) => s.id == targetSkillId)
                .firstOrNull;
            if (match != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _onSkillChanged(match);
              });
            }
          }

          if (widget.isFirstProof && _selectedSkill == null && targetSkillId != null) {
            return const Center(child: CircularProgressIndicator());
          }

          final skill = _selectedSkill;
          final recordedAt = _recordedAt ?? DateTime.now();
          final unit = _selectedUnit.isNotEmpty
              ? _selectedUnit
              : skill?.defaultUnit ?? MeasurementUnits.reps;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isFirstProof) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        "Great! Let's document your first proof.",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Text(
                      'Record another result for a skill you track. Every proof strengthens your proof stack.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (widget.isFirstProof && skill != null)
                    ReadOnlyValueField(label: 'Skill', value: skill.name)
                  else
                    DropdownButtonFormField<SkillModel>(
                      initialValue: _selectedSkill,
                      decoration: const InputDecoration(labelText: 'Skill'),
                      items: activeSkills
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: _onSkillChanged,
                      validator: (v) => v == null ? 'Select a skill' : null,
                    ),
                  if (skill != null) ...[
                    const SizedBox(height: 16),
                    ResultInputField(
                      controller: _resultController,
                      measurementType: skill.measurementType,
                      unit: unit,
                      label: 'Result',
                      validator: (v) => Validators.required(v, field: 'Result'),
                    ),
                    const SizedBox(height: 16),
                    UnitSelector(
                      allowedUnits: skill.allowedUnits,
                      selectedUnit: unit,
                      onChanged: (u) => setState(() => _selectedUnit = u),
                    ),
                    const SizedBox(height: 16),
                    DateTimePickerField(
                      label: 'Date & time',
                      value: recordedAt,
                      onChanged: (dt) => setState(() => _recordedAt = dt),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Verified by',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose self-reported or coach verified. Coach verified proofs strengthen your stack confidence.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProofSource.selectable.map((source) {
                        final selected = _proofSource == source;
                        return ChoiceChip(
                          label: Text(source.label),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _proofSource = source;
                            if (source != ProofSource.coach) {
                              _selectedCoachId = null;
                            }
                          }),
                          selectedColor: AppColors.accent.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: selected ? AppColors.accent : AppColors.inkSecondary,
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_proofSource == ProofSource.coach) ...[
                      const SizedBox(height: 16),
                      if (connectedCoaches.isEmpty)
                        Text(
                          'Connect with a coach in More → Coaches before requesting verification.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCoachId,
                          decoration: const InputDecoration(
                            labelText: 'Select coach',
                          ),
                          items: connectedCoaches
                              .map(
                                (link) => DropdownMenuItem(
                                  value: link.toUserId,
                                  child: _CoachOptionLabel(coachId: link.toUserId),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCoachId = value),
                        ),
                    ],
                    const SizedBox(height: 24),
                    ProofTextField(
                      controller: _notesController,
                      label: 'Personal notes',
                      hint: 'Optional context about this evidence',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        _mediaFile != null
                            ? 'Media attached'
                            : 'Attach media (optional)',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ProofButton(
                      label: widget.isFirstProof ? 'Save first proof' : 'Add proof',
                      isLoading: _isLoading,
                      onPressed: _save,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoachOptionLabel extends ConsumerWidget {
  const _CoachOptionLabel({required this.coachId});

  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityByUserIdProvider(coachId));
    return identityAsync.when(
      loading: () => const Text('Coach'),
      error: (_, __) => const Text('Coach'),
      data: (identity) => Text(identity?.displayName ?? 'Coach'),
    );
  }
}
