import '../domain/models/expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../rbac/data/rbac_providers.dart';

final contextFirestoreRepositoryProvider = Provider<ContextFirestoreRepository>((ref) {
  return ContextFirestoreRepository();
});

final expenseListProvider = StreamProvider<List<Expense>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Expense>[];
    return;
  }

  final repository = ref.watch(contextFirestoreRepositoryProvider);
  final context = await repository.resolveContextForUser(user.uid);

  // A DataScope.own team member only ever sees the expenses they recorded —
  // both because firestore.rules restrict them to `createdBy == me` and so
  // their dashboard/reports show their own contribution, not the business's.
  final ps = ref.watch(permissionServiceProvider);

  yield* repository.watchExpenses(
    uid: user.uid,
    context: context,
    createdByUid: ps.isOwnRecordsOnly ? user.uid : null,
  );
});
