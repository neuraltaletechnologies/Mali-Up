import 'package:flutter/foundation.dart';

/// Device features that exist on phones but not on the Windows desktop
/// build. Check these before showing UI that depends on them.
class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Camera barcode scanning (mobile_scanner). Not on Windows/Linux — there
  /// the scan screens take input from a USB/Bluetooth barcode scanner, which
  /// types the code like a keyboard and presses Enter.
  static bool get hasCameraScanner =>
      kIsWeb || _isMobile || defaultTargetPlatform == TargetPlatform.macOS;

  /// Reading the phone's address book (flutter_contacts).
  static bool get hasPhoneContacts => _isMobile;
}
