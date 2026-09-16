import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Raw stream of connectivity events. Rebuilt whenever the network state
/// changes (WiFi, mobile, none).
///
/// `onConnectivityChanged` only emits on transitions, so without seeding it
/// with the current state first, every consumer reads `valueOrNull == null`
/// (treated as offline) from app launch until the next network change.
final connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) async* {
  yield await Connectivity().checkConnectivity();
  yield* Connectivity().onConnectivityChanged;
});

/// True when at least one active connection type is present.
/// Used by SyncManager to gate outbound Firestore operations.
///
/// While `checkConnectivity()` is still resolving (the platform channel call
/// itself is async), the stream has no value yet. Defaulting that window to
/// "online" avoids a false "Offline" flash on cold start for the common case
/// of an actually-connected device; a real offline device corrects to `false`
/// as soon as the check resolves a moment later.
final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStreamProvider);
  return async.maybeWhen(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    orElse: () => true,
  );
});
