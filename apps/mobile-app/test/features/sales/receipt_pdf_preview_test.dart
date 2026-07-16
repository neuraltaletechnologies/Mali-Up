import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/sales/services/receipt_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes a receipt preview for visual QA', () async {
    final bytes = await ReceiptPdfService.build(
      sale: {
        'invoiceNumber': 'INV-202607-A1B2C3D4',
        'customerName': 'Asha Mushi',
        'customerPhone': '0754 123 456',
        'createdAt': DateTime(2026, 7, 17, 10, 30),
        'items': [
          {
            'name': 'Mchele wa Mbeya - kilo',
            'qty': 2,
            'unitPrice': 2500,
            'total': 5000,
          },
          {
            'name': 'Mafuta ya kupikia',
            'qty': 1,
            'unitPrice': 6500,
            'total': 6500,
          },
        ],
        'subtotal': 11500,
        'amount': 11500,
        'amountPaid': 7000,
        'paymentMethod': 'mpesa',
        'mpesaRef': 'QGH72KPL9Z',
        'notes': 'Asante kwa kununua nasi.',
      },
      businessName: 'Duka la Asha',
      printedBy: 'Neema Joseph',
      isSwahili: true,
      businessPhone: '+255 754 000 111',
      businessEmail: 'mauzo@dukalaasha.co.tz',
      businessAddress: 'Kinondoni, Dar es Salaam',
    );

    final directory = Directory('../../tmp/pdfs');
    await directory.create(recursive: true);
    await File('${directory.path}/receipt_preview.pdf').writeAsBytes(bytes);
  });
}
