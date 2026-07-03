import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sync_queue_dao.dart';
import '../../../../core/sync/offline_policy_notifier.dart';
import '../../../../core/sync/sync_utils.dart';
import '../../domain/models/customer.dart';
import 'customer_repository.dart';
import 'local_customer_repository.dart';
import 'remote_customer_repository.dart';

class SyncCustomerRepository implements CustomerRepository {
  final AppDatabase _db;
  final LocalCustomerRepository _local;
  final RemoteCustomerRepository remote;
  final SyncQueueDao _queue;
  final OfflinePolicyNotifier _policy;

  SyncCustomerRepository({
    required AppDatabase db,
    required String uid,
    required String businessId,
    required OfflinePolicyNotifier policy,
  })  : _db = db,
        _local = LocalCustomerRepository(db, businessId: businessId),
        remote = RemoteCustomerRepository(uid: uid, businessId: businessId),
        _queue = db.syncQueueDao,
        _policy = policy;

  // ─── Reads ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<Customer>> watchAll() => _local.watchAll();

  @override
  Future<Customer?> getById(String id) => _local.getById(id);

  @override
  Future<Customer?> findByPhone(String phone) => _local.findByPhone(phone);

  @override
  Future<List<Customer>> search(String query) => _local.search(query);

  @override
  Future<void> updateBalance(String id, double balance) =>
      _local.updateBalance(id, balance);

  // ─── Writes ────────────────────────────────────────────────────────────────

  @override
  Future<Customer> save(Customer customer) async {
    _policy.assertCanWrite();
    final isNew = customer.id.isEmpty;
    final entityId = isNew ? const Uuid().v4() : customer.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    int localVersion = 1;
    int createdAtMs = now;
    String? existingCreatedBy;
    String? existingAssignedTo;
    if (!isNew) {
      final existing = await _local.getRawById(entityId);
      if (existing != null) {
        localVersion = existing.localVersion + 1;
        createdAtMs = existing.createdAt;
        if (existing.createdBy.isNotEmpty) {
          existingCreatedBy = existing.createdBy;
        }
        if (existing.assignedToUserId.isNotEmpty) {
          existingAssignedTo = existing.assignedToUserId;
        }
      }
    }

    // Ownership is immutable once set — preserve it across partial updates.
    final toSave = customer.copyWith(
      id: entityId,
      createdByUserId: customer.createdByUserId ?? existingCreatedBy,
      assignedToUserId: customer.assignedToUserId ?? existingAssignedTo,
    );
    final payload = jsonEncode(toSave.toFirestore());
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
          entityType: const Value('customer'),
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
    return toSave;
  }

  /// Adjusts the customer balance by [delta] locally and queues a server-side
  /// FieldValue.increment, so an offline credit sale updates the balance the
  /// same way an online sale batch does (mirrors inventory quantity_delta).
  Future<void> adjustBalance(String id, double delta) async {
    _policy.assertCanWrite();
    final existing = await _local.getById(id);
    final newBalance = (existing?.balanceAmount ?? 0) + delta;
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = jsonEncode({'balanceDelta': delta});

    await _db.transaction(() async {
      await _local.updateBalance(id, newBalance);
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('customer'),
          entityId: Value(id),
          operation: const Value('balance_delta'),
          payload: Value(payload),
          checksum: Value(SyncUtils.sha256(payload)),
          localVersion: const Value(0),
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
          entityType: const Value('customer'),
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
