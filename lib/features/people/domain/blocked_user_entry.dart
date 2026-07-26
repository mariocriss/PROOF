import 'package:proof/features/people/domain/people_relationship_queries.dart';
import 'package:proof/shared/models/public_profile_model.dart';
import 'package:proof/shared/models/relationship_model.dart';

/// A person the current user blocked, with optional public display fields.
class BlockedUserEntry {
  const BlockedUserEntry({
    required this.relationship,
    required this.otherUserId,
    this.profile,
  });

  final RelationshipModel relationship;
  final String otherUserId;
  final PublicProfileModel? profile;

  String get displayName {
    final name = profile?.displayName.trim() ?? '';
    if (name.isNotEmpty) return name;
    return 'Unknown user';
  }

  String? get handle {
    final value = profile?.handle.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String get sortKey => displayName.toLowerCase();

  static List<BlockedUserEntry> buildSorted({
    required List<RelationshipModel> relationships,
    required String currentUserId,
    required Map<String, PublicProfileModel?> profilesByUserId,
  }) {
    final blocked = relationshipsBlockedByMe(relationships, currentUserId);
    final entries = blocked.map((relationship) {
      final otherId = otherRelationshipUserId(relationship, currentUserId);
      return BlockedUserEntry(
        relationship: relationship,
        otherUserId: otherId,
        profile: profilesByUserId[otherId],
      );
    }).toList();

    entries.sort((a, b) {
      final byName = a.sortKey.compareTo(b.sortKey);
      if (byName != 0) return byName;
      return a.otherUserId.compareTo(b.otherUserId);
    });
    return entries;
  }
}
