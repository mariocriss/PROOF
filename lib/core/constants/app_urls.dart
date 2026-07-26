import 'package:proof/core/constants/app_url_policy.dart';

/// Central launch URL and contact configuration.
///
/// Legal/marketing pages are served from Firebase Hosting (`website/`).
/// Default HTTPS hosts use the Firebase project id from `firebase_options.dart`
/// / `.firebaserc` (`proof-e913a`). After `firebase deploy --only hosting`,
/// these URLs resolve on `*.web.app` (and `*.firebaseapp.com`).
///
/// Leave [publicPassportBaseUrl] null until a real public web passport exists.
/// Set [supportEmail] to an owned inbox before store listing.
///
/// Checklist: `docs/LAUNCH_URLS_CHECKLIST.md`.
class AppUrls {
  AppUrls._();

  /// Detected Firebase project id (not invented). Used only to build Hosting URLs.
  static const String firebaseProjectId = 'proof-e913a';

  static const String _hostingOrigin = 'https://$firebaseProjectId.web.app';

  /// Firebase Hosting site root.
  static const String? websiteBaseUrl = _hostingOrigin;

  /// Hosted Privacy Policy (Play Console + in-app external link).
  static const String? privacyPolicyUrl = '$_hostingOrigin/privacy/';

  /// Hosted Terms of Service.
  static const String? termsOfServiceUrl = '$_hostingOrigin/terms/';

  /// Hosted account-deletion instructions (Play account-deletion URL).
  static const String? accountDeletionUrl = '$_hostingOrigin/delete-account/';

  /// Public web passport base — keep null until that product exists.
  static const String? publicPassportBaseUrl = null;

  /// Support inbox used by the app and Hosting support pages.
  static const String? supportEmail = 'mario-zderic@hotmail.com';

  static bool get hasWebsite => AppUrlPolicy.isHttpsUrl(websiteBaseUrl);

  static bool get hasPrivacyPolicyUrl =>
      AppUrlPolicy.isHttpsUrl(privacyPolicyUrl);

  static bool get hasTermsOfServiceUrl =>
      AppUrlPolicy.isHttpsUrl(termsOfServiceUrl);

  static bool get hasAccountDeletionUrl =>
      AppUrlPolicy.isHttpsUrl(accountDeletionUrl);

  /// Public web passport / QR / share-link destination is available only when
  /// an owned passport base URL is configured.
  static bool get publicWebPassportEnabled =>
      AppUrlPolicy.isHttpsUrl(publicPassportBaseUrl);

  static bool get hasSupportEmail =>
      AppUrlPolicy.isConfiguredSupportEmail(supportEmail);

  /// Shown when hosted legal URLs are still missing.
  static const String hostedLegalPlaceholderNotice =
      'Hosted Privacy Policy and Terms URLs are not configured yet. '
      'In-app copies below are informational drafts for this build — not a '
      'substitute for reviewed, hosted legal documents required by Google Play.';

  /// Shown when Hosting URLs are set but counsel has not signed off.
  static const String hostedLegalReviewNotice =
      'Hosted legal pages are linked below. Drafts on Firebase Hosting should '
      'receive legal review before public production launch.';

  static const String publicPassportUnavailableMessage =
      'Public web passport links are not available yet. '
      'A public profile URL will appear here once an owned domain is configured.';

  static const String supportEmailPlaceholderNotice =
      'Support email is not configured yet. Set AppUrls.supportEmail to an '
      'inbox on your owned domain before store listing.';

  /// Returns `null` when public web passport is disabled.
  static String? passportUrlForHandle(String handle) {
    return AppUrlPolicy.passportUrlForHandle(
      baseUrl: publicPassportBaseUrl,
      handle: handle,
    );
  }
}
