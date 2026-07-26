import 'package:proof/core/constants/app_urls.dart';

/// Launch-time feature flags.
class AppFeatures {
  AppFeatures._();

  /// Firebase Storage is disabled on the free plan for launch.
  /// Photo uploads (avatars, proof media, gym logos) are deferred.
  static const bool cloudStorageEnabled = false;

  /// Push notifications / FCM are not wired for this launch build.
  static const bool pushNotificationsEnabled = false;

  /// Public web passport pages, QR codes, and shareable profile URLs.
  /// Enabled only when [AppUrls.publicPassportBaseUrl] is a real HTTPS URL.
  static bool get publicWebPassportEnabled => AppUrls.publicWebPassportEnabled;
}
