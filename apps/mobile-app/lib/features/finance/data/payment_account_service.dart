import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/error_reporter.dart';
import '../../../core/services/localization_service.dart';
import '../domain/models/cash_account.dart';
import '../domain/models/cash_transaction.dart';
import '../domain/payment_method_accounts.dart';
import 'finance_providers.dart';

/// Thrown when money would move through a payment channel that has not been
/// activated. toString() is the user-facing bilingual message, so callers'
/// generic `catch (e) → snackbar($e)` paths read cleanly.
class PaymentChannelNotActivatedException implements Exception {
  final String message;
  PaymentChannelNotActivatedException(this.message);

  @override
  String toString() => message;
}

/// Returns the activated built-in account for a payment-method string
/// ('cash', 'mpesa', 'bank', 'bank_transfer', 'card'), or null when the
/// method doesn't map to a channel (credit) or it hasn't been activated yet.
/// Reads Drift, so it works offline.
Future<CashAccount?> activatedAccountForMethod(
    WidgetRef ref, String method) async {
  final accountId = PaymentMethodAccounts.accountIdForMethod(method);
  if (accountId == null) return null;
  return ref.read(cashRepositoryProvider).getAccountById(accountId);
}

/// The blocking message shown when the user tries to move money through a
/// channel that has not been activated in Mtiririko wa Fedha.
String activationRequiredMessage(String method) {
  final spec = PaymentMethodAccounts.specForMethod(method);
  final name = spec == null
      ? method
      : spec.nameFor(LocalizationService.isSwahili ? 'sw' : 'en');
  return LocalizationService.tr(
    en: 'Activate $name in Cash Flow first — enter the money currently in it.',
    sw: 'Washa $name katika Mtiririko wa Fedha kwanza — weka pesa iliyopo sasa.',
  );
}

/// Deposits money received on a sale (or invoice payment) into the activated
/// account for [method]. The transaction commits to Drift instantly and the
/// queued op replays the balance increment on Firestore idempotently.
///
/// Best-effort by design: callers run this *after* the sale itself has
/// committed, so a failure here must never surface as a failed sale —
/// it is reported to Sentry instead.
Future<void> depositSaleIntoMethodAccount(
  WidgetRef ref, {
  required String method,
  required double amount,
  required String invoiceNumber,
  String createdBy = '',
}) async {
  if (amount <= 0) return;
  try {
    final account = await activatedAccountForMethod(ref, method);
    if (account == null) return;
    final today = DateTime.now();
    final dateStr = '${today.year}'
        '-${today.month.toString().padLeft(2, '0')}'
        '-${today.day.toString().padLeft(2, '0')}';
    await ref.read(cashRepositoryProvider).addTransaction(CashTransaction(
          id: '',
          type: 'deposit',
          amount: amount,
          toAccountId: account.id,
          description: LocalizationService.tr(
              en: 'Sale $invoiceNumber', sw: 'Mauzo $invoiceNumber'),
          date: dateStr,
          reference: invoiceNumber,
          createdBy: createdBy,
        ));
  } catch (e, st) {
    ErrorReporter.captureException(e, stackTrace: st);
  }
}

/// Moves money into or out of a specific cash account — the generic sibling
/// of [depositSaleIntoMethodAccount] for callers that already hold a
/// concrete [CashAccount] (picked via a payment-account chooser) instead of
/// a fixed method string, e.g. custom accounts, expenses, and debt
/// repayments. Same best-effort contract: never throws, reports to Sentry.
Future<void> moveMoneyForAccount(
  WidgetRef ref, {
  required String accountId,
  required double amount,
  required bool isDeposit,
  required String description,
  String reference = '',
  String createdBy = '',
}) async {
  if (amount <= 0 || accountId.isEmpty) return;
  try {
    final today = DateTime.now();
    final dateStr = '${today.year}'
        '-${today.month.toString().padLeft(2, '0')}'
        '-${today.day.toString().padLeft(2, '0')}';
    await ref.read(cashRepositoryProvider).addTransaction(CashTransaction(
          id: '',
          type: isDeposit ? 'deposit' : 'withdrawal',
          amount: amount,
          toAccountId: isDeposit ? accountId : '',
          fromAccountId: isDeposit ? '' : accountId,
          description: description,
          date: dateStr,
          reference: reference,
          createdBy: createdBy,
        ));
  } catch (e, st) {
    ErrorReporter.captureException(e, stackTrace: st);
  }
}
