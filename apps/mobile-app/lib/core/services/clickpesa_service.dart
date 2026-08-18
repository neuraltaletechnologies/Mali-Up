import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'plan_service.dart';

/// Client for the `initiateClickPesaPayment` / `verifyClickPesaPayment` Cloud
/// Functions (`functions/src/clickpesa.ts`).
///
/// Uses ClickPesa's USSD-Push flow: the server pushes a mobile-money PIN
/// prompt straight to the user's phone (M-Pesa/Tigo Pesa/Airtel Money/
/// HaloPesa) — there is no checkout page or browser hop. The app never talks
/// to ClickPesa directly and never holds a ClickPesa API key: both calls are
/// proxied through Cloud Functions, which hold the real secret and are the
/// only code path allowed to write `plan`/`planExpiresAt`/`lastPayment` on
/// the user's Firestore doc (see firestore.rules — client writes to those
/// fields are rejected). This also means the amount charged always comes
/// from the admin-configured price on the server, never from anything the
/// client says.
class ClickPesaService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Pushes a payment prompt to [phoneNumber] for [tier]. Accepts common
  /// Tanzanian phone formats (0712345678, +255712345678, 255712345678) —
  /// the server normalizes and validates it.
  static Future<ClickPesaInitiateResult> initiatePayment({
    required PlanTier tier,
    required String phoneNumber,
  }) async {
    if (tier != PlanTier.growth && tier != PlanTier.business) {
      throw ArgumentError.value(tier, 'tier', 'Must be growth or business.');
    }
    try {
      debugPrint('[ClickPesa] Initiating USSD push for ${tier.name}');
      final callable = _functions.httpsCallable('initiateClickPesaPayment');
      final result = await callable.call<Map<String, dynamic>>({
        'tier': tier.name,
        'phoneNumber': phoneNumber,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      debugPrint('[ClickPesa] Push sent: ${data['orderReference']}');
      return ClickPesaInitiateResult.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[ClickPesa] Error initiating payment: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Checks the real ClickPesa status for [orderReference] via the server.
  /// The first time this reports `completed`, the plan has already been
  /// activated server-side — there is no separate client-side activation
  /// step.
  static Future<ClickPesaVerifyResult> verifyPayment(String orderReference) async {
    try {
      final callable = _functions.httpsCallable('verifyClickPesaPayment');
      final result = await callable.call<Map<String, dynamic>>({
        'orderReference': orderReference,
      });
      return ClickPesaVerifyResult.fromJson(
        Map<String, dynamic>.from(result.data as Map),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[ClickPesa] Error verifying payment: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Polls [verifyPayment] until the payment completes, fails, or
  /// [maxAttempts] is reached — i.e. while the user is entering their PIN on
  /// the USSD prompt. Returns the completed result; throws on failure or
  /// timeout.
  ///
  /// [maxAttempts] x [interval] is the hard timer on how long this will
  /// wait — 40 x 3s = 2 minutes by default — after which it throws rather
  /// than polling forever. Pass [isCancelled] so the caller can stop the
  /// polling immediately (e.g. the UI showing progress was dismissed)
  /// instead of continuing to call the server in the background until that
  /// timer runs out; a cancelled wait throws [ClickPesaCancelledException]
  /// rather than a generic failure, so callers can tell the two apart.
  static Future<ClickPesaVerifyResult> waitForPayment({
    required String orderReference,
    int maxAttempts = 40,
    Duration interval = const Duration(seconds: 3),
    bool Function()? isCancelled,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      if (isCancelled?.call() ?? false) {
        throw const ClickPesaCancelledException();
      }
      final result = await verifyPayment(orderReference);
      if (result.status == ClickPesaStatus.completed) return result;
      if (result.status == ClickPesaStatus.failed) {
        throw Exception('Payment failed');
      }
      if (isCancelled?.call() ?? false) {
        throw const ClickPesaCancelledException();
      }
      await Future.delayed(interval);
    }
    throw Exception('Payment verification timeout');
  }
}

/// Thrown by [ClickPesaService.waitForPayment] when its `isCancelled`
/// callback reports true — e.g. the screen showing payment progress was
/// dismissed while still waiting. Distinct from a real payment failure so
/// callers can stay silent instead of surfacing an error message for
/// something the user chose to walk away from.
class ClickPesaCancelledException implements Exception {
  const ClickPesaCancelledException();
  @override
  String toString() => 'ClickPesaCancelledException: payment wait cancelled';
}

enum ClickPesaStatus { completed, pending, failed }

/// Result of an `initiateClickPesaPayment` call.
class ClickPesaInitiateResult {
  final String orderReference;
  final String status;
  final String? channel;

  ClickPesaInitiateResult({required this.orderReference, required this.status, this.channel});

  factory ClickPesaInitiateResult.fromJson(Map<String, dynamic> json) {
    return ClickPesaInitiateResult(
      orderReference: json['orderReference'] as String,
      status: json['status'] as String? ?? 'PROCESSING',
      channel: json['channel'] as String?,
    );
  }
}

/// Result of a `verifyClickPesaPayment` call.
class ClickPesaVerifyResult {
  final ClickPesaStatus status;
  final PlanTier? tier;
  final DateTime? planExpiresAt;

  ClickPesaVerifyResult({required this.status, this.tier, this.planExpiresAt});

  factory ClickPesaVerifyResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = ClickPesaStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => ClickPesaStatus.pending,
    );
    return ClickPesaVerifyResult(
      status: status,
      tier: json['tier'] != null ? PlanTierX.fromString(json['tier'] as String) : null,
      planExpiresAt: json['planExpiresAt'] != null
          ? DateTime.tryParse(json['planExpiresAt'] as String)
          : null,
    );
  }
}
