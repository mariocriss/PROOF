import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/confidence_progress_segments.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/confidence_block_progress.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class TimelineEventDetailSheet extends ConsumerWidget {
  const TimelineEventDetailSheet({super.key, required this.event});

  final TimelineEvent event;

  static Future<void> show(BuildContext context, TimelineEvent event) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TimelineEventDetailSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillsProvider).valueOrNull ?? [];
    final proofs = ref.watch(proofsProvider).valueOrNull ?? [];
    final identity = ref.watch(physicalIdentityProvider).valueOrNull;

    final proof = _findProof(proofs);
    final skill = _findSkill(skills, proof);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
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
            Row(
              children: [
                _EventIcon(event: event, major: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                  ),
                ),
              ],
            ),
            if (event.subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                event.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              ProofDateUtils.formatDate(event.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
            const SizedBox(height: 24),
            ..._detailRows(context, skills, proofs, proof, skill, identity),
            const SizedBox(height: 28),
            ProofButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  ProofModel? _findProof(List<ProofModel> proofs) {
    final id = event.referenceId;
    if (id == null) return null;
    for (final proof in proofs) {
      if (proof.id == id) return proof;
    }
    return null;
  }

  SkillModel? _findSkill(List<SkillModel> skills, ProofModel? proof) {
    if (proof != null) {
      return skills.where((s) => s.id == proof.skillId).firstOrNull;
    }
    final id = event.referenceId;
    if (id == null) return null;
    return skills.where((s) => s.id == id).firstOrNull;
  }

  List<Widget> _detailRows(
    BuildContext context,
    List<SkillModel> skills,
    List<ProofModel> proofs,
    ProofModel? proof,
    SkillModel? skill,
    PhysicalIdentity? identity,
  ) {
    final rows = <Widget>[];

    void addRow(String label, String value) {
      rows.add(_DetailRow(label: label, value: value));
    }

    switch (event.type) {
      case TimelineEventType.personalBest:
      case TimelineEventType.coachVerified:
        if (skill != null) addRow('Skill', skill.name);
        if (proof != null) {
          addRow('Result', proof.formattedResult);
          addRow('Verification', proof.proofSource.label);
          if (proof.notes.isNotEmpty) addRow('Notes', proof.notes);
          if (proof.location.isNotEmpty) addRow('Location', proof.location);
        }
        if (skill != null) {
          final stackProofs = ProofStackMerge.proofsForSkillGroup(
            skill: skill,
            allSkills: skills,
            allProofs: proofs,
          );
          final confidence = ProofStackCalculator.calculate(stackProofs);
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidence',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    confidence.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ConfidenceBlockProgress(
                    filled: ConfidenceProgressSegments.filledFor(confidence),
                    total: ConfidenceProgressSegments.segmentCount,
                    segmentWidth: 10,
                    height: 6,
                    gap: 3,
                  ),
                ],
              ),
            ),
          );
        }
      case TimelineEventType.confidence:
        if (skill != null) {
          addRow('Skill', skill.name);
          final stackProofs = ProofStackMerge.proofsForSkillGroup(
            skill: skill,
            allSkills: skills,
            allProofs: proofs,
          );
          addRow(
            'Confidence',
            ProofStackCalculator.calculate(stackProofs).label,
          );
          addRow('Proofs', '${stackProofs.length}');
        }
      case TimelineEventType.milestone:
      case TimelineEventType.achievement:
        if (skill != null) addRow('Skill', skill.name);
        if (proof != null) addRow('Result', proof.formattedResult);
      case TimelineEventType.identity:
        if (identity != null) {
          addRow('Identity', identity.displayName);
          addRow('Handle', '@${identity.handle}');
        }
      case TimelineEventType.competition:
        if (proof != null) addRow('Result', proof.formattedResult);
    }

    if (rows.isEmpty) {
      rows.add(
        Text(
          'This milestone is part of your physical identity story.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSecondary,
                height: 1.5,
              ),
        ),
      );
    }

    return rows;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.event, this.major = false});

  final TimelineEvent event;
  final bool major;

  @override
  Widget build(BuildContext context) {
    final size = major ? 40.0 : 32.0;
    final iconSize = major ? 20.0 : 16.0;
    final accent = event.type.accentColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(event.type.icon, size: iconSize, color: accent),
    );
  }
}
