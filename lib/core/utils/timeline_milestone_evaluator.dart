import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';

class TimelineMilestoneCandidate {
  const TimelineMilestoneCandidate({
    required this.type,
    required this.title,
    this.subtitle = '',
    this.referenceId,
    this.milestoneKey,
  });

  final TimelineEventType type;
  final String title;
  final String subtitle;
  final String? referenceId;
  final String? milestoneKey;
}

class TimelineMilestoneEvaluator {
  TimelineMilestoneEvaluator._();

  static const proofCountMilestones = [10, 25, 50, 100];
  static const skillCountMilestones = [5, 10];

  static List<TimelineMilestoneCandidate> evaluateIdentityCreated({
    required PhysicalIdentity identity,
  }) {
    return [
      TimelineMilestoneCandidate(
        type: TimelineEventType.identity,
        milestoneKey: 'identity_created',
        title: 'Physical identity created',
        subtitle: '@${identity.handle}',
        referenceId: identity.userId,
      ),
    ];
  }

  static List<TimelineMilestoneCandidate> evaluateSkillAdded({
    required SkillModel skill,
    required List<SkillModel> allSkills,
  }) {
    final milestones = <TimelineMilestoneCandidate>[];
    final count = allSkills.length;

    if (count == 1) {
      milestones.add(
        TimelineMilestoneCandidate(
          type: TimelineEventType.milestone,
          milestoneKey: 'first_skill',
          title: 'Started tracking ${skill.name}',
          subtitle: 'Your first capability',
          referenceId: skill.id,
        ),
      );
    } else {
      final priorDisciplines = allSkills
          .where((s) => s.id != skill.id)
          .map((s) => s.discipline.toLowerCase())
          .toSet();
      if (!priorDisciplines.contains(skill.discipline.toLowerCase())) {
        milestones.add(
          TimelineMilestoneCandidate(
            type: TimelineEventType.milestone,
            milestoneKey: _disciplineKey(skill.discipline),
            title: 'New discipline added',
            subtitle: skill.discipline,
            referenceId: skill.id,
          ),
        );
      }
    }

    for (final threshold in skillCountMilestones) {
      if (count == threshold) {
        milestones.add(
          TimelineMilestoneCandidate(
            type: TimelineEventType.achievement,
            milestoneKey: 'skills_$threshold',
            title: _skillCountTitle(threshold),
            subtitle: '$threshold capabilities tracked',
          ),
        );
      }
    }

    return milestones;
  }

  static List<TimelineMilestoneCandidate> evaluateProofAdded({
    required ProofModel proof,
    required SkillModel? skill,
    required List<ProofModel> allProofs,
    required List<ProofModel> priorSkillProofs,
    required StackConfidence previousConfidence,
    required StackConfidence newConfidence,
    required bool isPersonalBest,
  }) {
    final milestones = <TimelineMilestoneCandidate>[];
    final totalProofs = allProofs.length;
    final priorProofs = allProofs.where((p) => p.id != proof.id).toList();
    final skillName = skill?.name ?? 'capability';

    if (totalProofs == 1) {
      milestones.add(
        const TimelineMilestoneCandidate(
          type: TimelineEventType.milestone,
          milestoneKey: 'first_proof',
          title: 'First proof documented',
          subtitle: 'Your journey is officially on record',
        ),
      );
    }

    if (proof.proofSource == ProofSource.coach &&
        !priorProofs.any((p) => p.proofSource == ProofSource.coach)) {
      milestones.add(
        TimelineMilestoneCandidate(
          type: TimelineEventType.coachVerified,
          milestoneKey: 'first_coach_verified',
          title: 'First coach-verified proof',
          subtitle: skillName,
          referenceId: proof.id,
        ),
      );
    }

    if (isPersonalBest && priorSkillProofs.isNotEmpty && skill != null) {
      milestones.add(
        TimelineMilestoneCandidate(
          type: TimelineEventType.personalBest,
          title: 'New ${skill.name} personal best',
          subtitle: proof.formattedResult,
          referenceId: proof.id,
        ),
      );
    }

    if (confidenceRank(newConfidence) > confidenceRank(previousConfidence) &&
        skill != null) {
      milestones.add(
        TimelineMilestoneCandidate(
          type: TimelineEventType.confidence,
          milestoneKey: 'confidence_${skill.id}_${newConfidence.value}',
          title: '${skill.name} reached ${newConfidence.label}',
          subtitle: 'Proof stack confidence increased',
          referenceId: skill.id,
        ),
      );
    }

    for (final threshold in proofCountMilestones) {
      if (totalProofs == threshold) {
        milestones.add(
          TimelineMilestoneCandidate(
            type: TimelineEventType.achievement,
            milestoneKey: 'proofs_$threshold',
            title: _proofCountTitle(threshold),
            subtitle: '$threshold proofs documented',
          ),
        );
      }
    }

    return milestones;
  }

  static List<TimelineMilestoneCandidate> evaluateOneYearActive({
    required PhysicalIdentity identity,
    required DateTime asOf,
  }) {
    final daysActive = asOf.difference(identity.createdAt).inDays;
    if (daysActive < 365) return const [];

    return const [
      TimelineMilestoneCandidate(
        type: TimelineEventType.achievement,
        milestoneKey: 'one_year_active',
        title: 'One year active',
        subtitle: 'A year of building your physical identity',
      ),
    ];
  }

  static int confidenceRank(StackConfidence confidence) =>
      StackConfidence.values.indexOf(confidence);

  static String _disciplineKey(String discipline) =>
      'discipline_${discipline.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

  static String _proofCountTitle(int count) => switch (count) {
        10 => 'Ten proofs documented',
        25 => 'Twenty-five proofs documented',
        50 => 'Fifty proofs documented',
        100 => 'One hundred proofs documented',
        _ => '$count proofs documented',
      };

  static String _skillCountTitle(int count) => switch (count) {
        5 => 'Five capabilities tracked',
        10 => 'Ten capabilities tracked',
        _ => '$count capabilities tracked',
      };
}
