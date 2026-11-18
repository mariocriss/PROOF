import 'package:flutter/material.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';

/// Distinct Registrar voice — monogram seal + vellum message panel.
class RegistrarPanel extends StatelessWidget {
  const RegistrarPanel({
    super.key,
    required this.primary,
    this.secondary,
    this.visible = true,
    this.compact = false,
  });

  final String primary;
  final String? secondary;
  final bool visible;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!visible || primary.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Semantics(
      label: [
        'PROOF Registrar',
        primary,
        if (secondary != null && secondary!.isNotEmpty) secondary!,
      ].join('. '),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: ExperienceTokens.vellumOverlay,
          borderRadius: BorderRadius.circular(ExperienceTokens.cornerRadiusSoft),
          border: Border.all(
            color: ExperienceTokens.identityInk.withValues(alpha: 0.10),
          ),
          boxShadow: ExperienceTokens.contactShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RegistrarMonogram(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROOF Registrar',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ExperienceTokens.identityInk.withValues(alpha: 0.50),
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    primary,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ExperienceTokens.identityInk,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      fontSize: compact ? 15 : null,
                    ),
                  ),
                  if (secondary != null && secondary!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      secondary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ExperienceTokens.recordInk.withValues(alpha: 0.72),
                        height: 1.4,
                        fontSize: compact ? 13 : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed Registrar monogram / seal mark.
class RegistrarMonogram extends StatelessWidget {
  const RegistrarMonogram({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ExperienceTokens.identityInk.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: ExperienceTokens.identityInk.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'PR',
        style: TextStyle(
          color: ExperienceTokens.identityInk.withValues(alpha: 0.72),
          fontSize: size * 0.28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Back-compat alias — prefer [RegistrarPanel].
class ExperienceGuideCaption extends RegistrarPanel {
  const ExperienceGuideCaption({
    super.key,
    required super.primary,
    super.secondary,
    super.visible,
  });
}
