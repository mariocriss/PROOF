import 'package:proof/core/utils/confidence_progress_segments.dart';
import 'package:proof/core/utils/identity_confidence_calculator.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';

class PassportCredentialViewData {
  const PassportCredentialViewData({
    required this.identity,
    required this.overallConfidence,
    required this.identityBadgeLabel,
    required this.skillsCount,
    required this.proofsCount,
    required this.coachVerifiedCount,
    required this.filledSegments,
    required this.trustIndicators,
    required this.publicUrl,
  });

  final PhysicalIdentity identity;
  final StackConfidence overallConfidence;
  final String identityBadgeLabel;
  final int skillsCount;
  final int proofsCount;
  final int coachVerifiedCount;
  final int filledSegments;
  final PassportTrustIndicators trustIndicators;
  final String publicUrl;

  factory PassportCredentialViewData.build({
    required PhysicalIdentity identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
    required String publicUrl,
    DateTime Function()? now,
  }) {
    final clock = now ?? DateTime.now;
    final activeSkills =
        skills.where((s) => s.status == SkillStatus.active).toList();
    final confidence = IdentityConfidenceCalculator.calculate(
      skills: skills,
      proofs: proofs,
    );
    final summaries = ProofStackMerge.buildSummaries(
      skills: skills,
      proofs: proofs,
    );

    return PassportCredentialViewData(
      identity: identity,
      overallConfidence: confidence,
      identityBadgeLabel: _identityBadge(confidence),
      skillsCount: activeSkills.length,
      proofsCount: proofs.length,
      coachVerifiedCount:
          proofs.where((p) => p.isCoachVerifiedForStack).length,
      filledSegments: ConfidenceProgressSegments.filledFor(confidence),
      trustIndicators: PassportTrustIndicators.build(
        identity: identity,
        proofs: proofs,
        timeline: timeline,
        summaries: summaries,
        now: clock(),
      ),
      publicUrl: publicUrl,
    );
  }

  static String _identityBadge(StackConfidence confidence) {
    return switch (confidence) {
      StackConfidence.trusted ||
      StackConfidence.strong ||
      StackConfidence.established =>
        'Established Identity',
      StackConfidence.developing => 'Developing Identity',
      StackConfidence.limitedEvidence => 'Building Identity',
    };
  }
}

class PassportTrustIndicators {
  const PassportTrustIndicators({
    required this.coachVerified,
    required this.identityAge,
    required this.latestMilestone,
    required this.mostConsistent,
  });

  final String coachVerified;
  final String identityAge;
  final String latestMilestone;
  final String mostConsistent;

  factory PassportTrustIndicators.build({
    required PhysicalIdentity identity,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
    required List<ProofStackSkillSummary> summaries,
    required DateTime now,
  }) {
    final coachProofs = proofs
        .where((p) => p.isCoachVerifiedForStack)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final coachVerified = coachProofs.isEmpty
        ? 'Not yet'
        : ProofDateUtils.formatRelative(coachProofs.first.recordedAt);

    final sortedTimeline = List<TimelineEvent>.from(timeline)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestMilestone = sortedTimeline.isEmpty
        ? 'No milestones yet'
        : _shortMilestoneTitle(sortedTimeline.first.title);

    String mostConsistent = '—';
    if (summaries.isNotEmpty) {
      final byProofs = List<ProofStackSkillSummary>.from(summaries)
        ..sort((a, b) => b.totalProofs.compareTo(a.totalProofs));
      mostConsistent = byProofs.first.skill.name;
    }

    return PassportTrustIndicators(
      coachVerified: coachVerified,
      identityAge: _formatIdentityAge(identity.createdAt, now),
      latestMilestone: latestMilestone,
      mostConsistent: mostConsistent,
    );
  }

  static String _formatIdentityAge(DateTime createdAt, DateTime now) {
    final months =
        (now.year - createdAt.year) * 12 + now.month - createdAt.month;
    if (months < 1) return 'Less than 1 month';
    if (months < 12) return months == 1 ? '1 month' : '$months months';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) {
      return years == 1 ? '1 year' : '$years years';
    }
    return '$years yr $remainingMonths mo';
  }

  static String _shortMilestoneTitle(String title) {
    if (title.length <= 28) return title;
    return '${title.substring(0, 25)}...';
  }
}
