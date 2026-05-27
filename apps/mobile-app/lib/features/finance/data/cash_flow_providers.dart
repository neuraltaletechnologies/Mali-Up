import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
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

// ── Cash transactions ─────────────────────────────────────────────────────────

final cashTransactionListProvider = StreamProvider<List<CashTransaction>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <CashTransaction>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <CashTransaction>[];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  yield* repo.watchCashTransactions(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
  );
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

/// Transactions for a specific account (all time).
final accountTransactionsProvider =
    Provider.family<List<CashTransaction>, String>((ref, accountId) {
  return ref
      .watch(cashTransactionListProvider)
      .maybeWhen(data: (d) => d, orElse: () => <CashTransaction>[])
      .where((t) => t.fromAccountId == accountId || t.toAccountId == accountId)
      .toList();
});

// ── Monthly aggregates ────────────────────────────────────────────────────────

/// Total inflow (deposits + incoming transfers) for the selected month.
final monthlyInflowProvider = Provider<double>((ref) {
  final txns = ref.watch(cfTransactionsByMonthProvider);
  return txns
      .where((t) => t.isDeposit || t.isTransfer)
      .where((t) => t.toAccountId.isNotEmpty)
      .fold(0.0, (s, t) => s + t.amount);
});

/// Total outflow (withdrawals + outgoing transfers) for the selected month.
final monthlyOutflowProvider = Provider<double>((ref) {
  final txns = ref.watch(cfTransactionsByMonthProvider);
  return txns
      .where((t) => t.isWithdrawal || t.isTransfer)
      .where((t) => t.fromAccountId.isNotEmpty)
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

// ── Daily reconciliations ─────────────────────────────────────────────────────

final reconciliationListProvider = StreamProvider<List<DailyReconciliation>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <DailyReconciliation>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <DailyReconciliation>[];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  yield* repo.watchDailyReconciliations(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
  );
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
