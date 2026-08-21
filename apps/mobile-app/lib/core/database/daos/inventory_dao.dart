import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/inventory_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [InventoryTable])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  // ─── Watches ───────────────────────────────────────────────────────────────

  Stream<List<InventoryTableData>> watchAll(String businessId) {
    return (select(inventoryTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.isDeleted.equals(0) &
              t.isActive.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<InventoryTableData>> watchLowStock(String businessId) {
    return (select(inventoryTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.isDeleted.equals(0) &
              t.isActive.equals(1)))
        .watch()
        .map((rows) => rows
            .where((r) =>
                r.lowStockThreshold > 0 && r.quantity <= r.lowStockThreshold)
            .toList());
  }

  Stream<List<InventoryTableData>> watchPendingSync() {
    return (select(inventoryTable)
          ..where((t) => t.syncStatus.isIn([
                'pending_create',
                'pending_update',
                'pending_delete',
              ])))
        .watch();
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  Future<InventoryTableData?> getById(String id) {
    return (select(inventoryTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<InventoryTableData?> getByBarcode(
    String businessId,
    String barcode,
  ) {
    return (select(inventoryTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.barcode.equals(barcode) &
              t.isDeleted.equals(0))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<InventoryTableData?> getBySku(
    String businessId,
    String sku,
  ) {
    return (select(inventoryTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.sku.equals(sku) &
              t.isDeleted.equals(0))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<InventoryTableData?> getByName(
    String businessId,
    String name,
  ) {
    return (select(inventoryTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.name.lower().equals(name.toLowerCase()) &
              t.isDeleted.equals(0) &
              t.isActive.equals(1))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<double> getTotalInventoryValue(String businessId) async {
    final rows = await (select(inventoryTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.isDeleted.equals(0) &
              t.isActive.equals(1)))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + (r.quantity * r.costPrice));
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  Future<void> upsert(InventoryTableCompanion entry) async {
    await into(inventoryTable).insertOnConflictUpdate(entry);
  }

  // Adjust quantity and accumulate the delta for conflict-safe sync.
  Future<void> adjustQuantity(String id, double delta) async {
    final item = await getById(id);
    if (item == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(inventoryTable)..where((t) => t.id.equals(id))).write(
      InventoryTableCompanion(
        quantity: Value(item.quantity + delta),
        quantityDelta: Value(item.quantityDelta + delta),
        syncStatus: const Value('pending_update'),
        localVersion: Value(item.localVersion + 1),
        updatedAt: Value(now),
      ),
    );
  }

  // Updates only the buying (cost) and selling price — leaves quantity and
  // quantityDelta untouched so it can never race with adjustQuantity's
  // delta-merge sync (see the class comment on InventoryTable.quantityDelta).
  Future<void> updatePricing(
    String id, {
    required double costPrice,
    required double unitPrice,
  }) async {
    final item = await getById(id);
    if (item == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(inventoryTable)..where((t) => t.id.equals(id))).write(
      InventoryTableCompanion(
        costPrice: Value(costPrice),
        unitPrice: Value(unitPrice),
        syncStatus: const Value('pending_update'),
        localVersion: Value(item.localVersion + 1),
        updatedAt: Value(now),
      ),
    );
  }

  // Mirrors a stock change that was already committed to Firestore by an
  // online sale/return batch. Leaves syncStatus and quantityDelta untouched:
  // the change needs no push, and flipping the row to pending would make
  // every future pull skip it.
  Future<void> applyCommittedDelta(String id, double delta) async {
    final item = await getById(id);
    if (item == null) return;
    await (update(inventoryTable)..where((t) => t.id.equals(id))).write(
      InventoryTableCompanion(
        quantity: Value(item.quantity + delta),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // Subtracts an already-pushed delta from the accumulator once the server
  // has applied it, so a later conflict merge can't re-apply the same amount.
  // Subtraction (not a reset) keeps deltas queued after this push intact.
  Future<void> consumeQuantityDelta(String id, double delta) async {
    final item = await getById(id);
    if (item == null) return;
    await (update(inventoryTable)..where((t) => t.id.equals(id))).write(
      InventoryTableCompanion(quantityDelta: Value(item.quantityDelta - delta)),
    );
  }

  Future<void> clearQuantityDelta(String id, double mergedQty) async {
    await (update(inventoryTable)..where((t) => t.id.equals(id))).write(
      InventoryTableCompanion(
        quantity: Value(mergedQty),
        quantityDelta: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(inventoryTable)..where((t) => t.id.equals(id))).write(
      InventoryTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markSynced(String id, {required int serverUpdatedAt}) async {
    await (update(inventoryTable)..where((t) => t.id.equals(id))).write(
      InventoryTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markConflict(String id) async {
    await (update(inventoryTable)..where((t) => t.id.equals(id))).write(
      const InventoryTableCompanion(syncStatus: Value('conflict')),
    );
  }

  Future<void> hardDelete(String id) async {
    await (delete(inventoryTable)..where((t) => t.id.equals(id))).go();
  }
}
