import 'package:cloud_firestore/cloud_firestore.dart';

enum GymStatus {
  draft('draft'),
  active('active'),
  suspended('suspended');

  const GymStatus(this.value);

  final String value;

  static GymStatus fromString(String? value) {
    return GymStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => GymStatus.draft,
    );
  }

  String get label => switch (this) {
        GymStatus.draft => 'Draft',
        GymStatus.active => 'Active',
        GymStatus.suspended => 'Suspended',
      };
}

class GymModel {
  const GymModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.logoUrl,
    this.address = '',
    this.country = '',
    this.website = '',
    this.description = '',
    this.city = '',
    this.contactEmail = '',
    this.managerName = '',
    this.phone = '',
  });

  final String id;
  final String name;
  final String handle;
  final String? logoUrl;
  final String address;
  final String country;
  final String city;
  final String website;
  final String description;
  final String contactEmail;
  final String managerName;
  final String phone;
  final GymStatus status;
  final String createdBy;
  final DateTime createdAt;

  factory GymModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GymModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      handle: data['handle'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as String? ?? '',
      country: data['country'] as String? ?? '',
      city: data['city'] as String? ?? '',
      website: data['website'] as String? ?? '',
      description: data['description'] as String? ?? '',
      contactEmail: data['contactEmail'] as String? ?? '',
      managerName: data['managerName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      status: GymStatus.fromString(data['status'] as String?),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'handle': handle,
      'logoUrl': logoUrl,
      'address': address,
      'country': country,
      'city': city,
      'website': website,
      'description': description,
      'contactEmail': contactEmail,
      'managerName': managerName,
      'phone': phone,
      'status': status.value,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
