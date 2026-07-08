import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/core/utils/timeline_milestone_evaluator.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';

class TimelineRebuilder {
  TimelineRebuilder._();

  static List<TimelineEvent> rebuild({
    required String userId,
    required PhysicalIdentity? identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    DateTime Function()? now,
  }) {
    if (identity == null) return const [];

    final clock = now ?? DateTime.now;
    final events = <_TimedMilestone>[];
    final skillsById = {for (final skill in skills) skill.id: skill};
    final accumulatedSkills = <SkillModel>[];
    final skillStates = <String, _SkillReplayState>{};
    final accumulatedProofs = <ProofModel>[];

    void addCandidates(
      List<TimelineMilestoneCandidate> candidates,
      DateTime at,
    ) {
      for (final candidate in candidates) {
        events.add(_TimedMilestone(candidate: candidate, at: at));
      }
    }

    addCandidates(
      TimelineMilestoneEvaluator.evaluateIdentityCreated(identity: identity),
      identity.createdAt,
    );

    final actions = <_ReplayAction>[
      for (final skill in skills)
        _ReplayAction.skill(skill, skill.createdAt),
      for (final proof in proofs)
        _ReplayAction.proof(proof, proof.recordedAt),
    ]..sort((a, b) => a.at.compareTo(b.at));

    for (final action in actions) {
      switch (action.kind) {
        case _ReplayActionKind.skill:
          final skill = action.skill!;
          accumulatedSkills.add(skill);
          skillStates.putIfAbsent(
            skill.id,
            () => _SkillReplayState(skill),
          );
          addCandidates(
            TimelineMilestoneEvaluator.evaluateSkillAdded(
              skill: skill,
              allSkills: List<SkillModel>.from(accumulatedSkills),
            ),
            action.at,
          );
        case _ReplayActionKind.proof:
          final proof = action.proof!;
          accumulatedProofs.add(proof);
          final skill = skillsById[proof.skillId];
          if (skill == null) continue;

          final state = skillStates.putIfAbsent(
            skill.id,
            () => _SkillReplayState(skill),
          );
          final priorSkillProofs = List<ProofModel>.from(state.proofs);
          final previousConfidence = state.confidence;
          state.proofs.add(proof);

          final normalized = proof.normalizedValue ??
              ResultNormalizer.parseNormalized(
                proof.result,
                skill.measurementType,
                proof.unit.isNotEmpty ? proof.unit : skill.defaultUnit,
              );

          var isPersonalBest = false;
          if (normalized != null &&
              BestResultLogic.isBetter(
                candidate: normalized,
                current: state.normalizedBestValue,
                performanceType: skill.performanceType,
              )) {
            isPersonalBest = priorSkillProofs.isNotEmpty;
            state.normalizedBestValue = normalized;
          }

          addCandidates(
            TimelineMilestoneEvaluator.evaluateProofAdded(
              proof: proof,
              skill: skill,
              allProofs: List<ProofModel>.from(accumulatedProofs),
              priorSkillProofs: priorSkillProofs,
              previousConfidence: previousConfidence,
              newConfidence: state.confidence,
              isPersonalBest: isPersonalBest,
            ),
            action.at,
          );
      }
    }

    final oneYearAt = identity.createdAt.add(const Duration(days: 365));
    if (!oneYearAt.isAfter(clock())) {
      addCandidates(
        TimelineMilestoneEvaluator.evaluateOneYearActive(
          identity: identity,
          asOf: clock(),
        ),
        oneYearAt,
      );
    }

    events.sort((a, b) => a.at.compareTo(b.at));

    final usedKeys = <String>{};
    final personalBestCounts = <String, int>{};
    final timelineEvents = <TimelineEvent>[];

    for (final timed in events) {
      final candidate = timed.candidate;
      if (candidate.milestoneKey != null) {
        if (usedKeys.contains(candidate.milestoneKey)) continue;
        usedKeys.add(candidate.milestoneKey!);
      }

      final docId = candidate.milestoneKey ??
          _personalBestDocId(candidate, personalBestCounts);

      timelineEvents.add(
        TimelineEvent(
          id: docId,
          userId: userId,
          type: candidate.type,
          title: candidate.title,
          subtitle: candidate.subtitle,
          referenceId: candidate.referenceId,
          milestoneKey: candidate.milestoneKey,
          createdAt: timed.at,
        ),
      );
    }

    return timelineEvents;
  }

  static String _personalBestDocId(
    TimelineMilestoneCandidate candidate,
    Map<String, int> personalBestCounts,
  ) {
    if (candidate.referenceId != null) {
      return 'pb_${candidate.referenceId}';
    }
    final key = '${candidate.type.value}_${candidate.title}';
    final count = personalBestCounts.update(key, (value) => value + 1, ifAbsent: () => 0);
    return 'pb_${key}_$count';
  }
}

class _TimedMilestone {
  const _TimedMilestone({required this.candidate, required this.at});

  final TimelineMilestoneCandidate candidate;
  final DateTime at;
}

enum _ReplayActionKind { skill, proof }

class _ReplayAction {
  const _ReplayAction._(this.kind, this.at, {this.skill, this.proof});

  factory _ReplayAction.skill(SkillModel skill, DateTime at) =>
      _ReplayAction._(_ReplayActionKind.skill, at, skill: skill);

  factory _ReplayAction.proof(ProofModel proof, DateTime at) =>
      _ReplayAction._(_ReplayActionKind.proof, at, proof: proof);

  final _ReplayActionKind kind;
  final DateTime at;
  final SkillModel? skill;
  final ProofModel? proof;
}

class _SkillReplayState {
  _SkillReplayState(SkillModel skill) : normalizedBestValue = skill.normalizedBestValue;

  final List<ProofModel> proofs = [];
  double? normalizedBestValue;

  StackConfidence get confidence => ProofStackCalculator.calculate(proofs);
}
