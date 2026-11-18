import 'package:flutter/material.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';

/// Full-viewport experience surface — replaces route focus during a moment.
class ExperienceStage extends StatelessWidget {
  const ExperienceStage({
    super.key,
    required this.child,
    this.onSkip,
    this.skippable = true,
    this.ctaLabel,
    this.onCta,
    this.ctaVisible = false,
    this.footer,
    this.secondaryAction,
  });

  final Widget child;
  final VoidCallback? onSkip;
  final bool skippable;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool ctaVisible;
  final Widget? footer;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ExperienceTokens.paperBackground,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ExperienceTokens.paperBackground,
              const Color(0xFFF3F0E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (skippable)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          ExperienceTokens.identityInk.withValues(alpha: 0.55),
                    ),
                    child: const Text('Skip'),
                  ),
                )
              else
                const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ExperienceTokens.spacingLg,
                  ),
                  child: Center(child: child),
                ),
              ),
              if (footer != null) footer!,
              if (secondaryAction != null) ...[
                const SizedBox(height: ExperienceTokens.spacingSm),
                secondaryAction!,
              ],
              if (ctaVisible && ctaLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ExperienceTokens.spacingLg,
                    ExperienceTokens.spacingSm,
                    ExperienceTokens.spacingLg,
                    ExperienceTokens.spacingLg,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ExperienceTokens.identityInk,
                        foregroundColor: ExperienceTokens.paperBackground,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onCta,
                      child: Text(ctaLabel!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
