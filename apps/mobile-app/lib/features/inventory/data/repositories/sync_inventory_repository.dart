import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sync_queue_dao.dart';
import '../../../../core/sync/offline_policy_notifier.dart';
import '../../../../core/sync/sync_utils.dart';
import '../../domain/models/inventory_item.dart';
import 'inventory_repository.dart';
import 'local_inventory_repository.dart';
import 'remote_inventory_repository.dart';

class SyncInventoryRepository implements InventoryRepository {
  final AppDatabase _db;
  final LocalInventoryRepository _local;
  final RemoteInventoryRepository remote;
  final SyncQueueDao _queue;
  final OfflinePolicyNotifier _policy;

  /// Fired (fire-and-forget) after a write lands in the sync queue, so the
  /// push cycle kicks off immediately instead of waiting for the next app
  /// launch or connectivity blip. See [SyncService.syncNow].
  final void Function()? onWrite;

  SyncInventoryRepository({
    required AppDatabase db,
    required String uid,
    required String businessId,
    required OfflinePolicyNotifier policy,
    this.onWrite,
  })  : _db = db,
        _local = LocalInventoryRepository(db, businessId: businessId),
        remote = RemoteInventoryRepository(uid: uid, businessId: businessId),
        _queue = db.syncQueueDao,
        _policy = policy;

  // ─── Reads ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<InventoryItem>> watchAll() => _local.watchAll();

  @override
  Stream<List<InventoryItem>> watchLowStock() => _local.watchLowStock();

  @override
  Future<InventoryItem?> getById(String id) => _local.getById(id);

  @override
  Future<InventoryItem?> getByBarcode(String barcode) =>
      _local.getByBarcode(barcode);

  @override
  Future<InventoryItem?> getBySku(String sku) => _local.getBySku(sku);

  @override
  Future<InventoryItem?> getByName(String name) => _local.getByName(name);

  @override
  Future<double> getTotalInventoryValue() => _local.getTotalInventoryValue();

  // ─── Writes ────────────────────────────────────────────────────────────────

  @override
  Future<void> save(InventoryItem item) async {
    _policy.assertCanWrite();
    final isNew = item.id.isEmpty;
    // Customer returns are separate records that deliberately share the
    // original product's name/SKU — deduping would silently turn the return
    // into a stock bump and drop its metadata.
    final isReturn = item.productType == 'customerReturn' ||
        item.productType == 'return';

    // Upsert-by-barcode/SKU: scanner populates the SKU field with the scanned
    // barcode value; check that first since it's more precise than name.
    if (isNew && !isReturn && item.sku.isNotEmpty) {
      final byBarcode = await _local.getByBarcode(item.sku);
      final duplicate = byBarcode ?? await _local.getBySku(item.sku);
      if (duplicate != null && duplicate.id.isNotEmpty) {
        await adjustQuantity(duplicate.id, item.currentStock);
        return;
      }
    }

    // Upsert-by-name: if a new product shares a name with an existing one,
    // increment stock on the existing record rather than creating a duplicate.
    if (isNew && !isReturn && item.name.isNotEmpty) {
      final duplicate = await _local.getByName(item.name);
      if (duplicate != null && duplicate.id.isNotEmpty) {
        await adjustQuantity(duplicate.id, item.currentStock);
        return;
      }
    }

    final entityId = isNew ? const Uuid().v4() : item.id;
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

    // InventoryItem.copyWith exposes id, so this is fine
    final toSave = item.copyWith(id: entityId);
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
          entityType: const Value('inventory_item'),
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
    onWrite?.call();
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
          entityType: const Value('inventory_item'),
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
    onWrite?.call();
  }

  /// Adjusts stock quantity and queues a delta-based sync entry so concurrent
  /// offline POS sales compose correctly on conflict (Phase 3 ConflictResolver).
  @override
  Future<void> adjustQuantity(String id, double delta) async {
    _policy.assertCanWrite();
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = jsonEncode({'quantityDelta': delta});

    await _db.transaction(() async {
      await _local.adjustQuantity(id, delta);
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('inventory_item'),
          entityId: Value(id),
          operation: const Value('quantity_delta'),
          payload: Value(payload),
          checksum: Value(SyncUtils.sha256(payload)),
          localVersion: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
    onWrite?.call();
  }

  /// Pushed as its own lightweight sync op (like [adjustQuantity]'s
  /// `quantity_delta`) rather than a full [save] — a full upsert would carry
  /// this device's `currentStock` snapshot and could stomp a concurrent
  /// stock movement from another device. See [InventoryRepository.updatePricing].
  @override
  Future<void> updatePricing(
    String id, {
    required double costPrice,
    required double unitPrice,
  }) async {
    _policy.assertCanWrite();
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = jsonEncode({
      'costPrice': costPrice,
      'unitPrice': unitPrice,
    });

    await _db.transaction(() async {
      await _local.updatePricing(id, costPrice: costPrice, unitPrice: unitPrice);
      await _queue.enqueue(
        SyncQueueTableCompanion(
          operationId: Value(const Uuid().v4()),
          entityType: const Value('inventory_item'),
          entityId: Value(id),
          operation: const Value('price_update'),
          payload: Value(payload),
          checksum: Value(SyncUtils.sha256(payload)),
          localVersion: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
    onWrite?.call();
  }
}
