import 'package:proof/shared/models/public_profile_model.dart';

class PeopleSearch {
  const PeopleSearch._();

  static String normalizeQuery(String query) {
    return query.trim().toLowerCase();
  }

  static String handleFromQuery(String query) {
    return normalizeQuery(query).replaceFirst(RegExp(r'^@'), '');
  }

  static bool shouldSearch(String query) {
    final normalized = normalizeQuery(query);
    if (normalized.isEmpty) return false;
    if (normalized.startsWith('@')) return normalized.length > 1;
    return normalized.length >= 2;
  }

  static List<PublicProfileModel> filterProfiles(
    List<PublicProfileModel> profiles,
    String query, {
    required String currentUserId,
    Set<String> blockedUserIds = const {},
  }) {
    if (!shouldSearch(query)) return [];

    final normalized = normalizeQuery(query);
    final handleQuery = handleFromQuery(query);

    return profiles.where((profile) {
      if (!profile.searchable) return false;
      if (profile.userId == currentUserId) return false;
      if (blockedUserIds.contains(profile.userId)) return false;

      return profile.displayNameLowercase.contains(normalized) ||
          profile.handleLowercase.contains(handleQuery) ||
          profile.city.toLowerCase().contains(normalized);
    }).toList()
      ..sort((a, b) {
        final aHandleExact = a.handleLowercase == handleQuery;
        final bHandleExact = b.handleLowercase == handleQuery;
        if (aHandleExact != bHandleExact) return aHandleExact ? -1 : 1;
        return a.displayNameLowercase.compareTo(b.displayNameLowercase);
      });
  }
}
