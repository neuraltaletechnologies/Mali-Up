import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/customer/data/repositories/local_customer_repository.dart';
import '../../features/customer/data/repositories/remote_customer_repository.dart';
import '../../features/customer/data/mappers/customer_mapper.dart';
import '../../features/finance/data/repositories/local_expense_repository.dart';
import '../../features/finance/data/repositories/remote_expense_repository.dart';
import '../../features/finance/data/mappers/expense_mapper.dart';
import '../../features/inventory/data/repositories/local_inventory_repository.dart';
import '../../features/inventory/data/repositories/remote_inventory_repository.dart';
import '../../features/inventory/data/mappers/inventory_mapper.dart';
import '../../features/invoice/data/repositories/local_invoice_repository.dart';
import '../../features/invoice/data/repositories/remote_invoice_repository.dart';
import '../../features/invoice/data/mappers/invoice_mapper.dart';
import '../database/app_database.dart';
import '../database/daos/settings_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import 'conflict_resolver.dart';
import 'sync_utils.dart';

enum SyncState { idle, syncing, offline, error }

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

  SyncState _state = SyncState.idle;
  String? _lastError;
  DateTime? _lastSyncAt;
  bool _isSyncing = false;

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
  }) {
    _queue = db.syncQueueDao;
    _settings = db.settingsDao;
    _conflicts = ConflictResolver(db: db, uid: uid, businessId: businessId);
    _localInvoice = LocalInvoiceRepository(db, businessId: businessId);
    _remoteInvoice = RemoteInvoiceRepository(uid: uid, businessId: businessId);
    _localCustomer = LocalCustomerRepository(db, businessId: businessId);
    _remoteCustomer = RemoteCustomerRepository(uid: uid, businessId: businessId);
    _localExpense = LocalExpenseRepository(db, businessId: businessId);
    _remoteExpense = RemoteExpenseRepository(uid: uid, businessId: businessId);
    _localInventory = LocalInventoryRepository(db, businessId: businessId);
    _remoteInventory = RemoteInventoryRepository(uid: uid, businessId: businessId);
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    // Recover any entries that were left in `processing` by a prior crash.
    await _queue.recoverStaleProcessing();

    // Sync on launch if we have connectivity.
    final initial = await Connectivity().checkConnectivity();
    final isOnline = initial.any((r) => r != ConnectivityResult.none);
    if (isOnline) {
      unawaited(syncNow());
    } else {
      _setState(SyncState.offline);
    }

    // Trigger a sync cycle each time connectivity returns.
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        await _settings.updateLastOnlineAt(
            DateTime.now().millisecondsSinceEpoch);
        unawaited(syncNow());
      } else {
        _setState(SyncState.offline);
        final existing = await _settings.getUserSettings();
        if (existing?.offlineSince == null) {
          await _settings
              .setOfflineSince(DateTime.now().millisecondsSinceEpoch);
        }
      }
    });
  }

  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Trigger a full push cycle. Safe to call redundantly.
  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _setState(SyncState.syncing);

    try {
      await _pushQueue();
      await _pullRemoteChanges();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await _settings.updateLastSyncAt(nowMs);
      await _settings.clearOfflineSince();
      _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(nowMs);
      _lastError = null;
      _setState(SyncState.idle);
    } catch (e) {
      _lastError = e.toString();
      _setState(SyncState.error);
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
            entry.id, 'Checksum mismatch — payload corrupted');
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
        default:
          await _queue.markFailed(
              entry.id, 'Unknown entityType: ${entry.entityType}');
      }
    } catch (e) {
      final attempts = entry.attempts + 1;
      if (attempts >= _maxRetries) {
        await _queue.markFailed(entry.id, e.toString());
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

    // Conflict check
    final serverData = await _remoteCustomer.fetchRaw(entry.entityId);
    if (serverData != null) {
      final serverTs = _extractTimestampMs(serverData['updatedAt']);
      final localRow = await _localCustomer.getRawById(entry.entityId);
      final serverUpdatedAt = localRow?.serverUpdatedAt ?? 0;
      if (serverTs > serverUpdatedAt) {
        // Last-write-wins resolution
        final localWon =
            await _conflicts.resolveCustomerConflict(entry.entityId);
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
        await _localInventory.markSynced(entry.entityId, serverTs);
      }
      await _queue.markCompleted(entry.id);
      return;
    }

    // Full upsert
    final serverData = await _remoteInventory.fetchRaw(entry.entityId);
    if (serverData != null) {
      final serverTs = _extractTimestampMs(serverData['updatedAt']);
      final localRow = await _localInventory.getRawById(entry.entityId);
      final serverUpdatedAt = localRow?.serverUpdatedAt ?? 0;
      if (serverTs > serverUpdatedAt && localRow != null &&
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

  // ─── Pull (Firestore → local) ──────────────────────────────────────────────

  /// Incremental pull — fetches records updated since the last confirmed sync
  /// and hydrates Drift with the latest server state. Skips rows that have
  /// local pending changes (they will win on the next push cycle).
  Future<void> _pullRemoteChanges() async {
    final settings = await _settings.getUserSettings();
    final sinceMs = settings?.lastSyncAt ?? 0;

    await Future.wait([
      _pullInvoices(sinceMs),
      _pullCustomers(sinceMs),
      _pullExpenses(sinceMs),
      _pullInventory(sinceMs),
    ]);
  }

  Future<void> _pullInvoices(int sinceMs) async {
    final updates = await _remoteInvoice.fetchUpdatedSince(sinceMs);
    for (final update in updates) {
      final localRaw = await _localInvoice.getRawById(update.id);
      // Don't overwrite rows with local pending changes.
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') { continue; }
      final invoice = InvoiceMapper.fromFirestore(update.data, update.id);
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      await _localInvoice.upsert(
        invoice,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs: localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
  }

  Future<void> _pullCustomers(int sinceMs) async {
    final updates = await _remoteCustomer.fetchUpdatedSince(sinceMs);
    for (final update in updates) {
      final localRaw = await _localCustomer.getRawById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') { continue; }
      final customer = CustomerMapper.fromFirestore(update.data, update.id);
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      await _localCustomer.upsert(
        customer,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs: localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
  }

  Future<void> _pullExpenses(int sinceMs) async {
    final updates = await _remoteExpense.fetchUpdatedSince(sinceMs);
    for (final update in updates) {
      final localRaw = await _localExpense.getRawById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') { continue; }
      final expense = ExpenseMapper.fromFirestore(update.data, update.id);
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      await _localExpense.upsert(
        expense,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs: localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
  }

  Future<void> _pullInventory(int sinceMs) async {
    final updates = await _remoteInventory.fetchUpdatedSince(sinceMs);
    for (final update in updates) {
      final localRaw = await _localInventory.getRawById(update.id);
      if (localRaw != null &&
          localRaw.syncStatus != 'synced' &&
          localRaw.syncStatus != 'conflict') { continue; }
      final item = InventoryMapper.fromFirestore(update.data, update.id);
      final serverTs = _extractTimestampMs(update.data['updatedAt']);
      await _localInventory.upsert(
        item,
        syncStatus: 'synced',
        localVersion: localRaw?.localVersion ?? 1,
        createdAtMs: localRaw?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: serverTs,
      );
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _setState(SyncState newState) {
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
    // Firestore Timestamp
    try {
      // Cloud Firestore Timestamp has a .millisecondsSinceEpoch getter
      final ts = value as dynamic;
      return (ts.millisecondsSinceEpoch as int?) ?? 0;
    } catch (_) {}
    if (value is int) return value;
    return 0;
  }
}
