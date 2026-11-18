import 'package:proof/core/constants/app_urls.dart';
import 'package:proof/features/experience/domain/experience_feature_flags.dart';

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

  // —— Experience Engine (all production defaults OFF) ——
  static const bool experienceEngineEnabled = false;
  static const bool passportMotionEnabled = false;
  static const bool guideEnabled = false;
  static const bool soundsEnabled = false;
  static const bool hapticsEnabled = false;
  static const bool accountCreationExperienceEnabled = false;
  static const bool firstProofExperienceEnabled = false;
  static const bool coachVerificationExperienceEnabled = false;

  static const ExperienceFeatureFlags experienceFlags = ExperienceFeatureFlags(
    experienceEngineEnabled: experienceEngineEnabled,
    passportMotionEnabled: passportMotionEnabled,
    guideEnabled: guideEnabled,
    soundsEnabled: soundsEnabled,
    hapticsEnabled: hapticsEnabled,
    accountCreationExperienceEnabled: accountCreationExperienceEnabled,
    firstProofExperienceEnabled: firstProofExperienceEnabled,
    coachVerificationExperienceEnabled: coachVerificationExperienceEnabled,
  );
}
