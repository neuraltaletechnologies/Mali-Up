import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/invoices_table.dart';
import '../tables/invoice_items_table.dart';

part 'invoice_dao.g.dart';

/// The most recent invoice line for a recurring service sold to one
/// customer — enough to compute how many billing periods have elapsed since.
/// See RecurringBillingCalculator.
class LastServiceBilling {
  final String date;
  final double quantity;
  const LastServiceBilling({required this.date, required this.quantity});
}

@DriftAccessor(tables: [InvoicesTable, InvoiceItemsTable])
class InvoiceDao extends DatabaseAccessor<AppDatabase>
    with _$InvoiceDaoMixin {
  InvoiceDao(super.db);

  // ─── Watches ───────────────────────────────────────────────────────────────

  Stream<List<InvoicesTableData>> watchAll(String businessId) {
    return (select(invoicesTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<InvoicesTableData>> watchByStatus(
    String businessId,
    String status,
  ) {
    return (select(invoicesTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.status.equals(status) &
              t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<InvoicesTableData>> watchOverdue(String businessId) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // Overdue = pending status AND dueDate has passed
    return (select(invoicesTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.status.equals('pending') &
              t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch()
        .map((rows) => rows.where((r) {
              try {
                return DateTime.parse(r.dueDate)
                    .millisecondsSinceEpoch <
                    nowMs;
              } catch (_) {
                return false;
              }
            }).toList());
  }

  Stream<List<InvoicesTableData>> watchPendingSync() {
    return (select(invoicesTable)
          ..where((t) =>
              t.syncStatus.isIn([
                'pending_create',
                'pending_update',
                'pending_delete',
              ])))
        .watch();
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  Future<InvoicesTableData?> getById(String id) {
    return (select(invoicesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<InvoiceItemsTableData>> getItemsForInvoice(String invoiceId) {
    return (select(invoiceItemsTable)
          ..where((t) => t.invoiceId.equals(invoiceId)))
        .get();
  }

  Future<List<InvoicesTableData>> getByCustomer(
    String businessId,
    String customerId,
  ) {
    return (select(invoicesTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.customerId.equals(customerId) &
              t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<double> getTotalOutstanding(String businessId) async {
    final query = selectOnly(invoicesTable)
      ..addColumns([invoicesTable.total.sum()])
      ..where(
        invoicesTable.businessId.equals(businessId) &
            invoicesTable.status.equals('pending') &
            invoicesTable.isDeleted.equals(0),
      );
    final row = await query.getSingleOrNull();
    return row?.read(invoicesTable.total.sum()) ?? 0.0;
  }

  Future<Map<String, double>> getMonthlySales(
    String businessId,
    int year,
  ) async {
    final yearStr = year.toString();
    final rows = await (select(invoicesTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.status.isIn(['paid', 'pending']) &
              t.isDeleted.equals(0) &
              t.date.like('$yearStr-%')))
        .get();

    final Map<String, double> result = {};
    for (final row in rows) {
      final month = row.date.substring(0, 7); // 'YYYY-MM'
      result[month] = (result[month] ?? 0) + row.total;
    }
    return result;
  }

  /// The latest invoice line billing [productId] to [customerId] — used to
  /// pre-fill how many periods a recurring service still owes. Read-only:
  /// arrears are derived from already-synced invoice history rather than
  /// tracked in a separate mutable record, so this self-corrects if an
  /// invoice is later edited or deleted.
  Future<LastServiceBilling?> getLastServiceBilling(
    String businessId,
    String customerId,
    String productId,
  ) async {
    final q = select(invoicesTable).join([
      innerJoin(
        invoiceItemsTable,
        invoiceItemsTable.invoiceId.equalsExp(invoicesTable.id),
      ),
    ])
      ..where(
        invoicesTable.businessId.equals(businessId) &
            invoicesTable.customerId.equals(customerId) &
            invoicesTable.isDeleted.equals(0) &
            invoiceItemsTable.productId.equals(productId),
      )
      ..orderBy([OrderingTerm.desc(invoicesTable.date)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    if (row == null) return null;
    return LastServiceBilling(
      date: row.readTable(invoicesTable).date,
      quantity: row.readTable(invoiceItemsTable).quantity,
    );
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  Future<void> upsert(InvoicesTableCompanion entry) async {
    await into(invoicesTable).insertOnConflictUpdate(entry);
  }

  Future<void> upsertItem(InvoiceItemsTableCompanion entry) async {
    await into(invoiceItemsTable).insertOnConflictUpdate(entry);
  }

  Future<void> replaceItems(
    String invoiceId,
    List<InvoiceItemsTableCompanion> items,
  ) async {
    await (delete(invoiceItemsTable)
          ..where((t) => t.invoiceId.equals(invoiceId)))
        .go();
    for (final item in items) {
      await into(invoiceItemsTable).insert(item);
    }
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(invoicesTable)..where((t) => t.id.equals(id))).write(
      InvoicesTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markSynced(String id, {required int serverUpdatedAt}) async {
    await (update(invoicesTable)..where((t) => t.id.equals(id))).write(
      InvoicesTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markConflict(String id) async {
    await (update(invoicesTable)..where((t) => t.id.equals(id))).write(
      const InvoicesTableCompanion(syncStatus: Value('conflict')),
    );
  }

  // Mirrors a return that was already committed to Firestore by
  // SalesReturnScreen's atomic batch. Leaves syncStatus untouched — the
  // change needs no push, and flipping the row to pending would make every
  // future incremental pull skip it (see InventoryDao.applyCommittedDelta).
  Future<void> applyCommittedReturn(
    String id, {
    required double returnedAmountDelta,
    required String creditNoteNumber,
  }) async {
    final row = await getById(id);
    if (row == null) return;
    await (update(invoicesTable)..where((t) => t.id.equals(id))).write(
      InvoicesTableCompanion(
        hasReturn: const Value(1),
        returnedAmount: Value(row.returnedAmount + returnedAmountDelta),
        creditNoteNumber: Value(creditNoteNumber),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> hardDelete(String id) async {
    await (delete(invoicesTable)..where((t) => t.id.equals(id))).go();
    await (delete(invoiceItemsTable)
          ..where((t) => t.invoiceId.equals(id)))
        .go();
  }
}
