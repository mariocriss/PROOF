import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/providers/shell_providers.dart';

/// Keeps tab widgets mounted but skips heavy provider subscriptions off-tab.
class DeferredShellTab extends ConsumerWidget {
  const DeferredShellTab({
    super.key,
    required this.tabIndex,
    required this.builder,
  });

  final int tabIndex;
  final Widget Function(BuildContext context, WidgetRef ref) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeShellTabIndexProvider);
    if (!isShellTabActive(tabIndex, activeTab)) {
      return const ColoredBox(color: AppColors.background);
    }

    return builder(context, ref);
  }
}
