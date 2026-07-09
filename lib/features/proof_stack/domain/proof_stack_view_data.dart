import 'package:proof/core/utils/trust_stage_progress.dart';
import 'package:proof/core/utils/proof_stack_calculator.dart';
import 'package:proof/core/utils/result_normalizer.dart';
import 'package:proof/core/utils/timeline_milestone_evaluator.dart';
import 'package:proof/features/proof_stack/domain/performance_chart_data.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/proof_source.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';

enum ProofStackTrend {
  notEnoughEvidence('Not enough evidence'),
  improving('Improving'),
  stable('Stable'),
  declining('Declining'),
  inactive('Inactive');

  const ProofStackTrend(this.label);
  final String label;
}

class ProofStackSkillSummary {
  const ProofStackSkillSummary({
    required this.skill,
    required this.proofs,
    required this.confidence,
    required this.trend,
    required this.selfReportedCount,
    required this.coachVerifiedCount,
    required this.lastUpdated,
  });

  final SkillModel skill;
  final List<ProofModel> proofs;
  final StackConfidence confidence;
  final ProofStackTrend trend;
  final int selfReportedCount;
  final int coachVerifiedCount;
  final DateTime? lastUpdated;

  int get totalProofs => proofs.length;

  String get proofStackLabel {
    final count = totalProofs;
    return count == 1 ? '1 proof' : '$count proofs';
  }

  String get verifiedByLabel =>
      'Self Reported ×$selfReportedCount · Coach Verified ×$coachVerifiedCount';

  factory ProofStackSkillSummary.build({
    required SkillModel skill,
    required List<ProofModel> proofs,
    DateTime Function()? now,
  }) {
    final clock = now ?? DateTime.now;
    final sortedProofs = List<ProofModel>.from(proofs)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return ProofStackSkillSummary(
      skill: skill,
      proofs: sortedProofs,
      confidence: ProofStackCalculator.calculate(sortedProofs),
      trend: _calculateTrend(
        skill: skill,
        proofs: sortedProofs,
        now: clock(),
      ),
      selfReportedCount: sortedProofs
          .where((p) => !p.isCoachVerifiedForStack)
          .length,
      coachVerifiedCount: sortedProofs
          .where((p) => p.isCoachVerifiedForStack)
          .length,
      lastUpdated:
          sortedProofs.isEmpty ? null : sortedProofs.first.recordedAt,
    );
  }

  static ProofStackTrend _calculateTrend({
    required SkillModel skill,
    required List<ProofModel> proofs,
    required DateTime now,
  }) {
    if (skill.status != SkillStatus.active) {
      return ProofStackTrend.inactive;
    }

    if (proofs.isEmpty || proofs.length == 1) {
      if (proofs.isEmpty) return ProofStackTrend.notEnoughEvidence;
      final daysSince = now.difference(proofs.first.recordedAt).inDays;
      if (daysSince > 90) return ProofStackTrend.inactive;
      return ProofStackTrend.notEnoughEvidence;
    }

    final daysSinceLatest = now.difference(proofs.first.recordedAt).inDays;
    if (daysSinceLatest > 90) return ProofStackTrend.inactive;

    final withValues = proofs
        .where((p) => p.normalizedValue != null)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (withValues.length < 2) return ProofStackTrend.notEnoughEvidence;

    final values = withValues.map((p) => p.normalizedValue!).toList();
    final trendLine = PerformanceChartView.linearTrendFromValues(values);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final threshold = range > 0 ? range * 0.02 : 0.01;

    if (trendLine.slope.abs() <= threshold) {
      return ProofStackTrend.stable;
    }

    final improving = skill.performanceType.higherIsBetter
        ? trendLine.slope > 0
        : trendLine.slope < 0;

    return improving ? ProofStackTrend.improving : ProofStackTrend.declining;
  }
}

class SkillProofStackDetail {
  const SkillProofStackDetail({
    required this.summary,
    required this.verificationGroups,
    required this.performanceHistory,
    required this.milestones,
    required this.remainingProgress,
    required this.trustProfile,
  });

  final ProofStackSkillSummary summary;
  final List<VerificationGroup> verificationGroups;
  final List<ProofModel> performanceHistory;
  final List<SkillStackMilestone> milestones;
  final String? remainingProgress;
  final TrustProfile trustProfile;

  factory SkillProofStackDetail.build({
    required SkillModel skill,
    required List<ProofModel> proofs,
    DateTime Function()? now,
  }) {
    final summary = ProofStackSkillSummary.build(
      skill: skill,
      proofs: proofs,
      now: now,
    );
    final sortedAsc = List<ProofModel>.from(summary.proofs)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final grouped = <ProofSource, List<ProofModel>>{};
    for (final source in _sourceOrder) {
      final items =
          summary.proofs.where((p) => p.proofSource == source).toList()
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      grouped[source] = items;
    }

    final verificationGroups = _displaySources
        .map(
          (source) => VerificationGroup(
            source: source,
            proofs: grouped[source] ?? const [],
          ),
        )
        .toList();

    return SkillProofStackDetail(
      summary: summary,
      verificationGroups: verificationGroups,
      performanceHistory: sortedAsc,
      milestones: _buildMilestones(skill: skill, proofs: sortedAsc),
      remainingProgress: _remainingProgress(skill),
      trustProfile: TrustProfile.build(
        confidence: summary.confidence,
        proofCount: summary.totalProofs,
      ),
    );
  }

  static const _displaySources = [
    ProofSource.selfReported,
    ProofSource.coach,
  ];

  static const _sourceOrder = [
    ProofSource.selfReported,
    ProofSource.coach,
  ];

  static String? remainingProgressFor(SkillModel skill) =>
      _remainingProgress(skill);

  static String? _remainingProgress(SkillModel skill) {
    if (skill.targetValue == null ||
        skill.targetValue!.isEmpty ||
        skill.currentBest == null ||
        skill.currentBest!.isEmpty) {
      return null;
    }

    final current = ResultNormalizer.parseNormalized(
      skill.currentBest,
      skill.measurementType,
      skill.currentBestUnit ?? skill.defaultUnit,
    );
    final target = ResultNormalizer.parseNormalized(
      skill.targetValue,
      skill.measurementType,
      skill.targetUnit ?? skill.defaultUnit,
    );

    if (current == null || target == null) return null;

    final remaining = (target - current).abs();
    final unit = skill.targetUnit ?? skill.defaultUnit;

    if (skill.performanceType.higherIsBetter) {
      if (current >= target) return 'Target reached';
      return '${_formatDelta(remaining)} $unit to target';
    }

    if (current <= target) return 'Target reached';
    return '${_formatDelta(remaining)} $unit to target';
  }

  static String _formatDelta(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  static List<SkillStackMilestone> _buildMilestones({
    required SkillModel skill,
    required List<ProofModel> proofs,
  }) {
    if (proofs.isEmpty) return const [];

    final milestones = <SkillStackMilestone>[];
    final priorProofs = <ProofModel>[];
    var confidence = StackConfidence.limitedEvidence;
    var bestValue = skill.normalizedBestValue;

    for (final proof in proofs) {
      final priorSkillProofs = List<ProofModel>.from(priorProofs);
      final previousConfidence = confidence;
      priorProofs.add(proof);
      confidence = ProofStackCalculator.calculate(priorProofs);

      if (priorSkillProofs.isEmpty) {
        milestones.add(
          SkillStackMilestone(
            title: 'First proof',
            subtitle: proof.formattedResult,
            date: proof.recordedAt,
          ),
        );
      }

      if (proof.isCoachVerifiedForStack &&
          !priorSkillProofs.any((p) => p.isCoachVerifiedForStack)) {
        milestones.add(
          SkillStackMilestone(
            title: 'First coach verification',
            subtitle: proof.formattedResult,
            date: proof.recordedAt,
          ),
        );
      }

      final normalized = proof.normalizedValue ??
          ResultNormalizer.parseNormalized(
            proof.result,
            skill.measurementType,
            proof.unit.isNotEmpty ? proof.unit : skill.defaultUnit,
          );

      if (normalized != null &&
          BestResultLogic.isBetter(
            candidate: normalized,
            current: bestValue,
            performanceType: skill.performanceType,
          )) {
        if (priorSkillProofs.isNotEmpty) {
          milestones.add(
            SkillStackMilestone(
              title: 'New personal best',
              subtitle: proof.formattedResult,
              date: proof.recordedAt,
            ),
          );
        }
        bestValue = normalized;
      }

      if (TimelineMilestoneEvaluator.confidenceRank(confidence) >
          TimelineMilestoneEvaluator.confidenceRank(previousConfidence)) {
        milestones.add(
          SkillStackMilestone(
            title: 'Confidence increased',
            subtitle: confidence.label,
            date: proof.recordedAt,
          ),
        );
      }
    }

    return milestones.reversed.toList();
  }
}

class SkillStackMilestone {
  const SkillStackMilestone({
    required this.title,
    required this.subtitle,
    required this.date,
  });

  final String title;
  final String subtitle;
  final DateTime date;
}

class VerificationGroup {
  const VerificationGroup({
    required this.source,
    required this.proofs,
  });

  final ProofSource source;
  final List<ProofModel> proofs;

  bool get isEmpty => proofs.isEmpty;
}

class TrustProfile {
  const TrustProfile({
    required this.filledSegments,
    required this.totalSegments,
    required this.statusMessage,
  });

  final int filledSegments;
  final int totalSegments;
  final String statusMessage;

  double get progress => filledSegments / totalSegments;

  factory TrustProfile.build({
    required StackConfidence confidence,
    required int proofCount,
  }) {
    return TrustProfile(
      filledSegments: TrustStageProgress.filledSegmentsFor(proofCount),
      totalSegments: TrustStageProgress.segmentCount,
      statusMessage: switch (confidence) {
        StackConfidence.limitedEvidence => 'Building trust...',
        StackConfidence.developing => 'Evidence growing...',
        StackConfidence.established => 'Established evidence',
        StackConfidence.strong => 'Strong evidence',
        StackConfidence.trusted => 'Highly trusted',
      },
    );
  }
}
