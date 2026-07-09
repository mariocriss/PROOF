class AppConstants {
  AppConstants._();

  static const String appName = 'PROOF';
  static const String appTagline = 'Your Physical Identity';

  static const int handleMinLength = 3;
  static const int handleMaxLength = 24;
  static const int bioMaxLength = 280;
  static const int displayNameMaxLength = 64;

  static const String passportBaseUrl = 'https://proof.app/passport';

  static String passportUrl(String handle) => '$passportBaseUrl/$handle';
}
