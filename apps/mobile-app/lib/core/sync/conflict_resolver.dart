import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/customer/data/repositories/local_customer_repository.dart';
import '../../features/customer/data/repositories/remote_customer_repository.dart';
import '../../features/debt/data/mappers/debt_mapper.dart';
import '../../features/debt/data/repositories/local_debt_repository.dart';
import '../../features/debt/data/repositories/remote_debt_repository.dart';
import '../../features/inventory/data/repositories/local_inventory_repository.dart';
import '../../features/inventory/data/repositories/remote_inventory_repository.dart';
import '../../features/invoice/data/repositories/local_invoice_repository.dart';
import '../database/app_database.dart';

/// Handles write conflicts between local Drift state and Firestore.
///
/// Invoice conflicts   → flag both sides for user review (never auto-resolve
///                        financial documents; NBAA compliance risk).
/// Customer conflicts  → last-write-wins by `updatedAt`.
/// Debt conflicts       → last-write-wins by `updatedAt`, same as customers —
///                        a debt/payment edit must actually reach the server
///                        instead of being stuck in permanent conflict.
/// Inventory conflicts → delta-merge: apply the accumulated offline delta on
///                        top of the current server quantity so concurrent POS
///                        sales compose correctly.
class ConflictResolver {
  final AppDatabase _db;
  final String uid;
  final String businessId;

  ConflictResolver({
    required AppDatabase db,
    required this.uid,
    required this.businessId,
  }) : _db = db;

  // ─── Invoice ────────────────────────────────────────────────────────────────

  /// Both sides have changed since the last confirmed sync.
  /// Flags the local row as `conflict`; the SyncService then marks the queue
  /// entry as `conflict` so the UI can surface a resolution dialog.
  Future<void> flagInvoiceConflict(String invoiceId) async {
    final local = LocalInvoiceRepository(_db, businessId: businessId);
    await local.markConflict(invoiceId);
  }

  // ─── Customer ───────────────────────────────────────────────────────────────

  /// Compares the local `updatedAt` against the server `updatedAt`.
  /// The winner's data is written to both Drift and Firestore.
  /// Returns `true` if the local version won (already in Firestore), `false`
  /// if the server version won and the local row was overwritten.
  Future<bool> resolveCustomerConflict(String customerId) async {
    final localRepo = LocalCustomerRepository(_db, businessId: businessId);
    final remoteRepo =
        RemoteCustomerRepository(uid: uid, businessId: businessId);

    final localRaw = await localRepo.getRawById(customerId);
    final serverData = await remoteRepo.fetchRaw(customerId);

    if (localRaw == null || serverData == null) return true;

    final localMs = localRaw.updatedAt;
    final serverTs = serverData['updatedAt'];
    final serverMs = serverTs is Timestamp
        ? serverTs.millisecondsSinceEpoch
        : (serverTs is int ? serverTs : 0);

    if (localMs >= serverMs) {
      // Local wins — nothing extra to do; SyncService will push it
      return true;
    }

    // Server wins — pull server data into Drift and mark as synced
    final serverCustomer = await remoteRepo.fetchById(customerId);
    if (serverCustomer == null) return true;
    await localRepo.upsert(
      serverCustomer,
      syncStatus: 'synced',
      localVersion: localRaw.localVersion,
      createdAtMs: localRaw.createdAt,
      serverUpdatedAt: serverMs,
    );
    return false;
  }

  // ─── Debt ───────────────────────────────────────────────────────────────────

  /// Compares the local `updatedAt` against the server `updatedAt`.
  /// The winner's data is written to both Drift and Firestore. Debt records
  /// (balances, payments) are financial data — an edit or payment the user
  /// just made locally must not be left stranded in permanent "conflict"
  /// limbo, so this always pushes forward instead of only flagging.
  /// Returns `true` if the local version won (SyncService should push it),
  /// `false` if the server version won and the local row was overwritten.
  Future<bool> resolveDebtConflict(String debtId) async {
    final localRepo = LocalDebtRepository(_db, businessId: businessId);
    final remoteRepo = RemoteDebtRepository(uid: uid, businessId: businessId);

    final localRaw = await localRepo.getRawById(debtId);
    final serverData = await remoteRepo.fetchRaw(debtId);

    if (localRaw == null || serverData == null) return true;

    final localMs = localRaw.updatedAt;
    final serverTs = serverData['updatedAt'];
    final serverMs = serverTs is Timestamp
        ? serverTs.millisecondsSinceEpoch
        : (serverTs is int ? serverTs : 0);

    if (localMs >= serverMs) {
      // Local wins — nothing extra to do; SyncService will push it
      return true;
    }

    // Server wins (edited more recently on another device) — pull it down.
    final serverDebt = DebtMapper.fromFirestore(serverData, debtId);
    await localRepo.upsert(
      serverDebt,
      syncStatus: 'synced',
      localVersion: localRaw.localVersion,
      createdAtMs: localRaw.createdAt,
      serverUpdatedAt: serverMs,
    );
    return false;
  }

  // ─── Inventory ──────────────────────────────────────────────────────────────

  /// Applies the accumulated offline `quantityDelta` on top of the server
  /// quantity, then clears the local delta and marks the item synced.
  /// Returns the merged quantity that was written to both Drift and Firestore.
  Future<double> resolveInventoryConflict(String itemId) async {
    final localRepo = LocalInventoryRepository(_db, businessId: businessId);
    final remoteRepo =
        RemoteInventoryRepository(uid: uid, businessId: businessId);

    final localRaw = await localRepo.getRawById(itemId);
    if (localRaw == null) return 0;

    final delta = localRaw.quantityDelta;
    if (delta == 0) return localRaw.quantity;

    // Apply delta on top of server quantity via Firestore increment
    final serverTs =
        await remoteRepo.applyQuantityDeltaAndGetTimestamp(itemId, delta);

    // Read back the merged server quantity
    final serverData = await remoteRepo.fetchRaw(itemId);
    final mergedQty = (serverData?['currentStock'] as num?)?.toDouble() ??
        (serverData?['stock'] as num?)?.toDouble() ??
        (localRaw.quantity);

    // Write merged quantity to Drift, clear the delta, then mark synced
    await localRepo.clearQuantityDelta(itemId, mergedQty);
    await localRepo.markSynced(itemId, serverTs);
    return mergedQty;
  }
}
