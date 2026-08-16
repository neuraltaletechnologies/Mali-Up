import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'plan_service.dart';

/// Client for the `createClickPesaPayment` / `verifyClickPesaPayment` Cloud
/// Functions (`functions/src/clickpesa.ts`).
///
/// The app never talks to ClickPesa directly and never holds a ClickPesa API
/// key: both the create-payment call and the payment-status poll are proxied
/// through Cloud Functions, which hold the real secret and are the only code
/// path allowed to write `plan`/`planExpiresAt`/`lastPayment` on the user's
/// Firestore doc (see firestore.rules — client writes to those fields are
/// rejected). This also means the amount charged always comes from the
/// admin-configured price on the server, never from anything the client says.
class ClickPesaService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Creates a ClickPesa payment for [tier] and returns the URL to open.
  static Future<ClickPesaPaymentResponse> createPayment({
    required PlanTier tier,
    String? returnUrl,
  }) async {
    if (tier != PlanTier.growth && tier != PlanTier.business) {
      throw ArgumentError.value(tier, 'tier', 'Must be growth or business.');
    }
    try {
      debugPrint('[ClickPesa] Creating payment for ${tier.name}');
      final callable = _functions.httpsCallable('createClickPesaPayment');
      final result = await callable.call<Map<String, dynamic>>({
        'tier': tier.name,
        'returnUrl': ?returnUrl,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      debugPrint('[ClickPesa] Payment created: ${data['paymentId']}');
      return ClickPesaPaymentResponse.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[ClickPesa] Error creating payment: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Checks the real ClickPesa status for [paymentId] via the server. The
  /// first time this reports `completed`, the plan has already been
  /// activated server-side — there is no separate client-side activation
  /// step.
  static Future<ClickPesaVerifyResult> verifyPayment(String paymentId) async {
    try {
      final callable = _functions.httpsCallable('verifyClickPesaPayment');
      final result = await callable.call<Map<String, dynamic>>({
        'paymentId': paymentId,
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
  /// [maxAttempts] is reached. Returns the completed result; throws on
  /// failure or timeout.
  static Future<ClickPesaVerifyResult> waitForPayment({
    required String paymentId,
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 3),
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final result = await verifyPayment(paymentId);
        if (result.status == ClickPesaStatus.completed) return result;
        if (result.status == ClickPesaStatus.failed) {
          throw Exception('Payment failed');
        }
      } on FirebaseFunctionsException {
        rethrow;
      }
      await Future.delayed(interval);
    }
    throw Exception('Payment verification timeout');
  }
}

enum ClickPesaStatus { completed, pending, failed }

/// Response from creating a payment.
class ClickPesaPaymentResponse {
  final String paymentId;
  final String paymentUrl;
  final String reference;
  final int amount;
  final String currency;

  ClickPesaPaymentResponse({
    required this.paymentId,
    required this.paymentUrl,
    required this.reference,
    required this.amount,
    required this.currency,
  });

  factory ClickPesaPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ClickPesaPaymentResponse(
      paymentId: json['paymentId'] as String,
      paymentUrl: json['paymentUrl'] as String,
      reference: json['reference'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
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
