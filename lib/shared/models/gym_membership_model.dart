import 'package:cloud_firestore/cloud_firestore.dart';

enum GymMembershipType {
  athlete('athlete'),
  coach('coach'),
  manager('manager');

  const GymMembershipType(this.value);

  final String value;

  static GymMembershipType fromString(String? value) {
    return GymMembershipType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => GymMembershipType.athlete,
    );
  }

  String get label => switch (this) {
        GymMembershipType.athlete => 'Athlete',
        GymMembershipType.coach => 'Coach',
        GymMembershipType.manager => 'Manager',
      };
}

enum GymMembershipStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  suspended('suspended'),
  removed('removed');

  const GymMembershipStatus(this.value);

  final String value;

  static GymMembershipStatus fromString(String? value) {
    return GymMembershipStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => GymMembershipStatus.pending,
    );
  }

  String get label => switch (this) {
        GymMembershipStatus.pending => 'Pending approval',
        GymMembershipStatus.approved => 'Approved member',
        GymMembershipStatus.rejected => 'Request declined',
        GymMembershipStatus.suspended => 'Suspended',
        GymMembershipStatus.removed => 'Removed',
      };

  bool get isActive => this == GymMembershipStatus.approved;
}

enum GymMembershipRequestResult {
  created,
  alreadyPending,
  alreadyApproved,
}

class GymMembershipModel {
  const GymMembershipModel({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.membershipType,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String gymId;
  final String userId;
  final GymMembershipType membershipType;
  final GymMembershipStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  static String membershipDocId({
    required String gymId,
    required String userId,
    required GymMembershipType type,
  }) {
    return '${gymId}_${userId}_${type.value}';
  }

  factory GymMembershipModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return GymMembershipModel(
      id: doc.id,
      gymId: data['gymId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      membershipType:
          GymMembershipType.fromString(data['membershipType'] as String?),
      status: GymMembershipStatus.fromString(data['status'] as String?),
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gymId': gymId,
      'userId': userId,
      'membershipType': membershipType.value,
      'status': status.value,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }
}
