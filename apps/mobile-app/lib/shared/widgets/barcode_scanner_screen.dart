import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/services/sentry_metrics_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/utils/platform_capabilities.dart';
import 'app_notification.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// The ML Kit barcode model ships unbundled (downloaded by Google Play Services
/// on demand — see `dev.steenbakker.mobile_scanner.useUnbundled` in
/// android/gradle.properties). Until it has downloaded, or on a device with no
/// Play Services, live detection throws. Both scanner screens route
/// [MobileScanner.onDetectError] here: show the standard navy toast once (it
/// lives in the root overlay, so it survives the screen being popped). The
/// caller then pops and its manual code-entry path takes over.
void _notifyScannerUnavailable(BuildContext context) {
  AppNotification.info(
    context,
    _t(
      'Barcode scanning needs internet the first time. Connect once, or type '
          'the code in.',
      'Skani ya barcode inahitaji intaneti mara ya kwanza. Unganisha mara moja, '
          'au andika nambari.',
    ),
    duration: const Duration(seconds: 5),
  );
}

/// Single-scan mode: returns the raw barcode string via Navigator.pop, or null.
class BarcodeScannerScreen extends StatefulWidget {
  final String? title;

  const BarcodeScannerScreen({super.key, this.title});

  static Future<String?> show(BuildContext context, {String? title}) {
    return Navigator.of(context).push<String>(
      AppMotion.taskRoute<String>(
        builder: (_) => BarcodeScannerScreen(title: title),
      ),
    );
  }

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  // Null on desktop (Windows): no camera scanning there — the screen takes
  // input from a USB barcode scanner instead (see _ScannerDeviceInput).
  final MobileScannerController? _ctrl = PlatformCapabilities.hasCameraScanner
      ? MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates)
      : null;
  bool _scanned = false;
  bool _scannerErrorHandled = false;
  late final AnimationController _flashAnim;

  void _onScannerError(Object error, StackTrace stackTrace) {
    if (_scannerErrorHandled || _scanned || !mounted) return;
    _scannerErrorHandled = true;
    _notifyScannerUnavailable(context);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _flashAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _flashAnim.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value != null) _accept(value);
  }

  void _accept(String value) {
    if (_scanned || value.isEmpty) return;
    _scanned = true;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    SentryMetricsService.scannerAttempt(success: true);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? _t('Scan Barcode', 'Skani Nambari')),
        actions: [
          if (ctrl != null) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => ctrl.toggleTorch(),
              tooltip: _t('Toggle flashlight', 'Washa/Zima taa'),
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => ctrl.switchCamera(),
              tooltip: _t('Switch camera', 'Badilisha kamera'),
            ),
          ],
        ],
      ),
      body: ctrl == null
          ? Center(child: _ScannerDeviceInput(onCode: _accept))
          : Stack(
              children: [
                MobileScanner(
                  controller: ctrl,
                  onDetect: _onDetect,
                  onDetectError: _onScannerError,
                ),
                const _ScanOverlay(),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _t(
                          'Point camera at barcode or QR code',
                          'Elekeza kamera kwenye barcode au QR code',
                        ),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Inline (in-page) continuous scanner ─────────────────────────────────────

/// What an [InlineBarcodeScanner] shows after a scan: the product that was
/// added (green) or why nothing was added (red).
class ScanFeedback {
  final String message;
  final bool ok;

  const ScanFeedback.ok(this.message) : ok = true;
  const ScanFeedback.error(this.message) : ok = false;
}

/// A compact camera strip that sits at the top of the page it is used on —
/// the cart stays visible right below it, so every scan lands in the cart
/// the cashier is looking at. No separate scan page.
///
/// Stays open and keeps scanning until [onClose]. A barcode held in front
/// of the camera is counted once; it counts again only after it has left
/// the view (so two identical items are two scans).
///
/// On desktop (no camera) it is a one-line field that a USB/Bluetooth
/// barcode scanner types into — every Enter is one scan.
class InlineBarcodeScanner extends StatefulWidget {
  /// Called for every accepted scan; the result is flashed on the strip.
  final Future<ScanFeedback> Function(String code) onCode;
  final VoidCallback onClose;
  final double height;
  final EdgeInsetsGeometry margin;

  const InlineBarcodeScanner({
    super.key,
    required this.onCode,
    required this.onClose,
    this.height = 170,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  @override
  State<InlineBarcodeScanner> createState() => _InlineBarcodeScannerState();
}

class _InlineBarcodeScannerState extends State<InlineBarcodeScanner> {
  // DetectionSpeed.normal re-reports a code every ~250ms while it stays in
  // view; [_lastSeen] turns that into "once per appearance".
  final MobileScannerController? _ctrl = PlatformCapabilities.hasCameraScanner
      ? MobileScannerController()
      : null;

  /// A code must be out of view this long before it counts again.
  static const _rearmGap = Duration(milliseconds: 900);

  final Map<String, DateTime> _lastSeen = {};
  bool _busy = false;
  bool _torchOn = false;
  bool _scannerErrorHandled = false;
  ScanFeedback? _feedback;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  void _onScannerError(Object error, StackTrace stackTrace) {
    if (_scannerErrorHandled || !mounted) return;
    _scannerErrorHandled = true;
    _notifyScannerUnavailable(context);
    widget.onClose();
  }

  void _onDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    for (final b in capture.barcodes) {
      final code = b.rawValue?.trim() ?? '';
      if (code.isEmpty) continue;
      final seen = _lastSeen[code];
      _lastSeen[code] = now;
      if (seen != null && now.difference(seen) < _rearmGap) continue;
      _handle(code);
      return; // one product per frame
    }
  }

  Future<void> _handle(String code) async {
    if (_busy || code.isEmpty) return;
    _busy = true;
    final timer = Stopwatch()..start();
    try {
      final result = await widget.onCode(code);
      if (!mounted) return;
      if (result.ok) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        SentryMetricsService.scannerAttempt(success: true);
        SentryMetricsService.scanToCartTime(timer.elapsed);
      } else {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        SentryMetricsService.scannerAttempt(success: false);
      }
      _feedbackTimer?.cancel();
      setState(() => _feedback = result);
      _feedbackTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _feedback = null);
      });
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    return Padding(
      padding: widget.margin,
      child: ctrl == null ? _buildDeviceInput() : _buildCamera(ctrl),
    );
  }

  Widget _buildCamera(MobileScannerController ctrl) {
    final fb = _feedback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: ctrl,
              onDetect: _onDetect,
              onDetectError: _onScannerError,
            ),
            // Aim line across the middle.
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.78,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.yellowBrand,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellowBrand.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _StripButton(
                    icon: _torchOn
                        ? Icons.flash_off_rounded
                        : Icons.flash_on_rounded,
                    tooltip: _t('Flashlight', 'Taa'),
                    onTap: () {
                      ctrl.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                  const SizedBox(width: 6),
                  _StripButton(
                    icon: Icons.close_rounded,
                    tooltip: _t('Stop scanning', 'Acha kuskani'),
                    onTap: widget.onClose,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: fb == null
                      ? _StripPill(
                          key: const ValueKey('hint'),
                          color: Colors.black54,
                          icon: Icons.qr_code_scanner_rounded,
                          text: _t(
                            'Point at a barcode — it goes straight to the cart',
                            'Elekeza kwenye barcode — inaingia kikapuni moja kwa moja',
                          ),
                        )
                      : _StripPill(
                          key: ValueKey(fb),
                          color: fb.ok ? AppColors.success : AppColors.error,
                          icon: fb.ok
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          text: fb.message,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInput() {
    final fb = _feedback;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InlineDeviceField(onCode: _handle, onClose: widget.onClose),
        if (fb != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(
                  fb.ok
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 16,
                  color: fb.ok ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fb.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: fb.ok ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Desktop variant of [InlineBarcodeScanner]: an always-focused field a USB
/// scanner types into (it ends each code with Enter).
class _InlineDeviceField extends StatefulWidget {
  final ValueChanged<String> onCode;
  final VoidCallback onClose;

  const _InlineDeviceField({required this.onCode, required this.onClose});

  @override
  State<_InlineDeviceField> createState() => _InlineDeviceFieldState();
}

class _InlineDeviceFieldState extends State<_InlineDeviceField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final code = raw.trim();
    _ctrl.clear();
    _focus.requestFocus();
    if (code.isNotEmpty) widget.onCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: _submit,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        letterSpacing: 1.1,
        color: AppColors.navyPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.tealAccent.withValues(alpha: 0.06),
        hintText: _t(
          'Scan with your barcode scanner, or type the code + Enter',
          'Skani kwa kifaa cha barcode, au andika nambari + Enter',
        ),
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.tealAccent,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close_rounded, size: 18),
          color: AppColors.textMuted,
          tooltip: _t('Stop scanning', 'Acha kuskani'),
          onPressed: widget.onClose,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.tealAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _StripPill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _StripPill({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _StripButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Desktop (Windows) replacement for the camera view. A USB/Bluetooth
/// barcode scanner acts as a keyboard: it types the code and presses Enter,
/// which submits this always-focused field. Typing a code by hand works too.
class _ScannerDeviceInput extends StatefulWidget {
  final ValueChanged<String> onCode;

  const _ScannerDeviceInput({required this.onCode});

  @override
  State<_ScannerDeviceInput> createState() => _ScannerDeviceInputState();
}

class _ScannerDeviceInputState extends State<_ScannerDeviceInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final code = raw.trim();
    _ctrl.clear();
    // Keep focus so the next scan lands here without a click.
    _focus.requestFocus();
    if (code.isNotEmpty) widget.onCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _t(
                'Scan with your barcode scanner',
                'Skani kwa kifaa chako cha barcode',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t(
                'Or type the code and press Enter',
                'Au andika nambari kisha bonyeza Enter',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
              cursorColor: AppColors.yellowBrand,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white12,
                hintText: _t('Barcode', 'Nambari ya barcode'),
                hintStyle: GoogleFonts.dmSans(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.keyboard_rounded,
                  color: Colors.white54,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.keyboard_return_rounded,
                    color: Colors.white70,
                  ),
                  tooltip: _t('Add', 'Ongeza'),
                  onPressed: () => _submit(_ctrl.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.yellowBrand),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const boxSize = 260.0;
    final top = (size.height - boxSize) / 2 - 40;
    final left = (size.width - boxSize) / 2;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              Positioned(
                top: top,
                left: left,
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: top,
          left: left,
          child: Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.tealAccent, width: 2.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Corner accent marks
        ...[
          Offset(left, top),
          Offset(left + boxSize - 24, top),
          Offset(left, top + boxSize - 24),
          Offset(left + boxSize - 24, top + boxSize - 24),
        ].map(
          (pos) => Positioned(
            left: pos.dx,
            top: pos.dy,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.primary, width: 3),
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
