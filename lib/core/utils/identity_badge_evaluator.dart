import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_badge.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/skill_status.dart';

class IdentityBadgeEvaluator {
  IdentityBadgeEvaluator._();

  static List<IdentityBadgeId> earned({
    required PhysicalIdentity identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final activeSkills =
        skills.where((s) => s.status == SkillStatus.active).toList();
    final awarded = <IdentityBadgeId>[];

    if (activeSkills.isNotEmpty) awarded.add(IdentityBadgeId.firstSkill);
    if (activeSkills.length >= 5) awarded.add(IdentityBadgeId.skills5);
    if (activeSkills.length >= 10) awarded.add(IdentityBadgeId.skills10);

    final daysActive = now.difference(identity.createdAt).inDays;
    if (daysActive >= 30) awarded.add(IdentityBadgeId.active30Days);
    if (daysActive >= 183) awarded.add(IdentityBadgeId.active6Months);
    if (daysActive >= 365) awarded.add(IdentityBadgeId.active1Year);

    return awarded;
  }

  /// Curated subset for Passport — important milestones only.
  static List<IdentityBadgeId> curatedForPassport({
    required PhysicalIdentity identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    DateTime? asOf,
  }) {
    final badges = earned(
      identity: identity,
      skills: skills,
      proofs: proofs,
      asOf: asOf,
    );
    if (badges.isEmpty) return const [];

    const priority = [
      IdentityBadgeId.active1Year,
      IdentityBadgeId.active6Months,
      IdentityBadgeId.active30Days,
      IdentityBadgeId.skills10,
      IdentityBadgeId.skills5,
      IdentityBadgeId.firstSkill,
    ];

    final selected = <IdentityBadgeId>[];
    for (final badge in priority) {
      if (badges.contains(badge)) {
        selected.add(badge);
      }
      if (selected.length >= 4) break;
    }
    return selected;
  }
}
