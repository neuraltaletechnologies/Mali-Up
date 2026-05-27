import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../customer/data/customer_providers.dart';
import '../domain/models/budget.dart';
import '../domain/models/cash_account.dart';
import '../domain/models/expense.dart';
import '../domain/models/recurring_expense_template.dart';

// ── Selected month for expense screen navigation ──────────────────────────────

class _SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime(DateTime.now().year, DateTime.now().month);

  void setMonth(DateTime month) => state = month;
}

final selectedMonthProvider = NotifierProvider<_SelectedMonthNotifier, DateTime>(
  _SelectedMonthNotifier.new,
);

// ── Expense streams ───────────────────────────────────────────────────────────

final expenseListProvider = StreamProvider<List<Expense>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Expense>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <Expense>[];
    return;
  }
  final repository = ref.read(contextFirestoreRepositoryProvider);
  yield* repository.watchExpenses(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
  );
});

/// Expenses filtered to the currently selected month.
final expensesByMonthProvider = Provider<List<Expense>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final all = ref.watch(expenseListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Expense>[],
      );
  return all.where((e) {
    final d = DateTime.tryParse(e.date);
    return d != null && d.year == month.year && d.month == month.month;
  }).toList();
});

/// Map of category → total spent in the selected month (approved only).
final categorySpendProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expensesByMonthProvider);
  final map = <String, double>{};
  for (final e in expenses) {
    if (e.status == 'rejected') continue;
    map[e.category] = (map[e.category] ?? 0) + (double.tryParse(e.amount) ?? 0);
  }
  return map;
});

/// Total spend in the selected month.
final monthTotalSpendProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesByMonthProvider);
  return expenses
      .where((e) => e.status != 'rejected')
      .fold(0.0, (s, e) => s + (double.tryParse(e.amount) ?? 0));
});

/// Monthly totals for the last 6 months (for trend chart).
final sixMonthSpendProvider = Provider<List<({int month, int year, double total})>>((ref) {
  final all = ref.watch(expenseListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Expense>[],
      );
  final now = DateTime.now();
  return List.generate(6, (i) {
    final m = DateTime(now.year, now.month - 5 + i);
    final total = all
        .where((e) {
          if (e.status == 'rejected') return false;
          final d = DateTime.tryParse(e.date);
          return d != null && d.year == m.year && d.month == m.month;
        })
        .fold(0.0, (s, e) => s + (double.tryParse(e.amount) ?? 0));
    return (month: m.month, year: m.year, total: total);
  });
});

// ── Budget streams ────────────────────────────────────────────────────────────

final budgetStreamProvider = StreamProvider<List<Budget>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Budget>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <Budget>[];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final col = repo.scopeCollection(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'budgets',
  );
  yield* col.snapshots().map(
        (s) => s.docs.map((d) => Budget.fromFirestore(d.data(), d.id)).toList(),
      );
});

/// Budgets filtered to the selected month.
final currentMonthBudgetsProvider = Provider<List<Budget>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(budgetStreamProvider)
      .maybeWhen(data: (d) => d, orElse: () => <Budget>[])
      .where((b) => b.month == month.month && b.year == month.year)
      .toList();
});

/// Budget amount per category for the selected month.
final categoryBudgetProvider = Provider<Map<String, double>>((ref) {
  final budgets = ref.watch(currentMonthBudgetsProvider);
  return {for (final b in budgets) b.category: b.amount};
});

// ── Helpers for budget writes ─────────────────────────────────────────────────

Future<void> saveBudget({
  required ProviderContainer container,
  required String category,
  required double amount,
  required int month,
  required int year,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final repo = container.read(contextFirestoreRepositoryProvider);
  final bizId = container.read(currentBusinessIdProvider).valueOrNull ?? '';
  if (bizId.isEmpty) return;
  final col = repo.scopeCollection(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'budgets',
  );
  // Upsert: find existing doc for category/month/year
  final existing = await col
      .where('category', isEqualTo: category)
      .where('month', isEqualTo: month)
      .where('year', isEqualTo: year)
      .limit(1)
      .get();
  final data = {
    'category': category,
    'amount': amount,
    'month': month,
    'year': year,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (existing.docs.isEmpty) {
    data['createdAt'] = FieldValue.serverTimestamp();
    await col.add(data);
  } else {
    await existing.docs.first.reference.update(data);
  }
}

// ── Recurring templates ───────────────────────────────────────────────────────

final recurringTemplateListProvider =
    StreamProvider<List<RecurringExpenseTemplate>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <RecurringExpenseTemplate>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <RecurringExpenseTemplate>[];
    return;
  }
  final repository = ref.read(contextFirestoreRepositoryProvider);
  yield* repository
      .watchRecurringTemplates(
        uid: user.uid,
        context: ResolvedFinanceContext.business(bizId),
      )
      .map((list) => list
          .map((m) => RecurringExpenseTemplate.fromMap(m, m['id'] as String))
          .toList());
});

// ── Cash accounts ─────────────────────────────────────────────────────────────

final cashAccountListProvider = StreamProvider<List<CashAccount>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <CashAccount>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <CashAccount>[];
    return;
  }
  final repository = ref.read(contextFirestoreRepositoryProvider);
  yield* repository.watchCashAccounts(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
  );
});
