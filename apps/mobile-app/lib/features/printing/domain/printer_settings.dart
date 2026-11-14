/// Receipt paper roll width. Thermal printers sold in TZ are almost all
/// 58mm (handheld / Bluetooth) or 80mm (counter / USB).
enum ReceiptPaperWidth {
  mm58(58, 32),
  mm80(80, 48);

  const ReceiptPaperWidth(this.mm, this.charsPerLine);

  /// Physical roll width, used for the PDF page width.
  final int mm;

  /// Characters per line in the printer's standard font (Font A), used for
  /// the ESC/POS text layout.
  final int charsPerLine;

  static ReceiptPaperWidth fromMm(int? mm) => mm == 58 ? mm58 : mm80;
}

/// How "Print receipt" reaches the printer.
enum PrinterConnection {
  /// The OS print dialog (Android print services, AirPrint, Windows
  /// drivers). Covers USB and Wi-Fi printers that have a driver installed.
  system,

  /// A paired classic-Bluetooth ESC/POS printer, sent raw text directly —
  /// no dialog. Android only.
  bluetooth,
}

/// Per-device printer setup. Not synced: the printer belongs to the phone
/// or till it's paired with, not to the business.
class PrinterSettings {
  final ReceiptPaperWidth paperWidth;
  final PrinterConnection connection;
  final String? bluetoothAddress;
  final String? bluetoothName;

  const PrinterSettings({
    this.paperWidth = ReceiptPaperWidth.mm80,
    this.connection = PrinterConnection.system,
    this.bluetoothAddress,
    this.bluetoothName,
  });

  /// True only when Bluetooth is chosen *and* a printer has been picked;
  /// otherwise printing falls back to the system dialog.
  bool get usesBluetooth =>
      connection == PrinterConnection.bluetooth &&
      (bluetoothAddress ?? '').isNotEmpty;

  PrinterSettings copyWith({
    ReceiptPaperWidth? paperWidth,
    PrinterConnection? connection,
    String? bluetoothAddress,
    String? bluetoothName,
  }) => PrinterSettings(
    paperWidth: paperWidth ?? this.paperWidth,
    connection: connection ?? this.connection,
    bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
    bluetoothName: bluetoothName ?? this.bluetoothName,
  );
}
