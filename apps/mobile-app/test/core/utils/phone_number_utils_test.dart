import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/utils/phone_number_utils.dart';

void main() {
  group('PhoneNumberUtils', () {
    test('canonicalizes Tanzanian local formats', () {
      expect(PhoneNumberUtils.canonical('0784 735 111'), '255784735111');
      expect(PhoneNumberUtils.canonical('784735111'), '255784735111');
      expect(PhoneNumberUtils.canonical('+255 784 735 111'), '255784735111');
    });

    test('preserves an existing non-Tanzanian country code', () {
      expect(PhoneNumberUtils.canonical('+254712345678'), '254712345678');
    });

    test('returns legacy Firestore lookup variants', () {
      expect(
        PhoneNumberUtils.lookupVariants('0784735111'),
        containsAll(<String>[
          '255784735111',
          '+255784735111',
          '0784735111',
          '784735111',
        ]),
      );
    });

    test('returns legacy Firestore lookup variants for international numbers', () {
      expect(
        PhoneNumberUtils.lookupVariants('+254712345678'),
        containsAll(<String>[
          '254712345678',
          '+254712345678',
          '0712345678',
          '712345678',
        ]),
      );
      expect(
        PhoneNumberUtils.lookupVariants('+256772123456'),
        containsAll(<String>[
          '256772123456',
          '+256772123456',
          '0772123456',
          '772123456',
        ]),
      );
    });

    test('derives auth email from the canonical phone', () {
      expect(PhoneNumberUtils.authEmail('0784735111'), '255784735111@mali.up');
      expect(PhoneNumberUtils.authEmail('+254712345678'), '254712345678@mali.up');
    });
  });
}
