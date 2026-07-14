import 'package:proof/core/constants/app_features.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/gym_model.dart';

class GymManagerStats {
  const GymManagerStats({
    required this.approvedAthletes,
    required this.approvedCoaches,
    required this.pendingAthleteRequests,
    required this.pendingCoachRequests,
  });

  final int approvedAthletes;
  final int approvedCoaches;
  final int pendingAthleteRequests;
  final int pendingCoachRequests;
}

class GymProfileCompleteness {
  const GymProfileCompleteness({
    required this.percent,
    required this.missingFields,
    required this.isComplete,
  });

  final int percent;
  final List<String> missingFields;
  final bool isComplete;

  static GymProfileCompleteness fromGym(GymModel gym) {
    final checks = <String, bool>{
      if (AppFeatures.cloudStorageEnabled)
        'Gym logo': gym.logoUrl != null && gym.logoUrl!.isNotEmpty,
      'Description': gym.description.trim().isNotEmpty,
      'Website': gym.website.trim().isNotEmpty,
      'Contact email': gym.contactEmail.trim().isNotEmpty,
      'Phone': gym.phone.trim().isNotEmpty,
      'Address': gym.address.trim().isNotEmpty,
      'City': gym.city.trim().isNotEmpty,
    };

    final completed = checks.values.where((v) => v).length;
    final missing =
        checks.entries.where((e) => !e.value).map((e) => e.key).toList();

    return GymProfileCompleteness(
      percent: ((completed / checks.length) * 100).round(),
      missingFields: missing,
      isComplete: missing.isEmpty,
    );
  }
}

enum GymActivityType {
  athleteJoined,
  coachApproved,
  athleteRequest,
  coachRequest,
  requestDeclined,
  profileUpdated,
}

class GymActivityItem {
  const GymActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
  });

  final GymActivityType type;
  final String title;
  final String subtitle;
  final DateTime date;
}

class GymAttentionItem {
  const GymAttentionItem({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.targetTab,
    this.requestsSubTab,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final int targetTab;
  final int? requestsSubTab;
}

class GymManagerDashboardData {
  const GymManagerDashboardData({
    required this.gym,
    required this.stats,
    required this.completeness,
    required this.attentionItems,
    required this.activity,
    required this.athletePending,
    required this.coachPending,
    required this.approvedAthletes,
    required this.approvedCoaches,
  });

  final GymModel gym;
  final GymManagerStats stats;
  final GymProfileCompleteness completeness;
  final List<GymAttentionItem> attentionItems;
  final List<GymActivityItem> activity;
  final List<GymMembershipModel> athletePending;
  final List<GymMembershipModel> coachPending;
  final List<GymMembershipModel> approvedAthletes;
  final List<GymMembershipModel> approvedCoaches;

  String get locationLabel {
    final parts = <String>[
      if (gym.city.trim().isNotEmpty) gym.city.trim(),
      if (gym.country.trim().isNotEmpty) gym.country.trim(),
    ];
    return parts.join(', ');
  }

  static GymManagerDashboardData build({
    required GymModel gym,
    required List<GymMembershipModel> memberships,
    Map<String, String> displayNames = const {},
  }) {
    final athletePending = memberships
        .where(
          (m) =>
              m.membershipType == GymMembershipType.athlete &&
              m.status == GymMembershipStatus.pending,
        )
        .toList();
    final coachPending = memberships
        .where(
          (m) =>
              m.membershipType == GymMembershipType.coach &&
              m.status == GymMembershipStatus.pending,
        )
        .toList();
    final approvedAthletes = memberships
        .where(
          (m) =>
              m.membershipType == GymMembershipType.athlete &&
              m.status == GymMembershipStatus.approved,
        )
        .toList();
    final approvedCoaches = memberships
        .where(
          (m) =>
              m.membershipType == GymMembershipType.coach &&
              m.status == GymMembershipStatus.approved,
        )
        .toList();

    final stats = GymManagerStats(
      approvedAthletes: approvedAthletes.length,
      approvedCoaches: approvedCoaches.length,
      pendingAthleteRequests: athletePending.length,
      pendingCoachRequests: coachPending.length,
    );

    final completeness = GymProfileCompleteness.fromGym(gym);
    final attention = <GymAttentionItem>[];

    if (athletePending.isNotEmpty) {
      attention.add(
        GymAttentionItem(
          title:
              '${athletePending.length} athlete request${athletePending.length == 1 ? '' : 's'} awaiting review',
          subtitle: 'Review membership requests from athletes',
          actionLabel: 'Review requests',
          targetTab: 1,
          requestsSubTab: 0,
        ),
      );
    }
    if (coachPending.isNotEmpty) {
      attention.add(
        GymAttentionItem(
          title:
              '${coachPending.length} coach approval request${coachPending.length == 1 ? '' : 's'}',
          subtitle: 'Coaches are waiting for your approval',
          actionLabel: 'Review coaches',
          targetTab: 1,
          requestsSubTab: 1,
        ),
      );
    }
    if (!completeness.isComplete) {
      attention.add(
        GymAttentionItem(
          title: 'Gym profile ${completeness.percent}% complete',
          subtitle: completeness.missingFields.take(3).join(', '),
          actionLabel: 'Complete profile',
          targetTab: 4,
        ),
      );
    }

    final activity = _buildActivity(
      gym: gym,
      memberships: memberships,
      displayNames: displayNames,
    );

    return GymManagerDashboardData(
      gym: gym,
      stats: stats,
      completeness: completeness,
      attentionItems: attention,
      activity: activity,
      athletePending: athletePending,
      coachPending: coachPending,
      approvedAthletes: approvedAthletes,
      approvedCoaches: approvedCoaches,
    );
  }

  static List<GymActivityItem> _buildActivity({
    required GymModel gym,
    required List<GymMembershipModel> memberships,
    required Map<String, String> displayNames,
  }) {
    final events = <GymActivityItem>[];

    for (final membership in memberships) {
      final name = displayNames[membership.userId] ?? 'A member';
      if (membership.status == GymMembershipStatus.approved &&
          membership.reviewedAt != null) {
        if (membership.membershipType == GymMembershipType.athlete) {
          events.add(
            GymActivityItem(
              type: GymActivityType.athleteJoined,
              title: '$name joined the gym',
              subtitle: 'Athlete membership approved',
              date: membership.reviewedAt!,
            ),
          );
        } else if (membership.membershipType == GymMembershipType.coach) {
          events.add(
            GymActivityItem(
              type: GymActivityType.coachApproved,
              title: '$name approved as coach',
              subtitle: 'Coach can now verify proofs',
              date: membership.reviewedAt!,
            ),
          );
        }
      } else if (membership.status == GymMembershipStatus.pending) {
        events.add(
          GymActivityItem(
            type: membership.membershipType == GymMembershipType.coach
                ? GymActivityType.coachRequest
                : GymActivityType.athleteRequest,
            title: membership.membershipType == GymMembershipType.coach
                ? '$name requested coach access'
                : '$name requested membership',
            subtitle: 'Awaiting your review',
            date: membership.requestedAt,
          ),
        );
      } else if (membership.status == GymMembershipStatus.rejected &&
          membership.reviewedAt != null) {
        events.add(
          GymActivityItem(
            type: GymActivityType.requestDeclined,
            title: '${membership.membershipType.label} request declined',
            subtitle: name,
            date: membership.reviewedAt!,
          ),
        );
      }
    }

    events.add(
      GymActivityItem(
        type: GymActivityType.profileUpdated,
        title: 'Gym profile created',
        subtitle: gym.name,
        date: gym.createdAt,
      ),
    );

    events.sort((a, b) => b.date.compareTo(a.date));
    return events.take(8).toList();
  }
}

String formatGymActivityDate(DateTime date) {
  return ProofDateUtils.formatRelative(date);
}
