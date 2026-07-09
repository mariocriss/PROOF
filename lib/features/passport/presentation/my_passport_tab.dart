import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/features/passport/presentation/my_passport_screen.dart';

class MyPassportTab extends ConsumerWidget {
  const MyPassportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MyPassportScreen();
  }
}