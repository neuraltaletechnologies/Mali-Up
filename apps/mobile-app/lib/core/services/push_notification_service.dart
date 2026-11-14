import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localization_service.dart';
import 'notification_service.dart';

/// Remote push notifications (FCM) — the server-driven counterpart to
/// [NotificationService]'s reactive on-device alerts. An admin composes a
/// message in the admin console (apps/admin "Notifications" page); the
/// `sendAdminBroadcast` Cloud Function (functions/src/notifications.ts)
/// sends it to FCM **topics**, and FCM fans it out to every subscribed
/// device. No device tokens are stored server-side, so a broadcast costs the
/// same whether there are 10 installs or 10 million.
///
/// Topics this device subscribes to (see [PushTopics]):
///   * `all_<lang>` — every signed-in device, in its app language.
///   * `biz_<businessId>_<lang>` — devices whose active business is that one.
/// The language suffix lets the server send each user their own copy.
///
/// Mirrors the static-singleton shape of [NotificationService] /
/// SecurityService. All topic/token operations run through one serial queue
/// so a sign-out's unsubscribe can never interleave with a sign-in's
/// subscribe.
class PushNotificationService {
  /// FCM runs on Android, iOS and macOS. Web is excluded until the
  /// `firebase-messaging-sw.js` service worker + VAPID key are wired up — the
  /// web SDK also can't subscribe to topics from the client, so it needs a
  /// server-side subscribe call too.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static const _prefsKey = 'push_subscribed_topics';

  /// FCM topic/token calls can stay pending while offline; cap them so one
  /// stuck call can't stall the queue (a timed-out topic isn't recorded, so
  /// it's retried on the next [setTopics]).
  static const _opTimeout = Duration(seconds: 20);

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _listenersAttached = false;
  static Future<void> _queue = Future<void>.value();

  /// uid [initialize] last set up (null after [dispose]), and the latest
  /// topics requested for a uid. Kept separate so the order the providers
  /// call [initialize] / [setTopics] / [dispose] in doesn't matter — topics
  /// are only applied once the matching session is live.
  static String? _sessionUid;
  static String? _desiredUid;
  static Set<String> _desired = const {};

  /// Emits an in-app route whenever the user taps a push notification that
  /// carries a `route` data field (foreground tap, background tap, or the
  /// app being opened cold from a tap) — consumed by
  /// `pushNotificationRouteProvider` in the widget tree.
  static final _routeController = StreamController<String>.broadcast();
  static Stream<String> get routeStream => _routeController.stream;

  /// Runs [op] after every previously queued operation, never concurrently.
  static Future<void> _serial(Future<void> Function() op) {
    final next = _queue.then((_) => op()).catchError((Object e) {
      debugPrint('[PushNotificationService] $e');
    });
    _queue = next;
    return next;
  }

  /// Requests the OS permission (iOS prompts explicitly; Android 13+ shares
  /// the POST_NOTIFICATIONS permission already requested by
  /// [NotificationService.requestPermission]) and starts listening for
  /// messages. Safe to call repeatedly.
  static Future<void> initialize(String uid) => _serial(() async {
    _sessionUid = uid;

    // Message listeners are process-wide, not per-user — attach once.
    if (!_listenersAttached) {
      _listenersAttached = true;
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
      NotificationService.tapPayloads.listen(_handleLocalTap);
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _handleOpenedMessage(initial);
    }

    try {
      await _messaging.requestPermission();
    } catch (e) {
      debugPrint('[PushNotificationService] requestPermission failed: $e');
    }
    // Topic calls throw without APNs; a later setTopics() retries.
    if (!await _apnsReady()) return;

    // Pre-topics builds registered tokens under users/{uid}/fcm_tokens
    // and the Cloud Function still sends to whatever is left there (for
    // devices that haven't updated yet). Drop this device's entry now
    // that it receives via topics, so it isn't sent everything twice.
    try {
      final token = await _messaging.getToken().timeout(_opTimeout);
      if (token != null) {
        // Not awaited: with Firestore persistence off, a delete made
        // offline only completes once it reaches the server.
        unawaited(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('fcm_tokens')
              .doc(token)
              .delete()
              .catchError((Object _) {}),
        );
      }
    } catch (_) {
      // Best-effort; a leftover entry only means a duplicate push.
    }

    await _applyTopics();
  });

  /// Makes [uid]'s device topic subscriptions exactly [desired]: subscribes
  /// to the new ones and unsubscribes from ones no longer wanted (business
  /// switch, language change). Applied now if [uid]'s session is live, else
  /// as soon as [initialize] for [uid] finishes.
  static Future<void> setTopics(String uid, Set<String> desired) {
    _desiredUid = uid;
    _desired = desired;
    return _serial(_applyTopics);
  }

  /// Only topics FCM confirmed are recorded, so a failed subscribe (offline,
  /// APNs not ready) is retried on the next call.
  static Future<void> _applyTopics() async {
    if (_sessionUid == null || _sessionUid != _desiredUid) return;
    final desired = _desired;
    if (!await _apnsReady()) return;
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_prefsKey) ?? const []).toSet();

    for (final topic in current.difference(desired)) {
      try {
        await _messaging.unsubscribeFromTopic(topic).timeout(_opTimeout);
        current.remove(topic);
      } catch (e) {
        debugPrint('[PushNotificationService] unsubscribe $topic: $e');
      }
    }
    for (final topic in desired.difference(current)) {
      try {
        await _messaging.subscribeToTopic(topic).timeout(_opTimeout);
        current.add(topic);
      } catch (e) {
        debugPrint('[PushNotificationService] subscribe $topic: $e');
      }
    }
    await prefs.setStringList(_prefsKey, current.toList());
  }

  /// Sign-out: stop this device receiving the previous account's pushes.
  /// Deleting the FCM token drops every topic subscription server-side in
  /// one go (and needs no Firestore auth, which is already gone by the time
  /// this runs). The next sign-in gets a fresh token and resubscribes.
  static Future<void> dispose() => _serial(() async {
    _sessionUid = null;
    try {
      await _messaging.deleteToken().timeout(_opTimeout);
    } catch (e) {
      debugPrint('[PushNotificationService] deleteToken failed: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  });

  /// iOS: token/topic calls throw until APNs has handed the device token to
  /// FCM, which happens asynchronously after launch. Wait briefly.
  static Future<bool> _apnsReady() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return true;
    }
    String? apns = await _messaging.getAPNSToken();
    for (var i = 0; apns == null && i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      apns = await _messaging.getAPNSToken();
    }
    if (apns == null) {
      debugPrint('[PushNotificationService] APNs token unavailable');
    }
    return apns != null;
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

  /// A tapped local notification — only push-originated ones carry a route
  /// (reactive alerts use `type:id` payloads, which are ignored here).
  static void _handleLocalTap(String payload) {
    if (payload.startsWith('/')) _routeController.add(payload);
  }
}

/// FCM topic names. Must stay in sync with `topicsFor()` in
/// functions/src/notifications.ts.
class PushTopics {
  static String _lang(AppLanguage language) =>
      language == AppLanguage.swahili ? 'sw' : 'en';

  /// FCM topic names allow only `[a-zA-Z0-9-_.~%]`.
  static String _safe(String id) =>
      id.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');

  static String all(AppLanguage language) => 'all_${_lang(language)}';

  static String business(String businessId, AppLanguage language) =>
      'biz_${_safe(businessId)}_${_lang(language)}';

  static Set<String> forUser({
    required String businessId,
    required AppLanguage language,
  }) => {
    all(language),
    if (businessId.isNotEmpty) business(businessId, language),
  };
}
