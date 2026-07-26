import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/constants/app_constants.dart';
import 'package:proof/core/constants/app_features.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/passport/domain/passport_credential_view_data.dart';
import 'package:proof/features/passport/presentation/passport_share_service.dart';
import 'package:proof/features/passport/presentation/widgets/passport_credential_card.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/relationship_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/providers/people_providers.dart';

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
                  _SharePassportCard(
                    data: data,
                    identity: identity,
                    skills: skills,
                    proofs: proofs,
                    timeline: timeline,
                  ),
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

class _SharePassportCard extends ConsumerStatefulWidget {
  const _SharePassportCard({
    required this.data,
    required this.identity,
    required this.skills,
    required this.proofs,
    required this.timeline,
  });

  final PassportCredentialViewData data;
  final PhysicalIdentity identity;
  final List<SkillModel> skills;
  final List<ProofModel> proofs;
  final List<TimelineEvent> timeline;

  @override
  ConsumerState<_SharePassportCard> createState() => _SharePassportCardState();
}

class _SharePassportCardState extends ConsumerState<_SharePassportCard> {
  bool _exporting = false;

  Future<({String? gymName, String? coachName})> _resolveContext() async {
    String? gymName;
    String? coachName;

    final memberships =
        ref.read(userGymMembershipsProvider).valueOrNull ?? [];
    final approvedAthlete = memberships.where(
      (m) =>
          m.membershipType == GymMembershipType.athlete &&
          m.status == GymMembershipStatus.approved,
    );
    if (approvedAthlete.isNotEmpty) {
      final gym =
          await ref.read(gymProvider(approvedAthlete.first.gymId).future);
      gymName = gym?.name;
    }

    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    final relationships = ref.read(relationshipsProvider).valueOrNull ?? [];
    if (userId != null) {
      final coachRel = relationships.where(
        (r) =>
            r.type == RelationshipType.coach &&
            r.status == RelationshipStatus.accepted &&
            r.fromUserId == userId,
      );
      if (coachRel.isNotEmpty) {
        final coachId = coachRel.first.toUserId;
        final coach = await ref.read(coachProfileProvider(coachId).future);
        coachName = coach?.displayName;
        if (coachName == null || coachName.isEmpty) {
          final identity =
              await ref.read(identityByUserIdProvider(coachId).future);
          coachName = identity?.displayName;
        }
      }
    }

    return (gymName: gymName, coachName: coachName);
  }

  Future<void> _downloadPdf() async {
    if (_exporting || PassportShareService.isPdfExportInProgress) return;
    setState(() => _exporting = true);
    try {
      final contextNames = await _resolveContext();
      if (!mounted) return;
      await PassportShareService.sharePdf(
        context: context,
        identity: widget.identity,
        skills: widget.skills,
        proofs: widget.proofs,
        timeline: widget.timeline,
        gymName: contextNames.gymName,
        coachName: contextNames.coachName,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

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
            AppFeatures.publicWebPassportEnabled
                ? 'Share your Physical Identity with coaches, employers or partners.'
                : 'Export a PDF snapshot of your Physical Identity. '
                    'Public web links and QR codes are unavailable until an owned domain is configured.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (AppFeatures.publicWebPassportEnabled) ...[
                Expanded(
                  child: _ShareTile(
                    icon: Icons.qr_code_2_outlined,
                    label: 'QR Code',
                    onTap: () =>
                        PassportShareService.showQrCode(context, widget.data),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShareTile(
                    icon: Icons.link,
                    label: 'Share Link',
                    onTap: () => PassportShareService.shareLink(widget.data),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _ShareTile(
                  icon: Icons.download_outlined,
                  label: _exporting ? 'Preparing…' : 'Download PDF',
                  onTap: _exporting ? null : _downloadPdf,
                  busy: _exporting,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareTile(
                  icon: Icons.more_horiz,
                  label: 'More Options',
                  onTap: () async {
                    final contextNames = await _resolveContext();
                    if (!context.mounted) return;
                    PassportShareService.showMoreOptions(
                      context: context,
                      data: widget.data,
                      skills: widget.skills,
                      proofs: widget.proofs,
                      timeline: widget.timeline,
                      gymName: contextNames.gymName,
                      coachName: contextNames.coachName,
                    );
                  },
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
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;

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
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  icon,
                  color: onTap == null ? AppColors.inkMuted : AppColors.accent,
                  size: 22,
                ),
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
