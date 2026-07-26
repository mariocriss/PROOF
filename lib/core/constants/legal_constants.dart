import 'package:proof/core/constants/app_urls.dart';

/// Legal document routes and optional hosted URLs.
///
/// Hosted URLs come from [AppUrls]. In-app documents are drafts for the build
/// and are not a substitute for reviewed hosted legal pages required by stores.
class LegalConstants {
  LegalConstants._();

  static const String privacyPolicyRoute = '/privacy-policy';
  static const String termsOfServiceRoute = '/terms';

  static String? get privacyPolicyUrl => AppUrls.privacyPolicyUrl;

  static String? get termsOfServiceUrl => AppUrls.termsOfServiceUrl;

  static String? get supportEmail => AppUrls.supportEmail;

  static String get supportContactLabel => AppUrls.hasSupportEmail
      ? AppUrls.supportEmail!
      : 'Support contact is not available in this build';
}
