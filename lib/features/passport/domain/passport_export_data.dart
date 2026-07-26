import 'package:proof/core/constants/app_constants.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/core/utils/identity_confidence_calculator.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_merge.dart';
import 'package:proof/features/proof_stack/domain/proof_stack_view_data.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/deleted_account_markers.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/models/verification_status.dart';

/// Safe, public-facing snapshot used only for Passport PDF export.
///
/// Intentionally excludes email, phone, Firebase IDs, rejection notes,
/// pending requests, blocked-user data, and other private fields.
class PassportExportData {
  const PassportExportData({
    required this.displayName,
    required this.handle,
    required this.publicUrl,
    required this.generatedAt,
    required this.memberSince,
    required this.overallConfidenceLabel,
    required this.identityAgeLabel,
    required this.totalSkills,
    required this.totalProofs,
    required this.coachVerifiedProofs,
    required this.selfReportedProofs,
    required this.disciplinesCount,
    required this.featuredSkills,
    required this.skillsByDomain,
    required this.domains,
    required this.timeline,
    required this.milestones,
    required this.appendixProofs,
    this.bio,
    this.location,
    this.avatarUrl,
    this.gymName,
    this.coachName,
  });

  final String displayName;
  final String handle;
  final String publicUrl;
  final DateTime generatedAt;
  final DateTime memberSince;
  final String overallConfidenceLabel;
  final String identityAgeLabel;
  final int totalSkills;
  final int totalProofs;
  final int coachVerifiedProofs;
  final int selfReportedProofs;
  final int disciplinesCount;
  final String? bio;
  final String? location;
  final String? avatarUrl;
  final String? gymName;
  final String? coachName;
  final List<PassportExportSkill> featuredSkills;
  final Map<String, List<PassportExportSkill>> skillsByDomain;
  final List<PassportExportDomain> domains;
  final List<PassportExportTimelineItem> timeline;
  final List<PassportExportTimelineItem> milestones;
  final List<PassportExportProof> appendixProofs;

  String get memberSinceLabel => ProofDateUtils.formatDate(memberSince);

  String get generatedDateLabel => ProofDateUtils.formatDate(generatedAt);

  /// Sanitized filename: `PROOF_Mario_Physical_Passport_2026.pdf`
  String get suggestedFilename {
    final year = generatedAt.year;
    final namePart = sanitizeFilenamePart(displayName);
    final safeName = namePart.isEmpty ? 'Athlete' : namePart;
    return 'PROOF_${safeName}_Physical_Passport_$year.pdf';
  }

  static String sanitizeFilenamePart(String input) {
    final cleaned = input
        .trim()
        .replaceAll(RegExp(r'[^\w\s\-]+', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_');
    if (cleaned.isEmpty) return '';
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }

  factory PassportExportData.fromPassport({
    required PhysicalIdentity identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
    String? gymName,
    String? coachName,
    DateTime Function()? now,
  }) {
    final clock = now ?? DateTime.now;
    final generatedAt = clock();

    final publicProofs = proofs
        .where(
          (p) =>
              p.verificationStatus != VerificationStatus.pendingVerification &&
              p.verificationStatus != VerificationStatus.rejected &&
              p.verificationStatus != VerificationStatus.declined,
        )
        .toList();

    final summaries = ProofStackMerge.buildSummaries(
      skills: skills,
      proofs: publicProofs,
      now: clock,
    );

    final exportSkills = summaries.map(PassportExportSkill.fromSummary).toList();

    final featured = _prioritizeFeatured(exportSkills).take(6).toList();

    final byDomain = <String, List<PassportExportSkill>>{};
    for (final skill in exportSkills) {
      byDomain.putIfAbsent(skill.domain, () => []).add(skill);
    }
    for (final list in byDomain.values) {
      list.sort((a, b) {
        final conf = b.confidenceRank.compareTo(a.confidenceRank);
        if (conf != 0) return conf;
        return b.proofCount.compareTo(a.proofCount);
      });
    }

    final domains = byDomain.entries.map((entry) {
      final domainSkills = entry.value;
      final top = domainSkills.isEmpty ? null : domainSkills.first;
      final proofsInDomain =
          domainSkills.fold<int>(0, (sum, s) => sum + s.proofCount);
      final highest = domainSkills.isEmpty
          ? null
          : domainSkills.reduce(
              (a, b) => a.confidenceRank >= b.confidenceRank ? a : b,
            );
      return PassportExportDomain(
        name: entry.key,
        skillCount: domainSkills.length,
        proofCount: proofsInDomain,
        topSkillName: top?.name,
        highestConfidenceLabel: highest?.confidenceLabel,
      );
    }).toList()
      ..sort((a, b) => b.proofCount.compareTo(a.proofCount));

    final confidence = IdentityConfidenceCalculator.calculate(
      skills: skills,
      proofs: publicProofs,
    );

    final coachVerified =
        publicProofs.where((p) => p.isCoachVerifiedForStack).length;
    final selfReported = publicProofs.length - coachVerified;

    final skillNameById = {
      for (final s in skills.where((s) => s.status == SkillStatus.active))
        s.id: s.name,
    };

    final appendix = _buildAppendix(
      summaries: summaries,
      skillNameById: skillNameById,
    );

    final timelineItems = _mapTimeline(timeline);
    final milestoneItems = timelineItems
        .where(
          (t) =>
              t.kind == PassportExportTimelineKind.milestone ||
              t.kind == PassportExportTimelineKind.achievement,
        )
        .toList();

    final bio = identity.bio.trim();
    final location = identity.location.trim();
    final gym = gymName?.trim();
    final coach = coachName?.trim();

    return PassportExportData(
      displayName: identity.displayName.trim().isEmpty
          ? '@${identity.handle}'
          : identity.displayName.trim(),
      handle: identity.handle,
      publicUrl: AppConstants.passportUrl(identity.handle),
      generatedAt: generatedAt,
      memberSince: identity.createdAt,
      overallConfidenceLabel: confidence.label,
      identityAgeLabel: _formatIdentityAge(identity.createdAt, generatedAt),
      totalSkills: exportSkills.length,
      totalProofs: publicProofs.length,
      coachVerifiedProofs: coachVerified,
      selfReportedProofs: selfReported,
      disciplinesCount: byDomain.length,
      bio: bio.isEmpty ? null : bio,
      location: location.isEmpty ? null : location,
      avatarUrl: identity.avatarUrl,
      gymName: (gym == null || gym.isEmpty) ? null : gym,
      coachName: (coach == null || coach.isEmpty) ? null : coach,
      featuredSkills: featured,
      skillsByDomain: byDomain,
      domains: domains,
      timeline: timelineItems.take(12).toList(),
      milestones: milestoneItems.take(10).toList(),
      appendixProofs: appendix,
    );
  }

  static List<PassportExportSkill> _prioritizeFeatured(
    List<PassportExportSkill> skills,
  ) {
    final sorted = List<PassportExportSkill>.from(skills)
      ..sort((a, b) {
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }
        final conf = b.confidenceRank.compareTo(a.confidenceRank);
        if (conf != 0) return conf;
        final proofs = b.proofCount.compareTo(a.proofCount);
        if (proofs != 0) return proofs;
        final aDate = a.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted;
  }

  static List<PassportExportProof> _buildAppendix({
    required List<ProofStackSkillSummary> summaries,
    required Map<String, String> skillNameById,
  }) {
    final items = <PassportExportProof>[];
    for (final summary in summaries) {
      final strongest = List<ProofModel>.from(summary.proofs)
        ..sort((a, b) {
          final aCoach = a.isCoachVerifiedForStack ? 1 : 0;
          final bCoach = b.isCoachVerifiedForStack ? 1 : 0;
          if (aCoach != bCoach) return bCoach.compareTo(aCoach);
          return b.recordedAt.compareTo(a.recordedAt);
        });
      for (final proof in strongest.take(3)) {
        items.add(
          PassportExportProof.fromProof(
            proof: proof,
            skillName: skillNameById[proof.skillId] ?? summary.skill.name,
          ),
        );
      }
    }
    items.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return items.take(40).toList();
  }

  static List<PassportExportTimelineItem> _mapTimeline(
    List<TimelineEvent> timeline,
  ) {
    final meaningful = timeline.where((e) {
      return switch (e.type) {
        TimelineEventType.identity ||
        TimelineEventType.milestone ||
        TimelineEventType.personalBest ||
        TimelineEventType.coachVerified ||
        TimelineEventType.achievement ||
        TimelineEventType.confidence =>
          true,
        TimelineEventType.competition => true,
      };
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return meaningful
        .map(
          (e) => PassportExportTimelineItem(
            title: e.title,
            description:
                e.subtitle.trim().isEmpty ? null : e.subtitle.trim(),
            date: e.createdAt,
            kind: switch (e.type) {
              TimelineEventType.milestone =>
                PassportExportTimelineKind.milestone,
              TimelineEventType.achievement =>
                PassportExportTimelineKind.achievement,
              TimelineEventType.personalBest =>
                PassportExportTimelineKind.personalBest,
              TimelineEventType.coachVerified =>
                PassportExportTimelineKind.coachVerified,
              _ => PassportExportTimelineKind.other,
            },
          ),
        )
        .toList();
  }

  static String _formatIdentityAge(DateTime createdAt, DateTime now) {
    final months =
        (now.year - createdAt.year) * 12 + now.month - createdAt.month;
    if (months < 1) return 'Less than 1 month';
    if (months < 12) return months == 1 ? '1 month' : '$months months';
    final years = months ~/ 12;
    final remaining = months % 12;
    if (remaining == 0) {
      return years == 1 ? '1 year' : '$years years';
    }
    return '$years yr $remaining mo';
  }
}

enum PassportExportTimelineKind {
  milestone,
  achievement,
  personalBest,
  coachVerified,
  other,
}

class PassportExportDomain {
  const PassportExportDomain({
    required this.name,
    required this.skillCount,
    required this.proofCount,
    this.topSkillName,
    this.highestConfidenceLabel,
  });

  final String name;
  final int skillCount;
  final int proofCount;
  final String? topSkillName;
  final String? highestConfidenceLabel;
}

class PassportExportSkill {
  const PassportExportSkill({
    required this.name,
    required this.domain,
    required this.confidenceLabel,
    required this.confidenceRank,
    required this.proofCount,
    required this.selfReportedCount,
    required this.coachVerifiedCount,
    required this.isFeatured,
    this.currentResult,
    this.unit,
    this.trendLabel,
    this.lastUpdated,
    this.statusLabel,
  });

  final String name;
  final String domain;
  final String? currentResult;
  final String? unit;
  final String confidenceLabel;
  final int confidenceRank;
  final int proofCount;
  final int selfReportedCount;
  final int coachVerifiedCount;
  final bool isFeatured;
  final String? trendLabel;
  final DateTime? lastUpdated;
  final String? statusLabel;

  String? get formattedResult {
    if (currentResult == null || currentResult!.isEmpty) return null;
    if (unit == null || unit!.isEmpty) return currentResult;
    return '$currentResult $unit';
  }

  String get evidenceSummary {
    final parts = <String>[];
    if (coachVerifiedCount > 0) {
      parts.add('$coachVerifiedCount Coach');
    }
    if (selfReportedCount > 0) {
      parts.add('$selfReportedCount Self Reported');
    }
    return parts.join(' · ');
  }

  factory PassportExportSkill.fromSummary(ProofStackSkillSummary summary) {
    final skill = summary.skill;
    final trend = summary.trend;
    final showTrend = trend != ProofStackTrend.notEnoughEvidence;

    String? statusLabel;
    if (skill.status == SkillStatus.paused) {
      statusLabel = 'Paused';
    } else if (summary.lastUpdated != null) {
      final days = DateTime.now().difference(summary.lastUpdated!).inDays;
      statusLabel = days > 90 ? 'Stale' : 'Current';
    }

    return PassportExportSkill(
      name: skill.name,
      domain: skill.discipline,
      currentResult: skill.currentBest,
      unit: skill.currentBestUnit ?? skill.defaultUnit,
      confidenceLabel: summary.confidence.label,
      confidenceRank: StackConfidence.values.indexOf(summary.confidence),
      proofCount: summary.totalProofs,
      selfReportedCount: summary.selfReportedCount,
      coachVerifiedCount: summary.coachVerifiedCount,
      isFeatured: skill.isFeatured,
      trendLabel: showTrend ? trend.label : null,
      lastUpdated: summary.lastUpdated,
      statusLabel: statusLabel,
    );
  }
}

class PassportExportTimelineItem {
  const PassportExportTimelineItem({
    required this.title,
    required this.date,
    required this.kind,
    this.description,
  });

  final String title;
  final String? description;
  final DateTime date;
  final PassportExportTimelineKind kind;

  String get dateLabel => ProofDateUtils.formatDate(date);
}

class PassportExportProof {
  const PassportExportProof({
    required this.skillName,
    required this.resultLabel,
    required this.evidenceSource,
    required this.recordedAt,
    required this.hasMedia,
    this.notes,
    this.location,
  });

  final String skillName;
  final String resultLabel;
  final String evidenceSource;
  final DateTime recordedAt;
  final bool hasMedia;
  final String? notes;
  final String? location;

  String get dateLabel => ProofDateUtils.formatDate(recordedAt);

  factory PassportExportProof.fromProof({
    required ProofModel proof,
    required String skillName,
  }) {
    final notes = proof.notes.trim();
    final location = proof.location.trim();
    return PassportExportProof(
      skillName: skillName,
      resultLabel: proof.formattedResult,
      evidenceSource: proof.coachAccountDeleted && proof.isCoachVerifiedForStack
          ? DeletedAccountMarkers.coachUnavailableLabel
          : proof.isCoachVerifiedForStack
              ? 'Coach verified'
              : 'Self reported',
      recordedAt: proof.recordedAt,
      hasMedia: proof.mediaUrl != null && proof.mediaUrl!.isNotEmpty,
      notes: notes.isEmpty ? null : notes,
      location: location.isEmpty ? null : location,
    );
  }
}
