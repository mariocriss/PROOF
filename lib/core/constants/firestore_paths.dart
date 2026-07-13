class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String identity = 'identity';
  static const String profile = 'profile';
  static const String skills = 'skills';
  static const String proofs = 'proofs';
  static const String timeline = 'timeline';
  static const String relationships = 'relationships';
  static const String verificationRequests = 'verificationRequests';
  static const String coachProfiles = 'coachProfiles';
  static const String gyms = 'gyms';
  static const String gymMemberships = 'gymMemberships';
  static const String gymHandles = 'gymHandles';
  static const String publicProfiles = 'publicProfiles';

  static String userDoc(String userId) => '$users/$userId';

  static String identityDoc(String userId) =>
      '$users/$userId/$identity/$profile';

  static String skillsCollection(String userId) =>
      '$users/$userId/$skills';

  static String proofsCollection(String userId) =>
      '$users/$userId/$proofs';

  static String timelineCollection(String userId) =>
      '$users/$userId/$timeline';
}
