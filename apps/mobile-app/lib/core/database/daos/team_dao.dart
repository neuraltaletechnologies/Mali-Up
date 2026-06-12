import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/team_members_table.dart';

part 'team_dao.g.dart';

@DriftAccessor(tables: [TeamMembersTable])
class TeamDao extends DatabaseAccessor<AppDatabase> with _$TeamDaoMixin {
  TeamDao(super.db);

  // ─── Watches ───────────────────────────────────────────────────────────────

  Stream<List<TeamMembersTableData>> watchAll(String businessId) {
    return (select(teamMembersTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.invitedAt)]))
        .watch();
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  Future<TeamMembersTableData?> getById(String id) {
    return (select(teamMembersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<TeamMembersTableData>> getAll(String businessId) {
    return (select(teamMembersTable)
          ..where((t) =>
              t.businessId.equals(businessId) & t.isDeleted.equals(0)))
        .get();
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  Future<void> upsert(TeamMembersTableCompanion entry) async {
    await into(teamMembersTable).insertOnConflictUpdate(entry);
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(teamMembersTable)..where((t) => t.id.equals(id))).write(
      TeamMembersTableCompanion(
        isDeleted: const Value(1),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markSynced(String id, {required int serverUpdatedAt}) async {
    await (update(teamMembersTable)..where((t) => t.id.equals(id))).write(
      TeamMembersTableCompanion(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdatedAt),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
