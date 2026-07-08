import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/proof_stack/domain/confidence_explainer.dart';
import 'package:proof/shared/models/confidence_level.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class ConfidenceExplanationSheet extends StatelessWidget {
  const ConfidenceExplanationSheet({
    super.key,
    required this.confidence,
    required this.proofCount,
    required this.selfReportedCount,
    required this.coachVerifiedCount,
  });

  final StackConfidence confidence;
  final int proofCount;
  final int selfReportedCount;
  final int coachVerifiedCount;

  static Future<void> show(
    BuildContext context, {
    required StackConfidence confidence,
    required int proofCount,
    required int selfReportedCount,
    required int coachVerifiedCount,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConfidenceExplanationSheet(
        confidence: confidence,
        proofCount: proofCount,
        selfReportedCount: selfReportedCount,
        coachVerifiedCount: coachVerifiedCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stackLines = ConfidenceExplainer.currentStackLines(
      selfReportedCount: selfReportedCount,
      coachVerifiedCount: coachVerifiedCount,
    );
    final tips = ConfidenceExplainer.strengthenTips(
      confidence: confidence,
      coachVerifiedCount: coachVerifiedCount,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: ConfidenceBadge(
                label: confidence.label,
                color: confidence.color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              confidence.label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: -0.3,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              ConfidenceExplainer.message(
                confidence: confidence,
                proofCount: proofCount,
                coachVerifiedCount: coachVerifiedCount,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkSecondary,
                    height: 1.55,
                  ),
            ),
            const SizedBox(height: 28),
            Text(
              'CURRENT PROOF STACK',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: AppColors.inkMuted,
                  ),
            ),
            const SizedBox(height: 12),
            ...stackLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'HOW TO STRENGTHEN THIS PROOF STACK',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: AppColors.inkMuted,
                  ),
            ),
            const SizedBox(height: 12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.accent,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.inkSecondary,
                              height: 1.45,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            ProofButton(
              label: 'Got it',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class TrustProgressBar extends StatelessWidget {
  const TrustProgressBar({
    super.key,
    required this.filledSegments,
    required this.totalSegments,
    required this.color,
    required this.statusMessage,
  });

  final int filledSegments;
  final int totalSegments;
  final Color color;
  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(totalSegments, (index) {
            final filled = index < filledSegments;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < totalSegments - 1 ? 4 : 0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: filled
                        ? color
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          statusMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSecondary,
              ),
        ),
      ],
    );
  }
}
