import 'package:flutter/material.dart';
import 'package:proof/core/constants/legal_constants.dart';
import 'package:proof/core/constants/legal_content.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: document.title,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
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
            'Questions? Email ${LegalConstants.supportEmail}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ],
      ),
    );
  }
}
