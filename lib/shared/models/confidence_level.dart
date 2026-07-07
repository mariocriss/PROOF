import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';

/// Stack confidence — computed from proof history, never user-entered.
enum StackConfidence {
  limitedEvidence('limited_evidence', 'Limited Evidence', AppColors.confidenceLimited),
  developing('developing', 'Developing', AppColors.confidenceDeveloping),
  established('established', 'Established', AppColors.confidenceEstablished),
  strong('strong', 'Strong', AppColors.confidenceStrong),
  trusted('trusted', 'Trusted', AppColors.confidenceTrusted);

  const StackConfidence(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  static StackConfidence fromString(String? value) {
    return StackConfidence.values.firstWhere(
      (l) => l.value == value,
      orElse: () => StackConfidence.limitedEvidence,
    );
  }
}

// Legacy alias for gradual migration in imports.
typedef ConfidenceLevel = StackConfidence;
