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
final isOnlineProvider = Provider<bool>((ref) {
  final results =
      ref.watch(connectivityStreamProvider).valueOrNull ?? const [];
  return results.any((r) => r != ConnectivityResult.none);
});
