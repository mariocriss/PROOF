import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/experience/application/experience_diagnostics.dart';

/// In-app pipeline log for Experience Engine QA (debug builds).
class ExperienceDiagnosticsPanel extends ConsumerWidget {
  const ExperienceDiagnosticsPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(kDebugMode);
    final diagnostics = ref.watch(experienceDiagnosticsProvider);
    final entries = diagnostics.entries;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Pipeline diagnostics',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: entries.isEmpty
                      ? null
                      : () => ref.read(experienceDiagnosticsProvider).clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            if (!compact)
              Text(
                'EVENT CREATED → ELIGIBLE → RECEIPT CLAIMED → QUEUED → '
                'PRESENTATION REQUESTED → OVERLAY SHOWN → RECEIPT COMPLETED',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                'No events yet. Trigger a real flow or gallery preview.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              )
            else ...[
              if (ref.watch(experienceDiagnosticsProvider).lastFailure
                  case final failure?)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Last failure: ${failure.stage}\n${failure.error}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                  ),
                ),
              ...entries.take(compact ? 8 : 20).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${e.timeLabel}  ${e.kind.label}'
                        '${e.eventId.isNotEmpty ? '\n  ${e.eventId}' : ''}'
                        '${e.detail.isNotEmpty ? '\n  ${e.detail}' : ''}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              height: 1.35,
                              color: _colorFor(e.kind),
                            ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorFor(ExperienceDiagnosticKind kind) {
    return switch (kind) {
      ExperienceDiagnosticKind.eventRejected ||
      ExperienceDiagnosticKind.receiptFailed =>
        AppColors.error,
      ExperienceDiagnosticKind.overlayShown ||
      ExperienceDiagnosticKind.receiptCompleted =>
        const Color(0xFF2C6E49),
      _ => AppColors.ink,
    };
  }
}
