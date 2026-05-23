import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/expense.dart';
import '../domain/models/cash_account.dart';
import '../domain/models/recurring_expense_template.dart';
import '../../customer/data/customer_providers.dart';

final expenseListProvider = StreamProvider<List<Expense>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Expense>[];
    return;
  }

  final repository = ref.watch(contextFirestoreRepositoryProvider);
  final context = await repository.resolveContextForUser(user.uid);
  yield* repository.watchExpenses(uid: user.uid, context: context);
});

final recurringTemplateListProvider =
    StreamProvider<List<RecurringExpenseTemplate>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <RecurringExpenseTemplate>[];
    return;
  }

  final repository = ref.watch(contextFirestoreRepositoryProvider);
  final context = await repository.resolveContextForUser(user.uid);
  yield* repository
      .watchRecurringTemplates(uid: user.uid, context: context)
      .map((list) => list
          .map((m) => RecurringExpenseTemplate.fromMap(m, m['id'] as String))
          .toList());
});

final cashAccountListProvider = StreamProvider<List<CashAccount>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <CashAccount>[];
    return;
  }

  final repository = ref.watch(contextFirestoreRepositoryProvider);
  final context = await repository.resolveContextForUser(user.uid);
  yield* repository.watchCashAccounts(uid: user.uid, context: context);
});
