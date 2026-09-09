import 'package:flutter/foundation.dart';

/// Central hook for reporting caught, non-fatal errors.
///
/// The app shipped `sentry_flutter` for this, but release builds never carried
/// a `SENTRY_DSN`, so it was inert in production while still adding ~1.5 MB of
/// native code to every install. It was removed for app size. This shim keeps a
/// single call site for every `catch` block so a real reporter (e.g.
/// `firebase_crashlytics`, which is cheap on top of the Firebase SDK already
/// bundled) can be wired back in one place later.
///
/// For now: log in debug, do nothing in release.
abstract final class ErrorReporter {
  /// Records a caught exception. Never throws.
  static void captureException(Object error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[ErrorReporter] $error');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
  }

  /// Clears any user context held by the reporter. No-op today; kept so the
  /// former `Sentry.configureScope((s) => s.setUser(null))` call sites have a
  /// stable target if a reporter is reintroduced.
  static void clearUser() {}
}
