import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  // ─── Watches ───────────────────────────────────────────────────────────────

  /// Live count of entries the user is waiting on (pending + processing + conflict).
  /// Drives the sync badge in the UI.
  Stream<int> watchPendingCount() {
    final countExpr = syncQueueTable.id.count();
    return (selectOnly(syncQueueTable)
          ..addColumns([countExpr])
          ..where(syncQueueTable.status.isIn([
            'pending',
            'processing',
            'conflict',
          ])))
        .watchSingle()
        .map((row) => row.read(countExpr) ?? 0);
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  /// Fetches the next batch of entries ready to be processed (FIFO order).
  /// Skips entries whose backoff window has not yet expired.
  Future<List<SyncQueueTableData>> fetchPending({required int limit}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(syncQueueTable)
          ..where((t) =>
              t.status.equals('pending') &
              t.nextRetryAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// True if any entries of [entityType] are still awaiting push. Used by the
  /// pull cycle to avoid overwriting locally-derived state (e.g. account
  /// balances) before the deltas that produced it have reached the server.
  Future<bool> hasPendingForType(String entityType) async {
    final row = await (select(syncQueueTable)
          ..where((t) =>
              t.entityType.equals(entityType) &
              t.status.isIn(['pending', 'processing']))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<List<SyncQueueTableData>> getFailedEntries() {
    return (select(syncQueueTable)
          ..where((t) => t.status.equals('failed'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<List<SyncQueueTableData>> getConflictEntries() {
    return (select(syncQueueTable)
          ..where((t) => t.status.equals('conflict'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  Future<void> enqueue(SyncQueueTableCompanion entry) async {
    // Conflict on operationId (unique), not the autoincrement PK.
    // This is idempotency: re-queuing the same logical operation updates
    // the payload rather than inserting a duplicate row.
    await into(syncQueueTable).insert(
      entry,
      onConflict: DoUpdate(
        (_) => entry,
        target: [syncQueueTable.operationId],
      ),
    );
  }

  Future<void> markProcessing(int id) async {
    await (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('processing'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markCompleted(int id) async {
    await (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('completed'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markFailed(int id, String errorMessage) async {
    await (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('failed'),
        errorMessage: Value(errorMessage),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markConflict(int id, String errorMessage) async {
    await (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('conflict'),
        errorMessage: Value(errorMessage),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Reschedules a failed entry with exponential backoff.
  Future<void> scheduleRetry(
    int id,
    int attempts,
    Duration backoff,
  ) async {
    final nextRetry =
        DateTime.now().add(backoff).millisecondsSinceEpoch;
    await (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('pending'),
        attempts: Value(attempts),
        nextRetryAt: Value(nextRetry),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Called on app start to recover entries left in 'processing' state
  /// by a previous crash. Resets them to 'pending' so they are retried.
  Future<void> recoverStaleProcessing() async {
    await (update(syncQueueTable)
          ..where((t) => t.status.equals('processing')))
        .write(
      SyncQueueTableCompanion(
        status: const Value('pending'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> cancelForEntity(String entityId) async {
    await (update(syncQueueTable)
          ..where((t) =>
              t.entityId.equals(entityId) &
              t.status.isIn(['pending', 'conflict'])))
        .write(
      SyncQueueTableCompanion(
        status: const Value('cancelled'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteCompleted() async {
    await (delete(syncQueueTable)
          ..where((t) => t.status.equals('completed')))
        .go();
  }
}
