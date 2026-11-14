import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/gen/strings.g.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../sales/services/receipt_pdf_service.dart';
import '../../data/bluetooth_printer_channel.dart';
import '../../data/printer_settings_store.dart';
import '../../domain/printer_settings.dart';
import '../../services/receipt_printer.dart';

/// Settings → Receipt printer: paper roll width (58/80mm), printer type
/// (system dialog vs. paired Bluetooth ESC/POS printer), and a test print.
/// Saved per device on every change.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  PrinterSettings? _settings;
  List<BluetoothPrinterDevice>? _devices;
  BluetoothPrinterError? _deviceError;
  bool _loadingDevices = false;
  bool _testing = false;

  bool get _btAvailable => BluetoothPrinterChannel.isAvailable;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await PrinterSettingsStore.load();
    if (!mounted) return;
    setState(() => _settings = settings);
    if (settings.connection == PrinterConnection.bluetooth && _btAvailable) {
      await _loadDevices();
    }
  }

  Future<void> _update(PrinterSettings next) async {
    setState(() => _settings = next);
    await PrinterSettingsStore.save(next);
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loadingDevices = true;
      _deviceError = null;
    });
    try {
      final devices = await BluetoothPrinterChannel.bondedDevices();
      if (!mounted) return;
      setState(() => _devices = devices);
    } on BluetoothPrinterException catch (e) {
      if (!mounted) return;
      setState(() {
        _devices = null;
        _deviceError = e.error;
      });
    } finally {
      if (mounted) setState(() => _loadingDevices = false);
    }
  }

  Future<void> _selectConnection(PrinterConnection connection) async {
    final settings = _settings;
    if (settings == null) return;
    await _update(settings.copyWith(connection: connection));
    if (connection == PrinterConnection.bluetooth && _devices == null) {
      await _loadDevices();
    }
  }

  Future<void> _testPrint() async {
    final settings = _settings;
    if (settings == null || _testing) return;
    setState(() => _testing = true);
    try {
      if (settings.connection == PrinterConnection.bluetooth && _btAvailable) {
        final address = settings.bluetoothAddress ?? '';
        if (address.isEmpty) {
          AppNotification.warning(
            context,
            t.receiptPrinter.settings.selectPrinterFirst,
          );
          return;
        }
        try {
          await ReceiptPrinter.printBluetoothTest(
            address: address,
            paperWidth: settings.paperWidth,
          );
          if (mounted) {
            AppNotification.success(context, t.receiptPrinter.settings.testSent);
          }
        } on BluetoothPrinterException catch (e) {
          if (mounted) {
            AppNotification.error(
              context,
              ReceiptPrinter.bluetoothErrorMessage(e.error),
            );
          }
        }
      } else {
        try {
          await ReceiptPdfService.print(
            sale: _sampleSale,
            businessName: 'Mali Up',
            printedBy: 'Mali Up',
            isSwahili: LocalizationService.isSwahili,
            paperWidth: settings.paperWidth,
          );
        } catch (_) {
          if (mounted) {
            AppNotification.error(context, t.receiptPrinter.systemFailed);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  static final Map<String, dynamic> _sampleSale = {
    'invoiceNumber': 'TEST-001',
    'date': DateTime.now(),
    'items': [
      {'name': 'Sukari 1kg', 'qty': 2, 'unitPrice': 3500, 'lineTotal': 7000},
      {'name': 'Mafuta ya kupikia 1L', 'qty': 1, 'unitPrice': 5500, 'lineTotal': 5500},
    ],
    'totalAmount': 12500,
    'amountPaid': 12500,
    'paymentMethod': 'cash',
  };

  @override
  Widget build(BuildContext context) {
    final s = t.receiptPrinter.settings;
    final settings = _settings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: AppColors.navyPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.screenTitle,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navyPrimary,
          ),
        ),
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Header(title: s.paperWidth, hint: s.paperWidthHint),
                _Card(
                  children: [
                    _OptionTile(
                      icon: Icons.receipt_long_rounded,
                      title: '58mm',
                      subtitle: s.mm58Hint,
                      selected: settings.paperWidth == ReceiptPaperWidth.mm58,
                      onTap: () => _update(
                        settings.copyWith(paperWidth: ReceiptPaperWidth.mm58),
                      ),
                    ),
                    const _Divider(),
                    _OptionTile(
                      icon: Icons.receipt_rounded,
                      title: '80mm',
                      subtitle: s.mm80Hint,
                      selected: settings.paperWidth == ReceiptPaperWidth.mm80,
                      onTap: () => _update(
                        settings.copyWith(paperWidth: ReceiptPaperWidth.mm80),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Header(title: s.connection),
                _Card(
                  children: [
                    _OptionTile(
                      icon: Icons.print_rounded,
                      title: s.system,
                      subtitle: s.systemHint,
                      selected:
                          settings.connection == PrinterConnection.system ||
                          !_btAvailable,
                      onTap: () => _selectConnection(PrinterConnection.system),
                    ),
                    const _Divider(),
                    _OptionTile(
                      icon: Icons.bluetooth_rounded,
                      title: s.bluetooth,
                      subtitle: _btAvailable
                          ? s.bluetoothHint
                          : s.bluetoothAndroidOnly,
                      selected:
                          _btAvailable &&
                          settings.connection == PrinterConnection.bluetooth,
                      enabled: _btAvailable,
                      onTap: () =>
                          _selectConnection(PrinterConnection.bluetooth),
                    ),
                  ],
                ),
                if (_btAvailable &&
                    settings.connection == PrinterConnection.bluetooth) ...[
                  const SizedBox(height: 20),
                  _buildDevicePicker(settings),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _testPrint,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined, size: 18),
                    label: Text(s.testPrint),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDevicePicker(PrinterSettings settings) {
    final s = t.receiptPrinter.settings;
    final devices = _devices ?? const <BluetoothPrinterDevice>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _Header(title: s.choosePrinter)),
            TextButton.icon(
              onPressed: _loadingDevices ? null : _loadDevices,
              icon: _loadingDevices
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(s.refresh),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tealAccent,
              ),
            ),
          ],
        ),
        if (_deviceError != null)
          _Notice(
            text: ReceiptPrinter.bluetoothErrorMessage(_deviceError!),
            color: AppColors.error,
          )
        else if (_devices != null && devices.isEmpty)
          _Notice(text: s.noDevices, color: AppColors.textMuted)
        else if (devices.isNotEmpty)
          _Card(
            children: [
              for (var i = 0; i < devices.length; i++) ...[
                if (i > 0) const _Divider(),
                _OptionTile(
                  icon: devices[i].isPrinter
                      ? Icons.print_rounded
                      : Icons.bluetooth_rounded,
                  title: devices[i].name,
                  subtitle: devices[i].isPrinter
                      ? '${s.likelyPrinter} · ${devices[i].address}'
                      : devices[i].address,
                  selected: settings.bluetoothAddress == devices[i].address,
                  onTap: () => _update(
                    settings.copyWith(
                      bluetoothAddress: devices[i].address,
                      bluetoothName: devices[i].name,
                    ),
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 10),
        _Notice(text: s.pairFirst, color: AppColors.textMuted),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? hint;

  const _Header({required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 60, color: AppColors.border);
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? AppColors.tealAccent : AppColors.textDisabled;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppColors.navyPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppColors.tealAccent : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final Color color;

  const _Notice({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
