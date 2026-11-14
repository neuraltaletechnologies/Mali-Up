import 'package:shared_preferences/shared_preferences.dart';

import '../domain/printer_settings.dart';

/// Persists [PrinterSettings] in SharedPreferences (device-local, offline).
abstract final class PrinterSettingsStore {
  static const _kPaperWidth = 'receipt_printer.paper_width_mm';
  static const _kConnection = 'receipt_printer.connection';
  static const _kBtAddress = 'receipt_printer.bt_address';
  static const _kBtName = 'receipt_printer.bt_name';

  static Future<PrinterSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PrinterSettings(
        paperWidth: ReceiptPaperWidth.fromMm(prefs.getInt(_kPaperWidth)),
        connection: prefs.getString(_kConnection) == 'bluetooth'
            ? PrinterConnection.bluetooth
            : PrinterConnection.system,
        bluetoothAddress: prefs.getString(_kBtAddress),
        bluetoothName: prefs.getString(_kBtName),
      );
    } catch (_) {
      return const PrinterSettings();
    }
  }

  static Future<void> save(PrinterSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPaperWidth, settings.paperWidth.mm);
    await prefs.setString(_kConnection, settings.connection.name);
    final address = settings.bluetoothAddress ?? '';
    if (address.isEmpty) {
      await prefs.remove(_kBtAddress);
      await prefs.remove(_kBtName);
    } else {
      await prefs.setString(_kBtAddress, address);
      await prefs.setString(_kBtName, settings.bluetoothName ?? address);
    }
  }
}
