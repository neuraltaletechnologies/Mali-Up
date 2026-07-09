import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pin_attempt_throttle.dart';

class SecurityService {
  static const _pinKey = 'security_pin'; // Changed from 'security_pin_hash'
  static const _lockEnabledKey = 'app_lock_enabled';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _throttle = PinAttemptThrottle('app_lock_pin');

  static final ValueNotifier<bool> lockEnabledNotifier = ValueNotifier(false);
  static final ValueNotifier<bool> biometricEnabledNotifier =
      ValueNotifier(false);
  static final ValueNotifier<bool> isLockedNotifier = ValueNotifier(false);

  static final _auth = LocalAuthentication();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

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
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null;
  }

  static Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  /// Returns how long the caller must wait before the next PIN attempt is
  /// allowed, or null if not currently locked out.
  static Future<Duration?> pinLockoutRemaining() => _throttle.lockoutRemaining();

  static Future<bool> verifyPin(String pin) async {
    if (await _throttle.lockoutRemaining() != null) return false;
    final stored = await _secureStorage.read(key: _pinKey);
    final matches = stored != null && stored == pin;
    if (matches) {
      await _throttle.recordSuccess();
    } else {
      await _throttle.recordFailure();
    }
    return matches;
  }

  static Future<void> enableAppLock(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: _pinKey, value: pin);
    await prefs.setBool(_lockEnabledKey, true);
    lockEnabledNotifier.value = true;
    isLockedNotifier.value = false;
  }

  static Future<void> disableAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _pinKey);
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
}
