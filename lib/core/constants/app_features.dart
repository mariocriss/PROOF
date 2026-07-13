/// Launch-time feature flags.
class AppFeatures {
  AppFeatures._();

  /// Firebase Storage is disabled on the free plan for launch.
  /// Photo uploads (avatars, proof media, gym logos) are deferred.
  static const bool cloudStorageEnabled = false;
}
