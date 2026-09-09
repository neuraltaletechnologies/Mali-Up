import 'package:flutter/foundation.dart';

/// Product-metric counters.
///
/// These used to flow to `Sentry.metrics`. `sentry_flutter` was removed for app
/// size (it was inert in production anyway — no DSN was ever shipped), so every
/// method here is now a no-op that only logs in debug. The typed API is kept
/// intact so the ~20 call sites don't change; wire `firebase_analytics` (or
/// another sink) into [_record] when product metrics are wanted back.
///
/// TODO: rename to `ProductMetricsService` — no longer Sentry-backed.
class SentryMetricsService {
  static bool _enabled = false;

  const SentryMetricsService._();

  static void configure({required bool enabled}) {
    _enabled = enabled;
  }

  static bool get enabled => _enabled;

  static void _record(
    String kind,
    String name,
    num value,
    Map<String, String>? attributes,
  ) {
    if (!_enabled) return;
    if (kDebugMode) {
      final tags = (attributes == null || attributes.isEmpty)
          ? ''
          : ' ${attributes.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
      debugPrint('[metrics] $kind $name=$value$tags');
    }
  }

  static void count(
    String name,
    int value, {
    Map<String, String>? attributes,
  }) {
    _record('count', name, value, attributes);
  }

  static void gauge(
    String name,
    num value, {
    String? unit,
    Map<String, String>? attributes,
  }) {
    _record('gauge', name, value, attributes);
  }

  static void distribution(
    String name,
    num value, {
    String? unit,
    Map<String, String>? attributes,
  }) {
    _record('distribution', name, value, attributes);
  }

  static void appLaunched({required bool sentryEnabled}) {
    count(
      'app_launch',
      1,
      attributes: {'sentry_enabled': sentryEnabled.toString()},
    );
  }

  static void salesCreated({required String status}) {
    count('sales_created', 1, attributes: {'status': status});
  }

  static void invoicePrinted({required String surface}) {
    count('invoice_printed', 1, attributes: {'surface': surface});
  }

  static void customerAdded({required String source}) {
    count('customer_added', 1, attributes: {'source': source});
  }

  static void scannerAttempt({required bool success}) {
    count(
      'barcode_scan',
      1,
      attributes: {'result': success ? 'success' : 'miss'},
    );
  }

  static void scanToCartTime(Duration elapsed) {
    distribution(
      'scan_to_cart_time_ms',
      elapsed.inMilliseconds,
      unit: 'millisecond',
    );
  }

  static void authSuccess(String method) {
    count('auth_success', 1, attributes: {'method': method});
  }

  static void authFailure(String method, String reason) {
    count(
      'auth_failure',
      1,
      attributes: {'method': method, 'reason': reason},
    );
  }

  static void deviceIntegrityChecked({
    required List<String> deviceVerdict,
    String? playProtectVerdict,
  }) {
    count(
      'device_integrity_checked',
      1,
      attributes: {
        'device_verdict': deviceVerdict.isEmpty
            ? 'none'
            : deviceVerdict.join(','),
        'play_protect_verdict': playProtectVerdict ?? 'unknown',
      },
    );
  }

  static void syncCycleCompleted({
    required bool success,
    required int queueSize,
  }) {
    count(
      'sync_cycle',
      1,
      attributes: {'result': success ? 'success' : 'error'},
    );
    if (queueSize > 0) {
      gauge('sync_queue_size', queueSize);
    }
  }

  static void syncConflict(String entityType) {
    count('sync_conflict', 1, attributes: {'entity_type': entityType});
  }

  static void expenseAdded() {
    count('expense_added', 1);
  }

  static void debtAdded() {
    count('debt_added', 1);
  }

  static void reportGenerated(String reportType) {
    count('report_generated', 1, attributes: {'report_type': reportType});
  }

  static void inventoryUpdated(String action) {
    count('inventory_updated', 1, attributes: {'action': action});
  }
}
