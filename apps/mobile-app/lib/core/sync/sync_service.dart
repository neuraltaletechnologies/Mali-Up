import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../services/error_reporter.dart';
import '../services/sentry_metrics_service.dart';

import '../../features/customer/data/repositories/local_customer_repository.dart';
import '../../features/customer/data/repositories/remote_customer_repository.dart';
import '../../features/customer/data/mappers/customer_mapper.dart';
import '../../features/debt/data/mappers/debt_mapper.dart';
import '../../features/debt/data/repositories/local_debt_repository.dart';
import '../../features/debt/data/repositories/remote_debt_repository.dart';
import '../../features/finance/data/mappers/cash_flow_mapper.dart';
import '../../features/finance/data/repositories/local_cash_repository.dart';
import '../../features/finance/data/repositories/local_expense_repository.dart';
import '../../features/finance/data/repositories/remote_cash_repository.dart';
import '../../features/finance/data/repositories/remote_expense_repository.dart';
import '../../features/finance/data/mappers/expense_mapper.dart';
import '../../features/inventory/data/repositories/local_inventory_repository.dart';
import '../../features/inventory/data/repositories/remote_inventory_repository.dart';
import '../../features/inventory/data/mappers/inventory_mapper.dart';
import '../../features/invoice/data/repositories/local_invoice_repository.dart';
import '../../features/invoice/data/repositories/remote_invoice_repository.dart';
import '../../features/invoice/data/mappers/invoice_mapper.dart';
import '../../features/team/data/mappers/team_member_mapper.dart';
import '../../features/team/data/repositories/local_team_repository.dart';
import '../../features/team/data/repositories/remote_team_repository.dart';
import '../database/app_database.dart';
import '../database/daos/settings_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import 'conflict_resolver.dart';
import 'offline_policy_notifier.dart';
import 'sync_utils.dart';

enum SyncState { idle, syncing, offline, error }

/// Which Firestore collections the current session's role is allowed to pull.
///
/// Firestore security rules reject a read the caller isn't granted, and the
/// pull phase fans out with `Future.wait` — so one rejected pull would fail
/// the whole sync cycle (`SyncState.error`, "sync problem" alert) even though
/// the member's own writes pushed fine. A restricted team member (e.g. a
/// cashier with `createSale` but no `viewCashFlow` / `manageExpenses`, or a
/// `DataScope.own` member) only gets the pulls their permissions cover;
/// [SyncPullScope.full] (owners, or a member whose record is still loading) is
/// the previous behaviour. The per-pull `permission-denied` guard in
/// [SyncService._pullRemoteChanges] is the belt-and-braces backstop.
class SyncPullScope {
  const SyncPullScope({
    this.sales = true,
    this.customers = true,
    this.expenses = true,
    this.inventory = true,
    this.debts = true,
    this.team = true,
    this.cashAccounts = true,
    this.cashFlow = true,
  });

  const SyncPullScope.full() : this();

  final bool sales;
  final bool customers;
  final bool expenses;
  final bool inventory;
  final bool debts;

  /// Staff list — owner-only in firestore.rules, so never pulled for a member.
  final bool team;

  /// cash_accounts (needed to pick a payment till on a sale).
  final bool cashAccounts;

  /// cash_transactions + daily_reconciliations (the ledger — `viewCashFlow`).
  final bool cashFlow;
}

/// The sync engine. Drains the [SyncQueueTable] by pushing each pending
/// operation to Firestore. One instance lives for the lifetime of the session.
///
/// Call [start] once after login. The service listens for connectivity changes
/// and automatically triggers a sync cycle when the device comes back online.
/// Each call to [syncNow] is safe to call multiple times — a running cycle
/// blocks concurrent calls via [_isSyncing].
class SyncService extends ChangeNotifier {
  static const _batchSize = 20;
  static const _maxRetries = 5;

  final String uid;
  final String businessId;
  final OfflinePolicyNotifier? offlinePolicy;

  /// Non-null when the signed-in user is a team member with `DataScope.own`
  /// (see team_member.dart) — their own Firebase Auth UID. Pulls for
  /// sales/expenses/inventory are then filtered to only the records they
  /// created (or, for inventory, are assigned to), matching what
  /// firestore.rules actually grants them read access to. Null pulls
  /// everything the account has permission to see, as before.
  final String? scopeReadsToUid;

  /// Non-null for the same `DataScope.own` members as [scopeReadsToUid], but
  /// carries their staff *record id* rather than their Auth UID. Inventory
  /// items are assigned by staff record id (so a member can be assigned a
  /// service before they accept their invite — see firestore.rules
  /// `isOwnAssignedRecord`), so the inventory pull filters on this. Older
  /// assignments used the Auth UID, so [_pullInventory] pulls both shapes.
  final String? scopeInventoryToMemberId;

  /// Which collections this session's role may pull — see [SyncPullScope].
  /// Defaults to full access (owners, and the brief window before a team
  /// member's record loads).
  final SyncPullScope pullScope;

  late final SyncQueueDao _queue;
  late final SettingsDao _settings;
  late final ConflictResolver _conflicts;
  late final LocalInvoiceRepository _localInvoice;
  late final RemoteInvoiceRepository _remoteInvoice;
  late final LocalCustomerRepository _localCustomer;
  late final RemoteCustomerRepository _remoteCustomer;
  late final LocalExpenseRepository _localExpense;
  late final RemoteExpenseRepository _remoteExpense;
  late final LocalInventoryRepository _localInventory;
  late final RemoteInventoryRepository _remoteInventory;
  late final LocalDebtRepository _localDebt;
  late final RemoteDebtRepository _remoteDebt;
  late final LocalTeamRepository _localTeam;
  late final RemoteTeamRepository _remoteTeam;
  late final LocalCashRepository _localCash;
  late final RemoteCashRepository _remoteCash;

  SyncState _state = SyncState.idle;
  String? _lastError;
  DateTime? _lastSyncAt;
  bool _isSyncing = false;

  /// Set once [dispose] runs. [start] awaits several things (queue recovery,
  /// connectivity check) before it finishes wiring itself up; if the owning
  /// provider is rebuilt (e.g. a business switch) and disposes this instance
  /// while one of those awaits is still pending, the coroutine must not touch
  /// state or notifyListeners() afterward, and must not go on to subscribe to
  /// connectivity changes — an orphan subscription would keep calling
  /// syncNow() against the stale businessId/uid forever.
  bool _disposed = false;

  /// Total records pulled down from Firestore during the most recent
  /// [syncNow] cycle — 0 means the pull ran but found nothing new. Read this
  /// right after awaiting [syncNow] to tell a caller (e.g. a silent
  /// pull-to-refresh) whether anything actually changed.
  int _pulledThisCycle = 0;
  int get lastPulledCount => _pulledThisCycle;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncState get state => _state;
  String? get lastError => _lastError;
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Live count of pending + processing + conflict entries (drives the badge).
  Stream<int> get pendingCountStream => _queue.watchPendingCount();

  SyncService({
    required AppDatabase db,
    required this.uid,
    required this.businessId,
    this.offlinePolicy,
    this.scopeReadsToUid,
    this.scopeInventoryToMemberId,
    this.pullScope = const SyncPullScope.full(),
  }) {
    _queue = db.syncQueueDao;
    _settings = db.settingsDao;
    _conflicts = ConflictResolver(db: db, uid: uid, businessId: businessId);
    _localInvoice = LocalInvoiceRepository(db, businessId: businessId);
    _remoteInvoice = RemoteInvoiceRepository(uid: uid, businessId: businessId);
    _localCustomer = LocalCustomerRepository(db, businessId: businessId);
    _remoteCustomer = RemoteCustomerRepository(
      uid: uid,
      businessId: businessId,
    );
    _localExpense = LocalExpenseRepository(db, businessId: businessId);
    _remoteExpense = RemoteExpenseRepository(uid: uid, businessId: businessId);
    _localInventory = LocalInventoryRepository(db, businessId: businessId);
    _remoteInventory = RemoteInventoryRepository(
      uid: uid,
      businessId: businessId,
    );
    _localDebt = LocalDebtRepository(db, businessId: businessId);
    _remoteDebt = RemoteDebtRepository(uid: uid, businessId: businessId);
    _localTeam = LocalTeamRepository(db, businessId: businessId);
    _remoteTeam = RemoteTeamRepository(uid: uid, businessId: businessId);
    _localCash = LocalCashRepository(db, businessId: businessId);
    _remoteCash = RemoteCashRepository(uid: uid, businessId: businessId);
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    // Recover any entries that were left in `processing` by a prior crash.
    await _queue.recoverStaleProcessing();
    if (_disposed) return;

    // One-time self-heal: debt conflicts used to be a dead end (flagged and
    // never retried) before conflict resolution existed for debts. Give any
    // leftover entries from that era a fresh pass now that they can actually
    // be resolved — safe for debts specifically (last-write-wins), unlike
    // invoices which stay flagged for manual review on purpose.
    await _queue.requeueConflicts('debt');
    if (_disposed) return;

    // Sync on launch if we have connectivity.
    final initial = await Connectivity().checkConnectivity();
    if (_disposed) return;
    final isOnline = initial.any((r) => r != ConnectivityResult.none);
    if (isOnline) {
      unawaited(syncNow());
    } else {
      _setState(SyncState.offline);
      await _markOffline();
    }
    if (_disposed) return;

    // Trigger a sync cycle each time connectivity returns.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      if (_disposed) return;
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        await _settings.updateLastOnlineAt(
          DateTime.now().millisecondsSinceEpoch,
        );
        unawaited(syncNow());
      } else {
        _setState(SyncState.offline);
        await _markOffline();
      }
    });
  }

  Future<void> _markOffline() async {
    final policy = offlinePolicy;
    if (policy != null) {
      await policy.markOffline();
      return;
    }
    final existing = await _settings.getUserSettings();
    if (existing?.offlineSince == null) {
      await _settings.setOfflineSince(DateTime.now().millisecondsSinceEpoch);
    }
  }

  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Trigger a full push cycle. Safe to call redundantly.
  Future<void> syncNow() async {
    if (_disposed || _isSyncing) return;
    _isSyncing = true;
    _setState(SyncState.syncing);

    try {
      await _pushQueue();
      await _pullRemoteChanges();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final policy = offlinePolicy;
      if (policy != null) {
        await policy.markOnline();
      } else {
        await _settings.clearOfflineSince();
      }
      _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(nowMs);
      _lastError = null;
      _setState(SyncState.idle);
      final pending = await _queue.fetchPending(limit: 999);
      SentryMetricsService.syncCycleCompleted(
        success: true,
        queueSize: pending.length,
      );
    } catch (e, st) {
      _lastError = e.toString();
      _setState(SyncState.error);
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.syncCycleCompleted(success: false, queueSize: 0);
    } finally {
      _isSyncing = false;
    }
  }

  // ─── Push (local → Firestore) ──────────────────────────────────────────────

  Future<void> _pushQueue() async {
    while (true) {
      final batch = await _queue.fetchPending(limit: _batchSize);
      if (batch.isEmpty) break;

      for (final entry in batch) {
        await _processEntry(entry);
      }

      // Keep going until the queue is fully drained.
      final remaining = await _queue.fetchPending(limit: 1);
      if (remaining.isEmpty) break;
    }

    // Clean up successfully processed entries to keep the table lean.
    await _queue.deleteCompleted();
  }

  Future<void> _processEntry(SyncQueueTableData entry) async {
    await _queue.markProcessing(entry.id);

    try {
      // Verify payload integrity before sending to Firestore.
      final actualChecksum = SyncUtils.sha256(entry.payload);
      if (actualChecksum != entry.checksum) {
        await _queue.markFailed(
          entry.id,
          'Checksum mismatch — payload corrupted',
        );
        return;
      }

      switch (entry.entityType) {
        case 'invoice':
          await _processInvoiceEntry(entry);
        case 'customer':
          await _processCustomerEntry(entry);
        case 'expense':
          await _processExpenseEntry(entry);
        case 'inventory_item':
          await _processInventoryEntry(entry);
        case 'debt':
          await _processDebtEntry(entry);
        case 'debt_payment':
          await _processDebtPaymentEntry(entry);
        case 'team_member':
          await _processTeamMemberEntry(entry);
        case 'cash_account':
          await _processCashAccountEntry(entry);
        case 'cash_transaction':
          await _processCashTransactionEntry(entry);
        case 'reconciliation':
          await _processReconciliationEntry(entry);
        default:
          await _queue.markFailed(
            entry.id,
            'Unknown entityType: ${entry.entityType}',
          );
      }
    } catch (e, st) {
      final attempts = entry.attempts + 1;
      if (attempts >= _maxRetries) {
        await _queue.markFailed(entry.id, e.toString());
        ErrorReporter.captureException(e, stackTrace: st);
      } else {
        final backoff = _backoffDuration(attempts);
        await _queue.scheduleRetry(entry.id, attempts, backoff);
      }
    }
  }

  // ─── Per-entity push handlers ──────────────────────────────────────────────

  Future<void> _processInvoiceEntry(SyncQueueTableData entry) async {
    if (entry.operation == 'delete') {
      await _remoteInvoice.delete(entry.entityId);
      await _queue.markCompleted(entry.id);
      return;
    }

    // Check for server-side conflict before pushing.
    final serverData = await _remoteInvoice.fetchRaw(entry.entityId);
    if (serverData != null) {
      final serverTs = _extractTimestampMs(serverData['updatedAt']);
      final localRow = await _localInvoice.getRawById(entry.entityId);
      final serverUpdatedAt = localRow?.serverUpdatedAt ?? 0;
      if (serverTs > (serverUpdatedAt)) {
        // Server changed since last sync — flag as conflict for user review.
        await _conflicts.flagInvoiceConflict(entry.entityId);
        await _queue.markConflict(entry.id, 'Server version is newer');
        return;
      }
    }

    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final invoice = InvoiceMapper.fromFirestore(payload, entry.entityId);
    final serverTs = await _remoteInvoice.saveAndGetTimestamp(invoice);
    await _localInvoice.markSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processCustomerEntry(SyncQueueTableData entry) async {
    if (entry.operation == 'delete') {
      await _remoteCustomer.delete(entry.entityId);
      await _queue.markCompleted(entry.id);
      return;
    }

    if (entry.operation == 'balance_delta') {
      // Offline credit sales queue balance increments so concurrent sessions
      // compose on the server exactly like online sale batches do.
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      final delta = (payload['balanceDelta'] as num?)?.toDouble() ?? 0;
      if (delta != 0) {
        final serverTs = await _remoteCustomer.applyBalanceDeltaAndGetTimestamp(
          entry.entityId,
          delta,
        );
        await _localCustomer.markSynced(entry.entityId, serverTs);
      }
      await _queue.markCompleted(entry.id);
      return;
    }

    // Conflict check
    final serverData = await _remoteCustomer.fetchRaw(entry.entityId);
    if (serverData != null) {
      final serverTs = _extractTimestampMs(serverData['updatedAt']);
      final localRow = await _localCustomer.getRawById(entry.entityId);
      final serverUpdatedAt = localRow?.serverUpdatedAt ?? 0;
      if (serverTs > serverUpdatedAt) {
        // Last-write-wins resolution
        final localWon = await _conflicts.resolveCustomerConflict(
          entry.entityId,
        );
        if (!localWon) {
          // Server won — cancel any further queued updates for this entity
          await _queue.cancelForEntity(entry.entityId);
          await _queue.markCompleted(entry.id);
          return;
        }
      }
    }

    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final customer = CustomerMapper.fromFirestore(payload, entry.entityId);
    final serverTs = await _remoteCustomer.saveAndGetTimestamp(customer);
    await _localCustomer.markSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processExpenseEntry(SyncQueueTableData entry) async {
    if (entry.operation == 'delete') {
      await _remoteExpense.delete(entry.entityId);
      await _queue.markCompleted(entry.id);
      return;
    }

    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final expense = ExpenseMapper.fromFirestore(payload, entry.entityId);
    final serverTs = await _remoteExpense.saveAndGetTimestamp(expense);
    await _localExpense.markSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processInventoryEntry(SyncQueueTableData entry) async {
    if (entry.operation == 'delete') {
      await _remoteInventory.delete(entry.entityId);
      await _queue.markCompleted(entry.id);
      return;
    }

    if (entry.operation == 'quantity_delta') {
      // Delta-merge conflict resolution for concurrent POS sessions.
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      final delta = (payload['quantityDelta'] as num?)?.toDouble() ?? 0;
      if (delta != 0) {
        final serverTs = await _remoteInventory
            .applyQuantityDeltaAndGetTimestamp(entry.entityId, delta);
        // The pushed amount is now on the server — remove it from the local
        // accumulator so ConflictResolver can't apply it a second time.
        await _localInventory.consumeQuantityDelta(entry.entityId, delta);
        await _localInventory.markSynced(entry.entityId, serverTs);
      }
      await _queue.markCompleted(entry.id);
      return;
    }

    if (entry.operation == 'price_update') {
      // Field-level push, mirroring quantity_delta above — never carries a
      // currentStock snapshot, so it can't race a concurrent stock movement.
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      final costPrice = (payload['costPrice'] as num?)?.toDouble() ?? 0;
      final unitPrice = (payload['unitPrice'] as num?)?.toDouble() ?? 0;
      final serverTs = await _remoteInventory.updatePricingAndGetTimestamp(
        entry.entityId,
        costPrice: costPrice,
        unitPrice: unitPrice,
      );
      await _localInventory.markSynced(entry.entityId, serverTs);
      await _queue.markCompleted(entry.id);
      return;
    }

    // Full upsert
    final serverData = await _remoteInventory.fetchRaw(entry.entityId);
    if (serverData != null) {
      final serverTs = _extractTimestampMs(serverData['updatedAt']);
      final localRow = await _localInventory.getRawById(entry.entityId);
      final serverUpdatedAt = localRow?.serverUpdatedAt ?? 0;
      if (serverTs > serverUpdatedAt &&
          localRow != null &&
          localRow.quantityDelta != 0) {
        await _conflicts.resolveInventoryConflict(entry.entityId);
        await _queue.markCompleted(entry.id);
        return;
      }
    }

    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final item = InventoryMapper.fromFirestore(payload, entry.entityId);
    final serverTs = await _remoteInventory.saveAndGetTimestamp(item);
    await _localInventory.markSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processDebtEntry(SyncQueueTableData entry) async {
    if (entry.operation == 'delete') {
      await _remoteDebt.delete(entry.entityId);
      await _queue.markCompleted(entry.id);
      return;
    }

    final serverData = await _remoteDebt.fetchRaw(entry.entityId);
    if (serverData != null) {
      final serverTs = _extractTimestampMs(serverData['updatedAt']);
      final localRow = await _localDebt.getRawById(entry.entityId);
      final serverUpdatedAt = localRow?.serverUpdatedAt ?? 0;
      if (serverTs > serverUpdatedAt) {
        // Last-write-wins: local changes take priority for debt records
        // (financial data must not be silently overwritten) — actually
        // resolve it rather than stalling the push forever.
        final localWon = await _conflicts.resolveDebtConflict(entry.entityId);
        if (!localWon) {
          // Server won — cancel any further queued updates for this entity
          await _queue.cancelForEntity(entry.entityId);
          await _queue.markCompleted(entry.id);
          return;
        }
      }
    }

    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final debt = DebtMapper.fromFirestore(payload, entry.entityId);
    final serverTs = await _remoteDebt.saveAndGetTimestamp(debt);
    await _localDebt.markSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processDebtPaymentEntry(SyncQueueTableData entry) async {
    if (entry.operation == 'delete') {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      final debtId = payload['debtId'] as String? ?? '';
      if (debtId.isNotEmpty) {
        await _remoteDebt.deletePayment(debtId, entry.entityId);
      }
      await _queue.markCompleted(entry.id);
      return;
    }

    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final debtId = payload['debtId'] as String? ?? '';
    if (debtId.isEmpty) {
      await _queue.markFailed(entry.id, 'debt_payment payload missing debtId');
      return;
    }

    final payment = DebtPaymentMapper.fromFirestore(payload, entry.entityId);
    final serverTs = await _remoteDebt.savePaymentAndGetTimestamp(
      debtId,
      payment,
    );
    await _localDebt.markPaymentSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processTeamMemberEntry(SyncQueueTableData entry) async {
    if (entry.operation == 'delete') {
      await _remoteTeam.delete(entry.entityId);
      await _queue.markCompleted(entry.id);
      return;
    }

    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final member = TeamMemberMapper.fromFirestore(payload, entry.entityId);
    final serverTs = await _remoteTeam.saveAndGetTimestamp(member);
    await _localTeam.markSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processCashAccountEntry(SyncQueueTableData entry) async {
    if (entry.operation == 'delete') {
      // Writes a tombstone (isDeleted: true) rather than removing the doc,
      // so other devices see the deletion via their incremental pulls.
      await _remoteCash.deleteAccount(entry.entityId);
      // Clear pending_delete so future pulls of this row aren't skipped.
      await _localCash.markAccountSynced(
        entry.entityId,
        DateTime.now().millisecondsSinceEpoch,
      );
      await _queue.markCompleted(entry.id);
      return;
    }

    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final account = CashAccountMapper.fromFirestore(payload, entry.entityId);
    // Creates push the full doc (incl. opening balance); updates only push
    // metadata so server-side FieldValue.increment deltas are never clobbered.
    final serverTs = entry.operation == 'create'
        ? await _remoteCash.createAccountAndGetTimestamp(account)
        : await _remoteCash.updateAccountAndGetTimestamp(account);
    await _localCash.markAccountSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processCashTransactionEntry(SyncQueueTableData entry) async {
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final txn = CashTransactionMapper.fromFirestore(payload, entry.entityId);
    // Idempotent: the remote repo skips the balance increments when the doc
    // already exists (a retry), so amounts are never double-applied.
    final serverTs = await _remoteCash.saveTransactionAndGetTimestamp(txn);
    await _localCash.markTransactionSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  Future<void> _processReconciliationEntry(SyncQueueTableData entry) async {
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final rec = ReconciliationMapper.fromFirestore(payload, entry.entityId);
    final serverTs = await _remoteCash.saveReconciliationAndGetTimestamp(rec);
    await _localCash.markReconciliationSynced(entry.entityId, serverTs);
    await _queue.markCompleted(entry.id);
  }

  // ─── Pull (Firestore → local) ──────────────────────────────────────────────

  /// Incremental pull — fetches records updated since the last confirmed sync
  /// and hydrates Drift with the latest server state. Skips rows that have
  /// local pending changes (they will win on the next push cycle).
  ///
  /// Each pull returns the max server `updatedAt` it saw (null if it skipped
  /// this cycle). The watermark advances to that max — never to the device
  /// clock. A device clock running ahead of Firestore's would otherwise set
  /// the watermark past every new server write and skip them forever (stock
  /// deducted by online sales would never appear locally).
  Future<void> _pullRemoteChanges() async {
    final settings = await _settings.getUserSettings();
    final sinceMs = settings?.lastSyncAt ?? 0;
    _pulledThisCycle = 0;

    final results = await Future.wait([
      if (pullScope.sales) _guardedPull('invoices', () => _pullInvoices(sinceMs)),
      if (pullScope.customers)
        _guardedPull('customers', () => _pullCustomers(sinceMs)),
      if (pullScope.expenses)
        _guardedPull('expenses', () => _pullExpenses(sinceMs)),
      if (pullScope.inventory)
        _guardedPull('inventory', () => _pullInventory(sinceMs)),
      if (pullScope.debts) _guardedPull('debts', () => _pullDebts(sinceMs)),
      if (pullScope.team)
        _guardedPull('team', () => _pullTeamMembers(sinceMs)),
      if (pullScope.cashAccounts)
        _guardedPull('cashAccounts', () => _pullCashAccounts(sinceMs)),
      if (pullScope.cashFlow)
        _guardedPull('cashTransactions', () => _pullCashTransactions(sinceMs)),
      if (pullScope.cashFlow)
        _guardedPull('reconciliations', () => _pullReconciliations(sinceMs)),
    ]);

    // Hold the watermark whenever a pull skipped (pending local deltas) so
    // the skipped records are retried on the next cycle.
    if (results.any((r) => r == null)) return;
    var maxTs = sinceMs;
    for (final r in results) {
      if (r! > maxTs) maxTs = r;
    }
    if (maxTs > sinceMs) {
      await _settings.updateLastSyncAt(maxTs);
    }
  }

  /// Runs one pull, swallowing a Firestore `permission-denied` so a single
  /// collection this session's role can't read doesn't fail the whole cycle.
  /// [pullScope] should already keep us from calling those pulls; this is the
  /// backstop for custom roles and rules/permission drift. Returns 0 (rather
  /// than null) on a denial — the collection is unreadable for this session,
  /// so there is nothing to retry and the watermark need not be held.
  Future<int?> _guardedPull(
    String label,
    Future<int?> Function() pull,
  ) async {
    try {
      return await pull();
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        if (kDebugMode) {
          debugPrint('[Sync] pull "$label" denied — skipping this cycle');
        }
        ErrorReporter.captureException(e, stackTrace: st);
        return 0;
      }
      rethrow;
    }
  }

  Future<int?> _pullInvoices(int sinceMs) async {
    final updates = await _remoteInvoice.fetchUpdatedSince(
      sinceMs,
      scopeToUid: scopeReadsToUid,
    );
    _pulledThisCycle += updates.length;
    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localInvoice.getRawById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      final invoice = InvoiceMapper.fromFirestore(update.data, update.id);
      await _localInvoice.upsert(
        invoice,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  Future<int?> _pullCustomers(int sinceMs) async {
    // While balance deltas from offline sales are still queued, the server
    // balances don't include them yet — pulling now would make local balances
    // jump backwards (same guard as cash accounts). Push runs first, so this
    // only skips a cycle when the push couldn't complete.
    if (await _queue.hasPendingForType('customer')) return null;

    final updates = await _remoteCustomer.fetchUpdatedSince(sinceMs);
    _pulledThisCycle += updates.length;
    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localCustomer.getRawById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      final customer = CustomerMapper.fromFirestore(update.data, update.id);
      await _localCustomer.upsert(
        customer,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  Future<int?> _pullExpenses(int sinceMs) async {
    final updates = await _remoteExpense.fetchUpdatedSince(
      sinceMs,
      scopeToUid: scopeReadsToUid,
    );
    _pulledThisCycle += updates.length;
    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localExpense.getRawById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      final expense = ExpenseMapper.fromFirestore(update.data, update.id);
      await _localExpense.upsert(
        expense,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  Future<int?> _pullInventory(int sinceMs) async {
    // While quantity deltas are still queued, server stock doesn't include
    // them yet — pulling now would overwrite the local quantity and zero the
    // pending delta (same guard as customers/cash accounts).
    if (await _queue.hasPendingForType('inventory_item')) return null;

    final memberId = scopeInventoryToMemberId;
    final List<({String id, Map<String, dynamic> data})> updates;
    if (memberId != null && memberId.isNotEmpty) {
      // A DataScope.own member's own items are those assigned to them. New
      // assignments carry their staff record id; assignments made while they
      // were already active may carry their Auth UID — pull both and de-dupe.
      final byMember = await _remoteInventory.fetchUpdatedSince(
        sinceMs,
        scopeToUid: memberId,
      );
      final byUid = (scopeReadsToUid != null && scopeReadsToUid != memberId)
          ? await _remoteInventory.fetchUpdatedSince(
              sinceMs,
              scopeToUid: scopeReadsToUid,
            )
          : const <({String id, Map<String, dynamic> data})>[];
      final seen = <String>{};
      updates = [
        for (final u in [...byMember, ...byUid])
          if (seen.add(u.id)) u,
      ];
    } else {
      updates = await _remoteInventory.fetchUpdatedSince(
        sinceMs,
        scopeToUid: scopeReadsToUid,
      );
    }
    _pulledThisCycle += updates.length;
    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localInventory.getRawById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      final item = InventoryMapper.fromFirestore(update.data, update.id);
      await _localInventory.upsert(
        item,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  Future<int?> _pullDebts(int sinceMs) async {
    final updates = await _remoteDebt.fetchUpdatedSince(sinceMs);
    _pulledThisCycle += updates.length;
    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localDebt.getRawById(update.id);
      // Skip rows with local pending changes — local wins on the push cycle.
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      final debt = DebtMapper.fromFirestore(update.data, update.id);
      await _localDebt.upsert(
        debt,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  Future<int?> _pullTeamMembers(int sinceMs) async {
    // Team members use a full-fetch if we've never synced; incremental otherwise.
    final updates = sinceMs == 0
        ? await _remoteTeam.fetchAll()
        : await _remoteTeam.fetchUpdatedSince(sinceMs);
    _pulledThisCycle += updates.length;

    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localTeam.getRawById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      final member = TeamMemberMapper.fromFirestore(update.data, update.id);
      await _localTeam.upsert(
        member,
        syncStatus: 'synced',
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  Future<int?> _pullCashAccounts(int sinceMs) async {
    // If transaction deltas are still queued, the server balances don't yet
    // include them — overwriting the locally-adjusted balance would make cash
    // totals jump backwards. Skip this cycle; the next one (after the queue
    // drains) will reconcile.
    if (await _queue.hasPendingForType('cash_transaction')) return null;

    final updates = sinceMs == 0
        ? await _remoteCash.fetchAllAccounts()
        : await _remoteCash.fetchAccountsUpdatedSince(sinceMs);
    _pulledThisCycle += updates.length;
    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localCash.getRawAccountById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      if (update.data['isDeleted'] == true) {
        // Tombstone from another device — hide the account locally.
        if (localRaw != null) {
          await _localCash.applyRemoteAccountDeletion(update.id, serverTs);
        }
        continue;
      }
      final account = CashAccountMapper.fromFirestore(update.data, update.id);
      await _localCash.upsertAccount(
        account,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  Future<int?> _pullCashTransactions(int sinceMs) async {
    final updates = sinceMs == 0
        ? await _remoteCash.fetchAllTransactions()
        : await _remoteCash.fetchTransactionsUpdatedSince(sinceMs);
    _pulledThisCycle += updates.length;
    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localCash.getRawTransactionById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      final txn = CashTransactionMapper.fromFirestore(update.data, update.id);
      await _localCash.upsertTransaction(
        txn,
        syncStatus: 'synced',
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  Future<int?> _pullReconciliations(int sinceMs) async {
    final updates = sinceMs == 0
        ? await _remoteCash.fetchAllReconciliations()
        : await _remoteCash.fetchReconciliationsUpdatedSince(sinceMs);
    _pulledThisCycle += updates.length;
    var maxTs = 0;
    for (final update in updates) {
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      if (serverTs > maxTs) maxTs = serverTs;
      final localRaw = await _localCash.getRawReconciliationById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') {
        continue;
      }
      final rec = ReconciliationMapper.fromFirestore(update.data, update.id);
      await _localCash.upsertReconciliation(
        rec,
        syncStatus: 'synced',
        createdAtMs:
            localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
    return maxTs;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _setState(SyncState newState) {
    if (_disposed) return;
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Exponential backoff: 30s, 2m, 8m, 32m, capped at 1h.
  static Duration _backoffDuration(int attempt) {
    final seconds = (30 * (1 << (attempt - 1))).clamp(30, 3600);
    return Duration(seconds: seconds);
  }

  static int _extractTimestampMs(dynamic value) {
    if (value == null) return 0;
    try {
      final ts = value as dynamic;
      return (ts.millisecondsSinceEpoch as int?) ?? 0;
    } catch (_) {}
    if (value is int) return value;
    return 0;
  }
}
