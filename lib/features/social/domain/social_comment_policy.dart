/// Client-side checks for gym activity comments.
///
/// Firestore rules enforce the same limits. This only fails fast in the UI.
class SocialCommentPolicy {
  SocialCommentPolicy._();

  static const int maxLength = 300;
  static const Duration minInterval = Duration(seconds: 15);

  static SocialCommentCheck check(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const SocialCommentCheck.rejected(SocialCommentRejection.empty);
    }
    if (text.length > maxLength) {
      return const SocialCommentCheck.rejected(SocialCommentRejection.tooLong);
    }
    return SocialCommentCheck.accepted(text);
  }
}

enum SocialCommentRejection { empty, tooLong }

class SocialCommentCheck {
  const SocialCommentCheck.accepted(this.text) : rejection = null;
  const SocialCommentCheck.rejected(this.rejection) : text = null;

  final String? text;
  final SocialCommentRejection? rejection;

  bool get isValid => text != null;
}
