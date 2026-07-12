import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/shared/models/verification_request_model.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class CoachVerificationQueueScreen extends ConsumerWidget {
  const CoachVerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(coachVerificationQueueProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Verification Queue',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: queue.isEmpty
          ? const Center(child: Text('No pending verification requests'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: queue.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _QueueCard(request: queue[index]);
              },
            ),
    );
  }
}

class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.request});

  final VerificationRequestModel request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athleteAsync = ref.watch(identityByUserIdProvider(request.athleteId));

    return athleteAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (athlete) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                athlete?.displayName ?? 'Athlete',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                request.skillName.isNotEmpty
                    ? request.skillName
                    : 'Proof request',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(request.resultLabel),
              if (request.variantName.isNotEmpty)
                Text(
                  request.variantName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              if (request.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Location: ${request.location}'),
              ],
              if (request.gymId.isNotEmpty) ...[
                const SizedBox(height: 4),
                _GymLabel(gymId: request.gymId),
              ],
              const SizedBox(height: 4),
              Text(
                ProofDateUtils.formatRelative(
                  request.recordedAt ?? request.createdAt,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              if (request.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(request.message),
              ],
              if (request.mediaUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    request.mediaUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ProofButton(
                      label: 'Verify',
                      onPressed: () async {
                        await ref
                            .read(firestoreServiceProvider)
                            .approveVerificationRequest(request.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Proof verified')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ProofButton(
                      label: 'Decline',
                      isOutlined: true,
                      onPressed: () => _reject(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject verification'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Optional note',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, noteController.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (note == null) return;

    final coachId = ref.read(authStateProvider).valueOrNull?.uid;
    if (coachId == null) return;

    await ref.read(firestoreServiceProvider).rejectVerificationRequest(
          requestId: request.id,
          rejectionNote: note,
          coachId: coachId,
        );
  }
}

class _GymLabel extends ConsumerWidget {
  const _GymLabel({required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymAsync = ref.watch(gymProvider(gymId));
    return gymAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (gym) => Text(
        gym?.name ?? 'Gym',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
      ),
    );
  }
}

class CoachAthletesScreen extends ConsumerWidget {
  const CoachAthletesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;
    final relationships = ref.watch(relationshipsProvider).valueOrNull ?? [];
    final athletes =
        userId == null ? [] : myAthletes(relationships, userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'My Athletes',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: athletes.isEmpty
          ? const Center(child: Text('No athletes connected yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: athletes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final athleteId = athletes[index].fromUserId;
                return _AthleteTile(athleteId: athleteId);
              },
            ),
    );
  }
}

class _AthleteTile extends ConsumerWidget {
  const _AthleteTile({required this.athleteId});

  final String athleteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityByUserIdProvider(athleteId));
    return identityAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (identity) {
        if (identity == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: identity.avatarUrl != null
                    ? NetworkImage(identity.avatarUrl!)
                    : null,
                child: identity.avatarUrl == null
                    ? Text(identity.displayName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text('@${identity.handle}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CoachVerifiedProofsScreen extends ConsumerWidget {
  const CoachVerifiedProofsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofs =
        ref.watch(coachApprovedVerificationsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Verified Proofs',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: proofs.isEmpty
          ? const Center(child: Text('No verified proofs yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: proofs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final proof = proofs[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proof.skillName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(proof.resultLabel),
                      const SizedBox(height: 4),
                      Text(
                        ProofDateUtils.formatRelative(proof.reviewedAt ?? proof.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
