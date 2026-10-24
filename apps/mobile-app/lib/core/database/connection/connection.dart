// Picks the Drift executor for the current platform. Native builds keep the
// persistent on-device SQLite file (offline-first); the web build uses a
// throwaway in-memory database instead — see web.dart.
export 'native.dart' if (dart.library.js_interop) 'web.dart';
