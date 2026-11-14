import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Why a Bluetooth print could not go out.
enum BluetoothPrinterError {
  /// No Bluetooth hardware, or not Android.
  unsupported,

  /// Bluetooth is switched off.
  off,

  /// BLUETOOTH_CONNECT was denied (Android 12+).
  permission,

  /// The saved printer is no longer paired.
  notFound,

  /// Printer off, out of range, or busy with another phone.
  connectFailed,
}

class BluetoothPrinterException implements Exception {
  final BluetoothPrinterError error;
  final String? detail;

  const BluetoothPrinterException(this.error, [this.detail]);

  static BluetoothPrinterError _fromCode(String code) => switch (code) {
    'off' => BluetoothPrinterError.off,
    'permission' => BluetoothPrinterError.permission,
    'unsupported' => BluetoothPrinterError.unsupported,
    'not_found' => BluetoothPrinterError.notFound,
    _ => BluetoothPrinterError.connectFailed,
  };

  @override
  String toString() => 'BluetoothPrinterException($error, $detail)';
}

class BluetoothPrinterDevice {
  final String name;
  final String address;

  /// The device reports the "imaging" Bluetooth class — sorted first.
  final bool isPrinter;

  const BluetoothPrinterDevice({
    required this.name,
    required this.address,
    required this.isPrinter,
  });
}

/// Dart side of `BluetoothPrinterHandler.kt` — classic Bluetooth (SPP)
/// ESC/POS printing to an already-paired printer. Android only; everywhere
/// else [isAvailable] is false and printing uses the system dialog.
abstract final class BluetoothPrinterChannel {
  static const _channel = MethodChannel('com.neuraltale.maliup/bt_printer');

  static bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Checks Bluetooth state, asking for BLUETOOTH_CONNECT if it hasn't been
  /// granted yet. Throws [BluetoothPrinterException] when not ready.
  static Future<void> ensureReady() async {
    if (!isAvailable) {
      throw const BluetoothPrinterException(BluetoothPrinterError.unsupported);
    }
    var status = await _status();
    if (status == 'permission') {
      await Permission.bluetoothConnect.request();
      status = await _status();
    }
    if (status != 'ready') {
      throw BluetoothPrinterException(BluetoothPrinterException._fromCode(status));
    }
  }

  static Future<String> _status() async {
    try {
      return await _channel.invokeMethod<String>('status') ?? 'unsupported';
    } on MissingPluginException {
      return 'unsupported';
    }
  }

  /// Paired devices, likely printers first.
  static Future<List<BluetoothPrinterDevice>> bondedDevices() async {
    await ensureReady();
    try {
      final raw = await _channel.invokeListMethod<Map>('bondedDevices') ?? [];
      final devices = [
        for (final d in raw)
          BluetoothPrinterDevice(
            name: (d['name'] ?? d['address'] ?? '').toString(),
            address: (d['address'] ?? '').toString(),
            isPrinter: d['isPrinter'] == true,
          ),
      ]..sort((a, b) {
          if (a.isPrinter != b.isPrinter) return a.isPrinter ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return devices;
    } on PlatformException catch (e) {
      throw BluetoothPrinterException(
        BluetoothPrinterException._fromCode(e.code),
        e.message,
      );
    }
  }

  /// Sends raw ESC/POS [bytes]. Completes once the printer has received
  /// them (opens and closes the connection per call).
  static Future<void> printBytes(String address, Uint8List bytes) async {
    await ensureReady();
    try {
      await _channel.invokeMethod<bool>('print', {
        'address': address,
        'bytes': bytes,
      });
    } on PlatformException catch (e) {
      throw BluetoothPrinterException(
        BluetoothPrinterException._fromCode(e.code),
        e.message,
      );
    }
  }
}
