import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/database/app_database.dart';
import 'package:mali_up/core/database/daos/inventory_dao.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late InventoryDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = db.inventoryDao;
  });

  tearDown(() async => db.close());

  InventoryTableCompanion makeItem({
    String id = 'item-1',
    String businessId = 'biz-1',
    String name = 'Sukari',
    String barcode = '1234567890',
    double quantity = 100.0,
    double lowStockThreshold = 20.0,
    double unitPrice = 2500.0,
    double costPrice = 2000.0,
    int isDeleted = 0,
    String syncStatus = 'synced',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return InventoryTableCompanion.insert(
      id: id,
      businessId: businessId,
      name: name,
      barcode: Value(barcode),
      quantity: Value(quantity),
      lowStockThreshold: Value(lowStockThreshold),
      unitPrice: Value(unitPrice),
      costPrice: Value(costPrice),
      createdAt: now,
      updatedAt: now,
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
    );
  }

  group('upsert / getById', () {
    test('inserts and retrieves an inventory item', () async {
      await dao.upsert(makeItem());
      final result = await dao.getById('item-1');
      expect(result, isNotNull);
      expect(result!.name, 'Sukari');
      expect(result.quantity, 100.0);
    });
  });

  group('getByBarcode', () {
    test('finds item by barcode within the same business', () async {
      await dao.upsert(makeItem(id: 'item-1', barcode: '111'));
      await dao.upsert(makeItem(id: 'item-2', barcode: '222'));

      final result = await dao.getByBarcode('biz-1', '111');
      expect(result, isNotNull);
      expect(result!.id, 'item-1');
    });

    test('returns null for barcode in a different business', () async {
      await dao.upsert(makeItem(id: 'item-1', businessId: 'biz-1'));

      final result = await dao.getByBarcode('biz-2', '1234567890');
      expect(result, isNull);
    });
  });

  group('watchLowStock', () {
    test('returns items at or below their low stock threshold', () async {
      await dao.upsert(makeItem(id: 'ok', quantity: 50, lowStockThreshold: 20));
      await dao.upsert(makeItem(
          id: 'low', quantity: 15, lowStockThreshold: 20));
      await dao.upsert(makeItem(
          id: 'exact', quantity: 20, lowStockThreshold: 20));

      final result = await dao.watchLowStock('biz-1').first;
      final ids = result.map((r) => r.id).toSet();
      expect(ids, containsAll(['low', 'exact']));
      expect(ids, isNot(contains('ok')));
    });
  });

  group('adjustQuantity', () {
    test('decreases quantity and accumulates negative delta', () async {
      await dao.upsert(makeItem(quantity: 100));
      await dao.adjustQuantity('item-1', -10);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 90.0);
      expect(result.quantityDelta, -10.0);
    });

    test('increases quantity and accumulates positive delta', () async {
      await dao.upsert(makeItem(quantity: 100));
      await dao.adjustQuantity('item-1', 50);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 150.0);
      expect(result.quantityDelta, 50.0);
    });

    test('accumulates multiple adjustments in delta', () async {
      await dao.upsert(makeItem(quantity: 100));
      await dao.adjustQuantity('item-1', -10);
      await dao.adjustQuantity('item-1', -5);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 85.0);
      expect(result.quantityDelta, -15.0);
    });

    test('increments localVersion on each adjustment', () async {
      await dao.upsert(makeItem());
      final before = await dao.getById('item-1');
      await dao.adjustQuantity('item-1', -1);
      final after = await dao.getById('item-1');

      expect(after!.localVersion, before!.localVersion + 1);
    });
  });

  group('clearQuantityDelta', () {
    test('resets delta to 0 and sets merged quantity', () async {
      await dao.upsert(makeItem(quantity: 100));
      await dao.adjustQuantity('item-1', -25);

      // Simulates ConflictResolver applying delta on top of server quantity
      await dao.clearQuantityDelta('item-1', 80.0);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 80.0);
      expect(result.quantityDelta, 0.0);
    });
  });

  group('getTotalInventoryValue', () {
    test('sums qty * costPrice for all active items', () async {
      await dao.upsert(makeItem(id: 'i1', quantity: 10, costPrice: 500));
      await dao.upsert(makeItem(id: 'i2', quantity: 5, costPrice: 1000));
      await dao.upsert(makeItem(id: 'i3', quantity: 3, costPrice: 200, isDeleted: 1));

      final value = await dao.getTotalInventoryValue('biz-1');
      // 10*500 + 5*1000 = 5000 + 5000 = 10000 (deleted item excluded)
      expect(value, 10000.0);
    });
  });
}
