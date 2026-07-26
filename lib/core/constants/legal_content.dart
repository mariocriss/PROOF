import 'package:proof/core/constants/app_urls.dart';

class LegalSection {
  const LegalSection({
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.introduction,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final String introduction;
  final List<LegalSection> sections;
}

/// In-app legal drafts aligned to the current launch build.
///
/// These are **not** formal legal advice or store-ready hosted policies.
/// Replace hosted URLs in [AppUrls] and have counsel review before production.
class LegalContent {
  LegalContent._();

  static const String lastUpdated = 'July 26, 2026';

  static const LegalDocument privacyPolicy = LegalDocument(
    title: 'Privacy Policy (in-app draft)',
    lastUpdated: lastUpdated,
    introduction:
        'PROOF helps you build a physical-identity profile with skills, proofs, '
        'and coach or gym relationships. This in-app draft describes data handled '
        'by the current launch build. It is informational only and is not a '
        'substitute for a reviewed Privacy Policy hosted on a domain you own.',
    sections: [
      LegalSection(
        title: 'Information we collect',
        paragraphs: [
          'Account information: email address and authentication credentials '
              'managed by Firebase Authentication (email/password).',
          'Profile and identity data you provide: display name, handle, role, '
              'optional location text, bio, skills, proofs, timeline events, and '
              'whether your profile is discoverable/public inside the app.',
          'Relationship data: friend requests and friendships, blocks, coach '
              'relationships, gym memberships, and verification requests between '
              'athletes and coaches.',
          'Trust and safety data: user reports you submit about other accounts '
              '(reason, optional details, and identifiers needed for review).',
          'Diagnostics: crash reports via Firebase Crashlytics in release builds. '
              'This launch build does not use Google Analytics.',
        ],
      ),
      LegalSection(
        title: 'Information we do not collect in this launch build',
        paragraphs: [
          'We do not operate in-app messaging or chat.',
          'We do not use Firebase Storage for photos or file uploads in this '
              'build (avatar, proof photo, and gym logo uploads are disabled).',
          'We do not request Health Connect access or continuous location '
              'permission. Any “location” on a profile is optional free text you type.',
        ],
      ),
      LegalSection(
        title: 'How we use information',
        paragraphs: [
          'We use your information to create and maintain your account, display '
              'your profile and proofs, enable friend/coach/gym features, process '
              'coach verifications, support blocking and reporting, and keep the '
              'service secure and stable.',
          'We do not sell your personal information.',
          'We use Google Firebase for authentication, Cloud Firestore, and '
              'Crashlytics infrastructure.',
        ],
      ),
      LegalSection(
        title: 'Sharing and visibility',
        paragraphs: [
          'Other signed-in users may see profile details according to your '
              'privacy settings, friendships, and coach or gym relationships.',
          'A public web passport page is not available until you configure an '
              'owned domain. In-app discoverability does not imply a public website.',
          'You can report other users from their profile. Reports are stored to '
              'help review abuse. If a reported account is deleted, public handles '
              'on reports are anonymized as described in our account-deletion docs.',
        ],
      ),
      LegalSection(
        title: 'Data retention and deletion',
        paragraphs: [
          'We retain your data while your account is active.',
          'You can delete your account from Account settings after confirming '
              'your password. Deletion removes your Firebase Authentication user '
              'and associated personal Firestore data after cleanup succeeds. '
              'Limited moderation records and historical verification markers may '
              'be retained as described in the account-deletion documentation.',
          'Cloud providers may retain backups for a limited period according to '
              'their infrastructure policies.',
        ],
      ),
      LegalSection(
        title: 'Your choices',
        paragraphs: [
          'You can update profile details, control discoverability, sign out, '
              'or delete your account in the app.',
          'Contact for privacy questions: mario-zderic@hotmail.com '
              '(Mario Zderic, The Netherlands). You can also use in-app Help '
              'or the Play Console support channel provided with the listing.',
        ],
      ),
      LegalSection(
        title: 'Children',
        paragraphs: [
          'PROOF is not directed to children under 13, and we do not knowingly '
              'collect personal information from children under 13.',
        ],
      ),
      LegalSection(
        title: 'Changes and hosted policy',
        paragraphs: [
          'We may update this draft as the product changes. Material store-facing '
              'policies are published at the hosted Privacy Policy URL configured '
              'in AppUrls (Firebase Hosting for project proof-e913a). '
              'Effective date of the hosted draft: July 26, 2026. '
              'This draft should receive legal review before public launch.',
        ],
      ),
    ],
  );

  static const LegalDocument termsOfService = LegalDocument(
    title: 'Terms of Service (in-app draft)',
    lastUpdated: lastUpdated,
    introduction:
        'These in-app Terms draft govern use of the current PROOF launch build. '
        'They are informational and not a substitute for reviewed Terms hosted '
        'on a domain you own.',
    sections: [
      LegalSection(
        title: 'Eligibility',
        paragraphs: [
          'You must be at least 13 years old and able to form a binding contract '
              'in your jurisdiction to use PROOF.',
        ],
      ),
      LegalSection(
        title: 'Your account',
        paragraphs: [
          'You are responsible for maintaining the security of your account and '
              'for activity that occurs under it.',
          'You agree to provide accurate information and keep your profile '
              'details reasonably up to date.',
        ],
      ),
      LegalSection(
        title: 'Proofs and content',
        paragraphs: [
          'You may add proofs and profile content that reflect your own '
              'achievements and training.',
          'Self-reported proofs are your responsibility. Coach-verified proofs '
              'represent a coach attestation within the app, not medical, legal, '
              'or professional advice.',
          'You must not publish content that is unlawful, harassing, misleading, '
              'or infringes the rights of others.',
        ],
      ),
      LegalSection(
        title: 'Acceptable use',
        paragraphs: [
          'You agree not to misuse PROOF, including by attempting unauthorized '
              'access, scraping, spamming, impersonation, or harassing other users.',
          'We may remove content, restrict features, or suspend accounts that '
              'violate these Terms or create risk for other users or the service.',
        ],
      ),
      LegalSection(
        title: 'Privacy',
        paragraphs: [
          'Our Privacy Policy draft explains how we handle personal information '
              'in this build. Hosted policies must be published before production '
              'listing when a domain is available.',
        ],
      ),
      LegalSection(
        title: 'Service availability',
        paragraphs: [
          'PROOF is provided on an "as is" and "as available" basis. Features may '
              'change, be suspended, or be discontinued. Some features (cloud photo '
              'storage, push notifications, public web passport) are disabled or '
              'unavailable in this launch configuration.',
          'We do not guarantee uninterrupted availability and are not liable for '
              'temporary outages or data loss beyond what is reasonably preventable.',
        ],
      ),
      LegalSection(
        title: 'Termination',
        paragraphs: [
          'You may stop using PROOF at any time and may delete your account from '
              'Account settings.',
          'We may suspend or terminate access if you materially breach these Terms.',
        ],
      ),
      LegalSection(
        title: 'Contact',
        paragraphs: [
          'Questions about these Terms: mario-zderic@hotmail.com. '
              'Operator: Mario Zderic. Governing law: The Netherlands. '
              'Effective date of the hosted draft: July 26, 2026. '
              'This draft should receive legal review before public launch.',
        ],
      ),
    ],
  );

  /// Shown above in-app legal documents when hosted URLs are missing.
  static String get hostedUrlBanner => AppUrls.hasPrivacyPolicyUrl
      ? AppUrls.hostedLegalReviewNotice
      : AppUrls.hostedLegalPlaceholderNotice;
}
