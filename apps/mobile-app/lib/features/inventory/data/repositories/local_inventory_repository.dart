import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/inventory_dao.dart';
import '../../domain/models/inventory_item.dart';
import '../mappers/inventory_mapper.dart';

class LocalInventoryRepository {
  final InventoryDao _dao;
  final String businessId;

  LocalInventoryRepository(AppDatabase db, {required this.businessId})
      : _dao = db.inventoryDao;

  Stream<List<InventoryItem>> watchAll() =>
      _dao.watchAll(businessId).map(
            (rows) => rows.map(InventoryMapper.fromRow).toList(),
          );

  Stream<List<InventoryItem>> watchLowStock() =>
      _dao.watchLowStock(businessId).map(
            (rows) => rows.map(InventoryMapper.fromRow).toList(),
          );

  Future<InventoryItem?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? InventoryMapper.fromRow(row) : null;
  }

  Future<InventoryTableData?> getRawById(String id) => _dao.getById(id);

  Future<InventoryItem?> getByBarcode(String barcode) async {
    final row = await _dao.getByBarcode(businessId, barcode);
    return row != null ? InventoryMapper.fromRow(row) : null;
  }

  Future<InventoryItem?> getBySku(String sku) async {
    final row = await _dao.getBySku(businessId, sku);
    return row != null ? InventoryMapper.fromRow(row) : null;
  }

  Future<double> getTotalInventoryValue() =>
      _dao.getTotalInventoryValue(businessId);

  Future<void> upsert(
    InventoryItem item, {
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
    double quantityDelta = 0,
  }) =>
      _dao.upsert(
        InventoryMapper.toCompanion(
          item,
          businessId: businessId,
          syncStatus: syncStatus,
          localVersion: localVersion,
          createdAtMs: createdAtMs,
          serverUpdatedAt: serverUpdatedAt,
          quantityDelta: quantityDelta,
        ),
      );

  Future<void> adjustQuantity(String id, double delta) =>
      _dao.adjustQuantity(id, delta);

  Future<void> softDelete(String id) => _dao.softDelete(id);
  Future<void> markSynced(String id, int serverUpdatedAtMs) =>
      _dao.markSynced(id, serverUpdatedAt: serverUpdatedAtMs);
  Future<void> markConflict(String id) => _dao.markConflict(id);
  Future<void> clearQuantityDelta(String id, double mergedQty) =>
      _dao.clearQuantityDelta(id, mergedQty);
}
