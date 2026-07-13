import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/people/domain/people_search.dart';
import 'package:proof/shared/models/public_profile_model.dart';

void main() {
  final profiles = [
    PublicProfileModel(
      userId: '1',
      displayName: 'Mario Rossi',
      handle: 'mario',
      displayNameLowercase: 'mario rossi',
      handleLowercase: 'mario',
      city: 'Rotterdam',
      updatedAt: DateTime(2026),
    ),
    PublicProfileModel(
      userId: '2',
      displayName: 'Chris Coach',
      handle: 'chris',
      displayNameLowercase: 'chris coach',
      handleLowercase: 'chris',
      city: 'Amsterdam',
      updatedAt: DateTime(2026),
    ),
    PublicProfileModel(
      userId: 'self',
      displayName: 'Me',
      handle: 'me',
      displayNameLowercase: 'me',
      handleLowercase: 'me',
      updatedAt: DateTime(2026),
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
        ).single.handle,
        'mario',
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
  });
}
