import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_service.dart';
import 'auth_provider.dart';

/// Registers/deregisters this device's FCM token as the signed-in user
/// changes. Public activation hook — watch exactly once, high in the
/// authenticated app shell (mirrors
/// notificationAggregatorActivatorProvider's shape).
final pushTokenRegistrarProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return;
  // firebase_messaging has no Windows/Linux implementation — the desktop
  // build gets only the on-device alerts from NotificationService.
  if (!PushNotificationService.isSupported) return;

  // ignore: unawaited_futures — fire-and-forget registration, never blocks UI.
  PushNotificationService.initialize(uid);

  ref.onDispose(() {
    // ignore: unawaited_futures
    PushNotificationService.dispose(uid);
  });
});

/// Emits an in-app route whenever a push notification carrying a `route`
/// data field is tapped — the shell listens to this and navigates.
final pushNotificationRouteProvider = StreamProvider<String>((ref) {
  return PushNotificationService.routeStream;
});
