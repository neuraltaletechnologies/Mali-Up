import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/business_id_provider.dart';
import '../../../core/providers/sync_provider.dart';
import '../domain/models/debt.dart';
import 'repositories/sync_debt_repository.dart';

export '../../../core/providers/business_id_provider.dart'
    show currentBusinessIdProvider;

// ── Repository provider ────────────────────────────────────────────────────────

/// Single [SyncDebtRepository] for the session.
/// Rebuilt when uid or businessId changes.
final debtRepositoryProvider = Provider<SyncDebtRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  final policy = ref.watch(offlinePolicyProvider);
  return SyncDebtRepository(
    db: db,
    uid: uid,
    businessId: bizId,
    policy: policy,
  );
});

// ── All debts stream ──────────────────────────────────────────────────────────

/// Offline-first stream of all debts for the current business.
/// Backed by Drift — works without internet.
final debtListProvider = StreamProvider<List<Debt>>((ref) {
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (bizId.isEmpty) return Stream.value(const <Debt>[]);
  return ref.watch(debtRepositoryProvider).watchAll();
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

// ── Payments (per debt) ───────────────────────────────────────────────────────

/// Offline-first stream of payments for a given debt, backed by Drift.
final debtPaymentsProvider =
    StreamProvider.family<List<DebtPayment>, String>((ref, debtId) {
  if (debtId.isEmpty) return Stream.value(const <DebtPayment>[]);
  return ref.watch(debtRepositoryProvider).watchPayments(debtId);
});
