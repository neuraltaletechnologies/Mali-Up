import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/inventory_item.dart';

abstract final class InventoryMapper {
  // ─── Drift row → domain ────────────────────────────────────────────────────

  static InventoryItem fromRow(InventoryTableData row) {
    final meta = _decodeMeta(row.metadata);
    return InventoryItem(
      id: row.id,
      name: row.name,
      description: row.description,
      category: row.category,
      categoryId: meta['categoryId'] as String? ?? '',
      categoryName: meta['categoryName'] as String? ?? row.category,
      sku: row.sku,
      currentStock: row.quantity,
      reorderPoint: row.lowStockThreshold,
      unitPrice: row.unitPrice,
      unit: row.unit,
      supplier: meta['supplier'] as String? ?? '',
      lastRestocked: meta['lastRestocked'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt)
          .toIso8601String(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt)
          .toIso8601String(),
      isActive: row.isActive == 1,
      expiryDate: meta['expiryDate'] as String? ?? '',
      batchNumber: meta['batchNumber'] as String? ?? '',
      warrantyPeriod: meta['warrantyPeriod'] as String? ?? '',
      brand: meta['brand'] as String? ?? '',
    );
  }

  // ─── domain → Drift companion ──────────────────────────────────────────────

  static InventoryTableCompanion toCompanion(
    InventoryItem item, {
    required String businessId,
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
    double quantityDelta = 0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = item.id.isNotEmpty ? item.id : const Uuid().v4();
    final meta = jsonEncode({
      'categoryId': item.categoryId,
      'categoryName': item.categoryName,
      'supplier': item.supplier,
      'lastRestocked': item.lastRestocked,
      'expiryDate': item.expiryDate,
      'batchNumber': item.batchNumber,
      'warrantyPeriod': item.warrantyPeriod,
      'brand': item.brand,
    });
    return InventoryTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(item.name),
      sku: Value(item.sku),
      barcode: const Value(''),
      category: Value(
        item.categoryName.isNotEmpty ? item.categoryName : item.category,
      ),
      unit: Value(item.unit),
      quantity: Value(item.currentStock),
      quantityDelta: Value(quantityDelta),
      lowStockThreshold: Value(item.reorderPoint),
      unitPrice: Value(item.unitPrice),
      costPrice: const Value(0),
      description: Value(item.description),
      imageUrl: const Value(''),
      isActive: Value(item.isActive ? 1 : 0),
      metadata: Value(meta),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: const Value(0),
    );
  }

  // ─── Firestore data → domain ───────────────────────────────────────────────

  static InventoryItem fromFirestore(Map<String, dynamic> data, String id) {
    return InventoryItem.fromFirestore(data, id);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _decodeMeta(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }
}
