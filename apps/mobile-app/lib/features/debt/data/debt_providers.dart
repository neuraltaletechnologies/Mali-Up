import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../customer/data/customer_providers.dart';
import '../domain/models/debt.dart';

// ── All debts stream ──────────────────────────────────────────────────────────

final debtListProvider = StreamProvider<List<Debt>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Debt>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <Debt>[];
    return;
  }
  final repository = ref.read(contextFirestoreRepositoryProvider);
  yield* repository.watchDebts(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
  );
});

// ── Filtered views ────────────────────────────────────────────────────────────

/// Active receivables — sorted most overdue first.
final receivablesProvider = Provider<List<Debt>>((ref) {
  final all = ref.watch(debtListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Debt>[],
      );
  return all
      .where((d) => d.type == 'receivable' && !d.isWrittenOff && !d.isFullyPaid)
      .toList()
    ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
});

/// Active payables — sorted soonest due first.
final payablesProvider = Provider<List<Debt>>((ref) {
  final all = ref.watch(debtListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Debt>[],
      );
  return all
      .where((d) => d.type == 'payable' && !d.isWrittenOff && !d.isFullyPaid)
      .toList()
    ..sort((a, b) => a.daysOverdue.compareTo(b.daysOverdue));
});

/// Written-off debts for audit log.
final writtenOffDebtsProvider = Provider<List<Debt>>((ref) {
  return ref
      .watch(debtListProvider)
      .maybeWhen(data: (d) => d, orElse: () => <Debt>[])
      .where((d) => d.isWrittenOff)
      .toList()
    ..sort((a, b) => b.writtenOffAt.compareTo(a.writtenOffAt));
});

// ── Totals ────────────────────────────────────────────────────────────────────

final totalReceivablesProvider = Provider<double>((ref) {
  return ref
      .watch(receivablesProvider)
      .fold(0.0, (s, d) => s + d.remainingAmount);
});

final totalPayablesProvider = Provider<double>((ref) {
  return ref
      .watch(payablesProvider)
      .fold(0.0, (s, d) => s + d.remainingAmount);
});

// ── Aging buckets (receivables only) ─────────────────────────────────────────

typedef AgingBuckets = ({
  double current,
  double d0to30,
  double d31to60,
  double d61to90,
  double d90plus,
  int countCurrent,
  int count0to30,
  int count31to60,
  int count61to90,
  int count90plus,
});

final receivablesAgingProvider = Provider<AgingBuckets>((ref) {
  final receivables = ref.watch(receivablesProvider);
  double current = 0, d0to30 = 0, d31to60 = 0, d61to90 = 0, d90plus = 0;
  int cc = 0, c1 = 0, c2 = 0, c3 = 0, c4 = 0;
  for (final d in receivables) {
    final amt = d.remainingAmount;
    switch (d.agingBucket) {
      case 'current':
        current += amt;
        cc++;
      case '0-30':
        d0to30 += amt;
        c1++;
      case '31-60':
        d31to60 += amt;
        c2++;
      case '61-90':
        d61to90 += amt;
        c3++;
      case '90+':
        d90plus += amt;
        c4++;
    }
  }
  return (
    current: current,
    d0to30: d0to30,
    d31to60: d31to60,
    d61to90: d61to90,
    d90plus: d90plus,
    countCurrent: cc,
    count0to30: c1,
    count31to60: c2,
    count61to90: c3,
    count90plus: c4,
  );
});

// ── Partial payments (per debt) ───────────────────────────────────────────────

final debtPaymentsProvider =
    StreamProvider.family<List<DebtPayment>, String>((ref, debtId) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <DebtPayment>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <DebtPayment>[];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  yield* repo.watchDebtPayments(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
    debtId: debtId,
  );
});
