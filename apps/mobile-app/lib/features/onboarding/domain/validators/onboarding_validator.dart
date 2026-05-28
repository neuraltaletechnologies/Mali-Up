import '../../../../core/services/localization_service.dart';

/// Pure-static validation for every onboarding form field.
///
/// Every method returns `null` when valid, or a localised error string.
/// Pass [isSwahili] from the active [AppLanguage] in [OnboardingState].
///
/// Usage:
/// ```dart
/// final error = OnboardingValidator.validatePhone(state.phone, isSwahili: state.isSwahili);
/// if (error != null) { /* show error */ }
/// ```
abstract final class OnboardingValidator {
  // ─── PHONE ────────────────────────────────────────────────────────────────

  /// Accepts any of:  +255XXXXXXXXX  |  07XXXXXXXX  |  06XXXXXXXX
  /// Strips spaces, dashes, and parentheses before matching.
  static String? validatePhone(String phone, {bool isSwahili = false}) {
    final cleaned = _strip(phone);
    if (cleaned.isEmpty) {
      return _t(isSwahili,
          en: 'Phone number is required.',
          sw: 'Namba ya simu inahitajika.');
    }
    // Must be a valid Tanzanian mobile number.
    final ok = RegExp(r'^(\+255|0)(6|7)\d{8}$').hasMatch(cleaned);
    if (!ok) {
      return _t(isSwahili,
          en: 'Enter a valid Tanzania number (+255 or 07/06 followed by 8 digits).',
          sw: 'Ingiza namba sahihi ya Tanzania (+255 au 07/06 ikifuatiwa na tarakimu 8).');
    }
    return null;
  }

  /// Validates a local number against its country dial code.
  /// Tanzania (+255): must be 9 digits starting with 6 or 7 (leading 0 stripped).
  /// All others: 7–15 digits after stripping leading zeros.
  static String? validateInternationalPhone(
    String localNumber,
    String dialCode, {
    bool isSwahili = false,
  }) {
    final cleaned = _strip(localNumber);
    if (cleaned.isEmpty) {
      return _t(isSwahili,
          en: 'Phone number is required.',
          sw: 'Namba ya simu inahitajika.');
    }
    final stripped = cleaned.replaceFirst(RegExp(r'^0+'), '');
    if (dialCode == '+255') {
      if (!RegExp(r'^[67]\d{8}$').hasMatch(stripped)) {
        return _t(isSwahili,
            en: 'Enter a valid Tanzania mobile number (e.g. 712 345 678).',
            sw: 'Ingiza namba sahihi ya simu ya Tanzania (mfano 712 345 678).');
      }
    } else {
      if (stripped.length < 7 || stripped.length > 15) {
        return _t(isSwahili,
            en: 'Enter a valid phone number.',
            sw: 'Ingiza namba sahihi ya simu.');
      }
    }
    return null;
  }

  /// Converts any local format to E.164 (+255XXXXXXXXX).
  static String normalisePhone(String phone) {
    final cleaned = _strip(phone);
    if (cleaned.startsWith('0')) return '+255${cleaned.substring(1)}';
    if (cleaned.startsWith('255') && !cleaned.startsWith('+')) {
      return '+$cleaned';
    }
    return cleaned; // already +255...
  }

  // ─── NAME ─────────────────────────────────────────────────────────────────

  /// Validates first name, last name, or any personal name field.
  /// Rules: not empty · min 2 chars · no digits.
  static String? validateName(String name, {bool isSwahili = false}) {
    final t = name.trim();
    if (t.isEmpty) {
      return _t(isSwahili, en: 'Name is required.', sw: 'Jina linahitajika.');
    }
    if (t.length < 2) {
      return _t(isSwahili,
          en: 'Name must be at least 2 characters.',
          sw: 'Jina lazima liwe na angalau herufi 2.');
    }
    if (RegExp(r'\d').hasMatch(t)) {
      return _t(isSwahili,
          en: 'Name must not contain numbers.',
          sw: 'Jina halitakiwi kuwa na nambari.');
    }
    return null;
  }

  // ─── PASSWORD ─────────────────────────────────────────────────────────────

  /// Rules: min 8 chars · at least 1 digit.
  static String? validatePassword(String password, {bool isSwahili = false}) {
    if (password.length < 8) {
      return _t(isSwahili,
          en: 'Password must be at least 8 characters.',
          sw: 'Nywila lazima iwe na angalau herufi 8.');
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return _t(isSwahili,
          en: 'Password must contain at least one number.',
          sw: 'Nywila lazima iwe na angalau nambari moja.');
    }
    return null;
  }

  // ─── PIN ──────────────────────────────────────────────────────────────────

  /// Rules: exactly 4 digits, no letters or symbols.
  static String? validatePin(String pin, {bool isSwahili = false}) {
    if (pin.isEmpty || pin.length != 4) {
      return _t(isSwahili,
          en: 'PIN must be exactly 4 digits.',
          sw: 'PIN lazima iwe tarakimu 4 tu.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      return _t(isSwahili,
          en: 'PIN must contain digits only.',
          sw: 'PIN lazima iwe nambari tu, bila herufi.');
    }
    return null;
  }

  // ─── BUSINESS NAME ────────────────────────────────────────────────────────

  /// Rules: not empty · min 2 chars.
  static String? validateBusinessName(String name, {bool isSwahili = false}) {
    final t = name.trim();
    if (t.isEmpty) {
      return _t(isSwahili,
          en: 'Business name is required.',
          sw: 'Jina la biashara linahitajika.');
    }
    if (t.length < 2) {
      return _t(isSwahili,
          en: 'Business name must be at least 2 characters.',
          sw: 'Jina la biashara lazima liwe na angalau herufi 2.');
    }
    return null;
  }

  // ─── OTP ──────────────────────────────────────────────────────────────────

  /// Validates a 6-digit SMS OTP code.
  static String? validateOtp(String otp, {bool isSwahili = false}) {
    if (otp.length != 6) {
      return _t(isSwahili,
          en: 'Enter the 6-digit code sent to your phone.',
          sw: 'Ingiza msimbo wa tarakimu 6 uliotumwa kwa simu yako.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return _t(isSwahili,
          en: 'Verification code must contain digits only.',
          sw: 'Msimbo wa uhakiki lazima uwe nambari tu.');
    }
    return null;
  }

  // ─── EMAIL ──────────────────────────────────────────────────────────────

  /// Validates an email address. If [optional] is true, empty values are
  /// accepted (returns null). Otherwise an empty value returns an error.
  static String? validateEmail(String email,
      {bool isSwahili = false, bool optional = true}) {
    final t = email.trim();
    if (t.isEmpty) {
      if (optional) return null;
      return _t(isSwahili,
          en: 'Email is required.', sw: 'Barua pepe inahitajika.');
    }
    // Simple but effective email pattern
    final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(t);
    if (!ok) {
      return _t(isSwahili,
          en: 'Enter a valid email address.',
          sw: 'Ingiza anwani sahihi ya barua pepe.');
    }
    return null;
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  static String _strip(String input) =>
      input.replaceAll(RegExp(r'[\s\-\(\)]'), '');

  static String _t(bool isSwahili, {required String en, required String sw}) =>
      isSwahili ? sw : en;
}
