import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/database/app_database.dart';
import 'package:mali_up/core/database/daos/invoice_dao.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late InvoiceDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = db.invoiceDao;
  });

  tearDown(() async {
    await db.close();
  });

  // ─── Helpers ────────────────────────────────────────────────────────────────

  InvoicesTableCompanion invoice({
    String id = 'inv-1',
    String businessId = 'biz-1',
    String customerId = 'cust-1',
    String status = 'pending',
    double total = 100.0,
    String syncStatus = 'synced',
    int isDeleted = 0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return InvoicesTableCompanion.insert(
      id: id,
      businessId: businessId,
      customerId: customerId,
      customerName: 'Juma Mwangi',
      invoiceNumber: 'INV-001',
      date: '2025-01-15',
      dueDate: '2025-02-15',
      status: Value(status),
      subtotal: 84.75,
      tax: 15.25,
      total: total,
      createdAt: now,
      updatedAt: now,
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
    );
  }

  // ─── Tests ──────────────────────────────────────────────────────────────────

  group('upsert / getById', () {
    test('inserts a new invoice and retrieves it by id', () async {
      await dao.upsert(invoice());

      final result = await dao.getById('inv-1');
      expect(result, isNotNull);
      expect(result!.invoiceNumber, 'INV-001');
      expect(result.total, 100.0);
    });

    test('upsert updates existing invoice on id conflict', () async {
      await dao.upsert(invoice());
      await dao.upsert(invoice(total: 250.0));

      final result = await dao.getById('inv-1');
      expect(result!.total, 250.0);
    });

    test('getById returns null for unknown id', () async {
      final result = await dao.getById('does-not-exist');
      expect(result, isNull);
    });
  });

  group('watchAll', () {
    test('excludes soft-deleted invoices', () async {
      await dao.upsert(invoice());
      await dao.upsert(invoice(id: 'inv-2', isDeleted: 1));

      final stream = dao.watchAll('biz-1');
      final result = await stream.first;

      expect(result.length, 1);
      expect(result.first.id, 'inv-1');
    });

    test('excludes invoices from other businesses', () async {
      await dao.upsert(invoice());
      await dao.upsert(invoice(id: 'inv-2', businessId: 'biz-2'));

      final result = await dao.watchAll('biz-1').first;
      expect(result.length, 1);
      expect(result.first.businessId, 'biz-1');
    });
  });

  group('watchByStatus', () {
    test('returns only invoices with matching status', () async {
      await dao.upsert(invoice(status: 'paid'));
      await dao.upsert(invoice(id: 'inv-2'));
      await dao.upsert(invoice(id: 'inv-3'));

      final result = await dao.watchByStatus('biz-1', 'pending').first;
      expect(result.length, 2);
      expect(result.every((i) => i.status == 'pending'), isTrue);
    });
  });

  group('getTotalOutstanding', () {
    test('sums total of all pending invoices', () async {
      await dao.upsert(invoice());
      await dao.upsert(invoice(id: 'inv-2', total: 250));
      await dao.upsert(invoice(id: 'inv-3', status: 'paid', total: 400));

      final outstanding = await dao.getTotalOutstanding('biz-1');
      expect(outstanding, 350.0);
    });

    test('returns 0.0 when no pending invoices exist', () async {
      final outstanding = await dao.getTotalOutstanding('biz-1');
      expect(outstanding, 0.0);
    });
  });

  group('getMonthlySales', () {
    test('groups invoices by YYYY-MM and sums totals', () async {
      await dao.upsert(
        invoice()
            .copyWith(date: const Value('2025-01-10')),
      );
      await dao.upsert(
        invoice(id: 'inv-2', total: 200)
            .copyWith(date: const Value('2025-01-25')),
      );
      await dao.upsert(
        invoice(id: 'inv-3', total: 500)
            .copyWith(date: const Value('2025-02-05')),
      );

      final result = await dao.getMonthlySales('biz-1', 2025);
      expect(result['2025-01'], 300.0);
      expect(result['2025-02'], 500.0);
    });
  });

  group('softDelete', () {
    test('marks invoice as deleted with pending_delete sync status', () async {
      await dao.upsert(invoice());
      await dao.softDelete('inv-1');

      final result = await dao.getById('inv-1');
      expect(result!.isDeleted, 1);
      expect(result.syncStatus, 'pending_delete');
    });

    test('soft-deleted invoice is excluded from watchAll', () async {
      await dao.upsert(invoice());
      await dao.softDelete('inv-1');

      final result = await dao.watchAll('biz-1').first;
      expect(result, isEmpty);
    });
  });

  group('markSynced', () {
    test('sets syncStatus to synced and records serverUpdatedAt', () async {
      await dao.upsert(
        invoice(syncStatus: 'pending_create'),
      );

      await dao.markSynced('inv-1', serverUpdatedAt: 9999999);

      final result = await dao.getById('inv-1');
      expect(result!.syncStatus, 'synced');
      expect(result.serverUpdatedAt, 9999999);
    });
  });

  group('markConflict', () {
    test('sets syncStatus to conflict', () async {
      await dao.upsert(invoice(syncStatus: 'pending_update'));
      await dao.markConflict('inv-1');

      final result = await dao.getById('inv-1');
      expect(result!.syncStatus, 'conflict');
    });
  });

  group('hardDelete', () {
    test('removes invoice and its items from the database', () async {
      await dao.upsert(invoice());
      await dao.upsertItem(InvoiceItemsTableCompanion.insert(
        id: 'item-1',
        invoiceId: 'inv-1',
        name: 'Maziwa',
        quantity: 2,
        unitPrice: 50,
        total: 100,
      ));

      await dao.hardDelete('inv-1');

      expect(await dao.getById('inv-1'), isNull);
      expect(await dao.getItemsForInvoice('inv-1'), isEmpty);
    });
  });

  group('getByCustomer', () {
    test('returns all invoices for a given customer', () async {
      await dao.upsert(invoice(customerId: 'cust-A'));
      await dao.upsert(invoice(id: 'inv-2', customerId: 'cust-A'));
      await dao.upsert(invoice(id: 'inv-3', customerId: 'cust-B'));

      final result = await dao.getByCustomer('biz-1', 'cust-A');
      expect(result.length, 2);
      expect(result.every((i) => i.customerId == 'cust-A'), isTrue);
    });
  });

  group('getLastServiceBilling', () {
    Future<void> addLine(
      String invoiceId,
      String productId, {
      double quantity = 1,
    }) => dao.upsertItem(
      InvoiceItemsTableCompanion.insert(
        id: '$invoiceId-$productId',
        invoiceId: invoiceId,
        name: 'Water',
        quantity: quantity,
        unitPrice: 5000,
        total: 5000 * quantity,
        productId: Value(productId),
      ),
    );

    test('returns null when the customer was never billed for this service',
        () async {
      await dao.upsert(invoice(customerId: 'cust-A'));
      await addLine('inv-1', 'prod-water');

      final result =
          await dao.getLastServiceBilling('biz-1', 'cust-A', 'prod-electric');
      expect(result, isNull);
    });

    test('picks the most recent invoice line for that customer + product',
        () async {
      await dao.upsert(
        invoice(customerId: 'cust-A').copyWith(date: const Value('2026-04-01')),
      );
      await addLine('inv-1', 'prod-water');
      await dao.upsert(
        invoice(id: 'inv-2', customerId: 'cust-A')
            .copyWith(date: const Value('2026-06-01')),
      );
      await addLine('inv-2', 'prod-water', quantity: 2);

      final result =
          await dao.getLastServiceBilling('biz-1', 'cust-A', 'prod-water');
      expect(result, isNotNull);
      expect(result!.date, '2026-06-01');
      expect(result.quantity, 2);
    });

    test('ignores other customers, other products and soft-deleted invoices',
        () async {
      await dao.upsert(invoice(customerId: 'cust-B'));
      await addLine('inv-1', 'prod-water');
      await dao.upsert(invoice(id: 'inv-2', customerId: 'cust-A'));
      await addLine('inv-2', 'prod-electric');
      await dao.upsert(invoice(id: 'inv-3', customerId: 'cust-A'));
      await addLine('inv-3', 'prod-water');
      await dao.softDelete('inv-3');

      final result =
          await dao.getLastServiceBilling('biz-1', 'cust-A', 'prod-water');
      expect(result, isNull);
    });
  });
}
