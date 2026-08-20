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
      await dao.upsert(makeItem(barcode: '111'));
      await dao.upsert(makeItem(id: 'item-2', barcode: '222'));

      final result = await dao.getByBarcode('biz-1', '111');
      expect(result, isNotNull);
      expect(result!.id, 'item-1');
    });

    test('returns null for barcode in a different business', () async {
      await dao.upsert(makeItem());

      final result = await dao.getByBarcode('biz-2', '1234567890');
      expect(result, isNull);
    });
  });

  group('watchLowStock', () {
    test('returns items at or below their low stock threshold', () async {
      await dao.upsert(makeItem(id: 'ok', quantity: 50));
      await dao.upsert(makeItem(
          id: 'low', quantity: 15));
      await dao.upsert(makeItem(
          id: 'exact', quantity: 20));

      final result = await dao.watchLowStock('biz-1').first;
      final ids = result.map((r) => r.id).toSet();
      expect(ids, containsAll(['low', 'exact']));
      expect(ids, isNot(contains('ok')));
    });

    test('excludes items without a threshold (services, returns)', () async {
      await dao.upsert(
          makeItem(id: 'service', quantity: 0, lowStockThreshold: 0));
      await dao.upsert(makeItem(id: 'low', quantity: 5));

      final result = await dao.watchLowStock('biz-1').first;
      expect(result.map((r) => r.id), ['low']);
    });
  });

  group('adjustQuantity', () {
    test('decreases quantity and accumulates negative delta', () async {
      await dao.upsert(makeItem());
      await dao.adjustQuantity('item-1', -10);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 90.0);
      expect(result.quantityDelta, -10.0);
    });

    test('increases quantity and accumulates positive delta', () async {
      await dao.upsert(makeItem());
      await dao.adjustQuantity('item-1', 50);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 150.0);
      expect(result.quantityDelta, 50.0);
    });

    test('accumulates multiple adjustments in delta', () async {
      await dao.upsert(makeItem());
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

  group('applyCommittedDelta', () {
    test('changes quantity without touching syncStatus or quantityDelta',
        () async {
      await dao.upsert(makeItem());
      await dao.applyCommittedDelta('item-1', -10);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 90.0);
      // The change is already on the server — the row must stay 'synced' so
      // pulls keep hydrating it, and no delta may be queued for push.
      expect(result.quantityDelta, 0.0);
      expect(result.syncStatus, 'synced');
    });

    test('does not clobber a pending offline delta on the same row', () async {
      await dao.upsert(makeItem());
      await dao.adjustQuantity('item-1', -5);
      await dao.applyCommittedDelta('item-1', -10);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 85.0);
      expect(result.quantityDelta, -5.0);
      expect(result.syncStatus, 'pending_update');
    });
  });

  group('consumeQuantityDelta', () {
    test('subtracts the pushed amount without touching quantity', () async {
      await dao.upsert(makeItem());
      await dao.adjustQuantity('item-1', -10);

      // Simulates SyncService pushing the -10 delta to Firestore.
      await dao.consumeQuantityDelta('item-1', -10);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 90.0);
      expect(result.quantityDelta, 0.0);
    });

    test('keeps deltas accumulated after the pushed one', () async {
      await dao.upsert(makeItem());
      await dao.adjustQuantity('item-1', -10);
      await dao.adjustQuantity('item-1', -5);

      // Only the first queued op (-10) has been pushed; -5 must survive so
      // a conflict merge can still apply it.
      await dao.consumeQuantityDelta('item-1', -10);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 85.0);
      expect(result.quantityDelta, -5.0);
    });
  });

  group('clearQuantityDelta', () {
    test('resets delta to 0 and sets merged quantity', () async {
      await dao.upsert(makeItem());
      await dao.adjustQuantity('item-1', -25);

      // Simulates ConflictResolver applying delta on top of server quantity
      await dao.clearQuantityDelta('item-1', 80.0);

      final result = await dao.getById('item-1');
      expect(result!.quantity, 80.0);
      expect(result.quantityDelta, 0.0);
    });
  });

  group('updatePricing', () {
    test('updates costPrice and unitPrice', () async {
      await dao.upsert(makeItem());
      await dao.updatePricing('item-1', costPrice: 2200, unitPrice: 2800);

      final result = await dao.getById('item-1');
      expect(result!.costPrice, 2200.0);
      expect(result.unitPrice, 2800.0);
    });

    test('does not touch quantity or a pending quantityDelta', () async {
      await dao.upsert(makeItem());
      await dao.adjustQuantity('item-1', 50); // pending restock, unsynced
      await dao.updatePricing('item-1', costPrice: 2200, unitPrice: 2800);

      final result = await dao.getById('item-1');
      // Weighted-average cost blending happens in the repository layer —
      // the DAO just persists whatever price it's given, and must leave
      // the quantity-delta accumulator alone so it can't race the
      // separate quantity_delta sync push.
      expect(result!.quantity, 150.0);
      expect(result.quantityDelta, 50.0);
      expect(result.costPrice, 2200.0);
      expect(result.unitPrice, 2800.0);
    });

    test('marks the row pending_update and bumps localVersion', () async {
      await dao.upsert(makeItem());
      final before = await dao.getById('item-1');
      await dao.updatePricing('item-1', costPrice: 2200, unitPrice: 2800);
      final after = await dao.getById('item-1');

      expect(after!.syncStatus, 'pending_update');
      expect(after.localVersion, before!.localVersion + 1);
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
