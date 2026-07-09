import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/confidence_progress_segments.dart';
import 'package:proof/features/passport/domain/passport_credential_view_data.dart';

class PassportCredentialCard extends StatelessWidget {
  const PassportCredentialCard({super.key, required this.data});

  final PassportCredentialViewData data;

  @override
  Widget build(BuildContext context) {
    final identity = data.identity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F3A31),
            AppColors.accent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: 20,
            child: Icon(
              Icons.shield_outlined,
              size: 120,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        backgroundImage: identity.avatarUrl != null
                            ? NetworkImage(identity.avatarUrl!)
                            : null,
                        child: identity.avatarUrl == null
                            ? Text(
                                identity.displayName.isNotEmpty
                                    ? identity.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 12,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          identity.displayName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                data.identityBadgeLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Since ${identity.createdAt.year}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'PHYSICAL IDENTITY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      letterSpacing: 1.4,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                data.overallConfidence.label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 12),
              _CredentialProgressBar(filled: data.filledSegments),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _CredentialStat(
                      value: '${data.skillsCount}',
                      label: 'Skills',
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _CredentialStat(
                      value: '${data.proofsCount}',
                      label: 'Proofs',
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _CredentialStat(
                      value: '${data.coachVerifiedCount}',
                      label: 'Coach Verified',
                      showShield: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _CredentialProgressBar extends StatelessWidget {
  const _CredentialProgressBar({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    const total = ConfidenceProgressSegments.segmentCount;
    return Row(
      children: List.generate(total, (index) {
        final isFilled = index < filled;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: isFilled
                    ? const Color(0xFF9BC4B0)
                    : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CredentialStat extends StatelessWidget {
  const _CredentialStat({
    required this.value,
    required this.label,
    this.showShield = false,
  });

  final String value;
  final String label;
  final bool showShield;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showShield) ...[
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
        ),
      ],
    );
  }
}

class PassportSectionLabel extends StatelessWidget {
  const PassportSectionLabel({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.inkMuted,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
