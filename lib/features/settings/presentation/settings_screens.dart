import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/constants/app_constants.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(physicalIdentityProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Settings',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'ACCOUNT',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.inkSecondary,
                ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            title: 'Edit profile',
            subtitle: identity != null ? '@${identity.handle}' : 'Update your identity',
            onTap: () => context.push('/edit-profile'),
          ),
          _SettingsTile(
            title: 'Privacy settings',
            subtitle: 'Control discoverability and public profile',
            onTap: () => context.push('/privacy-settings'),
          ),
          const SizedBox(height: 32),
          Text(
            'LEGAL',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.inkSecondary,
                ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            title: 'Privacy Policy',
            subtitle: 'View in app',
            onTap: () => context.push('/privacy-policy'),
          ),
          _SettingsTile(
            title: 'Terms of Service',
            subtitle: 'View in app',
            onTap: () => context.push('/terms'),
          ),
          const SizedBox(height: 32),
          Text(
            'SUPPORT',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.inkSecondary,
                ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            title: 'FAQ',
            subtitle: 'How PROOF works',
            onTap: () => context.push('/faq'),
          ),
          const SizedBox(height: 32),
          ProofButton(
            label: 'Sign out',
            isOutlined: true,
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'FAQ',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        children: const [
          _FaqItem(
            question: 'What is PROOF?',
            answer:
                'PROOF is a physical identity platform. It helps you document, verify, and present your real-world athletic capabilities over a lifetime.',
          ),
          _FaqItem(
            question: 'What is a Proof Stack?',
            answer:
                'Each skill has exactly one Proof Stack — the lifetime collection of every proof recorded for that capability. The stack grows over time and automatically calculates current best, confidence, and trend.',
          ),
          _FaqItem(
            question: 'What is the difference between a Skill and a Proof?',
            answer:
                'A Skill is a capability you track, like push-ups. A Proof is evidence of a specific performance. Starting a new capability creates a Skill. Recording another result creates a Proof inside that skill\'s stack.',
          ),
          _FaqItem(
            question: 'What is the Timeline?',
            answer:
                'Your timeline tells the story of meaningful milestones in your journey — personal bests, verified achievements, and identity moments — not every single upload.',
          ),
          _FaqItem(
            question: 'What is the Passport?',
            answer:
                'Your public passport is a shareable view of your physical identity — who you are, what you can do, and how well it is supported by evidence.',
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'About',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        children: [
          const Center(child: ProofMotto()),
          const SizedBox(height: 32),
          Text(
            'PROOF is a physical identity platform. It helps you document what you can actually do, build evidence over time, and present a credible record of your athletic capabilities — not just a workout log.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 36),
          Text(
            'HOW IT WORKS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.inkSecondary,
                ),
          ),
          const SizedBox(height: 16),
          const _AboutItem(
            title: 'Skills',
            body:
                'Skills are the capabilities you track — push-ups, a 5K, a back squat, and more. Each skill belongs to a discipline and owns exactly one Proof Stack for its lifetime evidence.',
          ),
          const _AboutItem(
            title: 'Proofs',
            body:
                'A proof is documented evidence for a skill: your result, when it happened, optional media, and how it was verified. Every new result becomes another proof in that skill\'s stack. Current best, confidence, and trend are never entered manually — they are always calculated from the stack.',
          ),
          const _AboutItem(
            title: 'Proof Stack',
            body:
                'Each skill has one Proof Stack — the complete collection of every proof ever recorded for that capability. The stack grows over time and automatically calculates current best, confidence, trend, and last updated.',
          ),
          const _AboutItem(
            title: 'Timeline',
            body:
                'The timeline captures meaningful milestones in your journey — personal bests, verified achievements, and identity moments — not every upload or edit.',
          ),
          const _AboutItem(
            title: 'Passport',
            body:
                'Your public passport is a shareable view of your physical identity: who you are, what you can do, how many disciplines you represent, and how well your capabilities are supported by evidence.',
          ),
          const SizedBox(height: 12),
          Text(
            'CONFIDENCE & VERIFICATION',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.inkSecondary,
                ),
          ),
          const SizedBox(height: 16),
          const _AboutItem(
            title: 'Verification',
            body:
                'When you add proof, choose how it was verified: self-reported or coach verified. Self-reported proofs document your own result. Coach verified proofs carry more weight in your stack confidence because a coach attests to the performance.',
          ),
          const _AboutItem(
            title: 'Disciplines',
            body:
                'Disciplines are broad training categories across your skills — for example, three skills like push-ups, pull-ups, and back squat all count as one discipline (Strength) in your identity summary.',
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '${AppConstants.appName} · Physical Identity Platform\nVersion $_version',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
