import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/shared/models/verification_request_model.dart';
import 'package:proof/shared/providers/people_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class VerificationRequestsScreen extends ConsumerWidget {
  const VerificationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(verificationRequestsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Verification Requests',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: requests.isEmpty
          ? const Center(child: Text('No verification requests yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _VerificationRequestTile(request: requests[index]);
              },
            ),
    );
  }
}

class _VerificationRequestTile extends StatelessWidget {
  const _VerificationRequestTile({required this.request});

  final VerificationRequestModel request;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (request.status) {
      VerificationRequestStatus.pending => 'Awaiting coach review',
      VerificationRequestStatus.approved => 'Approved',
      VerificationRequestStatus.declined => 'Declined',
      VerificationRequestStatus.rejected => 'Declined',
      VerificationRequestStatus.cancelled => 'Cancelled',
    };

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
            request.skillName.isNotEmpty ? request.skillName : 'Proof',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(request.resultLabel),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            ProofDateUtils.formatRelative(request.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
          if (request.displayDeclineReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${request.displayDeclineReason}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
