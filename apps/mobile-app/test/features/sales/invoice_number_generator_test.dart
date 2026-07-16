import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/sales/services/invoice_number_generator.dart';

void main() {
  group('InvoiceNumberGenerator', () {
    test('creates stable invoice and quotation formats', () {
      final date = DateTime(2026, 7, 17);

      expect(
        InvoiceNumberGenerator.create(
          now: date,
          uniqueId: '12345678-abcd-ef00',
        ),
        'INV-202607-12345678',
      );
      expect(
        InvoiceNumberGenerator.create(
          isQuotation: true,
          now: date,
          uniqueId: 'abcdef12-3456-7890',
        ),
        'QUO-202607-ABCDEF12',
      );
    });

    test(
      'different identifiers cannot produce the old time-based duplicate',
      () {
        final date = DateTime(2026, 7, 17, 10, 30);
        final first = InvoiceNumberGenerator.create(
          now: date,
          uniqueId: 'aaaaaaaa-1111-2222',
        );
        final second = InvoiceNumberGenerator.create(
          now: date,
          uniqueId: 'bbbbbbbb-1111-2222',
        );

        expect(first, isNot(second));
      },
    );
  });
}
