import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/timeline/domain/timeline_view_data.dart';
import 'package:proof/features/timeline/presentation/timeline_event_detail_sheet.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  TimelineFilter _filter = TimelineFilter.all;

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(timelineProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: timelineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (events) {
            final filtered = TimelineViewData.filter(events, _filter);
            final groups = TimelineViewData.groupByMonth(filtered);

            if (events.isEmpty) {
              return _TimelineEmptyState(
                onAddProof: () => context.push('/proofs/add'),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TimelineHeader(
                          onFilterTap: () => _showFilterSheet(context),
                        ),
                        const SizedBox(height: 24),
                        _TimelineFilterChips(
                          selected: _filter,
                          onSelected: (value) =>
                              setState(() => _filter = value),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No events in this category yet.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.inkSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          var cursor = 0;
                          for (final group in groups) {
                            if (index == cursor) {
                              return _TimelineMonthHeader(label: group.label);
                            }
                            cursor++;

                            for (var i = 0; i < group.events.length; i++) {
                              if (index == cursor) {
                                final event = group.events[i];
                                final isLastInTimeline =
                                    _isLastEvent(groups, group, i);
                                return _TimelineEntry(
                                  event: event,
                                  showConnector: !isLastInTimeline,
                                  onTap: () => TimelineEventDetailSheet.show(
                                    context,
                                    event,
                                  ),
                                );
                              }
                              cursor++;
                            }
                          }
                          return null;
                        },
                        childCount: _itemCount(groups),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _itemCount(List<TimelineMonthGroup> groups) {
    var count = 0;
    for (final group in groups) {
      count += 1 + group.events.length;
    }
    return count;
  }

  bool _isLastEvent(
    List<TimelineMonthGroup> groups,
    TimelineMonthGroup group,
    int eventIndex,
  ) {
    final isLastGroup = identical(group, groups.last);
    final isLastEventInGroup = eventIndex == group.events.length - 1;
    return isLastGroup && isLastEventInGroup;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filter timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                ...TimelineFilter.values.map(
                  (filter) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(filter.label),
                    trailing: _filter == filter
                        ? const Icon(Icons.check, color: AppColors.accent)
                        : null,
                    onTap: () {
                      setState(() => _filter = filter);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.onFilterTap});

  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your journey, in moments that matter.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onFilterTap,
          icon: const Icon(Icons.tune_outlined, color: AppColors.inkMuted),
          splashRadius: 22,
        ),
      ],
    );
  }
}

class _TimelineFilterChips extends StatelessWidget {
  const _TimelineFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final TimelineFilter selected;
  final ValueChanged<TimelineFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: TimelineFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onSelected(filter),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  child: Text(
                    filter.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.inkSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TimelineMonthHeader extends StatelessWidget {
  const _TimelineMonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.event,
    required this.showConnector,
    required this.onTap,
  });

  final TimelineEvent event;
  final bool showConnector;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final major = TimelineViewData.isMajorEvent(event);
    final accent = event.type.accentColor;
    final iconSize = major ? 40.0 : 32.0;
    final iconGlyph = major ? 20.0 : 16.0;
    final bottomPadding = major ? 28.0 : 22.0;
    final accentSubtitle = TimelineViewData.subtitleUsesAccent(event);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        event.type.icon,
                        size: iconGlyph,
                        color: accent,
                      ),
                    ),
                    if (showConnector)
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: (major
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.titleSmall)
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (event.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: accentSubtitle
                                  ? AppColors.accent
                                  : AppColors.inkSecondary,
                              fontWeight: accentSubtitle
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ProofDateUtils.formatTimelineDate(event.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState({required this.onAddProof});

  final VoidCallback onAddProof;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your journey, in moments that matter.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.4,
                    ),
              ),
              const Spacer(),
          Text(
            'Your story starts here.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Every proof, milestone and verification becomes part of your lifelong Physical Identity.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ProofButton(
            label: 'Add your first Proof',
            onPressed: onAddProof,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
