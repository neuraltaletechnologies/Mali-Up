import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/onboarding/domain/validators/onboarding_validator.dart';

void main() {
  group('OnboardingValidator', () {
    test('validatePhone accepts valid local and international numbers', () {
      expect(OnboardingValidator.validatePhone('0712345678'), isNull);
      expect(OnboardingValidator.validatePhone('+255712345678'), isNull);
      expect(OnboardingValidator.validatePhone('+254712345678'), isNull);
      expect(OnboardingValidator.validatePhone('+256772123456'), isNull);
      expect(OnboardingValidator.validatePhone('+2348031234567'), isNull);
      expect(OnboardingValidator.validatePhone('254712345678'), isNull);
    });

    test('validatePhone rejects empty and invalid numbers', () {
      expect(OnboardingValidator.validatePhone(''), isNotNull);
      expect(OnboardingValidator.validatePhone('123'), isNotNull);
      expect(OnboardingValidator.validatePhone('12345678901234567'), isNotNull);
    });

    test('validateInternationalPhone validates according to dial code', () {
      // Tanzania (+255)
      expect(
        OnboardingValidator.validateInternationalPhone('712345678', '+255'),
        isNull,
      );
      expect(
        OnboardingValidator.validateInternationalPhone('0712345678', '+255'),
        isNull,
      );
      expect(
        OnboardingValidator.validateInternationalPhone('112345678', '+255'),
        isNotNull,
      );

      // Kenya (+254)
      expect(
        OnboardingValidator.validateInternationalPhone('712345678', '+254'),
        isNull,
      );
      expect(
        OnboardingValidator.validateInternationalPhone('0712345678', '+254'),
        isNull,
      );

      // Uganda (+256)
      expect(
        OnboardingValidator.validateInternationalPhone('772123456', '+256'),
        isNull,
      );
    });

    test('normalisePhone handles local and international formats', () {
      expect(OnboardingValidator.normalisePhone('0712345678'), '+255712345678');
      expect(OnboardingValidator.normalisePhone('+254712345678'), '+254712345678');
      expect(OnboardingValidator.normalisePhone('254712345678'), '+254712345678');
      expect(OnboardingValidator.normalisePhone('00254712345678'), '+254712345678');
    });
  });
}
