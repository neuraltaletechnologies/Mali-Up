import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/debt_payments_table.dart';
import '../tables/debts_table.dart';

part 'debt_dao.g.dart';

@DriftAccessor(tables: [DebtsTable, DebtPaymentsTable])
class DebtDao extends DatabaseAccessor<AppDatabase> with _$DebtDaoMixin {
  DebtDao(super.db);

  // ─── Debt watches ──────────────────────────────────────────────────────────

  Stream<List<DebtsTableData>> watchAll(String businessId) {
    return (select(debtsTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  // ─── Debt queries ──────────────────────────────────────────────────────────

  Future<DebtsTableData?> getById(String id) {
    return (select(debtsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<DebtsTableData>> getAll(String businessId) {
    return (select(debtsTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0)))
        .get();
  }

  /// Looks up the receivable created for a sale, by the invoice number it was
  /// tagged with at creation (see SalesScreen — `invoiceRef: invoiceNumber`).
  /// Used by SalesReturnScreen to reduce what's owed when a credit sale is
  /// partially or fully returned. Written-off debts don't count — nothing is
  /// still owed there for a return to reduce.
  Future<DebtsTableData?> getByInvoiceRef(
    String businessId,
    String invoiceRef,
  ) {
    if (invoiceRef.isEmpty) return Future.value();
    return (select(debtsTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.invoiceRef.equals(invoiceRef) &
              t.isWrittenOff.equals(0) &
              t.isDeleted.equals(0))
          ..limit(1))
        .getSingleOrNull();
  }

  // ─── Debt mutations ────────────────────────────────────────────────────────

  Future<void> upsert(DebtsTableCompanion entry) async {
    await into(debtsTable).insertOnConflictUpdate(entry);
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(debtsTable)..where((t) => t.id.equals(id))).write(
      DebtsTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markSynced(String id, {required int serverUpdatedAt}) async {
    await (update(debtsTable)..where((t) => t.id.equals(id))).write(
      DebtsTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markConflict(String id) async {
    await (update(debtsTable)..where((t) => t.id.equals(id))).write(
      const DebtsTableCompanion(syncStatus: Value('conflict')),
    );
  }

  Future<void> updatePaidAmount(String id, double paidAmount) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(debtsTable)..where((t) => t.id.equals(id))).write(
      DebtsTableCompanion(
        paidAmount: Value(paidAmount),
        syncStatus: const Value('pending_update'),
        updatedAt: Value(now),
      ),
    );
  }

  // ─── DebtPayment watches ───────────────────────────────────────────────────

  Stream<List<DebtPaymentsTableData>> watchPaymentsForDebt(String debtId) {
    return (select(debtPaymentsTable)
          ..where((t) =>
              t.debtId.equals(debtId) & t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  // ─── DebtPayment queries ───────────────────────────────────────────────────

  Future<DebtPaymentsTableData?> getPaymentById(String id) {
    return (select(debtPaymentsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<DebtPaymentsTableData>> getPaymentsForDebt(String debtId) {
    return (select(debtPaymentsTable)
          ..where((t) =>
              t.debtId.equals(debtId) & t.isDeleted.equals(0)))
        .get();
  }

  // ─── DebtPayment mutations ─────────────────────────────────────────────────

  Future<void> upsertPayment(DebtPaymentsTableCompanion entry) async {
    await into(debtPaymentsTable).insertOnConflictUpdate(entry);
  }

  Future<void> softDeletePayment(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(debtPaymentsTable)..where((t) => t.id.equals(id))).write(
      DebtPaymentsTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markPaymentSynced(String id,
      {required int serverUpdatedAt}) async {
    await (update(debtPaymentsTable)..where((t) => t.id.equals(id))).write(
      DebtPaymentsTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
