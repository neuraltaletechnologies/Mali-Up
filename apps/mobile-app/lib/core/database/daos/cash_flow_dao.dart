import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cash_accounts_table.dart';
import '../tables/cash_transactions_table.dart';
import '../tables/daily_reconciliations_table.dart';

part 'cash_flow_dao.g.dart';

@DriftAccessor(tables: [
  CashAccountsTable,
  CashTransactionsTable,
  DailyReconciliationsTable,
])
class CashFlowDao extends DatabaseAccessor<AppDatabase>
    with _$CashFlowDaoMixin {
  CashFlowDao(super.db);

  // ─── Cash account watches ──────────────────────────────────────────────────

  Stream<List<CashAccountsTableData>> watchAccounts(String businessId) {
    return (select(cashAccountsTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  // ─── Cash account queries ──────────────────────────────────────────────────

  Future<CashAccountsTableData?> getAccountById(String id) {
    return (select(cashAccountsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ─── Cash account mutations ────────────────────────────────────────────────

  Future<void> upsertAccount(CashAccountsTableCompanion entry) async {
    await into(cashAccountsTable).insertOnConflictUpdate(entry);
  }

  Future<void> softDeleteAccount(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(cashAccountsTable)..where((t) => t.id.equals(id))).write(
      CashAccountsTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(now),
      ),
    );
  }

  /// Applies a deletion that already happened on the server (a pulled
  /// tombstone) — unlike [softDeleteAccount] there is nothing left to push.
  Future<void> applyRemoteAccountDeletion(String id,
      {required int serverUpdatedAt}) async {
    await (update(cashAccountsTable)..where((t) => t.id.equals(id))).write(
      CashAccountsTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markAccountSynced(String id,
      {required int serverUpdatedAt}) async {
    await (update(cashAccountsTable)..where((t) => t.id.equals(id))).write(
      CashAccountsTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Adjusts the cached balance without touching syncStatus — balance deltas
  /// are pushed to Firestore via `cash_transaction` queue ops (server-side
  /// FieldValue.increment), not via account upserts.
  Future<void> adjustAccountBalance(String id, double delta) async {
    await customStatement(
      'UPDATE cash_accounts SET balance = balance + ?, updated_at = ? '
      'WHERE id = ?',
      [delta, DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  Future<void> updateAccountLastReconciled(String id, String date) async {
    await (update(cashAccountsTable)..where((t) => t.id.equals(id))).write(
      CashAccountsTableCompanion(
        lastReconciled: Value(date),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // ─── Transaction watches ───────────────────────────────────────────────────

  Stream<List<CashTransactionsTableData>> watchTransactions(
      String businessId) {
    return (select(cashTransactionsTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  // ─── Transaction queries ───────────────────────────────────────────────────

  Future<CashTransactionsTableData?> getTransactionById(String id) {
    return (select(cashTransactionsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ─── Transaction mutations ─────────────────────────────────────────────────

  Future<void> upsertTransaction(
      CashTransactionsTableCompanion entry) async {
    await into(cashTransactionsTable).insertOnConflictUpdate(entry);
  }

  Future<void> markTransactionSynced(String id,
      {required int serverUpdatedAt}) async {
    await (update(cashTransactionsTable)..where((t) => t.id.equals(id)))
        .write(
      CashTransactionsTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // ─── Reconciliation watches ────────────────────────────────────────────────

  Stream<List<DailyReconciliationsTableData>> watchReconciliations(
      String businessId) {
    return (select(dailyReconciliationsTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  // ─── Reconciliation queries ────────────────────────────────────────────────

  Future<DailyReconciliationsTableData?> getReconciliationById(String id) {
    return (select(dailyReconciliationsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ─── Reconciliation mutations ──────────────────────────────────────────────

  Future<void> upsertReconciliation(
      DailyReconciliationsTableCompanion entry) async {
    await into(dailyReconciliationsTable).insertOnConflictUpdate(entry);
  }

  Future<void> markReconciliationSynced(String id,
      {required int serverUpdatedAt}) async {
    await (update(dailyReconciliationsTable)..where((t) => t.id.equals(id)))
        .write(
      DailyReconciliationsTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
