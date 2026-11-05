import 'package:flutter/foundation.dart';
import 'package:smart_auth/smart_auth.dart';

/// Reads a one-time code from the incoming SMS so the user doesn't have to
/// type it — Android only.
///
/// Uses Android's SMS User Consent API: when the code arrives, the system
/// asks "Allow Mali Up to read this message?" and one tap fills it in. The
/// silent SMS Retriever API isn't an option because it needs an app hash in
/// the message text, and Beem's OTP API writes that text itself.
///
/// iOS needs nothing here — a field with `AutofillHints.oneTimeCode` gets
/// the code suggested above the keyboard. Elsewhere (web, Windows) this is a
/// no-op and the user types the code as before.
class SmsCodeAutofill {
  SmsCodeAutofill._();

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Starts listening for the next SMS (Android keeps the listener for up to
  /// 5 minutes) and returns the [digits]-long code in it, or null when
  /// unsupported, declined, timed out or no code was found. Call it right
  /// before the code is requested so the SMS isn't missed.
  static Future<String?> listen({int digits = 6}) async {
    if (!isSupported) return null;
    try {
      // Only one consent listener can be active — drop a stale one first.
      await SmartAuth.instance.removeUserConsentApiListener();
      final res = await SmartAuth.instance.getSmsWithUserConsentApi(
        matcher: '(?<!\\d)\\d{$digits}(?!\\d)',
      );
      final code = res.data?.code;
      return (code != null && code.length == digits) ? code : null;
    } catch (_) {
      return null;
    }
  }

  /// Stops a pending [listen] (e.g. the screen closed first).
  static Future<void> cancel() async {
    if (!isSupported) return;
    try {
      await SmartAuth.instance.removeUserConsentApiListener();
    } catch (_) {}
  }
}
