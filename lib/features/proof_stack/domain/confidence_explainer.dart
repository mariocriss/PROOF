import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/models/proof_source.dart';

class ConfidenceExplainer {
  ConfidenceExplainer._();

  static String message({
    required StackConfidence confidence,
    required int proofCount,
    required int coachVerifiedCount,
    bool isIdentityLevel = false,
  }) {
    if (isIdentityLevel) {
      return identityMessage(
        confidence: confidence,
        proofCount: proofCount,
        coachVerifiedCount: coachVerifiedCount,
      );
    }

    switch (confidence) {
      case StackConfidence.limitedEvidence:
        if (proofCount <= 1) {
          return 'This skill currently has one documented proof.\n\n'
              'Trust is built through evidence, not claims.';
        }
        return 'Evidence for this skill is still limited.\n\n'
            'Trust is built through evidence, not claims.';

      case StackConfidence.developing:
        return 'Your proof stack is developing.\n\n'
            'A pattern of documented performance is beginning to form.';

      case StackConfidence.established:
        return 'This skill has established evidence.\n\n'
            'Multiple proofs across time support your current best.';

      case StackConfidence.strong:
        return 'This is a strong proof stack.\n\n'
            'Sustained documentation makes this capability increasingly credible.';

      case StackConfidence.trusted:
        return 'This proof stack is trusted.\n\n'
            'Long-term evidence and verification make this one of your most credible claims.';
    }
  }

  static String identityMessage({
    required StackConfidence confidence,
    required int proofCount,
    required int coachVerifiedCount,
  }) {
    switch (confidence) {
      case StackConfidence.limitedEvidence:
        if (proofCount <= 1) {
          return 'Your physical identity has one documented proof.\n\n'
              'Trust is built through evidence, not claims.';
        }
        return 'Your physical identity has limited evidence.\n\n'
            'Trust is built through evidence, not claims.';

      case StackConfidence.developing:
        return 'Your physical identity is developing.\n\n'
            'A pattern of documented performance is beginning to form across your skills.';

      case StackConfidence.established:
        return 'Your physical identity is established.\n\n'
            'Multiple proofs across skills support your documented capabilities.';

      case StackConfidence.strong:
        return 'Your physical identity is strong.\n\n'
            'Sustained documentation makes your physical claims increasingly credible.';

      case StackConfidence.trusted:
        return 'Your physical identity is trusted.\n\n'
            'Long-term evidence and verification make this one of your most credible identities.';
    }
  }

  static List<String> identityStrengthenTips({
    required StackConfidence confidence,
    required int coachVerifiedCount,
  }) {
    final tips = <String>[
      'Continue documenting proofs across your skills',
      'Build consistency over time',
    ];
    if (coachVerifiedCount == 0) {
      tips.add('Add coach-verified proofs to strengthen credibility');
    }
    if (confidence.index >= StackConfidence.established.index) {
      tips.add('Maintain evidence across multiple capabilities');
    }
    return tips;
  }

  static List<String> currentStackLines({
    required int selfReportedCount,
    required int coachVerifiedCount,
  }) {
    final lines = <String>[];
    if (selfReportedCount > 0) {
      lines.add(
        selfReportedCount == 1
            ? '✓ 1 Self Reported Proof'
            : '✓ $selfReportedCount Self Reported Proofs',
      );
    }
    if (coachVerifiedCount > 0) {
      lines.add(
        coachVerifiedCount == 1
            ? '✓ 1 Coach Verified Proof'
            : '✓ $coachVerifiedCount Coach Verified Proofs',
      );
    }
    if (lines.isEmpty) {
      lines.add('No proofs documented yet');
    }
    return lines;
  }

  static List<String> strengthenTips({
    required StackConfidence confidence,
    required int coachVerifiedCount,
  }) {
    final tips = <String>[
      'Continue documenting results over time',
      'Add more verified evidence',
    ];
    if (coachVerifiedCount == 0) {
      tips.add('Have future performances verified by a coach');
    }
    if (confidence.index >= StackConfidence.established.index) {
      tips.add('Maintain consistency across different dates');
    }
    return tips;
  }

  static String proofSourceLine(ProofSource source, int count) {
    if (count == 0) return '${source.label} ×0';
    return '${source.label} ×$count';
  }
}
