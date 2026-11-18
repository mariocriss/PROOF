import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/experience/application/experience_diagnostics.dart';

/// Debug-only banner when the experience pipeline fails.
class ExperienceDebugFailureBanner extends ConsumerWidget {
  const ExperienceDebugFailureBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    final failure = ref.watch(experienceDiagnosticsProvider).lastFailure;
    if (failure == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.error.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Experience pipeline failed at ${failure.stage}\n'
                  '${failure.eventId}\n'
                  '${failure.error}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: () {
                  ref.read(experienceDiagnosticsProvider).dismissFailureBanner();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
