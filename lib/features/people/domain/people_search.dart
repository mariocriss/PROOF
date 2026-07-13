import 'package:proof/shared/models/public_profile_model.dart';

class PeopleSearch {
  const PeopleSearch._();

  static const int _minCityTokenLength = 4;

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

  static List<String> tokens(String query) {
    return normalizeQuery(query)
        .split(RegExp(r'\s+'))
        .map((token) => token.replaceFirst(RegExp(r'^@'), ''))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  static String effectiveHandle(PublicProfileModel profile) {
    if (profile.handleLowercase.isNotEmpty) return profile.handleLowercase;
    return profile.handle.toLowerCase();
  }

  static String effectiveName(PublicProfileModel profile) {
    if (profile.displayNameLowercase.isNotEmpty) {
      return profile.displayNameLowercase;
    }
    return profile.displayName.toLowerCase();
  }

  static bool tokenMatchesProfile(String token, PublicProfileModel profile) {
    final handle = effectiveHandle(profile);
    final name = effectiveName(profile);
    final city = profile.city.toLowerCase();

    if (handle.contains(token)) return true;

    for (final word in name.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      if (word.startsWith(token) || word.contains(token)) return true;
    }

    if (name.contains(token)) return true;

    if (token.length >= _minCityTokenLength && city.contains(token)) {
      return true;
    }

    return false;
  }

  static bool profileMatchesQuery(
    List<String> queryTokens,
    PublicProfileModel profile,
  ) {
    if (queryTokens.isEmpty) return false;
    return queryTokens.every((token) => tokenMatchesProfile(token, profile));
  }

  static int matchScore(String query, PublicProfileModel profile) {
    final handleQuery = handleFromQuery(query);
    final handle = effectiveHandle(profile);
    final name = effectiveName(profile);
    final queryTokens = tokens(query);

    if (handle == handleQuery) return 0;
    if (handle.startsWith(handleQuery)) return 1;
    if (queryTokens.length == 1 && handle.contains(queryTokens.single)) {
      return 2;
    }
    if (name == normalizeQuery(query)) return 3;
    if (name.startsWith(normalizeQuery(query))) return 4;
    if (queryTokens.every((token) => name.contains(token))) return 5;
    if (queryTokens.length == 1 &&
        profile.city.toLowerCase().contains(queryTokens.single)) {
      return 6;
    }
    return 7;
  }

  static bool isVisibleProfile(
    PublicProfileModel profile, {
    required String currentUserId,
    Set<String> blockedUserIds = const {},
  }) {
    if (!profile.searchable) return false;
    if (profile.userId == currentUserId) return false;
    if (blockedUserIds.contains(profile.userId)) return false;
    return true;
  }

  static List<PublicProfileModel> filterProfiles(
    List<PublicProfileModel> profiles,
    String query, {
    required String currentUserId,
    Set<String> blockedUserIds = const {},
  }) {
    if (!shouldSearch(query)) return [];

    final queryTokens = tokens(query);
    if (queryTokens.isEmpty) return [];

    return profiles
        .where((profile) {
          if (!isVisibleProfile(
            profile,
            currentUserId: currentUserId,
            blockedUserIds: blockedUserIds,
          )) {
            return false;
          }
          return profileMatchesQuery(queryTokens, profile);
        })
        .toList()
      ..sort((a, b) {
        final scoreCompare =
            matchScore(query, a).compareTo(matchScore(query, b));
        if (scoreCompare != 0) return scoreCompare;
        return effectiveName(a).compareTo(effectiveName(b));
      });
  }

  static List<PublicProfileModel> mergeResults({
    required List<PublicProfileModel> filtered,
    required List<PublicProfileModel> extra,
    PublicProfileModel? handleMatch,
    required String currentUserId,
    Set<String> blockedUserIds = const {},
  }) {
    final merged = <String, PublicProfileModel>{};

    void add(PublicProfileModel profile) {
      if (!isVisibleProfile(
        profile,
        currentUserId: currentUserId,
        blockedUserIds: blockedUserIds,
      )) {
        return;
      }
      merged[profile.userId] = profile;
    }

    if (handleMatch != null) add(handleMatch);
    for (final profile in filtered) {
      add(profile);
    }
    for (final profile in extra) {
      add(profile);
    }

    final results = merged.values.toList()
      ..sort((a, b) => effectiveName(a).compareTo(effectiveName(b)));

    if (handleMatch != null) {
      results.removeWhere((profile) => profile.userId == handleMatch.userId);
      results.insert(0, handleMatch);
    }

    return results;
  }
}
