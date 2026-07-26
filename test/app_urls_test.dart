import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/constants/app_features.dart';
import 'package:proof/core/constants/app_url_policy.dart';
import 'package:proof/core/constants/app_urls.dart';

void main() {
  group('launch AppUrls (repository defaults)', () {
    test('does not point at third-party proof.app domains', () {
      expect(AppUrls.websiteBaseUrl, isNot(contains('proof.app')));
      expect(AppUrls.privacyPolicyUrl, isNot(contains('proof.app')));
      expect(AppUrls.termsOfServiceUrl, isNot(contains('proof.app')));
      expect(AppUrls.accountDeletionUrl, isNot(contains('proof.app')));
      expect(AppUrls.publicPassportBaseUrl, isNull);
      expect(AppUrls.supportEmail, 'mario-zderic@hotmail.com');
    });

    test('Firebase Hosting legal URLs use detected project id', () {
      expect(AppUrls.firebaseProjectId, 'proof-e913a');
      expect(AppUrls.websiteBaseUrl, 'https://proof-e913a.web.app');
      expect(AppUrls.privacyPolicyUrl, 'https://proof-e913a.web.app/privacy/');
      expect(AppUrls.termsOfServiceUrl, 'https://proof-e913a.web.app/terms/');
      expect(
        AppUrls.accountDeletionUrl,
        'https://proof-e913a.web.app/delete-account/',
      );
      expect(AppUrls.hasWebsite, isTrue);
      expect(AppUrls.hasPrivacyPolicyUrl, isTrue);
      expect(AppUrls.hasTermsOfServiceUrl, isTrue);
      expect(AppUrls.hasAccountDeletionUrl, isTrue);
      expect(AppUrls.hasSupportEmail, isTrue);
      expect(AppUrls.publicWebPassportEnabled, isFalse);
      expect(AppFeatures.publicWebPassportEnabled, isFalse);
      expect(AppUrls.passportUrlForHandle('mario'), isNull);
    });
  });

  group('AppUrlPolicy absent states', () {
    test('rejects null, empty, http, and hostless values', () {
      expect(AppUrlPolicy.isHttpsUrl(null), isFalse);
      expect(AppUrlPolicy.isHttpsUrl(''), isFalse);
      expect(AppUrlPolicy.isHttpsUrl('   '), isFalse);
      expect(AppUrlPolicy.isHttpsUrl('http://example.com/privacy'), isFalse);
      expect(AppUrlPolicy.isHttpsUrl('https://'), isFalse);
      expect(AppUrlPolicy.isHttpsUrl('not-a-url'), isFalse);
      expect(AppUrlPolicy.passportUrlForHandle(baseUrl: null, handle: 'a'), isNull);
      expect(
        AppUrlPolicy.passportUrlForHandle(
          baseUrl: 'https://example.com/passport',
          handle: '  ',
        ),
        isNull,
      );
    });

    test('rejects placeholder support emails', () {
      expect(AppUrlPolicy.isConfiguredSupportEmail(null), isFalse);
      expect(AppUrlPolicy.isConfiguredSupportEmail(''), isFalse);
      expect(
        AppUrlPolicy.isConfiguredSupportEmail('SUPPORT_EMAIL_NOT_CONFIGURED'),
        isFalse,
      );
      expect(
        AppUrlPolicy.isConfiguredSupportEmail('REPLACE_ME@example.com'),
        isFalse,
      );
      expect(AppUrlPolicy.isConfiguredSupportEmail('nodomain'), isFalse);
    });
  });

  group('AppUrlPolicy configured states', () {
    test('accepts owned https legal and website URLs', () {
      expect(
        AppUrlPolicy.isHttpsUrl('https://example.com'),
        isTrue,
      );
      expect(
        AppUrlPolicy.isHttpsUrl('https://example.com/privacy'),
        isTrue,
      );
      expect(
        AppUrlPolicy.isHttpsUrl('https://example.com/terms'),
        isTrue,
      );
      expect(
        AppUrlPolicy.isHttpsUrl('https://example.com/account-deletion'),
        isTrue,
      );
      expect(
        AppUrlPolicy.canLaunchExternalUrl('https://example.com/privacy'),
        isTrue,
      );
    });

    test('builds passport URLs only from https base', () {
      expect(
        AppUrlPolicy.passportUrlForHandle(
          baseUrl: 'https://example.com/passport/',
          handle: '@Mario',
        ),
        'https://example.com/passport/Mario',
      );
      expect(
        AppUrlPolicy.passportUrlForHandle(
          baseUrl: 'http://example.com/passport',
          handle: 'mario',
        ),
        isNull,
      );
    });

    test('accepts a normal support inbox', () {
      expect(
        AppUrlPolicy.isConfiguredSupportEmail('hello@example.com'),
        isTrue,
      );
    });
  });
}
