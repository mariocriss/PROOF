import 'package:flutter_test/flutter_test.dart';
import 'package:proof/shared/models/gym_model.dart';
import 'package:proof/features/gyms/domain/gym_search.dart';

void main() {
  final gyms = [
    GymModel(
      id: '1',
      name: 'Iron Temple',
      handle: 'irontemple',
      status: GymStatus.active,
      createdBy: 'u1',
      createdAt: DateTime(2024),
      city: 'Zagreb',
      country: 'Croatia',
    ),
    GymModel(
      id: '2',
      name: 'Proof HQ',
      handle: 'proofhq',
      status: GymStatus.active,
      createdBy: 'u2',
      createdAt: DateTime(2024),
      city: 'Split',
      country: 'Croatia',
    ),
    GymModel(
      id: '3',
      name: 'Draft Gym',
      handle: 'draft',
      status: GymStatus.draft,
      createdBy: 'u3',
      createdAt: DateTime(2024),
    ),
  ];

  test('shouldSearch requires at least two characters or @handle', () {
    expect(GymSearch.shouldSearch(''), isFalse);
    expect(GymSearch.shouldSearch('i'), isFalse);
    expect(GymSearch.shouldSearch('ir'), isTrue);
    expect(GymSearch.shouldSearch('@'), isFalse);
    expect(GymSearch.shouldSearch('@iron'), isTrue);
  });

  test('filterActiveGyms matches name city country and handle', () {
    final results = GymSearch.filterActiveGyms(gyms, 'zagreb');
    expect(results.map((g) => g.id), ['1']);

    final byHandle = GymSearch.filterActiveGyms(gyms, '@proofhq');
    expect(byHandle.map((g) => g.id), ['2']);
  });

  test('filterActiveGyms excludes non-active gyms', () {
    final results = GymSearch.filterActiveGyms(gyms, 'draft');
    expect(results, isEmpty);
  });

  test('mergeResults adds handle lookup match once', () {
    final merged = GymSearch.mergeResults(
      filtered: gyms.where((g) => g.id == '1').toList(),
      handleMatch: gyms[1],
    );
    expect(merged.map((g) => g.id), ['2', '1']);
  });
}
