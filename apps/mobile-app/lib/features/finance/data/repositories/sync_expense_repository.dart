import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sync_queue_dao.dart';
import '../../../../core/sync/sync_utils.dart';
import '../../domain/models/expense.dart';
import 'expense_repository.dart';
import 'local_expense_repository.dart';
import 'remote_expense_repository.dart';

class SyncExpenseRepository implements ExpenseRepository {
  final AppDatabase _db;
  final LocalExpenseRepository _local;
  final RemoteExpenseRepository remote;
  final SyncQueueDao _queue;

  SyncExpenseRepository({
    required AppDatabase db,
    required String uid,
    required String businessId,
  })  : _db = db,
        _local = LocalExpenseRepository(db, businessId: businessId),
        remote = RemoteExpenseRepository(uid: uid, businessId: businessId),
        _queue = db.syncQueueDao;

  // ─── Reads ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<Expense>> watchAll() => _local.watchAll();

  @override
  Stream<List<Expense>> watchByCategory(String category) =>
      _local.watchByCategory(category);

  @override
  Future<Expense?> getById(String id) => _local.getById(id);

  @override
  Future<List<Expense>> getByDateRange(String fromDate, String toDate) =>
      _local.getByDateRange(fromDate, toDate);

  @override
  Future<double> getTotalByDateRange(String fromDate, String toDate) =>
      _local.getTotalByDateRange(fromDate, toDate);

  @override
  Future<List<Expense>> getRecurringTemplates() =>
      _local.getRecurringTemplates();

  // ─── Writes ────────────────────────────────────────────────────────────────

  @override
  Future<void> save(Expense expense) async {
    final isNew = expense.id.isEmpty;
    final entityId = isNew ? const Uuid().v4() : expense.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    int localVersion = 1;
    int createdAtMs = now;
    if (!isNew) {
      final existing = await _local.getRawById(entityId);
      if (existing != null) {
        localVersion = existing.localVersion + 1;
        createdAtMs = existing.createdAt;
      }
    }

    // Expense.copyWith doesn't expose id, so reconstruct with the assigned id.
    final toSave = Expense(
      id: entityId,
      category: expense.category,
      amount: expense.amount,
      date: expense.date,
      note: expense.note,
      recipient: expense.recipient,
      isRecurring: expense.isRecurring,
      recurrenceType: expense.recurrenceType,
      nextDueDate: expense.nextDueDate,
      templateId: expense.templateId,
      receiptUrl: expense.receiptUrl,
      paymentMethod: expense.paymentMethod,
      status: expense.status,
      approvedBy: expense.approvedBy,
      createdBy: expense.createdBy,
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
          entityType: const Value('expense'),
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
    final now = DateTime.now().millisecondsSinceEpoch;
    const payload = '{}';

    await _db.transaction(() async {
      await _local.softDelete(id);
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('expense'),
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
