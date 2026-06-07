import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/expenses_table.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: [ExpensesTable])
class ExpenseDao extends DatabaseAccessor<AppDatabase>
    with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  // ─── Watches ───────────────────────────────────────────────────────────────

  Stream<List<ExpensesTableData>> watchAll(String businessId) {
    return (select(expensesTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<ExpensesTableData>> watchByCategory(
    String businessId,
    String category,
  ) {
    return (select(expensesTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.category.equals(category) &
              t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<ExpensesTableData>> watchPendingSync() {
    return (select(expensesTable)
          ..where((t) => t.syncStatus.isIn([
                'pending_create',
                'pending_update',
                'pending_delete',
              ])))
        .watch();
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  Future<ExpensesTableData?> getById(String id) {
    return (select(expensesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<ExpensesTableData>> getByDateRange(
    String businessId,
    String fromDate,
    String toDate,
  ) {
    return (select(expensesTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.date.isBiggerOrEqualValue(fromDate) &
              t.date.isSmallerOrEqualValue(toDate) &
              t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<double> getTotalByDateRange(
    String businessId,
    String fromDate,
    String toDate,
  ) async {
    final query = selectOnly(expensesTable)
      ..addColumns([expensesTable.amount.sum()])
      ..where(
        expensesTable.businessId.equals(businessId) &
            expensesTable.date.isBiggerOrEqualValue(fromDate) &
            expensesTable.date.isSmallerOrEqualValue(toDate) &
            expensesTable.isDeleted.equals(0),
      );
    final row = await query.getSingleOrNull();
    return row?.read(expensesTable.amount.sum()) ?? 0.0;
  }

  Future<List<ExpensesTableData>> getRecurringTemplates(
      String businessId) {
    return (select(expensesTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.isRecurring.equals(1) &
              t.isDeleted.equals(0)))
        .get();
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  Future<void> upsert(ExpensesTableCompanion entry) async {
    await into(expensesTable).insertOnConflictUpdate(entry);
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(expensesTable)..where((t) => t.id.equals(id))).write(
      ExpensesTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markSynced(String id, {required int serverUpdatedAt}) async {
    await (update(expensesTable)..where((t) => t.id.equals(id))).write(
      ExpensesTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markConflict(String id) async {
    await (update(expensesTable)..where((t) => t.id.equals(id))).write(
      const ExpensesTableCompanion(syncStatus: Value('conflict')),
    );
  }

  Future<void> hardDelete(String id) async {
    await (delete(expensesTable)..where((t) => t.id.equals(id))).go();
  }
}
