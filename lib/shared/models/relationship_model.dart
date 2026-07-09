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
  rejected('rejected');

  const RelationshipStatus(this.value);

  final String value;

  static RelationshipStatus fromString(String? value) {
    return RelationshipStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RelationshipStatus.pending,
    );
  }
}

class RelationshipModel {
  const RelationshipModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final RelationshipType type;
  final RelationshipStatus status;
  final DateTime createdAt;

  factory RelationshipModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return RelationshipModel(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      type: RelationshipType.fromString(data['type'] as String?),
      status: RelationshipStatus.fromString(data['status'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'type': type.value,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RelationshipModel copyWith({
    RelationshipStatus? status,
  }) {
    return RelationshipModel(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
