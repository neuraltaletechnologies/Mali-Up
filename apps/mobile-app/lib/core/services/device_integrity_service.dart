import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../features/rbac/data/audit_log_service.dart';
import 'error_reporter.dart';
import 'sentry_metrics_service.dart';

/// Requests a Play Integrity token for the current device, verifies it via
/// the `checkDeviceIntegrity` Cloud Function, and records the verdict in the
/// business audit log.
///
/// Android-only (Play Integrity has no Android-independent equivalent); a
/// no-op everywhere else. Every failure is swallowed and reported to Sentry
/// only — this is informational logging, it must never block or delay
/// sign-in.
class DeviceIntegrityService {
  DeviceIntegrityService._();

  static const _channel = MethodChannel('com.neuraltale.maliup/play_integrity');

  static Future<void> checkAndLog({
    required String businessId,
    required String performedByUid,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final nonce = _generateNonce();
      final token =
          await _channel.invokeMethod<String>('requestToken', {'nonce': nonce});
      if (token == null || token.isEmpty) return;

      final callable =
          FirebaseFunctions.instance.httpsCallable('checkDeviceIntegrity');
      final response = await callable.call<Map<String, dynamic>>({
        'integrityToken': token,
        'nonce': nonce,
      });
      final data = Map<String, dynamic>.from(response.data as Map);

      final deviceRecognitionVerdict =
          List<String>.from(data['deviceRecognitionVerdict'] as List? ?? const []);
      final playProtectVerdict = data['playProtectVerdict'] as String?;

      SentryMetricsService.deviceIntegrityChecked(
        deviceVerdict: deviceRecognitionVerdict,
        playProtectVerdict: playProtectVerdict,
      );

      await AuditLogService().logDeviceIntegrity(
        businessId: businessId,
        performedByUid: performedByUid,
        deviceRecognitionVerdict: deviceRecognitionVerdict,
        recentDeviceActivityLevel: data['recentDeviceActivityLevel'] as String?,
        sdkVersion: data['sdkVersion'] as int?,
        playProtectVerdict: playProtectVerdict,
        appAccessRiskApps: data['appAccessRiskApps'] == null
            ? null
            : List<String>.from(data['appAccessRiskApps'] as List),
        appRecognitionVerdict: data['appRecognitionVerdict'] as String?,
        appLicensingVerdict: data['appLicensingVerdict'] as String?,
      );
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
    }
  }

  static String _generateNonce() {
    final raw = '${const Uuid().v4()}-${DateTime.now().microsecondsSinceEpoch}';
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }
}
