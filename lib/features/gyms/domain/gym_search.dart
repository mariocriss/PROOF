import 'package:proof/shared/models/gym_model.dart';

class GymSearch {
  const GymSearch._();

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

  static List<GymModel> filterActiveGyms(
    List<GymModel> gyms,
    String query,
  ) {
    final normalized = normalizeQuery(query);
    if (!shouldSearch(query)) return [];

    final handleQuery = handleFromQuery(query);
    return gyms.where((gym) {
      if (gym.status != GymStatus.active) return false;
      return gym.name.toLowerCase().contains(normalized) ||
          gym.city.toLowerCase().contains(normalized) ||
          gym.country.toLowerCase().contains(normalized) ||
          gym.address.toLowerCase().contains(normalized) ||
          gym.handle.contains(handleQuery);
    }).toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
  }

  static List<GymModel> mergeResults({
    required List<GymModel> filtered,
    GymModel? handleMatch,
  }) {
    if (handleMatch == null || handleMatch.status != GymStatus.active) {
      return filtered;
    }

    final results = [handleMatch, ...filtered.where((gym) => gym.id != handleMatch.id)];
    return results;
  }
}
