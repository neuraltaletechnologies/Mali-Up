import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../sales/data/sales_providers.dart' show parseNumericAmount;
import '../domain/models/inventory_item.dart';
import '../presentation/providers/inventory_providers.dart';

/// Offline-first inventory stream backed by Drift.
/// Maps InventoryItem domain objects to the legacy raw-map shape so all
/// existing consumers (dashboard, reports) require no changes.
///
/// Items without their own picture (typed in by hand, or added before the
/// catalog had pictures) borrow the matching master-catalog picture, so the
/// stock list, POS and dashboard show photos for them too.
final inventoryItemListProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final images = ref.watch(catalogImageIndexProvider).valueOrNull;
  return ref.watch(inventoryProvider).whenData(
        (items) => items.map((i) => _itemToMap(i, images)).toList(),
      );
});

/// Cached master-catalog pictures, looked up by barcode or product name.
final catalogImageIndexProvider = StreamProvider<CatalogImageIndex>((ref) {
  final dao = ref.watch(appDatabaseProvider).masterCatalogDao;
  return dao.watchProductsWithImages().map(CatalogImageIndex.fromRows);
});

class CatalogImageIndex {
  final Map<String, String> _byBarcode;
  final Map<String, String> _byName;
  const CatalogImageIndex._(this._byBarcode, this._byName);

  factory CatalogImageIndex.fromRows(List<MasterProductsTableData> rows) {
    final byBarcode = <String, String>{};
    final byName = <String, String>{};
    for (final r in rows) {
      final url = r.imageUrl.trim();
      if (url.isEmpty) continue;
      for (final n in [r.productName, r.productNameSw]) {
        final key = _normName(n);
        if (key.isNotEmpty) byName.putIfAbsent(key, () => url);
      }
      try {
        for (final b in jsonDecode(r.commonBarcodes) as List) {
          final key = b.toString().trim();
          if (key.isNotEmpty) byBarcode.putIfAbsent(key, () => url);
        }
      } catch (_) {}
    }
    return CatalogImageIndex._(byBarcode, byName);
  }

  /// Barcode first (exact product), then name.
  String lookup({required String barcode, required String name}) {
    final b = barcode.trim();
    if (b.isNotEmpty) {
      final hit = _byBarcode[b];
      if (hit != null) return hit;
    }
    return _byName[_normName(name)] ?? '';
  }

  static String _normName(String s) =>
      s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _imageFor(InventoryItem item, CatalogImageIndex? images) {
  if (item.imageUrl.trim().isNotEmpty) return item.imageUrl;
  return images?.lookup(barcode: item.sku, name: item.name) ?? '';
}

Map<String, dynamic> _itemToMap(
  InventoryItem item,
  CatalogImageIndex? images,
) => {
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
      'billingCycle': item.billingCycle,
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
      'sellingUnits': item.sellingUnits.map((u) => u.toJson()).toList(),
      'bomIngredients': item.bomIngredients.map((i) => i.toJson()).toList(),
      'bomOverheads': item.bomOverheads.map((o) => o.toJson()).toList(),
      'bomBatchYield': item.bomBatchYield,
      'assignedToUserId': item.assignedToUserId,
      'imageUrl': _imageFor(item, images),
    };

int parseStock(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double parseUnitPrice(Object? value) {
  return parseNumericAmount(value);
}
