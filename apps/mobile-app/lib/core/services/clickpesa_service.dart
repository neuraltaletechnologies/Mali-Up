import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'plan_service.dart';

/// Client for the `initiateClickPesaPayment` / `verifyClickPesaPayment` /
/// `clickpesaWebhook` Cloud Functions (`functions/src/clickpesa.ts`).
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
///
/// Waiting for a result does NOT poll ClickPesa — see [waitForPayment].
class ClickPesaService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// Asks the server to check ClickPesa's real status for [orderReference]
  /// right now. Used only as the low-frequency fallback tick inside
  /// [waitForPayment] — prefer watching the Firestore doc directly, which is
  /// what actually resolves the wait. The first time this (or the webhook)
  /// sees `completed`, the plan has already been activated server-side.
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

  /// Waits for [orderReference] to resolve, without polling ClickPesa.
  ///
  /// Primarily just watches the `clickpesa_payments/{orderReference}`
  /// Firestore document in real time — free, instant, and it's ClickPesa's
  /// own webhook (see `clickpesaWebhook` in functions/src/clickpesa.ts) that
  /// writes the resolved status there the moment it confirms, typically
  /// within seconds of the user acting on the phone prompt. This replaced an
  /// earlier design that polled a Cloud Function every 3 seconds for up to 2
  /// minutes per payment — harmless at low volume, but ClickPesa's own API
  /// call quota (100/day until KYC is completed, and still finite after)
  /// made that unusable at any real scale.
  ///
  /// A low-frequency fallback poll (once every [fallbackInterval], default
  /// 20s) runs alongside the listener purely as a safety net for a webhook
  /// that isn't configured yet or a lost delivery — it doesn't produce the
  /// result itself, it just asks the server to check, which writes to the
  /// same Firestore doc the listener is already watching. Total ClickPesa
  /// usage per pending payment is at most one call per [fallbackInterval]
  /// even in the worst case (no webhook at all), and effectively zero once
  /// the webhook is set up, since the listener resolves first.
  static Future<ClickPesaVerifyResult> waitForPayment({
    required String orderReference,
    Duration timeout = const Duration(minutes: 3),
    Duration fallbackInterval = const Duration(seconds: 20),
    bool Function()? isCancelled,
  }) async {
    final completer = Completer<ClickPesaVerifyResult>();
    final deadline = DateTime.now().add(timeout);

    void finishOk(ClickPesaVerifyResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    void finishErr(Object error) {
      if (!completer.isCompleted) completer.completeError(error);
    }

    final sub = _db
        .collection('clickpesa_payments')
        .doc(orderReference)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final result = ClickPesaVerifyResult.fromJson(data);
      if (result.status == ClickPesaStatus.completed) {
        finishOk(result);
      } else if (result.status == ClickPesaStatus.failed) {
        finishErr(Exception('Payment failed'));
      }
    }, onError: finishErr);

    final fallbackTimer = Timer.periodic(fallbackInterval, (_) {
      if (completer.isCompleted) return;
      unawaited(() async {
        try {
          await verifyPayment(orderReference);
        } catch (e) {
          debugPrint('[ClickPesa] fallback poll error: $e');
        }
      }());
    });

    final watchdog = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (completer.isCompleted) return;
      if (isCancelled?.call() ?? false) {
        finishErr(const ClickPesaCancelledException());
      } else if (DateTime.now().isAfter(deadline)) {
        finishErr(Exception('Payment verification timeout'));
      }
    });

    try {
      return await completer.future;
    } finally {
      unawaited(sub.cancel());
      fallbackTimer.cancel();
      watchdog.cancel();
    }
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

/// Result of a `verifyClickPesaPayment` call, or of reading the
/// `clickpesa_payments/{orderReference}` Firestore doc directly — both
/// share the same `status`/`tier`/`planExpiresAt` field shape by design, so
/// this one factory parses either.
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
