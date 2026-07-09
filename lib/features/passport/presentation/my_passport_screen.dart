import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/constants/app_constants.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/passport/domain/passport_credential_view_data.dart';
import 'package:proof/features/passport/presentation/passport_share_service.dart';
import 'package:proof/features/passport/presentation/widgets/passport_credential_card.dart';
import 'package:proof/shared/providers/app_providers.dart';

class MyPassportScreen extends ConsumerWidget {
  const MyPassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(physicalIdentityProvider);
    final skillsAsync = ref.watch(skillsProvider);
    final proofsAsync = ref.watch(proofsProvider);
    final timelineAsync = ref.watch(timelineProvider);

    return identityAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e')),
      ),
      data: (identity) {
        if (identity == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final skills = skillsAsync.valueOrNull ?? [];
        final proofs = proofsAsync.valueOrNull ?? [];
        final timeline = timelineAsync.valueOrNull ?? [];

        final data = PassportCredentialViewData.build(
          identity: identity,
          skills: skills,
          proofs: proofs,
          timeline: timeline,
          publicUrl: AppConstants.passportUrl(identity.handle),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PassportHeader(data: data),
                  const SizedBox(height: 24),
                  PassportCredentialCard(data: data),
                  const SizedBox(height: 28),
                  const PassportSectionLabel(title: 'TRUST INDICATORS'),
                  _TrustIndicatorsCard(indicators: data.trustIndicators),
                  const SizedBox(height: 28),
                  const PassportSectionLabel(title: 'SHARE PASSPORT'),
                  _SharePassportCard(data: data),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PassportHeader extends StatelessWidget {
  const _PassportHeader({required this.data});

  final PassportCredentialViewData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Passport',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: AppColors.ink,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your Physical Identity. Proven.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => PassportShareService.shareLink(data),
          icon: const Icon(Icons.ios_share_outlined),
          color: AppColors.ink,
          tooltip: 'Share passport',
        ),
      ],
    );
  }
}

class _TrustIndicatorsCard extends StatelessWidget {
  const _TrustIndicatorsCard({required this.indicators});

  final PassportTrustIndicators indicators;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _TrustColumn(
                icon: Icons.verified_user_outlined,
                label: 'Coach Verified',
                value: indicators.coachVerified,
              ),
            ),
            _divider(),
            Expanded(
              child: _TrustColumn(
                icon: Icons.calendar_today_outlined,
                label: 'Identity Age',
                value: indicators.identityAge,
              ),
            ),
            _divider(),
            Expanded(
              child: _TrustColumn(
                icon: Icons.star_outline,
                label: 'Latest Milestone',
                value: indicators.latestMilestone,
              ),
            ),
            _divider(),
            Expanded(
              child: _TrustColumn(
                icon: Icons.track_changes_outlined,
                label: 'Most Consistent',
                value: indicators.mostConsistent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      color: AppColors.divider,
    );
  }
}

class _TrustColumn extends StatelessWidget {
  const _TrustColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.inkMuted),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _SharePassportCard extends StatelessWidget {
  const _SharePassportCard({required this.data});

  final PassportCredentialViewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Share your Physical Identity with coaches, employers or partners.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ShareTile(
                  icon: Icons.qr_code_2_outlined,
                  label: 'QR Code',
                  onTap: () => PassportShareService.showQrCode(context, data),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareTile(
                  icon: Icons.link,
                  label: 'Share Link',
                  onTap: () => PassportShareService.shareLink(data),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareTile(
                  icon: Icons.download_outlined,
                  label: 'Download PDF',
                  onTap: () => PassportShareService.sharePdf(data),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareTile(
                  icon: Icons.more_horiz,
                  label: 'More Options',
                  onTap: () =>
                      PassportShareService.showMoreOptions(context, data),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accent, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
