import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/customers_table.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [CustomersTable])
class CustomerDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerDaoMixin {
  CustomerDao(super.db);

  // ─── Watches ───────────────────────────────────────────────────────────────

  Stream<List<CustomersTableData>> watchAll(String businessId) {
    return (select(customersTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<CustomersTableData>> watchPendingSync() {
    return (select(customersTable)
          ..where((t) => t.syncStatus.isIn([
                'pending_create',
                'pending_update',
                'pending_delete',
              ])))
        .watch();
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  Future<CustomersTableData?> getById(String id) {
    return (select(customersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<CustomersTableData>> search(
    String businessId,
    String query,
  ) async {
    final lower = query.toLowerCase();
    final all = await (select(customersTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0)))
        .get();
    return all
        .where((c) =>
            c.name.toLowerCase().contains(lower) ||
            c.phone.contains(lower) ||
            c.email.toLowerCase().contains(lower))
        .toList();
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  Future<void> upsert(CustomersTableCompanion entry) async {
    await into(customersTable).insertOnConflictUpdate(entry);
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(customersTable)..where((t) => t.id.equals(id))).write(
      CustomersTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markSynced(String id, {required int serverUpdatedAt}) async {
    await (update(customersTable)..where((t) => t.id.equals(id))).write(
      CustomersTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markConflict(String id) async {
    await (update(customersTable)..where((t) => t.id.equals(id))).write(
      const CustomersTableCompanion(syncStatus: Value('conflict')),
    );
  }

  Future<void> hardDelete(String id) async {
    await (delete(customersTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateBalance(String id, double balance) async {
    await (update(customersTable)..where((t) => t.id.equals(id))).write(
      CustomersTableCompanion(
        balance: Value(balance),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
