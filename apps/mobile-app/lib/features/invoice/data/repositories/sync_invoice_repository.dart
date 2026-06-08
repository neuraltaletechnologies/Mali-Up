import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sync_queue_dao.dart';
import '../../../../core/sync/offline_policy_notifier.dart';
import '../../../../core/sync/sync_utils.dart';
import '../../domain/models/invoice.dart';
import 'invoice_repository.dart';
import 'local_invoice_repository.dart';
import 'remote_invoice_repository.dart';

/// The single InvoiceRepository implementation the UI calls.
///
/// Reads always come from Drift (offline-safe).
/// Writes are atomic: the entity is written to Drift AND a sync-queue entry
/// is appended in a single SQLite transaction, so the UI never sees a partial
/// state even if the app crashes mid-write.
class SyncInvoiceRepository implements InvoiceRepository {
  final AppDatabase _db;
  final LocalInvoiceRepository _local;
  final RemoteInvoiceRepository remote; // Phase 3 SyncService accesses this
  final SyncQueueDao _queue;
  final OfflinePolicyNotifier _policy;

  SyncInvoiceRepository({
    required AppDatabase db,
    required String uid,
    required String businessId,
    required OfflinePolicyNotifier policy,
  })  : _db = db,
        _local = LocalInvoiceRepository(db, businessId: businessId),
        remote = RemoteInvoiceRepository(uid: uid, businessId: businessId),
        _queue = db.syncQueueDao,
        _policy = policy;

  // ─── Reads (always from Drift) ─────────────────────────────────────────────

  @override
  Stream<List<Invoice>> watchAll() => _local.watchAll();

  @override
  Stream<List<Invoice>> watchByStatus(String status) =>
      _local.watchByStatus(status);

  @override
  Stream<List<Invoice>> watchOverdue() => _local.watchOverdue();

  @override
  Future<Invoice?> getById(String id) => _local.getById(id);

  @override
  Future<List<Invoice>> getByCustomer(String customerId) =>
      _local.getByCustomer(customerId);

  @override
  Future<double> getTotalOutstanding() => _local.getTotalOutstanding();

  @override
  Future<Map<String, double>> getMonthlySales(int year) =>
      _local.getMonthlySales(year);

  // ─── Writes (Drift + SyncQueue, atomic transaction) ───────────────────────

  @override
  Future<void> save(Invoice invoice) async {
    _policy.assertCanWrite();
    final isNew = invoice.id.isEmpty;
    final entityId = isNew ? const Uuid().v4() : invoice.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Read current local version outside the transaction (read-only)
    int localVersion = 1;
    int createdAtMs = now;
    if (!isNew) {
      final existing = await _local.getRawById(entityId);
      if (existing != null) {
        localVersion = existing.localVersion + 1;
        createdAtMs = existing.createdAt;
      }
    }

    final toSave = invoice.copyWith(id: entityId);
    final payload = jsonEncode({...toSave.toFirestore()});
    final operationId = const Uuid().v4();

    await _db.transaction(() async {
      await _local.upsert(
        toSave,
        syncStatus: isNew ? 'pending_create' : 'pending_update',
        localVersion: localVersion,
        createdAtMs: createdAtMs,
      );
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(operationId),
          entityType: const Value('invoice'),
          entityId: Value(entityId),
          operation: Value(isNew ? 'create' : 'update'),
          payload: Value(payload),
          checksum: Value(SyncUtils.sha256(payload)),
          localVersion: Value(localVersion),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    _policy.assertCanWrite();
    final now = DateTime.now().millisecondsSinceEpoch;
    const payload = '{}';

    await _db.transaction(() async {
      await _local.softDelete(id);
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('invoice'),
          entityId: Value(id),
          operation: const Value('delete'),
          payload: const Value(payload),
          checksum: Value(SyncUtils.sha256(payload)),
          localVersion: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }
}
