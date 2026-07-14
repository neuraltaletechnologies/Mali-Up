import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/sales/services/receipt_pdf_service.dart';

void main() {
  group('ReceiptPdfService', () {
    test('builds a valid PDF receipt from sale data', () async {
      final bytes = await ReceiptPdfService.build(
        sale: {
          'invoiceNumber': 'INV-202607-0012',
          'customerName': 'Asha Mushi',
          'customerPhone': '0754123456',
          'createdAt': DateTime(2026, 7, 14, 10, 30),
          'items': [
            {'name': 'Mchele', 'qty': 2, 'unitPrice': 2500, 'total': 5000},
          ],
          'subtotal': 5000,
          'amount': 5000,
          'amountPaid': 5000,
          'paymentMethod': 'cash',
        },
        businessName: 'Duka la Asha',
        printedBy: 'Asha',
        isSwahili: true,
      );

      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('creates a safe PDF filename', () {
      expect(
        ReceiptPdfService.filename('INV/2026 07 #12'),
        'receipt_INV_2026_07_12.pdf',
      );
      expect(ReceiptPdfService.filename('  '), 'receipt_sale.pdf');
    });
  });
}
