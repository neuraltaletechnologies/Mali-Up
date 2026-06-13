import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sales/data/sales_providers.dart' show parseNumericAmount;
import '../domain/models/inventory_item.dart';
import '../presentation/providers/inventory_providers.dart';

/// Offline-first inventory stream backed by Drift.
/// Maps InventoryItem domain objects to the legacy raw-map shape so all
/// existing consumers (dashboard, reports) require no changes.
final inventoryItemListProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ref.watch(inventoryProvider).whenData(
        (items) => items.map(_itemToMap).toList(),
      );
});

Map<String, dynamic> _itemToMap(InventoryItem item) => {
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'category': item.categoryName.isNotEmpty ? item.categoryName : item.category,
      'categoryId': item.categoryId,
      'categoryName': item.categoryName.isNotEmpty ? item.categoryName : item.category,
      'sku': item.sku,
      'currentStock': item.currentStock,
      'stock': item.currentStock,
      'quantity': item.currentStock,
      'reorderPoint': item.reorderPoint,
      'unitPrice': item.unitPrice,
      'sellingPrice': item.unitPrice,
      'costPrice': item.costPrice,
      'buyingPrice': item.costPrice,
      'productType': item.productType,
      'unit': item.unit,
      'supplier': item.supplier,
      'lastRestocked': item.lastRestocked,
      'createdAt': item.createdAt,
      'updatedAt': item.updatedAt,
      'isActive': item.isActive,
      'expiryDate': item.expiryDate,
      'batchNumber': item.batchNumber,
      'warrantyPeriod': item.warrantyPeriod,
      'brand': item.brand,
    };

int parseStock(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double parseUnitPrice(Object? value) {
  return parseNumericAmount(value);
}
