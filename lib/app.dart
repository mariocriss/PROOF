import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/router/app_router.dart';
import 'package:proof/core/theme/app_theme.dart';
import 'package:proof/features/experience/presentation/experience_overlay_host.dart';
import 'package:proof/features/experience/presentation/widgets/experience_debug_failure_banner.dart';

class ProofApp extends ConsumerWidget {
  const ProofApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PROOF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ExperienceOverlayHost(
              child: child ?? const SizedBox.shrink(),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ExperienceDebugFailureBanner(),
            ),
          ],
        );
      },
    );
  }
}
