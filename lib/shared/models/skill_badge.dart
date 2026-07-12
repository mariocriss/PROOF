enum SkillBadgeId {
  firstProof('first_proof', 'First Proof'),
  proofs10('proofs_10', '10 Proofs'),
  proofs25('proofs_25', '25 Proofs'),
  proofs50('proofs_50', '50 Proofs'),
  proofs100('proofs_100', '100 Proofs'),
  firstCoachVerification('first_coach_verification', 'First Coach Verification'),
  coachVerifications5('coach_verifications_5', '5 Coach Verifications'),
  establishedSkill('established_skill', 'Established Skill'),
  strongSkill('strong_skill', 'Strong Skill'),
  trustedSkill('trusted_skill', 'Trusted Skill'),
  firstPersonalBest('first_personal_best', 'First Personal Best'),
  goalReached('goal_reached', 'Goal Reached'),
  personalBests3('personal_bests_3', '3 Personal Bests'),
  personalBests10('personal_bests_10', '10 Personal Bests'),
  variantFirstProof('variant_first_proof', 'Variant First Proof'),
  variantsDocumented3('variants_documented_3', 'Three Variants Documented');

  const SkillBadgeId(this.value, this.label);

  final String value;
  final String label;

  static SkillBadgeId? fromString(String? value) {
    if (value == null) return null;
    for (final badge in SkillBadgeId.values) {
      if (badge.value == value) return badge;
    }
    return null;
  }

  bool get isMajorTimelineEvent => switch (this) {
        SkillBadgeId.goalReached ||
        SkillBadgeId.establishedSkill ||
        SkillBadgeId.strongSkill ||
        SkillBadgeId.trustedSkill ||
        SkillBadgeId.firstCoachVerification =>
          true,
        _ => false,
      };
}

enum IdentityBadgeId {
  firstSkill('first_skill', 'First Skill'),
  skills5('skills_5', '5 Skills'),
  skills10('skills_10', '10 Skills'),
  active30Days('active_30_days', '30 Days Active'),
  active6Months('active_6_months', '6 Months Active'),
  active1Year('active_1_year', '1 Year Active');

  const IdentityBadgeId(this.value, this.label);

  final String value;
  final String label;
}
