import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);

    return Scaffold(
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
                  'Every proof, milestone and personal best becomes part of your lifelong physical identity.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.border,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (event.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                event.subtitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              ProofDateUtils.formatRelative(event.createdAt),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key, required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityByHandleProvider(handle));

    return identityAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: ProofAppBar(
          title: 'Passport',
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (identity) {
        if (identity == null) {
          return Scaffold(
            appBar: ProofAppBar(
              title: 'Passport',
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: const EmptyState(
              title: 'Identity not found',
              message: 'No public passport exists for this handle.',
            ),
          );
        }

        if (!identity.isPublic) {
          return Scaffold(
            appBar: ProofAppBar(
              title: 'Passport',
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: const EmptyState(
              title: 'Private identity',
              message: 'This physical identity is not publicly visible.',
            ),
          );
        }

        return Scaffold(
          appBar: ProofAppBar(
            title: 'Passport',
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'PHYSICAL IDENTITY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A lifelong record of verified physical capability.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      IdentityAvatar(
                        avatarUrl: identity.avatarUrl,
                        displayName: identity.displayName,
                        radius: 56,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        identity.displayName,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${identity.handle}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.accent,
                            ),
                      ),
                      if (identity.location.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(identity.location),
                      ],
                      if (identity.bio.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          identity.bio,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      Text(
                        'Member since ${ProofDateUtils.formatDate(identity.createdAt)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
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
