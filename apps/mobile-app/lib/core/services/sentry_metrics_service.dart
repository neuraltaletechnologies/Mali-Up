import 'package:sentry_flutter/sentry_flutter.dart';

class SentryMetricsService {
  static bool _enabled = false;

  const SentryMetricsService._();

  static void configure({required bool enabled}) {
    _enabled = enabled;
  }

  static bool get enabled => _enabled;

  static void count(
    String name,
    int value, {
    Map<String, SentryAttribute>? attributes,
  }) {
    if (!_enabled) return;
    Sentry.metrics.count(name, value, attributes: attributes);
  }

  static void gauge(
    String name,
    num value, {
    String? unit,
    Map<String, SentryAttribute>? attributes,
  }) {
    if (!_enabled) return;
    Sentry.metrics.gauge(name, value, unit: unit, attributes: attributes);
  }

  static void distribution(
    String name,
    num value, {
    String? unit,
    Map<String, SentryAttribute>? attributes,
  }) {
    if (!_enabled) return;
    Sentry.metrics.distribution(
      name,
      value,
      unit: unit,
      attributes: attributes,
    );
  }

  static void appLaunched({required bool sentryEnabled}) {
    count(
      'app_launch',
      1,
      attributes: {
        'sentry_enabled': SentryAttribute.string(sentryEnabled.toString()),
      },
    );
  }

  static void salesCreated({required num amount, required String status}) {
    count(
      'sales_created',
      1,
      attributes: {
        'status': SentryAttribute.string(status),
      },
    );
    gauge(
      'sales_created_amount',
      amount,
      attributes: {'status': SentryAttribute.string(status)},
    );
  }

  static void invoicePrinted({required String surface}) {
    count(
      'invoice_printed',
      1,
      attributes: {
        'surface': SentryAttribute.string(surface),
      },
    );
  }

  static void customerAdded({required String source}) {
    count(
      'customer_added',
      1,
      attributes: {
        'source': SentryAttribute.string(source),
      },
    );
  }

  static void scannerAttempt({required bool success}) {
    count(
      'barcode_scan',
      1,
      attributes: {
        'result': SentryAttribute.string(success ? 'success' : 'miss'),
      },
    );
  }

  static void scanToCartTime(Duration elapsed) {
    distribution(
      'scan_to_cart_time_ms',
      elapsed.inMilliseconds,
      unit: SentryMetricUnit.millisecond,
    );
  }

  static void authSuccess(String method) {
    count(
      'auth_success',
      1,
      attributes: {'method': SentryAttribute.string(method)},
    );
  }

  static void authFailure(String method, String reason) {
    count(
      'auth_failure',
      1,
      attributes: {
        'method': SentryAttribute.string(method),
        'reason': SentryAttribute.string(reason),
      },
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
        'device_verdict': SentryAttribute.string(
          deviceVerdict.isEmpty ? 'none' : deviceVerdict.join(','),
        ),
        'play_protect_verdict':
            SentryAttribute.string(playProtectVerdict ?? 'unknown'),
      },
    );
  }

  static void syncCycleCompleted({required bool success, required int queueSize}) {
    count(
      'sync_cycle',
      1,
      attributes: {
        'result': SentryAttribute.string(success ? 'success' : 'error'),
      },
    );
    if (queueSize > 0) {
      gauge('sync_queue_size', queueSize);
    }
  }

  static void syncConflict(String entityType) {
    count(
      'sync_conflict',
      1,
      attributes: {'entity_type': SentryAttribute.string(entityType)},
    );
  }

  static void expenseAdded() {
    count('expense_added', 1);
  }

  static void debtAdded() {
    count('debt_added', 1);
  }

  static void reportGenerated(String reportType) {
    count(
      'report_generated',
      1,
      attributes: {'report_type': SentryAttribute.string(reportType)},
    );
  }

  static void inventoryUpdated(String action) {
    count(
      'inventory_updated',
      1,
      attributes: {'action': SentryAttribute.string(action)},
    );
  }
}
