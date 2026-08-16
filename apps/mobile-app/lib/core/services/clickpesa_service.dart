import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'plan_service.dart';

class ClickPesaService {
  /// ClickPesa API base URL
  static const String _baseUrl = 'https://api.clickpesa.com/v2';

  /// Get credentials from dart-define (build-time injection)
  static String get _clientId {
    const configured = String.fromEnvironment('CLICKPESA_CLIENT_ID');
    if (configured.isNotEmpty) return configured;
    throw StateError('CLICKPESA_CLIENT_ID not configured');
  }

  static String get _apiKey {
    const configured = String.fromEnvironment('CLICKPESA_API_KEY');
    if (configured.isNotEmpty) return configured;
    throw StateError('CLICKPESA_API_KEY not configured');
  }

  /// Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $_apiKey',
    'X-Client-Id': _clientId,
  };

  /// Create a payment request for plan upgrade
  /// Returns the payment URL to redirect the user
  static Future<ClickPesaPaymentResponse> createPayment({
    required PlanTier tier,
    required int amountTzs,
    required String paymentRef,
    required String customerPhone,
    required String customerEmail,
    String? callbackUrl,
    String? returnUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('User not authenticated');

    final body = {
      'amount': amountTzs,
      'currency': 'TZS',
      'reference': paymentRef,
      'description': 'Mali Up ${tier.name.toUpperCase()} plan upgrade',
      'customer': {
        'phone': customerPhone,
        'email': customerEmail,
        'name': user.displayName ?? user.email ?? 'Mali Up User',
      },
      'metadata': {
        'tier': tier.name,
        'userId': user.uid,
        'paymentRef': paymentRef,
      },
      'callbackUrl': ?callbackUrl,
      'returnUrl': ?returnUrl,
    };

    try {
      debugPrint('[ClickPesa] Creating payment for $tier: $amountTzs TZS');
      final response = await http
          .post(
            Uri.parse('$_baseUrl/payments'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        debugPrint('[ClickPesa] Payment created: ${data['id']}');
        return ClickPesaPaymentResponse.fromJson(data);
      } else {
        final error = 'ClickPesa API Error: ${response.statusCode} - ${response.body}';
        debugPrint('[ClickPesa] $error');
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('[ClickPesa] Error creating payment: $e');
      rethrow;
    }
  }

  /// Verify payment status by payment ID
  static Future<ClickPesaPaymentStatus> verifyPayment(String paymentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/payments/$paymentId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return ClickPesaPaymentStatus.fromJson(data);
      } else {
        throw Exception('ClickPesa verify error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[ClickPesa] Error verifying payment: $e');
      rethrow;
    }
  }

  /// Check payment status by reference (our internal reference)
  static Future<ClickPesaPaymentStatus?> checkPaymentByReference(String reference) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/payments?reference=$reference'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        final payments = data['data'] as List?;
        if (payments != null && payments.isNotEmpty) {
          return ClickPesaPaymentStatus.fromJson(payments.first);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[ClickPesa] Error checking payment by reference: $e');
      return null;
    }
  }

  /// Poll for payment completion (used after redirect returns)
  static Future<ClickPesaPaymentStatus> waitForPayment({
    required String paymentId,
    int maxAttempts = 20,
    Duration interval = const Duration(seconds: 3),
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final status = await verifyPayment(paymentId);
        if (status.isCompleted) {
          return status;
        }
        if (status.isFailed) {
          throw Exception('Payment failed: ${status.failureReason ?? 'Unknown error'}');
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('Payment failed')) rethrow;
      }
      await Future.delayed(interval);
    }
    throw Exception('Payment verification timeout');
  }

  /// Process payment completion and activate plan
  /// This should be called after successful payment verification
  static Future<void> processSuccessfulPayment({
    required ClickPesaPaymentStatus payment,
    required PlanTier tier,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('User not authenticated');

    final db = FirebaseFirestore.instance;

    // Calculate expiry date based on plan
    final months = _getPlanMonths(tier);
    final expiresAt = DateTime.now().add(Duration(days: 30 * months));

    // Update user's plan in Firestore
    await db.collection('users').doc(user.uid).set({
      'plan': tier.name,
      'planExpiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastPayment': {
        'reference': payment.reference,
        'amount': payment.amount,
        'currency': payment.currency,
        'paymentId': payment.id,
        'paidAt': Timestamp.fromDate(payment.paidAt ?? DateTime.now()),
        'provider': 'clickpesa',
      },
    }, SetOptions(merge: true));

    debugPrint('[ClickPesa] Plan activated for user ${user.uid}: $tier');
  }

  static int _getPlanMonths(PlanTier tier) {
    switch (tier) {
      case PlanTier.growth:
      case PlanTier.business:
        return 6;
      case PlanTier.enterprise:
        return 12;
      case PlanTier.lifetime:
        return 999;
      default:
        return 1;
    }
  }
}

/// Response from creating a payment
class ClickPesaPaymentResponse {
  final String id;
  final String paymentUrl;
  final String reference;
  final int amount;
  final String currency;
  final String status;
  final DateTime createdAt;

  ClickPesaPaymentResponse({
    required this.id,
    required this.paymentUrl,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory ClickPesaPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ClickPesaPaymentResponse(
      id: json['id'] as String,
      paymentUrl: json['paymentUrl'] as String? ?? json['url'] as String,
      reference: json['reference'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Payment status from ClickPesa
class ClickPesaPaymentStatus {
  final String id;
  final String reference;
  final int amount;
  final String currency;
  final String status;
  final DateTime? paidAt;
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  ClickPesaPaymentStatus({
    required this.id,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    this.paidAt,
    this.failureReason,
    this.metadata,
  });

  factory ClickPesaPaymentStatus.fromJson(Map<String, dynamic> json) {
    return ClickPesaPaymentStatus(
      id: json['id'] as String,
      reference: json['reference'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      failureReason: json['failureReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  bool get isCompleted => status == 'completed' || status == 'paid';
  bool get isFailed => status == 'failed' || status == 'cancelled' || status == 'expired';
  bool get isPending => status == 'pending' || status == 'processing';

  PlanTier? get tierFromMetadata {
    if (metadata == null) return null;
    final tierStr = metadata!['tier'] as String?;
    if (tierStr == null) return null;
    return PlanTierX.fromString(tierStr);
  }

  String? get userIdFromMetadata => metadata?['userId'] as String?;
  String? get paymentRefFromMetadata => metadata?['paymentRef'] as String?;
}