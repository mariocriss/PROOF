import 'package:flutter/material.dart';
import 'package:proof/core/constants/app_urls.dart';
import 'package:proof/core/constants/legal_constants.dart';
import 'package:proof/core/constants/legal_content.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalDocumentScreen(document: LegalContent.privacyPolicy);
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalDocumentScreen(document: LegalContent.termsOfService);
  }
}

class _LegalDocumentScreen extends StatelessWidget {
  const _LegalDocumentScreen({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: AppColors.ink,
        );
    final sectionTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final hostedUrl = document.title.contains('Privacy')
        ? AppUrls.privacyPolicyUrl
        : AppUrls.termsOfServiceUrl;
    final hasHosted = document.title.contains('Privacy')
        ? AppUrls.hasPrivacyPolicyUrl
        : AppUrls.hasTermsOfServiceUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: document.title,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              hasHosted
                  ? AppUrls.hostedLegalReviewNotice
                  : AppUrls.hostedLegalPlaceholderNotice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSecondary,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Last updated: ${document.lastUpdated}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
          const SizedBox(height: 16),
          Text(document.introduction, style: bodyStyle),
          for (final section in document.sections) ...[
            const SizedBox(height: 24),
            Text(section.title, style: sectionTitleStyle),
            const SizedBox(height: 8),
            for (final paragraph in section.paragraphs) ...[
              Text(paragraph, style: bodyStyle),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 24),
          Text(
            hasHosted
                ? 'Hosted version: $hostedUrl'
                : 'Hosted URL is not available in this build.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
          if (hasHosted) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(hostedUrl!);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('Open hosted version'),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Questions? ${LegalConstants.supportContactLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ],
      ),
    );
  }
}
