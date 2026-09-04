import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sync_queue_dao.dart';
import '../../../../core/sync/offline_policy_notifier.dart';
import '../../../../core/sync/sync_utils.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../domain/models/daily_reconciliation.dart';
import '../mappers/cash_flow_mapper.dart';
import 'local_cash_repository.dart';
import 'remote_cash_repository.dart';

/// Offline-first write path for cash accounts, cash transactions, and daily
/// reconciliations. Reads always come from Drift; every write commits the
/// entity and a sync-queue entry in a single SQLite transaction.
class SyncCashRepository {
  final AppDatabase _db;
  final LocalCashRepository _local;
  final RemoteCashRepository remote;
  final SyncQueueDao _queue;
  final OfflinePolicyNotifier _policy;

  SyncCashRepository({
    required AppDatabase db,
    required String uid,
    required String businessId,
    required OfflinePolicyNotifier policy,
  })  : _db = db,
        _local = LocalCashRepository(db, businessId: businessId),
        remote = RemoteCashRepository(uid: uid, businessId: businessId),
        _queue = db.syncQueueDao,
        _policy = policy;

  // ─── Reads — always from Drift ─────────────────────────────────────────────

  Stream<List<CashAccount>> watchAccounts() => _local.watchAccounts();
  Stream<List<CashTransaction>> watchTransactions() =>
      _local.watchTransactions();
  Stream<List<DailyReconciliation>> watchReconciliations() =>
      _local.watchReconciliations();

  Future<CashAccount?> getAccountById(String id) =>
      _local.getAccountById(id);

  // ─── Account writes ────────────────────────────────────────────────────────

  Future<void> saveAccount(CashAccount account) async {
    _policy.assertCanWrite();
    final isNew = account.id.isEmpty;
    final entityId = isNew ? const Uuid().v4() : account.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    int localVersion = 1;
    int createdAtMs = now;
    double balance = account.balance;
    if (!isNew) {
      final existing = await _local.getRawAccountById(entityId);
      if (existing != null) {
        localVersion = existing.localVersion + 1;
        createdAtMs = existing.createdAt;
        // Edits never change balance — balance only moves via transactions.
        balance = existing.balance;
      }
    }

    final toSave = account.copyWith(balance: balance);
    final withId = CashAccount(
      id: entityId,
      name: toSave.name,
      type: toSave.type,
      balance: toSave.balance,
      accountNumber: toSave.accountNumber,
      currency: toSave.currency,
      lastReconciled: toSave.lastReconciled,
    );

    final payload = jsonEncode(withId.toFirestore());

    await _db.transaction(() async {
      await _local.upsertAccount(
        withId,
        syncStatus: isNew ? 'pending_create' : 'pending_update',
        localVersion: localVersion,
        createdAtMs: createdAtMs,
      );
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('cash_account'),
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

  /// Activates one of the built-in payment-method accounts (deterministic
  /// id from [PaymentMethodAccounts]) with the real balance the user counted.
  /// Unlike [saveAccount], a non-empty id is still a *create*: the queued op
  /// must push the full doc — including the opening balance — and stay
  /// idempotent if the account was activated on another device meanwhile
  /// (remote create is a set-merge on the same deterministic doc id).
  Future<void> activateMethodAccount(CashAccount account) async {
    _policy.assertCanWrite();
    assert(account.id.isNotEmpty, 'method accounts have deterministic ids');
    final now = DateTime.now().millisecondsSinceEpoch;

    // Scoped to this business (LocalCashRepository filters by businessId), so
    // the same channel activated under a *different* business does not make
    // this one look already-activated.
    final existing = await _local.getRawAccountById(account.id);
    if (existing != null && existing.isDeleted == 0) {
      // Already activated for this business (possibly pulled from another
      // device) — keep the existing balance, it only moves through
      // transactions.
      return;
    }

    final payload = jsonEncode(account.toFirestore());

    await _db.transaction(() async {
      await _local.upsertAccount(
        account,
        syncStatus: 'pending_create',
        localVersion: (existing?.localVersion ?? 0) + 1,
        createdAtMs: existing?.createdAt ?? now,
      );
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('cash_account'),
          entityId: Value(account.id),
          operation: const Value('create'),
          payload: Value(payload),
          checksum: Value(SyncUtils.sha256(payload)),
          localVersion: Value((existing?.localVersion ?? 0) + 1),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<void> deleteAccount(String id) async {
    _policy.assertCanWrite();
    final now = DateTime.now().millisecondsSinceEpoch;
    const payload = '{}';

    await _db.transaction(() async {
      await _local.softDeleteAccount(id);
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('cash_account'),
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

  // ─── Transaction writes ────────────────────────────────────────────────────

  /// Records the transaction and adjusts the affected account balances —
  /// all locally and instantly. The queued op replays the same balance
  /// increments on Firestore (idempotently) during sync.
  Future<void> addTransaction(CashTransaction txn) async {
    _policy.assertCanWrite();
    final entityId = txn.id.isNotEmpty ? txn.id : const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final withId = txn.copyWith();
    final toSave = CashTransaction(
      id: entityId,
      type: withId.type,
      amount: withId.amount,
      fromAccountId: withId.fromAccountId,
      toAccountId: withId.toAccountId,
      description: withId.description,
      date: withId.date,
      reference: withId.reference,
      activityCategory: withId.activityCategory,
      createdBy: withId.createdBy,
    );

    final payload = jsonEncode(toSave.toFirestore());

    await _db.transaction(() async {
      await _local.upsertTransaction(
        toSave,
        syncStatus: 'pending_create',
        createdAtMs: now,
      );

      // Apply balance deltas to the local account cache.
      if (toSave.isDeposit && toSave.toAccountId.isNotEmpty) {
        await _local.adjustAccountBalance(toSave.toAccountId, toSave.amount);
      } else if (toSave.isWithdrawal && toSave.fromAccountId.isNotEmpty) {
        await _local.adjustAccountBalance(
            toSave.fromAccountId, -toSave.amount);
      } else if (toSave.isTransfer) {
        if (toSave.fromAccountId.isNotEmpty) {
          await _local.adjustAccountBalance(
              toSave.fromAccountId, -toSave.amount);
        }
        if (toSave.toAccountId.isNotEmpty) {
          await _local.adjustAccountBalance(
              toSave.toAccountId, toSave.amount);
        }
      }

      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('cash_transaction'),
          entityId: Value(entityId),
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

  // ─── Reconciliation writes ─────────────────────────────────────────────────

  Future<void> saveReconciliation(DailyReconciliation rec) async {
    _policy.assertCanWrite();
    final entityId = rec.id.isNotEmpty
        ? rec.id
        : ReconciliationMapper.deterministicId(rec.accountId, rec.date);
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await _local.getRawReconciliationById(entityId);

    final toSave = DailyReconciliation(
      id: entityId,
      accountId: rec.accountId,
      date: rec.date,
      openingBalance: rec.openingBalance,
      closingBalance: rec.closingBalance,
      totalDeposits: rec.totalDeposits,
      totalWithdrawals: rec.totalWithdrawals,
      notes: rec.notes,
      reconciledBy: rec.reconciledBy,
      isReconciled: rec.isReconciled,
    );

    final payload = jsonEncode(toSave.toFirestore());

    await _db.transaction(() async {
      await _local.upsertReconciliation(
        toSave,
        syncStatus:
            existing == null ? 'pending_create' : 'pending_update',
        createdAtMs: existing?.createdAt ?? now,
      );
      // Keep the account's lastReconciled marker fresh for offline reads.
      await _local.updateAccountLastReconciled(rec.accountId, rec.date);
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('reconciliation'),
          entityId: Value(entityId),
          operation: Value(existing == null ? 'create' : 'update'),
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
