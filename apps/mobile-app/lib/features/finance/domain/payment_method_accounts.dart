import 'package:flutter/material.dart';

import 'models/cash_account.dart';

/// One of the four built-in payment channels every business starts with.
/// These accounts are never created by hand — the user *activates* each one
/// by entering the actual money currently in it, and only activated channels
/// can receive sale money or pay for stock purchases.
class PaymentMethodSpec {
  /// Deterministic account id (Drift row + Firestore doc). One per business,
  /// so activation is idempotent across devices and offline retries.
  final String accountId;
  final String nameEn;
  final String nameSw;
  final String type; // CashAccount.type
  final IconData icon;

  /// Canonical method string this spec resolves from/to
  /// (see [PaymentMethodAccounts.accountIdForMethod]).
  final String methodKey;

  const PaymentMethodSpec({
    required this.accountId,
    required this.nameEn,
    required this.nameSw,
    required this.type,
    required this.icon,
    required this.methodKey,
  });

  String nameFor(String language) => language == 'sw' ? nameSw : nameEn;

  CashAccount toAccount({required double openingBalance, String? accountNumber}) {
    return CashAccount(
      id: accountId,
      name: nameSw, // Swahili-first canonical name; UI localizes via the spec
      type: type,
      balance: openingBalance,
      accountNumber: accountNumber,
    );
  }
}

abstract final class PaymentMethodAccounts {
  static const cashId = 'pm_cash';
  static const mpesaId = 'pm_mpesa';
  static const bankId = 'pm_bank';
  static const cardId = 'pm_card';

  static const specs = <PaymentMethodSpec>[
    PaymentMethodSpec(
      accountId: cashId,
      nameEn: 'Cash',
      nameSw: 'Taslimu',
      type: 'Cash',
      icon: Icons.payments_rounded,
      methodKey: 'cash',
    ),
    PaymentMethodSpec(
      accountId: mpesaId,
      nameEn: 'M-Pesa',
      nameSw: 'M-Pesa',
      type: 'Mobile Money',
      icon: Icons.phone_android_rounded,
      methodKey: 'mpesa',
    ),
    PaymentMethodSpec(
      accountId: bankId,
      nameEn: 'Bank',
      nameSw: 'Benki',
      type: 'Bank',
      icon: Icons.account_balance_rounded,
      methodKey: 'bank',
    ),
    PaymentMethodSpec(
      accountId: cardId,
      nameEn: 'Card',
      nameSw: 'Kadi',
      type: 'Card',
      icon: Icons.credit_card_rounded,
      methodKey: 'card',
    ),
  ];

  static bool isMethodAccountId(String id) =>
      id == cashId || id == mpesaId || id == bankId || id == cardId;

  static PaymentMethodSpec? specForAccountId(String id) {
    for (final s in specs) {
      if (s.accountId == id) return s;
    }
    return null;
  }

  /// Maps every payment-method string the app writes on invoices
  /// ('cash', 'mpesa', 'bank', 'bank_transfer', 'card') to its account id.
  /// Returns null for 'credit' and unknown values — no money moves for those.
  static String? accountIdForMethod(String method) {
    return switch (method.toLowerCase().trim()) {
      'cash' => cashId,
      'mpesa' || 'm-pesa' => mpesaId,
      'bank' || 'bank_transfer' => bankId,
      'card' => cardId,
      _ => null,
    };
  }

  static PaymentMethodSpec? specForMethod(String method) {
    final id = accountIdForMethod(method);
    return id == null ? null : specForAccountId(id);
  }
}
