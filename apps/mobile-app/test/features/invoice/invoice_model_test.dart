import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/invoice/domain/models/invoice.dart';

void main() {
  group('Invoice.fromFirestore', () {
    test(
      'parses a quick-sale document (amount/items keys, Timestamp dates)',
      () {
        final data = {
          'invoiceNumber': 'INV-202606-0001',
          'type': 'invoice',
          'status': 'partial',
          'customerName': 'John',
          'customerPhone': '+255700000001',
          'items': [
            {
              'name': 'Samsung A25',
              'qty': 2,
              'unitPrice': 250000,
              'total': 500000,
              'inventoryItemId': 'prod-1',
            },
          ],
          'subtotal': 500000,
          'discountAmount': 20000,
          'vatAmount': 86400,
          'amount': 566400,
          'totalAmount': 566400,
          'amountPaid': 200000,
          'paymentMethod': 'mpesa',
          'createdBy': 'staff-user-1',
          'dueDate': Timestamp.fromDate(DateTime(2026, 7)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 6, 12)),
        };

        final inv = Invoice.fromFirestore(data, 'abc');

        expect(inv.total, 566400);
        expect(inv.amountPaid, 200000);
        expect(inv.outstanding, 366400);
        expect(inv.tax, 86400);
        expect(inv.discountAmount, 20000);
        expect(inv.paymentMethod, 'mpesa');
        expect(inv.status, 'partial');
        expect(inv.createdBy, 'staff-user-1');
        expect(inv.toFirestore()['createdBy'], 'staff-user-1');
        expect(inv.dueDate, DateTime(2026, 7).toIso8601String());
        expect(inv.items, hasLength(1));
        expect(inv.items.first.name, 'Samsung A25');
        expect(inv.items.first.quantity, 2);
        expect(inv.items.first.id, 'prod-1');
      },
    );

    test('parses a full-invoice document (lineItems/totalAmount keys)', () {
      final data = {
        'invoiceNumber': 'INV-202606-0002',
        'type': 'quotation',
        'status': 'sent',
        'lineItems': [
          {
            'productId': 'prod-9',
            'productName': 'Cement Bag',
            'qty': 10,
            'unitPrice': 18000,
            'lineTotal': 180000,
          },
        ],
        'subtotal': 180000,
        'vatAmount': 0,
        'totalAmount': 180000,
        'amount': 180000,
        'invoiceDate': Timestamp.fromDate(DateTime(2026, 6, 10)),
      };

      final inv = Invoice.fromFirestore(data, 'def');

      expect(inv.type, 'quotation');
      expect(inv.total, 180000);
      expect(inv.date, DateTime(2026, 6, 10).toIso8601String());
      expect(inv.items.single.name, 'Cement Bag');
      expect(inv.items.single.id, 'prod-9');
      expect(inv.items.single.total, 180000);
    });

    test('tolerates missing/odd fields without crashing', () {
      final inv = Invoice.fromFirestore({'status': 'paid'}, 'x');
      expect(inv.total, 0);
      expect(inv.outstanding, 0);
      expect(inv.items, isEmpty);
      expect(inv.dueDate, '');
    });

    test('outstanding never goes negative on overpayment', () {
      final inv = Invoice.fromFirestore({
        'amount': 1000,
        'amountPaid': 1500,
        'status': 'paid',
      }, 'y');
      expect(inv.outstanding, 0);
    });
  });
}
