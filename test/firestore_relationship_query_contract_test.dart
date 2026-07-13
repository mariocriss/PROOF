import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against regressions in Firestore relationship access patterns.
///
/// Firestore evaluates whole queries against security rules. A query that might
/// return documents the user cannot read fails with permission-denied even when
/// a direct create on a new doc would be allowed.
void main() {
  final firestoreServiceSource = File(
    'lib/shared/services/firestore_service.dart',
  ).readAsStringSync();

  final findFriendRelationshipBody = RegExp(
    r'Future<RelationshipModel\?> findFriendRelationship\([\s\S]*?\n  \}',
  ).firstMatch(firestoreServiceSource)?.group(0);

  test('findFriendRelationship only uses participant-scoped queries', () {
    expect(findFriendRelationshipBody, isNotNull);

    final body = findFriendRelationshipBody!;
    final codeOnly = body
        .split('\n')
        .where((line) => !line.trim().startsWith('//'))
        .join('\n');

    expect(codeOnly.contains('_relationships.doc('), isFalse);
    expect(codeOnly.contains('whereIn'), isFalse);
    expect(body.contains("where('fromUserId', isEqualTo: userIdA)"), isTrue);
    expect(body.contains("where('toUserId', isEqualTo: userIdA)"), isTrue);
  });

  test('documents the participant-scoped query contract', () {
    expect(
      firestoreServiceSource,
      contains('Only query relationships where the current user is a guaranteed participant'),
    );
  });
}
