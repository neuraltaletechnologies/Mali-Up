// TEMPLATE FILE - DO NOT COMMIT REAL CREDENTIALS
// This is a template showing the structure of firebase_options.dart
// 
// TO SET UP FIREBASE CREDENTIALS:
// 1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
// 2. Run: `flutterfire configure`
// 3. Select your Firebase project
// 4. FlutterFire will auto-generate lib/firebase_options.dart with real credentials
// 5. Add lib/firebase_options.dart to .gitignore (already done)
// 6. Commit this template instead
//
// The generated file should have:
// - Real apiKey (from Firebase Console > Project Settings)
// - Real appId (from Firebase Console > Project Settings)
// - Real messagingSenderId (from Firebase Console > Project Settings)
// - Real projectId (your Firebase project ID)
// - Real storageBucket (from Firebase Console > Project Settings)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  // EXAMPLE ONLY - Fill in with real values from `flutterfire configure`
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  // EXAMPLE ONLY - Fill in with real values from `flutterfire configure`
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.neuraltale.maliup',
  );
}
