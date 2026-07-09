import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';

class ConfidenceBlockProgress extends StatelessWidget {
  const ConfidenceBlockProgress({
    super.key,
    required this.filled,
    required this.total,
    this.segmentWidth = 15,
    this.height = 8,
    this.gap = 4,
  });

  final int filled;
  final int total;
  final double segmentWidth;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final isFilled = index < filled;
        return Padding(
          padding: EdgeInsets.only(right: index < total - 1 ? gap : 0),
          child: Container(
            width: segmentWidth,
            height: height,
            decoration: BoxDecoration(
              color: isFilled
                  ? AppColors.accent
                  : AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      }),
    );
  }
}
