import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customer/data/customer_providers.dart';
import '../domain/models/cash_account.dart';
import '../domain/models/cash_transaction.dart';
import '../domain/models/daily_reconciliation.dart';
import 'finance_providers.dart';

// ── Month selector for cash flow screens ──────────────────────────────────────

class _CfMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime(DateTime.now().year, DateTime.now().month);

  void setMonth(DateTime month) => state = month;
  void prev() => state = DateTime(state.year, state.month - 1);
  void next() {
    final candidate = DateTime(state.year, state.month + 1);
    if (!candidate.isAfter(DateTime.now())) state = candidate;
  }
}

final cfMonthProvider = NotifierProvider<_CfMonthNotifier, DateTime>(_CfMonthNotifier.new);

// ── Cash transactions (offline-first, backed by Drift) ───────────────────────

final cashTransactionListProvider =
    StreamProvider<List<CashTransaction>>((ref) {
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (bizId.isEmpty) return Stream.value(const <CashTransaction>[]);
  return ref.watch(cashRepositoryProvider).watchTransactions();
});

/// Transactions filtered to the currently selected month.
final cfTransactionsByMonthProvider = Provider<List<CashTransaction>>((ref) {
  final month = ref.watch(cfMonthProvider);
  return ref
      .watch(cashTransactionListProvider)
      .maybeWhen(data: (d) => d, orElse: () => <CashTransaction>[])
      .where((t) {
        final d = DateTime.tryParse(t.date);
        return d != null && d.year == month.year && d.month == month.month;
      })
      .toList();
});

/// Transactions for a specific account (all time). Deposits only belong to
/// their destination account and withdrawals to their source account — the
/// other side may carry a stale prefill id from older app versions.
final accountTransactionsProvider =
    Provider.family<List<CashTransaction>, String>((ref, accountId) {
  return ref
      .watch(cashTransactionListProvider)
      .maybeWhen(data: (d) => d, orElse: () => <CashTransaction>[])
      .where((t) {
        if (t.isDeposit) return t.toAccountId == accountId;
        if (t.isWithdrawal) return t.fromAccountId == accountId;
        return t.fromAccountId == accountId || t.toAccountId == accountId;
      })
      .toList();
});

// ── Monthly aggregates ────────────────────────────────────────────────────────

/// Total inflow (deposits) for the selected month. Transfers are internal
/// movements between own accounts, so they are not money into the business.
final monthlyInflowProvider = Provider<double>((ref) {
  final txns = ref.watch(cfTransactionsByMonthProvider);
  return txns
      .where((t) => t.isDeposit && t.toAccountId.isNotEmpty)
      .fold(0.0, (s, t) => s + t.amount);
});

/// Total outflow (withdrawals) for the selected month. Transfers are internal
/// movements between own accounts, so they are not money out of the business.
final monthlyOutflowProvider = Provider<double>((ref) {
  final txns = ref.watch(cfTransactionsByMonthProvider);
  return txns
      .where((t) => t.isWithdrawal && t.fromAccountId.isNotEmpty)
      .fold(0.0, (s, t) => s + t.amount);
});

/// Net cash flow for the selected month (inflow minus outflow, excluding transfers).
final netCashFlowProvider = Provider<double>((ref) {
  final txns = ref.watch(cfTransactionsByMonthProvider);
  double net = 0;
  for (final t in txns) {
    if (t.isDeposit) net += t.amount;
    if (t.isWithdrawal) net -= t.amount;
  }
  return net;
});

/// Totals grouped by activity category for the selected month.
final cfByActivityProvider =
    Provider<Map<String, ({double inflow, double outflow})>>((ref) {
  final txns = ref.watch(cfTransactionsByMonthProvider);
  final map = <String, ({double inflow, double outflow})>{};

  for (final t in txns) {
    if (t.isTransfer) continue;
    final cat = t.activityCategory;
    final current = map[cat] ?? (inflow: 0.0, outflow: 0.0);
    if (t.isDeposit) {
      map[cat] = (inflow: current.inflow + t.amount, outflow: current.outflow);
    } else if (t.isWithdrawal) {
      map[cat] = (inflow: current.inflow, outflow: current.outflow + t.amount);
    }
  }
  return map;
});

// ── Daily reconciliations (offline-first, backed by Drift) ───────────────────

final reconciliationListProvider =
    StreamProvider<List<DailyReconciliation>>((ref) {
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (bizId.isEmpty) return Stream.value(const <DailyReconciliation>[]);
  return ref.watch(cashRepositoryProvider).watchReconciliations();
});

/// Reconciliations for a specific account.
final accountReconciliationsProvider =
    Provider.family<List<DailyReconciliation>, String>((ref, accountId) {
  return ref
      .watch(reconciliationListProvider)
      .maybeWhen(data: (d) => d, orElse: () => <DailyReconciliation>[])
      .where((r) => r.accountId == accountId)
      .toList();
});

// ── Total cash position across all accounts ───────────────────────────────────

final totalCashPositionProvider = Provider<double>((ref) {
  return ref
      .watch(cashAccountListProvider)
      .maybeWhen(data: (d) => d, orElse: () => <CashAccount>[])
      .fold(0.0, (s, a) => s + a.balance);
});
