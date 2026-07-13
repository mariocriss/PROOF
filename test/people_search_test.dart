import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/people/domain/people_search.dart';
import 'package:proof/shared/models/public_profile_model.dart';

void main() {
  PublicProfileModel profile({
    required String userId,
    required String displayName,
    required String handle,
    String city = '',
    String displayNameLowercase = '',
    String handleLowercase = '',
  }) {
    return PublicProfileModel(
      userId: userId,
      displayName: displayName,
      handle: handle,
      displayNameLowercase: displayNameLowercase,
      handleLowercase: handleLowercase,
      city: city,
      updatedAt: DateTime(2026),
    );
  }

  final profiles = [
    profile(
      userId: '1',
      displayName: 'Mario Rossi',
      handle: 'mario',
      displayNameLowercase: 'mario rossi',
      handleLowercase: 'mario',
      city: 'Rotterdam',
    ),
    profile(
      userId: '2',
      displayName: 'Chris Coach',
      handle: 'chris',
      displayNameLowercase: 'chris coach',
      handleLowercase: 'chris',
      city: 'Amsterdam',
    ),
    profile(
      userId: '3',
      displayName: 'Tessa Kiers',
      handle: 'tessakiers',
      displayNameLowercase: 'tessa kiers',
      handleLowercase: 'tessakiers',
      city: 'Utrecht',
    ),
    profile(
      userId: '4',
      displayName: 'Legacy User',
      handle: 'legacyuser',
      city: 'Rotterdam',
    ),
    profile(
      userId: 'self',
      displayName: 'Me',
      handle: 'me',
      displayNameLowercase: 'me',
      handleLowercase: 'me',
    ),
  ];

  group('PeopleSearch', () {
    test('normalizeQuery trims and lowercases', () {
      expect(PeopleSearch.normalizeQuery('  Mario '), 'mario');
    });

    test('handleFromQuery strips @', () {
      expect(PeopleSearch.handleFromQuery('@mario'), 'mario');
    });

    test('shouldSearch requires minimum length', () {
      expect(PeopleSearch.shouldSearch('m'), isFalse);
      expect(PeopleSearch.shouldSearch('ma'), isTrue);
      expect(PeopleSearch.shouldSearch('@'), isFalse);
      expect(PeopleSearch.shouldSearch('@m'), isTrue);
    });

    test('filterProfiles matches name, handle, and city', () {
      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'mario',
          currentUserId: 'self',
        ).map((p) => p.handle),
        ['mario'],
      );

      expect(
        PeopleSearch.filterProfiles(
          profiles,
          '@chris',
          currentUserId: 'self',
        ).single.handle,
        'chris',
      );

      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'rotterdam',
          currentUserId: 'self',
        ).map((p) => p.handle),
        ['legacyuser', 'mario'],
      );
    });

    test('short queries do not match city substrings', () {
      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'te',
          currentUserId: 'self',
        ).map((p) => p.handle),
        ['tessakiers'],
      );
    });

    test('partial handle search finds tessakiers', () {
      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'tessa',
          currentUserId: 'self',
        ).single.handle,
        'tessakiers',
      );
    });

    test('falls back to handle when lowercase fields are missing', () {
      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'legacy',
          currentUserId: 'self',
        ).single.handle,
        'legacyuser',
      );
    });

    test('multi-token search requires every token to match', () {
      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'tessa utrecht',
          currentUserId: 'self',
        ).single.handle,
        'tessakiers',
      );

      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'ik tessa',
          currentUserId: 'self',
        ),
        isEmpty,
      );
    });

    test('filterProfiles excludes current user and blocked users', () {
      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'me',
          currentUserId: 'self',
        ),
        isEmpty,
      );

      expect(
        PeopleSearch.filterProfiles(
          profiles,
          'chris',
          currentUserId: 'self',
          blockedUserIds: {'2'},
        ),
        isEmpty,
      );
    });

    test('mergeResults adds exact handle lookup once', () {
      final handleMatch = profiles[2];
      final merged = PeopleSearch.mergeResults(
        filtered: PeopleSearch.filterProfiles(
          profiles,
          'tessa',
          currentUserId: 'self',
        ),
        extra: const [],
        handleMatch: handleMatch,
        currentUserId: 'self',
      );

      expect(merged.first.handle, 'tessakiers');
      expect(merged.where((p) => p.userId == '3').length, 1);
    });
  });
}
