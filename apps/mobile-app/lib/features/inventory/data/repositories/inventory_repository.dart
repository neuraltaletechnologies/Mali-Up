import '../../domain/models/inventory_item.dart';

abstract interface class InventoryRepository {
  Stream<List<InventoryItem>> watchAll();
  Stream<List<InventoryItem>> watchLowStock();

  Future<InventoryItem?> getById(String id);
  Future<InventoryItem?> getByBarcode(String barcode);
  Future<InventoryItem?> getBySku(String sku);
  Future<InventoryItem?> getByName(String name);
  Future<double> getTotalInventoryValue();

  Future<void> save(InventoryItem item);
  Future<void> delete(String id);

  /// Adjusts stock quantity by [delta] (negative for sales, positive for restocking).
  /// Uses the delta-merge strategy so concurrent offline POS changes compose safely.
  Future<void> adjustQuantity(String id, double delta);
}
