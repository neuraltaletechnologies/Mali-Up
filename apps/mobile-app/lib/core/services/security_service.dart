import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const _pinKey = 'security_pin_hash';
  static const _lockEnabledKey = 'app_lock_enabled';
  static const _biometricEnabledKey = 'biometric_enabled';

  static final ValueNotifier<bool> lockEnabledNotifier = ValueNotifier(false);
  static final ValueNotifier<bool> biometricEnabledNotifier =
      ValueNotifier(false);
  static final ValueNotifier<bool> isLockedNotifier = ValueNotifier(false);

  static final _auth = LocalAuthentication();

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    lockEnabledNotifier.value = prefs.getBool(_lockEnabledKey) ?? false;
    biometricEnabledNotifier.value =
        prefs.getBool(_biometricEnabledKey) ?? false;
    if (lockEnabledNotifier.value) {
      isLockedNotifier.value = true;
    }
  }

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hashPin(pin));
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  static Future<void> enableAppLock(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hashPin(pin));
    await prefs.setBool(_lockEnabledKey, true);
    lockEnabledNotifier.value = true;
    isLockedNotifier.value = false;
  }

  static Future<void> disableAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.setBool(_biometricEnabledKey, false);
    lockEnabledNotifier.value = false;
    biometricEnabledNotifier.value = false;
    isLockedNotifier.value = false;
  }

  static Future<void> enableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
    biometricEnabledNotifier.value = true;
  }

  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    biometricEnabledNotifier.value = false;
  }

  static Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access Mali Up',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static void lockApp() {
    if (lockEnabledNotifier.value) {
      isLockedNotifier.value = true;
    }
  }

  static void unlockApp() {
    isLockedNotifier.value = false;
  }

  // XOR-based obfuscation with a fixed salt — keeps the PIN out of plain text
  // in SharedPreferences without requiring a crypto package.
  static String _hashPin(String pin) {
    const salt = 'MaliUp@Security#2026';
    final saltBytes = utf8.encode(salt);
    final pinBytes = utf8.encode(pin);
    final xored = List<int>.generate(
      pinBytes.length,
      (i) => pinBytes[i] ^ saltBytes[i % saltBytes.length],
    );
    return base64Url.encode(xored);
  }
}
