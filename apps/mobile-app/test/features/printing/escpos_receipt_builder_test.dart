import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/printing/domain/printer_settings.dart';
import 'package:mali_up/features/printing/services/escpos_receipt_builder.dart';
import 'package:mali_up/features/sales/services/receipt_data.dart';

/// Strips ESC/POS command sequences and returns the printed text lines.
List<String> _printedLines(Uint8List bytes) {
  final text = StringBuffer();
  var i = 0;
  while (i < bytes.length) {
    final b = bytes[i];
    if (b == 0x1B) {
      // ESC @ is 2 bytes; ESC a/E/d n are 3.
      i += bytes[i + 1] == 0x40 ? 2 : 3;
    } else if (b == 0x1D) {
      // GS ! n is 3 bytes; GS V B n is 4.
      i += bytes[i + 1] == 0x56 ? 4 : 3;
    } else {
      text.writeCharCode(b);
      i++;
    }
  }
  final lines = text.toString().split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  return lines;
}

Map<String, dynamic> _sale() => {
  'invoiceNumber': 'INV-0042',
  'type': 'sale',
  'customerName': 'Mama Neema Duka la Rejareja Kariakoo',
  'customerPhone': '0712 345 678',
  'date': DateTime(2026, 11, 14, 9, 5),
  'items': [
    {'name': 'Sukari 1kg', 'qty': 2, 'unitPrice': 3500, 'lineTotal': 7000},
    {
      'name': 'Mafuta ya kupikia ya alizeti lita tano (5L) – Korie',
      'qty': 12.5,
      'unitPrice': 1250000,
      'lineTotal': 15625000,
    },
  ],
  'subtotal': 15632000,
  'totalAmount': 15632000,
  'amountPaid': 10000000,
  'paymentMethod': 'mpesa',
  'mpesaRef': 'QK7H2X9',
  'notes': 'Asante, karibu tena 😀',
};

void main() {
  group('EscPosReceiptBuilder', () {
    for (final width in ReceiptPaperWidth.values) {
      test('${width.mm}mm: no printed line is wider than the paper', () {
        final bytes = EscPosReceiptBuilder.build(
          receipt: ReceiptData.fromSale(_sale(), isSwahili: true),
          businessName: 'Duka la Mfano na Wenzake Limited',
          printedBy: 'Asha',
          paperWidth: width,
          businessAddress: 'Ilala, Dar es Salaam',
          businessPhone: '0755 000 111',
        );
        final lines = _printedLines(bytes);
        expect(lines, isNotEmpty);
        for (final line in lines) {
          expect(
            line.length,
            lessThanOrEqualTo(width.charsPerLine),
            reason: '"$line"',
          );
        }
      });
    }

    test('prints the same totals as the PDF data, in Swahili', () {
      final receipt = ReceiptData.fromSale(_sale(), isSwahili: true);
      final text = _printedLines(
        EscPosReceiptBuilder.build(
          receipt: receipt,
          businessName: 'Duka',
          printedBy: 'Asha',
          paperWidth: ReceiptPaperWidth.mm80,
        ),
      ).join('\n');

      expect(text, contains('RISITI YA MAUZO'));
      expect(text, contains('Namba INV-0042'));
      expect(text, contains('JUMLA KUU'));
      expect(text, contains('TZS 15,632,000'));
      expect(text, contains('Imelipwa'));
      expect(text, contains('TZS 10,000,000'));
      expect(text, contains('Baki'));
      expect(text, contains('TZS 5,632,000'));
      expect(text, contains('Malipo: M-Pesa'));
      expect(text, contains('Kumb: QK7H2X9'));
      expect(text, contains('Imerekodiwa na Asha'));
    });

    test('debt receipts and quotations get their own titles', () {
      String titleFor(String type) => _printedLines(
        EscPosReceiptBuilder.build(
          receipt: ReceiptData.fromSale({
            ..._sale(),
            'type': type,
          }, isSwahili: false),
          businessName: 'Shop',
          printedBy: 'User',
          paperWidth: ReceiptPaperWidth.mm58,
        ),
      ).join('\n');

      expect(titleFor('debt'), contains('DEBT RECEIPT'));
      final quotation = titleFor('quotation');
      expect(quotation, contains('QUOTATION'));
      // A quotation isn't paid yet — no Paid/Balance lines.
      expect(quotation, isNot(contains('Paid')));
    });

    test('a sale with no line items still prints one item line', () {
      final text = _printedLines(
        EscPosReceiptBuilder.build(
          receipt: ReceiptData.fromSale({
            'invoiceNumber': 'Q-1',
            'totalAmount': 5000,
            'amountPaid': 5000,
          }, isSwahili: true),
          businessName: 'Duka',
          printedBy: 'Asha',
          paperWidth: ReceiptPaperWidth.mm58,
        ),
      ).join('\n');
      expect(text, contains('Bidhaa ya mauzo'));
      expect(text, contains('1 x 5,000'));
    });

    test('ends with feed + cut', () {
      final bytes = EscPosReceiptBuilder.testPage(
        paperWidth: ReceiptPaperWidth.mm58,
        isSwahili: true,
      );
      expect(bytes.sublist(0, 2), [0x1B, 0x40]);
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00]);
    });
  });

  group('EscPosWriter', () {
    test('folds non-ASCII text to printable ASCII', () {
      expect(EscPosWriter.fold('Café – “bei” × 2 • 😀'), 'Cafe - "bei" x 2 * ?');
    });

    test('wraps on word boundaries and splits over-long words', () {
      expect(EscPosWriter.wrap('Sukari ya miwa kilo moja', 12), [
        'Sukari ya',
        'miwa kilo',
        'moja',
      ]);
      expect(EscPosWriter.wrap('ABCDEFGHIJKLMNOP', 6), ['ABCDEF', 'GHIJKL', 'MNOP']);
    });

    test('columns fall back to two lines when they do not fit', () {
      final w = EscPosWriter(16)
        ..columns('Jumla', 'TZS 1,000')
        ..columns('Jumla ndogo sana', 'TZS 1,000,000');
      expect(_printedLines(w.bytes), [
        'Jumla  TZS 1,000',
        'Jumla ndogo sana',
        '   TZS 1,000,000',
      ]);
    });
  });
}
