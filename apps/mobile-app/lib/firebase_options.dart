// Lightweight runtime Firebase options loader.
// This file intentionally avoids committing real credentials.
// Preferred developer workflow: generate a local `lib/firebase_options.dart` via
// the FlutterFire CLI or provide overrides via `--dart-define` when building.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'firebase_options.template.dart' as _template;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Try to read values from `--dart-define` at build time. If the
    // required `FIREBASE_API_KEY` is provided, construct options from
    // the environment. Otherwise fallback to the included template which
    // contains placeholders (developers should generate a real file).
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    if (apiKey.isNotEmpty) {
      const appId = String.fromEnvironment('FIREBASE_APP_ID');
      const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
      const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
      const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
      const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

      final opts = FirebaseOptions(
        apiKey: apiKey,
        appId: appId.isNotEmpty ? appId : '',
        messagingSenderId: messagingSenderId.isNotEmpty ? messagingSenderId : '',
        projectId: projectId.isNotEmpty ? projectId : '',
        storageBucket: storageBucket.isNotEmpty ? storageBucket : null,
        authDomain: authDomain.isNotEmpty ? authDomain : null,
        measurementId: measurementId.isNotEmpty ? measurementId : null,
      );

      // For web we expect web-specific values; the caller should ensure
      // they set the correct env when building for web.
      return opts;
    }

    // No runtime overrides — return the template (placeholder) defaults.
    if (kIsWeb) return _template.DefaultFirebaseOptions.web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _template.DefaultFirebaseOptions.android;
      case TargetPlatform.iOS:
        return _template.DefaultFirebaseOptions.ios;
      case TargetPlatform.macOS:
        return _template.DefaultFirebaseOptions.macos;
      case TargetPlatform.windows:
        return _template.DefaultFirebaseOptions.windows;
      case TargetPlatform.linux:
      default:
        return _template.DefaultFirebaseOptions.android;
    }
  }
}
