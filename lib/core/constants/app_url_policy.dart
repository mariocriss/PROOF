/// Pure URL / contact validation used by [AppUrls] and unit tests.
///
/// Keeps launch config free of broken http(s) links when values are absent.
class AppUrlPolicy {
  AppUrlPolicy._();

  /// True only for non-empty `https://` URLs with a host.
  static bool isHttpsUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty;
  }

  /// True for a plausible email that is not an explicit placeholder.
  static bool isConfiguredSupportEmail(String? raw) {
    final email = raw?.trim() ?? '';
    if (email.isEmpty) return false;
    final upper = email.toUpperCase();
    if (upper.contains('NOT_CONFIGURED')) return false;
    if (upper == 'REPLACE_ME' || upper.startsWith('REPLACE_ME@')) return false;
    if (upper == 'YOUR-SUPPORT-EMAIL' || upper.contains('YOUR-SUPPORT-EMAIL@')) {
      return false;
    }
    final at = email.indexOf('@');
    if (at <= 0 || at >= email.length - 1) return false;
    final domain = email.substring(at + 1);
    return domain.contains('.') &&
        !domain.startsWith('.') &&
        !domain.endsWith('.');
  }

  /// Builds `base/handle` when [baseUrl] is a valid HTTPS passport base.
  /// Returns `null` when the public web passport is not configured.
  static String? passportUrlForHandle({
    required String? baseUrl,
    required String handle,
  }) {
    if (!isHttpsUrl(baseUrl)) return null;
    final base = baseUrl!.trim().replaceAll(RegExp(r'/+$'), '');
    final normalized = handle.trim().replaceFirst(RegExp(r'^@'), '');
    if (normalized.isEmpty) return null;
    return '$base/$normalized';
  }

  /// External legal / support pages may open only when HTTPS is configured.
  static bool canLaunchExternalUrl(String? raw) => isHttpsUrl(raw);
}
