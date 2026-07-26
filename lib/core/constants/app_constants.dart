import 'package:proof/core/constants/app_urls.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'PROOF';
  static const String appTagline = 'Your Physical Identity';

  static const int handleMinLength = 3;
  static const int handleMaxLength = 24;
  static const int bioMaxLength = 280;
  static const int displayNameMaxLength = 64;

  /// Public passport URL when web hosting is configured; otherwise `null`.
  static String? passportUrl(String handle) =>
      AppUrls.passportUrlForHandle(handle);
}
