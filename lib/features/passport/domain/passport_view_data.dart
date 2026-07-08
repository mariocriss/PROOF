import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/core/utils/identity_confidence_calculator.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/shared/models/skill_status.dart';

class PassportViewData {
  const PassportViewData({
    required this.identity,
    required this.skills,
    required this.proofs,
    required this.timeline,
    required this.overallConfidence,
    required this.topSkills,
    required this.recentMilestones,
    required this.recentTimeline,
    required this.statistics,
  });

  final PhysicalIdentity identity;
  final List<SkillModel> skills;
  final List<ProofModel> proofs;
  final List<TimelineEvent> timeline;
  final StackConfidence overallConfidence;
  final List<PassportSkillEntry> topSkills;
  final List<PassportMilestone> recentMilestones;
  final List<TimelineEvent> recentTimeline;
  final PassportStatistics statistics;

  factory PassportViewData.build({
    required PhysicalIdentity identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
  }) {
    final activeSkills =
        skills.where((s) => s.status == SkillStatus.active).toList();

    final skillEntries = activeSkills.map((skill) {
      final skillProofs =
          proofs.where((p) => p.skillId == skill.id).toList();
      final confidence = skill.stackConfidence ??
          ProofStackCalculator.calculate(skillProofs);
      return PassportSkillEntry(
        skill: skill,
        proofCount: skillProofs.length,
        confidence: confidence,
      );
    }).toList()
      ..sort((a, b) {
        final confCompare = _confidenceRank(b.confidence) - _confidenceRank(a.confidence);
        if (confCompare != 0) return confCompare;
        return b.proofCount.compareTo(a.proofCount);
      });

    final milestones = proofs
        .map(
          (p) => PassportMilestone(
            title: p.formattedResult,
            subtitle: _skillName(activeSkills, p.skillId),
            date: p.recordedAt,
          ),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentTimeline = List<TimelineEvent>.from(timeline)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final disciplines =
        activeSkills.map((s) => s.discipline).toSet().length;

    return PassportViewData(
      identity: identity,
      skills: activeSkills,
      proofs: proofs,
      timeline: timeline,
      overallConfidence: IdentityConfidenceCalculator.calculate(
        skills: skills,
        proofs: proofs,
      ),
      topSkills: skillEntries.take(5).toList(),
      recentMilestones: milestones.take(5).toList(),
      recentTimeline: recentTimeline.take(5).toList(),
      statistics: PassportStatistics(
        totalProofs: proofs.length,
        totalSkills: activeSkills.length,
        disciplines: disciplines,
        coachVerified: proofs
            .where((p) => p.proofSource == ProofSource.coach)
            .length,
        skillsWithProofs: activeSkills
            .where((s) => proofs.any((p) => p.skillId == s.id))
            .length,
        memberSince: identity.createdAt,
      ),
    );
  }

  static int _confidenceRank(StackConfidence c) =>
      StackConfidence.values.indexOf(c);

  static String _skillName(List<SkillModel> skills, String skillId) {
    return skills
        .where((s) => s.id == skillId)
        .map((s) => s.name)
        .firstOrNull ?? 'Skill';
  }
}

class PassportSkillEntry {
  const PassportSkillEntry({
    required this.skill,
    required this.proofCount,
    required this.confidence,
  });

  final SkillModel skill;
  final int proofCount;
  final StackConfidence confidence;
}

class PassportMilestone {
  const PassportMilestone({
    required this.title,
    required this.subtitle,
    required this.date,
  });

  final String title;
  final String subtitle;
  final DateTime date;
}

class PassportStatistics {
  const PassportStatistics({
    required this.totalProofs,
    required this.totalSkills,
    required this.disciplines,
    required this.coachVerified,
    required this.skillsWithProofs,
    required this.memberSince,
  });

  final int totalProofs;
  final int totalSkills;
  final int disciplines;
  final int coachVerified;
  final int skillsWithProofs;
  final DateTime memberSince;
}
