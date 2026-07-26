import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:proof/shared/services/auth_service.dart';
import 'package:proof/shared/services/firestore_service.dart';

enum AccountDeletionStatus {
  success,
  failed,
}

/// Result of an account deletion attempt. Auth is deleted only on [success].
class AccountDeletionResult {
  const AccountDeletionResult._({
    required this.status,
    required this.authDeleted,
    this.userMessage,
  });

  factory AccountDeletionResult.success() => const AccountDeletionResult._(
        status: AccountDeletionStatus.success,
        authDeleted: true,
      );

  factory AccountDeletionResult.failed(String userMessage) =>
      AccountDeletionResult._(
        status: AccountDeletionStatus.failed,
        authDeleted: false,
        userMessage: userMessage,
      );

  final AccountDeletionStatus status;
  final bool authDeleted;
  final String? userMessage;

  bool get isSuccess => status == AccountDeletionStatus.success;
}

/// Orchestrates reauth → Firestore cleanup → Auth delete (Auth last).
///
/// Injectable for unit tests; production wiring uses [AccountDeletionService.create].
class AccountDeletionService {
  AccountDeletionService({
    required Future<void> Function(String password) reauthenticate,
    required Future<void> Function(String userId) deleteUserData,
    required Future<void> Function() deleteAuthUser,
    required String? Function() currentUserId,
    required String Function(FirebaseAuthException e) mapAuthError,
    void Function(String stage, Object error)? recordDiagnostic,
  })  : _reauthenticate = reauthenticate,
        _deleteUserData = deleteUserData,
        _deleteAuthUser = deleteAuthUser,
        _currentUserId = currentUserId,
        _mapAuthError = mapAuthError,
        _recordDiagnostic = recordDiagnostic;

  factory AccountDeletionService.create({
    required AuthService auth,
    required FirestoreService firestore,
    void Function(String stage, Object error)? recordDiagnostic,
  }) {
    return AccountDeletionService(
      reauthenticate: auth.reauthenticateWithPassword,
      deleteUserData: firestore.deleteAllUserData,
      deleteAuthUser: auth.deleteCurrentUser,
      currentUserId: () => auth.currentUser?.uid,
      mapAuthError: (e) =>
          auth.mapAuthError(e) ?? 'Could not delete account. Please try again.',
      recordDiagnostic: recordDiagnostic ?? recordAccountDeletionDiagnostic,
    );
  }

  final Future<void> Function(String password) _reauthenticate;
  final Future<void> Function(String userId) _deleteUserData;
  final Future<void> Function() _deleteAuthUser;
  final String? Function() _currentUserId;
  final String Function(FirebaseAuthException e) _mapAuthError;
  final void Function(String stage, Object error)? _recordDiagnostic;

  bool _inProgress = false;

  bool get isDeleting => _inProgress;

  static const firestoreFailedMessage =
      'We could not finish deleting your account data. Your account is still '
      'active — please try again.';

  static const authFailedAfterCleanupMessage =
      'Your account data was removed, but sign-in could not be closed. '
      'Please try deleting again, or contact support if this continues.';

  static const alreadyInProgressMessage =
      'Account deletion is already in progress.';

  static const wrongUserMessage =
      'You are not signed in as this account. Sign in again and retry.';

  /// Deletes the signed-in user's data then Auth. Never deletes Auth if
  /// Firestore cleanup fails.
  Future<AccountDeletionResult> deleteAccount({
    required String userId,
    required String password,
  }) async {
    if (_inProgress) {
      return AccountDeletionResult.failed(alreadyInProgressMessage);
    }

    final signedInId = _currentUserId();
    if (signedInId == null || signedInId != userId) {
      return AccountDeletionResult.failed(wrongUserMessage);
    }

    if (password.trim().isEmpty) {
      return AccountDeletionResult.failed('Please enter your password.');
    }

    _inProgress = true;
    try {
      try {
        await _reauthenticate(password);
      } on FirebaseAuthException catch (e) {
        _recordDiagnostic?.call('reauth', e);
        return AccountDeletionResult.failed(_friendlyAuthMessage(e));
      } catch (e) {
        _recordDiagnostic?.call('reauth', e);
        return AccountDeletionResult.failed(
          'Could not confirm your password. Please try again.',
        );
      }

      try {
        await _deleteUserData(userId);
      } catch (e) {
        _recordDiagnostic?.call('firestore', e);
        return AccountDeletionResult.failed(_friendlyDataMessage(e));
      }

      try {
        await _deleteAuthUser();
      } on FirebaseAuthException catch (e) {
        _recordDiagnostic?.call('auth', e);
        return AccountDeletionResult.failed(authFailedAfterCleanupMessage);
      } catch (e) {
        _recordDiagnostic?.call('auth', e);
        return AccountDeletionResult.failed(authFailedAfterCleanupMessage);
      }

      return AccountDeletionResult.success();
    } finally {
      _inProgress = false;
    }
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-mismatch':
        return 'Incorrect password. Try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'requires-recent-login':
        return 'Please confirm your password and try again.';
      default:
        final mapped = _mapAuthError(e);
        if (mapped.toLowerCase().contains('firebase')) {
          return 'Could not confirm your password. Please try again.';
        }
        return mapped;
    }
  }

  String _friendlyDataMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        default:
          return firestoreFailedMessage;
      }
    }
    return firestoreFailedMessage;
  }
}

/// Release-only diagnostic: stage + error code/type. No passwords, emails, or PII.
void recordAccountDeletionDiagnostic(String stage, Object error) {
  if (!kReleaseMode) return;

  String? code;
  if (error is FirebaseAuthException) {
    code = error.code;
  } else if (error is FirebaseException) {
    code = error.code;
  }

  FirebaseCrashlytics.instance.recordError(
    Exception('account_deletion_failed'),
    StackTrace.current,
    reason: 'account_deletion_failed stage=$stage code=${code ?? error.runtimeType}',
    fatal: false,
  );
}
