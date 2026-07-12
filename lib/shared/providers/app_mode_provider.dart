import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode {
  athlete,
  coach,
  gymManager,
}

final activeAppModeProvider = StateProvider<AppMode?>((ref) => null);
