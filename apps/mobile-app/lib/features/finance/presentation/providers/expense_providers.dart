import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/business_id_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../data/repositories/sync_expense_repository.dart';
import '../../domain/models/expense.dart';

final expenseRepositoryProvider = Provider<SyncExpenseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  final policy = ref.watch(offlinePolicyProvider);
  return SyncExpenseRepository(db: db, uid: uid, businessId: bizId, policy: policy);
});

/// Live stream of all non-deleted expenses, ordered by date descending.
/// Backed by Drift — works fully offline.
final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll();
});

final expensesByCategoryProvider =
    StreamProvider.family<List<Expense>, String>((ref, category) {
  return ref.watch(expenseRepositoryProvider).watchByCategory(category);
});

final expensesByDateRangeProvider =
    FutureProvider.family<List<Expense>, ({String from, String to})>(
        (ref, range) {
  return ref
      .watch(expenseRepositoryProvider)
      .getByDateRange(range.from, range.to);
});

final expenseTotalByDateRangeProvider =
    FutureProvider.family<double, ({String from, String to})>((ref, range) {
  return ref
      .watch(expenseRepositoryProvider)
      .getTotalByDateRange(range.from, range.to);
});

final recurringExpenseTemplatesProvider =
    FutureProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).getRecurringTemplates();
});
