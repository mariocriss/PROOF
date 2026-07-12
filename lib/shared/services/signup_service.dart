import 'package:firebase_auth/firebase_auth.dart';
import 'package:proof/shared/services/auth_service.dart';
import 'package:proof/shared/services/firestore_service.dart';

/// Handles signup edge cases: abandoning incomplete onboarding and re-registering
/// with an email that still has an unfinished Firebase Auth account.
class SignupService {
  SignupService({
    required AuthService auth,
    required FirestoreService firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final AuthService _auth;
  final FirestoreService _firestore;

  Future<bool> hasIncompleteOnboarding(String userId) async {
    final user = await _firestore.getUser(userId);
    return user == null || !user.onboardingCompleted;
  }

  /// Removes Firestore data and deletes the Firebase Auth user when onboarding
  /// was never completed.
  Future<void> abandonIncompleteSignup() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final completed = !(await hasIncompleteOnboarding(user.uid));
    if (completed) {
      throw StateError('Cannot abandon a completed account');
    }

    await _firestore.deleteAllUserData(user.uid);
    await _auth.deleteCurrentUser();
  }

  /// Creates a new account, or clears an incomplete existing account and retries.
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signUp(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      return _restartIncompleteSignup(email: email, password: password);
    }
  }

  Future<UserCredential> _restartIncompleteSignup({
    required String email,
    required String password,
  }) async {
    late UserCredential existing;
    try {
      existing = await _auth.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found') {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message:
              'This email is already registered with a different password. Sign in instead.',
        );
      }
      rethrow;
    }

    final userId = existing.user!.uid;
    if (!(await hasIncompleteOnboarding(userId))) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'This email is already registered. Sign in to your account.',
      );
    }

    await _firestore.deleteAllUserData(userId);
    await existing.user!.delete();
    return _auth.signUp(email: email, password: password);
  }
}
