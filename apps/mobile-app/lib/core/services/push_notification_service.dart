import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Remote push notifications (FCM) — the server-driven counterpart to
/// [NotificationService]'s reactive on-device alerts. An admin composes a
/// message in the admin console (apps/admin "Notifications" page); the
/// `sendAdminBroadcast` Cloud Function (functions/src/notifications.ts) fans
/// it out to every device token registered here, under
/// `users/{uid}/fcm_tokens/{token}`.
///
/// Mirrors the static-singleton shape of [NotificationService] /
/// SecurityService. Not covered by the offline-first sync repositories —
/// this is a one-way registry the Cloud Function reads via the Admin SDK,
/// nothing here is ever read back by the client.
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenRefreshSub;
  static bool _listenersAttached = false;

  /// Emits an in-app route whenever the user taps a push notification that
  /// carries a `route` data field (foreground tap, background tap, or the
  /// app being opened cold from a tap) — consumed by
  /// `pushNotificationRouteProvider` in the widget tree.
  static final _routeController = StreamController<String>.broadcast();
  static Stream<String> get routeStream => _routeController.stream;

  /// Requests the OS permission (iOS prompts explicitly; Android 13+ shares
  /// the POST_NOTIFICATIONS permission already requested by
  /// [NotificationService.requestPermission]), registers the current
  /// device's token under [uid], and starts listening for messages. Safe to
  /// call again on a uid change — the previous token subscription is
  /// replaced, not stacked.
  static Future<void> initialize(String uid) async {
    try {
      await _messaging.requestPermission();

      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));

      // Message listeners are process-wide, not per-user — attach once.
      if (!_listenersAttached) {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
        final initial = await _messaging.getInitialMessage();
        if (initial != null) _handleOpenedMessage(initial);
        _listenersAttached = true;
      }
    } catch (e) {
      // Never let push setup block sign-in or app usage.
      debugPrint('[PushNotificationService] initialize failed: $e');
    }
  }

  /// Forgets this device's token for [uid] — call on sign-out so a shared
  /// device doesn't keep receiving a previous account's pushes.
  static Future<void> dispose(String uid) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('fcm_tokens')
            .doc(token)
            .delete();
      }
    } catch (e) {
      debugPrint('[PushNotificationService] token cleanup failed: $e');
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[PushNotificationService] failed to save token: $e');
    }
  }

  /// App is foregrounded — FCM never auto-displays in that state, so show
  /// it through the same local-notification channel reactive alerts use.
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    NotificationService.showLocalNotification(
      id: message.hashCode & 0x7fffffff,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: message.data['route'] as String?,
    );
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) _routeController.add(route);
  }
}
