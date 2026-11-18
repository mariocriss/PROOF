import 'package:flutter/material.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';

/// Quiet hold before a stamp or witness mark — no visual spectacle.
class SilentMoment extends StatelessWidget {
  const SilentMoment({
    super.key,
    required this.child,
    this.reduceMotion = false,
    this.duration = ExperienceTokens.pauseMax,
  });

  final Widget child;
  final bool reduceMotion;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: duration,
      curve: ExperienceTokens.primaryCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
