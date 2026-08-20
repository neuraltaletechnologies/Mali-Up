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

  /// Updates only the buying (cost) and selling price of an item — never
  /// touches quantity, so it's safe to call around a restock without
  /// racing [adjustQuantity]'s delta-merge sync. [costPrice] is expected to
  /// already reflect whatever costing the caller wants recorded (e.g. a
  /// weighted average blending old stock with a newly-restocked batch at a
  /// different buying price); [unitPrice] simply replaces the old selling
  /// price outright, applying to old and new stock alike.
  Future<void> updatePricing(
    String id, {
    required double costPrice,
    required double unitPrice,
  });
}
