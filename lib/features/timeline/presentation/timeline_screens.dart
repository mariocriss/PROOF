import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Timeline',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyState(
              title: 'Your story starts here.',
              message:
                  'Every milestone, personal best and verified achievement becomes part of your lifelong physical identity.',
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              final showYearHeader = _shouldShowYearHeader(events, index);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showYearHeader) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: 20, top: index == 0 ? 8 : 28),
                      child: Text(
                        '${event.createdAt.year}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.inkMuted,
                              letterSpacing: 1.5,
                            ),
                      ),
                    ),
                  ],
                  _TimelineStoryEntry(
                    event: event,
                    isLast: isLast,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _shouldShowYearHeader(List<TimelineEvent> events, int index) {
    if (index == 0) return true;
    return events[index].createdAt.year != events[index - 1].createdAt.year;
  }
}

class _TimelineStoryEntry extends StatelessWidget {
  const _TimelineStoryEntry({
    required this.event,
    required this.isLast,
  });

  final TimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = event.type.accentColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(event.type.icon, size: 16, color: accent),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          letterSpacing: -0.3,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (event.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.inkSecondary,
                            height: 1.4,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    ProofDateUtils.formatDate(event.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                          letterSpacing: 0.3,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
