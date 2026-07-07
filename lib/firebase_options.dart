import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration.
///
/// Replace with real values by running:
///   dart pub global activate flutterfire_cli
///   flutterfire configure
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for PROOF.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOAYuogWwuuDyd9qmSx-UD3hi0-sCaxE4',
    appId: '1:233832067155:android:fa291498fc7a7158e096a6',
    messagingSenderId: '233832067155',
    projectId: 'proof-e913a',
    storageBucket: 'proof-e913a.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCe1dnpGBpFHMm-r_BrDQJ5GTPouOoX49s',
    appId: '1:233832067155:ios:4fd9d33d8df724e7e096a6',
    messagingSenderId: '233832067155',
    projectId: 'proof-e913a',
    storageBucket: 'proof-e913a.firebasestorage.app',
    iosBundleId: 'com.proof.proof',
  );
}
