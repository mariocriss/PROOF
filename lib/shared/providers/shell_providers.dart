import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which bottom-nav tab is currently visible (0 = Dashboard … 4 = More).
final activeShellTabIndexProvider = StateProvider<int>((ref) => 0);

bool isShellTabActive(int tabIndex, int activeTabIndex) =>
    tabIndex == activeTabIndex;
