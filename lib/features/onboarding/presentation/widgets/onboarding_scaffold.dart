import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/onboarding_paths.dart';
import 'package:proof/shared/models/onboarding_step.dart';
import 'package:proof/shared/models/user_role.dart';
import 'package:proof/shared/providers/app_providers.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && onBack != null) onBack!();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: onBack == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
          automaticallyImplyLeading: onBack != null,
          actions: trailing != null ? [trailing!] : null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 28),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> navigateOnboardingBack({
  required WidgetRef ref,
  required BuildContext context,
  required OnboardingStep currentStep,
  required UserRole accountType,
  required Future<void> Function() saveDraft,
}) async {
  final route = OnboardingPaths.previousRoute(
    step: currentStep,
    role: accountType,
  );
  if (route == null) return;

  if (context.mounted) {
    context.go(route);
  }

  try {
    await saveDraft();
    final user = ref.read(authServiceProvider).currentUser;
    final previous = OnboardingStep.previousFor(currentStep, accountType);
    if (user != null && previous != null) {
      await ref.read(firestoreServiceProvider).updateOnboardingProgress(
            userId: user.uid,
            onboardingStep: previous,
          );
    }
  } catch (_) {
    // Navigation already happened; draft sync can retry on next continue.
  }
}
