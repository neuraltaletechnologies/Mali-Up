import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customer/data/customer_providers.dart';
import '../domain/models/debt.dart';
import 'debt_providers.dart';

/// Keeps the customer balance and the debt ledger consistent — the same
/// invariant the sale flows maintain (a credit sale increments the customer
/// balance and creates a receivable; a settlement decrements the balance and
/// pays the receivable down). Manual debt edits and customer-page payments
/// go through these helpers so both screens always show the same money.
///
/// How much of the customer's balance a debt record accounts for: the
/// remaining amount of an active receivable linked to that customer.
double _balanceContribution(Debt? d) {
  if (d == null || d.type != 'receivable' || d.isWrittenOff) return 0;
  if (d.partyId.isEmpty) return 0;
  return d.remainingAmount;
}

/// Mirrors a debt create/edit/write-off/delete into the linked customer's
/// balance. Pass the record as it was ([before], null on create) and as it
/// is now ([after], null on delete); the balance moves by the difference.
/// Uses the offline-first delta path (Drift + queued FieldValue.increment),
/// so concurrent sessions compose on the server. Best-effort: a missing or
/// unlinked customer changes nothing.
Future<void> adjustCustomerBalanceForDebtChange(
  WidgetRef ref, {
  Debt? before,
  Debt? after,
}) async {
  final deltas = <String, double>{};
  final beforeContribution = _balanceContribution(before);
  if (beforeContribution != 0) {
    deltas[before!.partyId] =
        (deltas[before.partyId] ?? 0) - beforeContribution;
  }
  final afterContribution = _balanceContribution(after);
  if (afterContribution != 0) {
    deltas[after!.partyId] = (deltas[after.partyId] ?? 0) + afterContribution;
  }

  final customerRepo = ref.read(customerRepositoryProvider);
  for (final entry in deltas.entries) {
    if (entry.value == 0) continue;
    try {
      await customerRepo.adjustBalance(entry.key, entry.value);
    } catch (_) {}
  }
}

/// Applies a payment made on the customer page to the customer's open
/// receivables, oldest due date first, so the Debts screen stops counting
/// the settled money as owed. Records a [DebtPayment] and denormalizes
/// paidAmount on each debt — the same pattern as the manual repayment flow
/// in debt_detail_screen. Returns the amount that found a matching debt
/// (legacy balances may exceed the ledger; the rest just reduces the
/// balance). Does NOT touch the customer balance — the caller adjusts it
/// once for the full payment.
Future<double> applyCustomerPaymentToDebts(
  WidgetRef ref, {
  required String customerId,
  required double amount,
  required String method,
  String note = '',
  required String recordedBy,
}) async {
  if (customerId.isEmpty || amount <= 0) return 0;

  final debtRepo = ref.read(debtRepositoryProvider);
  final debts = await debtRepo.watchAll().first;
  final open = debts
      .where((d) =>
          d.type == 'receivable' &&
          d.partyId == customerId &&
          !d.isWrittenOff &&
          !d.isFullyPaid)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  var left = amount;
  double applied = 0;
  for (final d in open) {
    if (left <= 0) break;
    final pay = left.clamp(0.0, d.remainingAmount);
    if (pay <= 0) continue;
    await debtRepo.addPayment(
      d.id,
      DebtPayment(
        id: '',
        amount: pay,
        date: dateStr,
        method: method,
        note: note,
        recordedBy: recordedBy,
      ),
    );
    final newPaid = d.paidAmount + pay;
    await debtRepo.save(d.copyWith(
      paidAmount: newPaid,
      status: newPaid >= d.totalOwedWithInterest ? 'paid' : d.status,
    ));
    applied += pay;
    left -= pay;
  }
  return applied;
}
