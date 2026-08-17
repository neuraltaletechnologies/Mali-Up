import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Device notifications: system-tray alerts fired reactively while the app
/// is open, plus the unread-badge count shown on the shell's bell icon.
///
/// There is no background execution in this app (no WorkManager/exact
/// alarms), so nothing here is scheduled — [showLocalNotification] is only
/// ever called from [NotificationAggregatorService] while the app is
/// running. Mirrors the static-singleton shape of [SecurityService].
class NotificationService {
  static const _channelId = 'mali_up_alerts';
  static const _channelName = 'Mali Up Alerts';
  static const _channelDescription =
      'Low stock, overdue debts, overdue invoices, sync issues';

  /// Live unread count, driven by [NotificationAggregatorService] and read
  /// by the bell icon badge.
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Sets up the plugin and the Android notification channel. Does NOT
  /// request the OS permission — call [requestPermission] from a deliberate
  /// user action instead (opening the Notifications screen).
  static Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
      _initialized = true;
    } catch (e) {
      // Never let notification setup block app startup.
      debugPrint('[NotificationService] initialize failed: $e');
    }
  }

  static Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPermission() async {
    try {
      return (await Permission.notification.status).isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Shows (or, for a repeated [id], updates in place) a system tray
  /// notification. Callers derive [id] as a stable hash of the alert's
  /// dedup key so re-showing the same key never stacks duplicates.
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showLocalNotification failed: $e');
    }
  }

  /// Stable, platform-int-safe id for a dedup key, so repeated alerts for
  /// the same entity update the same tray notification instead of stacking.
  static int idForKey(String businessId, String type, String? entityId) {
    return Object.hash(businessId, type, entityId ?? '') & 0x7fffffff;
  }
}
