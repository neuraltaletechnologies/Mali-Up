import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/database/app_database.dart';
import 'package:mali_up/core/database/daos/customer_dao.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late CustomerDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = db.customerDao;
  });

  tearDown(() async => db.close());

  CustomersTableCompanion makeCustomer({
    String id = 'cust-1',
    String businessId = 'biz-1',
    String name = 'Amina Saleh',
    String phone = '0712345678',
    int isDeleted = 0,
    String syncStatus = 'synced',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return CustomersTableCompanion.insert(
      id: id,
      businessId: businessId,
      name: name,
      phone: phone,
      createdAt: now,
      updatedAt: now,
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
    );
  }

  group('upsert / getById', () {
    test('inserts and retrieves a customer', () async {
      await dao.upsert(makeCustomer());
      final result = await dao.getById('cust-1');
      expect(result, isNotNull);
      expect(result!.name, 'Amina Saleh');
    });

    test('upsert overwrites existing customer on id conflict', () async {
      await dao.upsert(makeCustomer());
      await dao.upsert(makeCustomer(name: 'Amina Saleh Mkuu'));
      final result = await dao.getById('cust-1');
      expect(result!.name, 'Amina Saleh Mkuu');
    });
  });

  group('watchAll', () {
    test('returns customers for the given business only', () async {
      await dao.upsert(makeCustomer(id: 'c1'));
      await dao.upsert(makeCustomer(id: 'c2', businessId: 'biz-2'));

      final result = await dao.watchAll('biz-1').first;
      expect(result.length, 1);
      expect(result.first.id, 'c1');
    });

    test('excludes soft-deleted customers', () async {
      await dao.upsert(makeCustomer(id: 'c1'));
      await dao.upsert(makeCustomer(id: 'c2', isDeleted: 1));

      final result = await dao.watchAll('biz-1').first;
      expect(result.length, 1);
      expect(result.first.id, 'c1');
    });

    test('orders customers alphabetically by name', () async {
      await dao.upsert(makeCustomer(id: 'c1', name: 'Zuberi'));
      await dao.upsert(makeCustomer(id: 'c2', name: 'Amina'));

      final result = await dao.watchAll('biz-1').first;
      expect(result.first.name, 'Amina');
      expect(result.last.name, 'Zuberi');
    });
  });

  group('search', () {
    test('finds customers by partial name', () async {
      await dao.upsert(makeCustomer(id: 'c1'));
      await dao.upsert(makeCustomer(id: 'c2', name: 'Juma Bakari'));

      final result = await dao.search('biz-1', 'amina');
      expect(result.length, 1);
      expect(result.first.name, 'Amina Saleh');
    });

    test('finds customers by phone number', () async {
      await dao.upsert(makeCustomer(id: 'c1'));
      await dao.upsert(makeCustomer(id: 'c2', phone: '0754000000'));

      final result = await dao.search('biz-1', '0754');
      expect(result.length, 1);
      expect(result.first.phone, '0754000000');
    });

    test('returns all customers when query is empty', () async {
      await dao.upsert(makeCustomer(id: 'c1'));
      await dao.upsert(makeCustomer(id: 'c2', name: 'Zuberi'));

      final result = await dao.search('biz-1', '');
      expect(result.length, 2);
    });
  });

  group('softDelete', () {
    test('marks as deleted with pending_delete sync status', () async {
      await dao.upsert(makeCustomer());
      await dao.softDelete('cust-1');

      final result = await dao.getById('cust-1');
      expect(result!.isDeleted, 1);
      expect(result.syncStatus, 'pending_delete');
    });
  });

  group('updateBalance', () {
    test('updates the balance field', () async {
      await dao.upsert(makeCustomer());
      await dao.updateBalance('cust-1', 75000.0);

      final result = await dao.getById('cust-1');
      expect(result!.balance, 75000.0);
    });
  });

  group('markSynced', () {
    test('sets status to synced and stores serverUpdatedAt', () async {
      await dao.upsert(makeCustomer(syncStatus: 'pending_create'));
      await dao.markSynced('cust-1', serverUpdatedAt: 1234567890);

      final result = await dao.getById('cust-1');
      expect(result!.syncStatus, 'synced');
      expect(result.serverUpdatedAt, 1234567890);
    });
  });
}
