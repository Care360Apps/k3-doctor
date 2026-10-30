// K3 secure environment-based Firebase initialization.
// No production Firebase project identifiers are committed to this repository.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError('K3 Firebase configured only for Android/iOS.');
    }
    const apiKey = String.fromEnvironment('K3_FIREBASE_API_KEY');
    const appId = String.fromEnvironment('K3_FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('K3_FIREBASE_SENDER_ID');
    const projectId = String.fromEnvironment('K3_FIREBASE_PROJECT_ID');
    const storageBucket = String.fromEnvironment('K3_FIREBASE_STORAGE_BUCKET');
    if (apiKey.isEmpty || appId.isEmpty || senderId.isEmpty || projectId.isEmpty) {
      throw StateError('Missing required Firebase configuration for K3 build.');
    }
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }
}
