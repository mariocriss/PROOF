import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proof/shared/models/onboarding_draft.dart';
import 'package:proof/shared/models/onboarding_step.dart';
import 'package:proof/shared/models/user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.hasIdentity = false,
    this.role = UserRole.athlete,
    this.accountType = UserRole.athlete,
    this.specialty = '',
    this.primaryGymId,
    this.onboardingStep = OnboardingStep.chooseAccountType,
    this.onboardingCompleted = false,
    this.physicalIdentityId,
    this.coachProfileId,
    this.managedGymIds = const [],
    this.onboardingDraft = const OnboardingDraft(),
  });

  final String id;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasIdentity;
  final UserRole role;
  final UserRole accountType;
  final String specialty;
  final String? primaryGymId;
  final OnboardingStep onboardingStep;
  final bool onboardingCompleted;
  final String? physicalIdentityId;
  final String? coachProfileId;
  final List<String> managedGymIds;
  final OnboardingDraft onboardingDraft;

  bool get isCoach => role.isCoach;
  bool get isGymManager => role.isGymManager;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final role = UserRole.fromString(data['role'] as String?);
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasIdentity: data['hasIdentity'] as bool? ?? false,
      role: role,
      accountType: UserRole.fromString(
        data['accountType'] as String? ?? data['role'] as String?,
      ),
      specialty: data['specialty'] as String? ?? '',
      primaryGymId: data['primaryGymId'] as String?,
      onboardingStep: _resolveOnboardingStep(data),
      onboardingCompleted: _resolveOnboardingCompleted(data),
      physicalIdentityId: data['physicalIdentityId'] as String?,
      coachProfileId: data['coachProfileId'] as String?,
      managedGymIds: List<String>.from(data['managedGymIds'] as List? ?? []),
      onboardingDraft: OnboardingDraft.fromMap(
        data['onboardingDraft'] as Map<String, dynamic>?,
      ),
    );
  }

  static OnboardingStep _resolveOnboardingStep(Map<String, dynamic> data) {
    if (data.containsKey('onboardingStep')) {
      return OnboardingStep.fromString(data['onboardingStep'] as String?);
    }
    return OnboardingStep.chooseAccountType;
  }

  static bool _resolveOnboardingCompleted(Map<String, dynamic> data) {
    if (data.containsKey('onboardingCompleted')) {
      return data['onboardingCompleted'] as bool? ?? false;
    }
    return false;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'hasIdentity': hasIdentity,
      'role': role.value,
      'accountType': accountType.value,
      'specialty': specialty,
      'primaryGymId': primaryGymId,
      'onboardingStep': onboardingStep.value,
      'onboardingCompleted': onboardingCompleted,
      'physicalIdentityId': physicalIdentityId,
      'coachProfileId': coachProfileId,
      'managedGymIds': managedGymIds,
      'onboardingDraft': onboardingDraft.toMap(),
    };
  }

  UserModel copyWith({
    String? email,
    DateTime? updatedAt,
    bool? hasIdentity,
    UserRole? role,
    UserRole? accountType,
    String? specialty,
    String? primaryGymId,
    OnboardingStep? onboardingStep,
    bool? onboardingCompleted,
    String? physicalIdentityId,
    String? coachProfileId,
    List<String>? managedGymIds,
    OnboardingDraft? onboardingDraft,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasIdentity: hasIdentity ?? this.hasIdentity,
      role: role ?? this.role,
      accountType: accountType ?? this.accountType,
      specialty: specialty ?? this.specialty,
      primaryGymId: primaryGymId ?? this.primaryGymId,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      physicalIdentityId: physicalIdentityId ?? this.physicalIdentityId,
      coachProfileId: coachProfileId ?? this.coachProfileId,
      managedGymIds: managedGymIds ?? this.managedGymIds,
      onboardingDraft: onboardingDraft ?? this.onboardingDraft,
    );
  }
}
