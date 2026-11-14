import 'package:flutter/material.dart';

import '../../../core/services/error_reporter.dart';
import '../../../core/services/localization_service.dart';
import '../../../i18n/gen/strings.g.dart';
import '../../../shared/widgets/app_notification.dart';
import '../../sales/services/receipt_data.dart';
import '../../sales/services/receipt_pdf_service.dart';
import '../data/bluetooth_printer_channel.dart';
import '../data/printer_settings_store.dart';
import '../domain/printer_settings.dart';
import 'escpos_receipt_builder.dart';

/// The one "Print receipt" entry point for every receipt surface (sale
/// sheet, invoice detail, debt receipts).
///
/// Reads this device's printer settings: a paired Bluetooth thermal printer
/// gets raw ESC/POS text with no dialog; otherwise the system print dialog
/// opens with the PDF sized to the chosen roll width (USB/Wi-Fi/Windows
/// printers with a driver). Shows its own success/error notifications.
abstract final class ReceiptPrinter {
  /// [meta] is the map from [ReceiptPdfService.loadMeta]. Returns true when
  /// the receipt was sent to a printer.
  static Future<bool> printReceipt(
    BuildContext context, {
    required Map<String, dynamic> sale,
    required Map<String, String> meta,
  }) async {
    final settings = await PrinterSettingsStore.load();
    final isSwahili = LocalizationService.isSwahili;
    final businessName = meta['businessName'] ?? 'Business';
    final printedBy = meta['printedBy'] ?? 'User';

    if (settings.usesBluetooth && BluetoothPrinterChannel.isAvailable) {
      if (context.mounted) {
        AppNotification.info(
          context,
          t.receiptPrinter.sending(name: settings.bluetoothName ?? ''),
          icon: Icons.print_rounded,
        );
      }
      try {
        final bytes = EscPosReceiptBuilder.build(
          receipt: ReceiptData.fromSale(sale, isSwahili: isSwahili),
          businessName: businessName,
          printedBy: printedBy,
          paperWidth: settings.paperWidth,
          businessPhone: meta['businessPhone'] ?? '',
          businessEmail: meta['businessEmail'] ?? '',
          businessAddress: meta['businessAddress'] ?? '',
        );
        await BluetoothPrinterChannel.printBytes(
          settings.bluetoothAddress!,
          bytes,
        );
        if (context.mounted) {
          AppNotification.success(context, t.receiptPrinter.printed);
        }
        return true;
      } on BluetoothPrinterException catch (e) {
        if (context.mounted) {
          AppNotification.error(context, bluetoothErrorMessage(e.error));
        }
        return false;
      }
    }

    try {
      return await ReceiptPdfService.print(
        sale: sale,
        businessName: businessName,
        printedBy: printedBy,
        isSwahili: isSwahili,
        businessPhone: meta['businessPhone'] ?? '',
        businessEmail: meta['businessEmail'] ?? '',
        businessAddress: meta['businessAddress'] ?? '',
        businessLogoUrl: meta['businessLogoUrl'] ?? '',
        paperWidth: settings.paperWidth,
      );
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      if (context.mounted) {
        AppNotification.error(context, t.receiptPrinter.systemFailed);
      }
      return false;
    }
  }

  /// Sends a test page to a Bluetooth printer. Throws
  /// [BluetoothPrinterException].
  static Future<void> printBluetoothTest({
    required String address,
    required ReceiptPaperWidth paperWidth,
  }) => BluetoothPrinterChannel.printBytes(
    address,
    EscPosReceiptBuilder.testPage(
      paperWidth: paperWidth,
      isSwahili: LocalizationService.isSwahili,
    ),
  );

  static String bluetoothErrorMessage(BluetoothPrinterError error) =>
      switch (error) {
        BluetoothPrinterError.off => t.receiptPrinter.errors.off,
        BluetoothPrinterError.permission => t.receiptPrinter.errors.permission,
        BluetoothPrinterError.unsupported =>
          t.receiptPrinter.errors.unsupported,
        BluetoothPrinterError.notFound => t.receiptPrinter.errors.notFound,
        BluetoothPrinterError.connectFailed =>
          t.receiptPrinter.errors.connectFailed,
      };
}
