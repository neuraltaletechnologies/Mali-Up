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

    if (canonicalPhone.startsWith('255') && canonicalPhone.length > 3) {
      final local = canonicalPhone.substring(3);
      variants.add(local);
      variants.add('0$local');
    }

    return variants.toList(growable: false);
  }

  static String authEmail(String phone) => '${canonical(phone)}@mali.up';
}
