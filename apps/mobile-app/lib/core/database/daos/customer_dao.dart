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

  Future<CustomersTableData?> findByPhone(String businessId, String phone) {
    return (select(customersTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.isDeleted.equals(0) &
              t.phone.equals(phone)))
        .getSingleOrNull();
  }

  Future<List<CustomersTableData>> search(
    String businessId,
    String query,
  ) {
    // SQL-side LIKE keeps search fast on large customer books — avoids
    // materializing every row just to filter in Dart.
    final pattern = '%${query.toLowerCase()}%';
    return (select(customersTable)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.isDeleted.equals(0) &
              (t.name.lower().like(pattern) |
                  t.phone.like(pattern) |
                  t.email.lower().like(pattern) |
                  t.tags.lower().like(pattern)))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
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
