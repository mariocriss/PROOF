import 'package:proof/core/utils/confidence_progress_segments.dart';
import 'package:proof/core/utils/day_streak_calculator.dart';
import 'package:proof/core/utils/identity_confidence_calculator.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';

class DashboardViewData {
  const DashboardViewData({
    required this.identity,
    required this.identityConfidence,
    required this.skillsCount,
    required this.proofsCount,
    required this.selfReportedCount,
    required this.coachVerifiedCount,
    required this.dayStreak,
    required this.focusSkill,
    required this.recentActivity,
  });

  final PhysicalIdentity identity;
  final StackConfidence identityConfidence;
  final int skillsCount;
  final int proofsCount;
  final int selfReportedCount;
  final int coachVerifiedCount;
  final int dayStreak;
  final ProofStackSkillSummary? focusSkill;
  final List<TimelineEvent> recentActivity;

  int get identityFilledSegments =>
      ConfidenceProgressSegments.filledFor(identityConfidence);

  static const identityTotalSegments = ConfidenceProgressSegments.segmentCount;

  String get identityHelperText => switch (identityConfidence) {
        StackConfidence.limitedEvidence =>
          'Keep building. Consistency creates trust.',
        StackConfidence.developing =>
          'Keep building. Consistency creates trust.',
        StackConfidence.established =>
          'Your evidence is taking shape.',
        StackConfidence.strong => 'A credible physical identity is forming.',
        StackConfidence.trusted => 'Your identity is strongly supported.',
      };

  String get tipText => switch (identityConfidence) {
        StackConfidence.limitedEvidence ||
        StackConfidence.developing =>
          'Add more proofs to increase your confidence.',
        StackConfidence.established =>
          'Coach-verified proofs strengthen your identity further.',
        StackConfidence.strong ||
        StackConfidence.trusted =>
          'Maintain consistency to preserve your trusted identity.',
      };

  factory DashboardViewData.build({
    required PhysicalIdentity identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
  }) {
    final activeSkills =
        skills.where((s) => s.status == SkillStatus.active).toList();
    final summaries = ProofStackMerge.buildSummaries(
      skills: skills,
      proofs: proofs,
    );

    return DashboardViewData(
      identity: identity,
      identityConfidence: IdentityConfidenceCalculator.calculate(
        skills: skills,
        proofs: proofs,
      ),
      skillsCount: activeSkills.length,
      proofsCount: proofs.length,
      selfReportedCount:
          proofs.where((p) => p.proofSource == ProofSource.selfReported).length,
      coachVerifiedCount:
          proofs.where((p) => p.isCoachVerifiedForStack).length,
      dayStreak: DayStreakCalculator.calculate(proofs),
      focusSkill: summaries.isEmpty ? null : summaries.first,
      recentActivity: List<TimelineEvent>.from(timeline)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  static int focusFilledSegments(StackConfidence confidence) =>
      ConfidenceProgressSegments.filledFor(confidence);

  static const focusTotalSegments = ConfidenceProgressSegments.segmentCount;
}
