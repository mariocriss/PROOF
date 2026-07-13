import 'package:cloud_firestore/cloud_firestore.dart';

enum RelationshipType {
  friend('friend'),
  coach('coach'),
  athlete('athlete');

  const RelationshipType(this.value);

  final String value;

  static RelationshipType fromString(String? value) {
    return RelationshipType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => RelationshipType.friend,
    );
  }
}

enum RelationshipStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  rejected('rejected'),
  blocked('blocked');

  const RelationshipStatus(this.value);

  final String value;

  static RelationshipStatus fromString(String? value) {
    if (value == null || value.isEmpty) return RelationshipStatus.pending;
    return RelationshipStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RelationshipStatus.pending,
    );
  }

  bool get isTerminal => switch (this) {
        RelationshipStatus.accepted ||
        RelationshipStatus.declined ||
        RelationshipStatus.rejected ||
        RelationshipStatus.blocked =>
          true,
        _ => false,
      };
}

class RelationshipModel {
  const RelationshipModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.requesterSeen = true,
    this.recipientSeen = false,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final RelationshipType type;
  final RelationshipStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final bool requesterSeen;
  final bool recipientSeen;

  String get requesterUserId => fromUserId;
  String get recipientUserId => toUserId;

  factory RelationshipModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return RelationshipModel(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ??
          data['requesterUserId'] as String? ??
          '',
      toUserId: data['toUserId'] as String? ??
          data['recipientUserId'] as String? ??
          '',
      type: RelationshipType.fromString(data['type'] as String?),
      status: RelationshipStatus.fromString(data['status'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      requesterSeen: data['requesterSeen'] as bool? ?? true,
      recipientSeen: data['recipientSeen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'requesterUserId': fromUserId,
      'recipientUserId': toUserId,
      'type': type.value,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'requesterSeen': requesterSeen,
      'recipientSeen': recipientSeen,
    };
  }

  RelationshipModel copyWith({
    RelationshipStatus? status,
    DateTime? respondedAt,
    bool? requesterSeen,
    bool? recipientSeen,
  }) {
    return RelationshipModel(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      requesterSeen: requesterSeen ?? this.requesterSeen,
      recipientSeen: recipientSeen ?? this.recipientSeen,
    );
  }

  static String friendDocId(String userIdA, String userIdB) {
    final sorted = [userIdA, userIdB]..sort();
    return 'friend_${sorted[0]}_${sorted[1]}';
  }
}
