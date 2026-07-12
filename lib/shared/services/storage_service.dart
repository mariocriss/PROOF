import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    final ref = _storage.ref().child('avatars/$userId/profile.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadGymLogo({
    required String gymId,
    required File file,
  }) async {
    final ref = _storage.ref().child('gyms/$gymId/logo.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadProofMedia({
    required String userId,
    required String proofId,
    required File file,
  }) async {
    final ref = _storage.ref().child('proofs/$userId/$proofId/media');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
