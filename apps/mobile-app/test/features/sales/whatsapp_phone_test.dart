import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/sales/data/sales_providers.dart';

void main() {
  group('normalizeWhatsAppPhone', () {
    test('converts local Tanzanian format to international digits', () {
      expect(normalizeWhatsAppPhone('0754123456'), '255754123456');
      expect(normalizeWhatsAppPhone('0754 123 456'), '255754123456');
      expect(normalizeWhatsAppPhone('0754-123-456'), '255754123456');
    });

    test('strips + and formatting from international numbers', () {
      expect(normalizeWhatsAppPhone('+255754123456'), '255754123456');
      expect(normalizeWhatsAppPhone('+255 754 123 456'), '255754123456');
      expect(normalizeWhatsAppPhone('255754123456'), '255754123456');
    });

    test('handles the 00 international dialing prefix', () {
      expect(normalizeWhatsAppPhone('00255754123456'), '255754123456');
    });

    test('returns empty for undialable input', () {
      expect(normalizeWhatsAppPhone(''), '');
      expect(normalizeWhatsAppPhone('n/a'), '');
      expect(normalizeWhatsAppPhone('12345'), '');
    });
  });
}
