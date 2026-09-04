import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/constants/countries.dart';

void main() {
  test('Tanzania is pinned first', () {
    expect(kCountries.first.code, 'TZ');
  });

  test('every country has a unique 2-letter uppercase code', () {
    final seen = <String>{};
    for (final c in kCountries) {
      expect(c.code.length, 2, reason: '${c.name} has a bad code "${c.code}"');
      expect(c.code, c.code.toUpperCase());
      expect(seen.add(c.code), isTrue, reason: 'duplicate code ${c.code}');
      expect(c.name.trim(), isNotEmpty);
    }
  });

  test('flag is derived from the code as two regional-indicator symbols', () {
    // 🇹🇿 = U+1F1F9 U+1F1FF
    expect(countryByCode('TZ')!.flag.runes.toList(), [0x1F1F9, 0x1F1FF]);
    expect(countryByCode('ke')!.flag.runes.toList(), [0x1F1F0, 0x1F1EA]);
  });

  test('countryByCode is case-insensitive and null-safe', () {
    expect(countryByCode('ng')?.name, 'Nigeria');
    expect(countryByCode('ZZ'), isNull);
    expect(countryByCode(''), isNull);
    expect(countryByCode(null), isNull);
  });

  test('countryNameOrCode falls back to the raw code', () {
    expect(countryNameOrCode('TZ'), 'Tanzania');
    expect(countryNameOrCode('ZZ'), 'ZZ');
  });
}
