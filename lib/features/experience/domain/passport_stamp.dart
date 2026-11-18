import 'package:flutter/painting.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';

enum PassportStampShape {
  circle,
  circleNotched,
  wideRectangle,
  hexagon,
  perforatedRectangle,
}

enum PassportStampTrustClass {
  selfReported,
  imported,
  aiVerified,
  coachVerified,
  federationVerified,
}

class PassportStampDefinition {
  const PassportStampDefinition({
    required this.shape,
    required this.trustClass,
    this.embossed = false,
    this.showWitnessBar = false,
    this.useFoilEdge = false,
  });

  final PassportStampShape shape;
  final PassportStampTrustClass trustClass;
  final bool embossed;
  final bool showWitnessBar;
  final bool useFoilEdge;

  Color get inkColor => switch (trustClass) {
        PassportStampTrustClass.selfReported => ExperienceTokens.recordInk,
        PassportStampTrustClass.imported => ExperienceTokens.archivalInk,
        PassportStampTrustClass.aiVerified => ExperienceTokens.institutionalInk,
        PassportStampTrustClass.coachVerified => ExperienceTokens.witnessInk,
        PassportStampTrustClass.federationVerified =>
          ExperienceTokens.witnessInk,
      };

  static const PassportStampDefinition selfReportedCircle =
      PassportStampDefinition(
    shape: PassportStampShape.circle,
    trustClass: PassportStampTrustClass.selfReported,
  );

  static const PassportStampDefinition coachWitnessed =
      PassportStampDefinition(
    shape: PassportStampShape.circle,
    trustClass: PassportStampTrustClass.coachVerified,
    embossed: true,
    showWitnessBar: true,
  );
}

class PassportStampInstance {
  const PassportStampInstance({
    required this.definition,
    required this.label,
    this.dateLabel = '',
    this.descriptor = '',
    this.witnessLabel = '',
    this.semanticsLabel,
  });

  final PassportStampDefinition definition;
  final String label;
  final String dateLabel;
  final String descriptor;
  final String witnessLabel;
  final String? semanticsLabel;

  String get accessibleLabel {
    if (semanticsLabel != null && semanticsLabel!.isNotEmpty) {
      return semanticsLabel!;
    }
    final parts = <String>[
      if (label.isNotEmpty) label,
      if (descriptor.isNotEmpty) descriptor,
      if (dateLabel.isNotEmpty) dateLabel,
      if (witnessLabel.isNotEmpty) 'Verified by $witnessLabel',
      definition.trustClass.name,
    ];
    return parts.join('. ');
  }
}
