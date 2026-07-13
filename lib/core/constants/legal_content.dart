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

class LegalContent {
  LegalContent._();

  static const String lastUpdated = 'July 13, 2026';

  static const LegalDocument privacyPolicy = LegalDocument(
    title: 'Privacy Policy',
    lastUpdated: lastUpdated,
    introduction:
        'PROOF ("we", "us", or "our") helps you build and share a verified '
        'physical identity. This Privacy Policy explains what information we '
        'collect, how we use it, and the choices you have.',
    sections: [
      LegalSection(
        title: 'Information we collect',
        paragraphs: [
          'Account information: email address and authentication credentials '
              'managed by Firebase Authentication.',
          'Profile and identity data: display name, handle, role, location, '
              'bio, skills, proofs, timeline events, and privacy preferences '
              'such as whether your profile is public.',
          'Social data: friend requests, connections, coach relationships, gym '
              'memberships, and messages you send within the app.',
          'Usage data: app interactions needed to operate core features, plus '
              'crash reports in release builds to improve stability.',
        ],
      ),
      LegalSection(
        title: 'How we use information',
        paragraphs: [
          'We use your information to create and maintain your account, display '
              'your physical identity, enable social features, process coach '
              'verifications, and keep the service secure.',
          'We do not sell your personal information.',
          'We may use service providers such as Google Firebase to host '
              'authentication, database, and crash reporting infrastructure.',
        ],
      ),
      LegalSection(
        title: 'Sharing and visibility',
        paragraphs: [
          'Your public profile, passport link, and people-search listing are '
              'visible to others only when your profile is set to public in '
              'Privacy settings.',
          'Friends and coaches may see additional profile details according to '
              'your connections and app features.',
          'You can report other users from their profile. Reports are stored to '
              'help us review abuse.',
        ],
      ),
      LegalSection(
        title: 'Data retention and deletion',
        paragraphs: [
          'We retain your data while your account is active.',
          'You can delete your account from Account settings. Deletion removes '
              'your authentication account and associated Firestore data, '
              'including profile, proofs, relationships, and reports you '
              'submitted, subject to limited backup retention by our providers.',
        ],
      ),
      LegalSection(
        title: 'Your choices',
        paragraphs: [
          'You can update profile details, control discoverability, sign out, '
              'or delete your account at any time.',
          'You can contact us at support@proof.app with privacy questions or '
              'requests.',
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
        title: 'Changes',
        paragraphs: [
          'We may update this policy from time to time. Material changes will '
              'be reflected in the in-app version and updated date shown above.',
        ],
      ),
    ],
  );

  static const LegalDocument termsOfService = LegalDocument(
    title: 'Terms of Service',
    lastUpdated: lastUpdated,
    introduction:
        'These Terms of Service ("Terms") govern your use of PROOF. By creating '
        'an account or using the app, you agree to these Terms.',
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
          'You must not upload or publish content that is unlawful, harassing, '
              'misleading, or infringes the rights of others.',
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
          'Our Privacy Policy explains how we handle personal information. By '
              'using PROOF, you also agree to the Privacy Policy.',
        ],
      ),
      LegalSection(
        title: 'Service availability',
        paragraphs: [
          'PROOF is provided on an "as is" and "as available" basis. Features may '
              'change, be suspended, or be discontinued.',
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
          'Questions about these Terms can be sent to support@proof.app.',
        ],
      ),
    ],
  );
}
