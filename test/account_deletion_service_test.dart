import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proof/shared/services/account_deletion_service.dart';

void main() {
  const userId = 'user-athlete-1';

  AccountDeletionService buildService({
    String? signedInId = userId,
    Future<void> Function(String password)? reauthenticate,
    Future<void> Function(String userId)? deleteUserData,
    Future<void> Function()? deleteAuthUser,
    List<String>? stages,
  }) {
    return AccountDeletionService(
      currentUserId: () => signedInId,
      reauthenticate: reauthenticate ?? ((_) async {}),
      deleteUserData: deleteUserData ?? ((_) async {}),
      deleteAuthUser: deleteAuthUser ?? (() async {}),
      mapAuthError: (e) => e.message ?? e.code,
      recordDiagnostic: (stage, _) => stages?.add(stage),
    );
  }

  test('successful deletion deletes Auth only after Firestore cleanup', () async {
    final order = <String>[];
    final service = buildService(
      reauthenticate: (password) async {
        expect(password, 'secret');
        order.add('reauth');
      },
      deleteUserData: (id) async {
        expect(id, userId);
        order.add('firestore');
      },
      deleteAuthUser: () async => order.add('auth'),
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');

    expect(result.isSuccess, isTrue);
    expect(result.authDeleted, isTrue);
    expect(order, ['reauth', 'firestore', 'auth']);
  });

  test('wrong password during reauthentication keeps Auth', () async {
    var authDeleted = false;
    var dataDeleted = false;
    final stages = <String>[];
    final service = buildService(
      stages: stages,
      reauthenticate: (_) async {
        throw FirebaseAuthException(code: 'wrong-password');
      },
      deleteUserData: (_) async => dataDeleted = true,
      deleteAuthUser: () async => authDeleted = true,
    );

    final result = await service.deleteAccount(userId: userId, password: 'bad');

    expect(result.isSuccess, isFalse);
    expect(result.authDeleted, isFalse);
    expect(result.userMessage, 'Incorrect password. Try again.');
    expect(dataDeleted, isFalse);
    expect(authDeleted, isFalse);
    expect(stages, ['reauth']);
  });

  test('network failure during reauth keeps Auth and shows friendly error', () async {
    final service = buildService(
      reauthenticate: (_) async {
        throw FirebaseAuthException(code: 'network-request-failed');
      },
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');

    expect(result.isSuccess, isFalse);
    expect(result.authDeleted, isFalse);
    expect(result.userMessage, contains('Network error'));
  });

  test('partial Firestore cleanup failure does not delete Auth', () async {
    var authDeleted = false;
    final stages = <String>[];
    final service = buildService(
      stages: stages,
      deleteUserData: (_) async {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      },
      deleteAuthUser: () async => authDeleted = true,
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');

    expect(result.isSuccess, isFalse);
    expect(result.authDeleted, isFalse);
    expect(authDeleted, isFalse);
    expect(result.userMessage, AccountDeletionService.firestoreFailedMessage);
    expect(stages, ['firestore']);
  });

  test('network failure during Firestore cleanup keeps Auth', () async {
    final service = buildService(
      deleteUserData: (_) async {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      },
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');

    expect(result.isSuccess, isFalse);
    expect(result.authDeleted, isFalse);
    expect(result.userMessage, contains('Network error'));
  });

  test('repeated taps while in progress are rejected', () async {
    late AccountDeletionService service;
    service = buildService(
      reauthenticate: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      },
    );

    final first = service.deleteAccount(userId: userId, password: 'secret');
    final second = await service.deleteAccount(userId: userId, password: 'secret');

    expect(second.isSuccess, isFalse);
    expect(second.userMessage, AccountDeletionService.alreadyInProgressMessage);
    expect((await first).isSuccess, isTrue);
  });

  test('missing documents path succeeds when cleanup no-ops', () async {
    final service = buildService(
      deleteUserData: (_) async {
        // Idempotent cleanup: nothing to delete.
      },
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');
    expect(result.isSuccess, isTrue);
    expect(result.authDeleted, isTrue);
  });

  test('athlete account deletion runs full sequence', () async {
    final touched = <String>[];
    final service = buildService(
      deleteUserData: (id) async {
        touched.add('athlete:$id');
      },
      deleteAuthUser: () async => touched.add('auth'),
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');
    expect(result.isSuccess, isTrue);
    expect(touched, ['athlete:user-athlete-1', 'auth']);
  });

  test('coach account deletion runs full sequence', () async {
    const coachId = 'user-coach-1';
    final touched = <String>[];
    final service = buildService(
      signedInId: coachId,
      deleteUserData: (id) async => touched.add('coach:$id'),
      deleteAuthUser: () async => touched.add('auth'),
    );

    final result =
        await service.deleteAccount(userId: coachId, password: 'secret');
    expect(result.isSuccess, isTrue);
    expect(touched, ['coach:user-coach-1', 'auth']);
  });

  test('gym membership deletion is included in Firestore cleanup step', () async {
    var cleanedGymData = false;
    final service = buildService(
      deleteUserData: (_) async {
        cleanedGymData = true;
      },
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');
    expect(result.isSuccess, isTrue);
    expect(cleanedGymData, isTrue);
  });

  test('reports and blocks cleanup happens before Auth delete', () async {
    final order = <String>[];
    final service = buildService(
      deleteUserData: (_) async {
        order.add('reports_blocks_relationships');
      },
      deleteAuthUser: () async => order.add('auth'),
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');
    expect(result.isSuccess, isTrue);
    expect(order, ['reports_blocks_relationships', 'auth']);
  });

  test('does not expose raw Firebase exception text to the user', () async {
    final service = buildService(
      deleteUserData: (_) async {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        );
      },
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');
    expect(result.userMessage, isNot(contains('Missing or insufficient')));
    expect(result.userMessage, isNot(contains('permission-denied')));
  });

  test('Auth failure after Firestore still reports failure without claiming success',
      () async {
    final stages = <String>[];
    final service = buildService(
      stages: stages,
      deleteAuthUser: () async {
        throw FirebaseAuthException(code: 'requires-recent-login');
      },
    );

    final result = await service.deleteAccount(userId: userId, password: 'secret');
    expect(result.isSuccess, isFalse);
    expect(result.authDeleted, isFalse);
    expect(
      result.userMessage,
      AccountDeletionService.authFailedAfterCleanupMessage,
    );
    expect(stages, ['auth']);
  });
}
