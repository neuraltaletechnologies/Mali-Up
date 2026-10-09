/// Phone-number helpers used at authentication boundaries.
///
/// New records use digits-only international numbers (for example
/// `255784735111`). Lookup variants are retained for records written by older
/// app versions as `+255...`, `0784...`, or `784...`.
class PhoneNumberUtils {
  const PhoneNumberUtils._();

  static String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// Returns the canonical digits-only number used by Mali Up.
  ///
  /// A number without a country code is treated as Tanzanian because Tanzania
  /// is the app's default market. Numbers that already include a country code
  /// are preserved.
  static String canonical(String input) {
    var digits = digitsOnly(input);
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) return '255${digits.substring(1)}';
    if (digits.length == 9) return '255$digits';
    return digits;
  }

  static const List<String> _kAfricanCountryCodes = [
    // 3-digit African dial codes
    '255', '254', '256', '250', '257', '211', '251', '252', '253', '291',
    '265', '260', '263', '258', '261', '267', '264', '268', '266', '234',
    '233', '221', '225', '237', '243', '242', '244', '249', '218', '216',
    '213', '212', '222', '223', '226', '227', '235', '241', '230', '229',
    '228', '248', '269', '238', '240', '224', '245', '231', '232', '220',
    '236',
    // 2-digit dial codes
    '20', '27',
  ];

  /// Exact values that may exist in Firestore across schema generations.
  static List<String> lookupVariants(String input) {
    final raw = digitsOnly(input);
    final canonicalPhone = canonical(input);
    final variants = <String>{
      if (canonicalPhone.isNotEmpty) canonicalPhone,
      if (canonicalPhone.isNotEmpty) '+$canonicalPhone',
      if (raw.isNotEmpty) raw,
      if (raw.isNotEmpty) '+$raw',
    };

    for (final prefix in _kAfricanCountryCodes) {
      if (canonicalPhone.startsWith(prefix) && canonicalPhone.length > prefix.length + 5) {
        final local = canonicalPhone.substring(prefix.length);
        variants.add(local);
        variants.add('0$local');
        break;
      }
    }

    return variants.toList(growable: false);
  }

  static String authEmail(String phone) => '${canonical(phone)}@mali.up';
}
