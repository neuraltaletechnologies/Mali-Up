import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sync_queue_dao.dart';
import '../../../../core/sync/offline_policy_notifier.dart';
import '../../../../core/sync/sync_utils.dart';
import '../../domain/models/debt.dart';
import 'debt_repository.dart';
import 'local_debt_repository.dart';
import 'remote_debt_repository.dart';

class SyncDebtRepository implements DebtRepository {
  final AppDatabase _db;
  final LocalDebtRepository _local;
  final RemoteDebtRepository remote;
  final SyncQueueDao _queue;
  final OfflinePolicyNotifier _policy;

  SyncDebtRepository({
    required AppDatabase db,
    required String uid,
    required String businessId,
    required OfflinePolicyNotifier policy,
  })  : _db = db,
        _local = LocalDebtRepository(db, businessId: businessId),
        remote = RemoteDebtRepository(uid: uid, businessId: businessId),
        _queue = db.syncQueueDao,
        _policy = policy;

  // ─── Reads — always from Drift ─────────────────────────────────────────────

  @override
  Stream<List<Debt>> watchAll() => _local.watchAll();

  @override
  Future<Debt?> getById(String id) => _local.getById(id);

  @override
  Future<Debt?> getByInvoiceRef(String invoiceRef) =>
      _local.getByInvoiceRef(invoiceRef);

  @override
  Stream<List<DebtPayment>> watchPayments(String debtId) =>
      _local.watchPayments(debtId);

  // ─── Debt writes ───────────────────────────────────────────────────────────

  @override
  Future<void> save(Debt debt) async {
    _policy.assertCanWrite();
    final isNew = debt.id.isEmpty;
    final entityId = isNew ? const Uuid().v4() : debt.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    int localVersion = 1;
    int createdAtMs = now;
    int? serverUpdatedAt;
    if (!isNew) {
      final existing = await _local.getRawById(entityId);
      if (existing != null) {
        localVersion = existing.localVersion + 1;
        createdAtMs = existing.createdAt;
        // Carry the last-known server timestamp forward — otherwise every
        // local edit wipes it back to null, and the next push mistakes its
        // own already-synced debt for a server-side conflict.
        serverUpdatedAt = existing.serverUpdatedAt;
      }
    }

    final toSave = debt.copyWith();
    // assign generated id if new
    final debtWithId = isNew
        ? Debt(
            id: entityId,
            partyName: debt.partyName,
            partyPhone: debt.partyPhone,
            partyId: debt.partyId,
            type: debt.type,
            originalAmount: debt.originalAmount,
            paidAmount: debt.paidAmount,
            dueDate: debt.dueDate,
            status: debt.status,
            invoiceRef: debt.invoiceRef,
            note: debt.note,
            createdBy: debt.createdBy,
            createdAt: debt.createdAt,
            isWrittenOff: debt.isWrittenOff,
            writeOffReason: debt.writeOffReason,
            writtenOffBy: debt.writtenOffBy,
            writtenOffAt: debt.writtenOffAt,
          )
        : toSave;

    final payload = jsonEncode(debtWithId.toFirestore());
    final operationId = const Uuid().v4();

    await _db.transaction(() async {
      await _local.upsert(
        debtWithId,
        syncStatus: isNew ? 'pending_create' : 'pending_update',
        localVersion: localVersion,
        createdAtMs: createdAtMs,
        serverUpdatedAt: serverUpdatedAt,
      );
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(operationId),
          entityType: const Value('debt'),
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
          entityType: const Value('debt'),
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

  // ─── DebtPayment writes ────────────────────────────────────────────────────

  @override
  Future<void> addPayment(String debtId, DebtPayment payment) async {
    _policy.assertCanWrite();
    final paymentId =
        payment.id.isNotEmpty ? payment.id : const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final paymentWithId = DebtPayment(
      id: paymentId,
      amount: payment.amount,
      date: payment.date,
      method: payment.method,
      note: payment.note,
      recordedBy: payment.recordedBy,
    );

    // Build a payload that carries both debt-id and payment data so
    // SyncService can route it to the correct Firestore subcollection.
    final payloadMap = {
      'debtId': debtId,
      ...paymentWithId.toFirestore(),
    };
    final payload = jsonEncode(payloadMap);
    final operationId = const Uuid().v4();

    await _db.transaction(() async {
      await _local.upsertPayment(
        paymentWithId,
        debtId: debtId,
        syncStatus: 'pending_create',
        createdAtMs: now,
      );
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(operationId),
          entityType: const Value('debt_payment'),
          entityId: Value(paymentId),
          operation: const Value('create'),
          payload: Value(payload),
          checksum: Value(SyncUtils.sha256(payload)),
          localVersion: const Value(1),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }
}
