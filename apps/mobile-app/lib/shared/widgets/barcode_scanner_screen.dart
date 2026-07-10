import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/services/sentry_metrics_service.dart';
import '../../core/services/localization_service.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

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
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scanned = false;
  late final AnimationController _flashAnim;

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
    _ctrl.dispose();
    _flashAnim.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    _scanned = true;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    SentryMetricsService.scannerAttempt(success: true);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? _t('Scan Barcode', 'Skani Nambari')),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _ctrl.toggleTorch(),
            tooltip: _t('Toggle flashlight', 'Washa/Zima taa'),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _ctrl.switchCamera(),
            tooltip: _t('Switch camera', 'Badilisha kamera'),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          const _ScanOverlay(),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _t('Point camera at barcode or QR code',
                      'Elekeza kamera kwenye barcode au QR code'),
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── POS Continuous Scanner ────────────────────────────────────────────────────

/// Cart item entry used by the POS scanner overlay.
class PosCartEntry {
  final String barcode;
  final String name;
  final double price;
  int qty;

  PosCartEntry({
    required this.barcode,
    required this.name,
    required this.price,
    this.qty = 1,
  });
}

/// Continuous scanner for POS flow.
///
/// Stays open after each scan. Calls [onScanned] for every new unique barcode.
/// Shows a floating mini-cart with running item count and subtotal.
/// Debounce prevents duplicate scans within [scanCooldown].
class PosScannerScreen extends StatefulWidget {
  /// Called every time a new barcode is successfully scanned.
  /// Return a [PosCartEntry] to display it in the mini-cart, or null to ignore.
  final Future<PosCartEntry?> Function(String barcode) onScanned;

  /// Shown at the top-left of the appbar.
  final String title;

  /// Cooldown between accepted scans of the same barcode.
  final Duration scanCooldown;

  const PosScannerScreen({
    super.key,
    required this.onScanned,
    this.title = 'Scan Items',
    this.scanCooldown = const Duration(milliseconds: 600),
  });

  static Future<List<PosCartEntry>> show(
    BuildContext context, {
    required Future<PosCartEntry?> Function(String barcode) onScanned,
    String title = 'Scan Items',
  }) async {
    final result = await Navigator.of(context).push<List<PosCartEntry>>(
      AppMotion.taskRoute<List<PosCartEntry>>(
        builder: (_) => PosScannerScreen(onScanned: onScanned, title: title),
      ),
    );
    return result ?? [];
  }

  @override
  State<PosScannerScreen> createState() => _PosScannerScreenState();
}

class _PosScannerScreenState extends State<PosScannerScreen>
    with SingleTickerProviderStateMixin {
  // Default DetectionSpeed.normal allows re-detection of the same barcode in
  // successive frames — required for consecutive identical products.
  // Accidental double-reads are filtered by the software cooldown below.
  final MobileScannerController _ctrl = MobileScannerController();

  final List<PosCartEntry> _cart = [];
  final Map<String, DateTime> _lastScanTime = {};
  bool _processing = false;
  Timer? _labelClearTimer;

  late final AnimationController _successAnim;
  late final Animation<double> _successScale;
  String? _lastScannedName;

  int get _totalItems => _cart.fold(0, (s, e) => s + e.qty);
  double get _subtotal => _cart.fold(0.0, (s, e) => s + e.price * e.qty);

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _successScale = CurvedAnimation(
      parent: _successAnim,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _labelClearTimer?.cancel();
    _ctrl.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;

    // Cooldown check — prevents scanning the same barcode twice in quick succession.
    final now = DateTime.now();
    final lastTime = _lastScanTime[value];
    if (lastTime != null &&
        now.difference(lastTime) < widget.scanCooldown) {
      return;
    }

    _processing = true;
    _lastScanTime[value] = now;
  final scanTimer = Stopwatch()..start();

    HapticFeedback.mediumImpact();

    try {
      final entry = await widget.onScanned(value);
      if (!mounted) return;

      if (entry != null) {
        setState(() {
          // If same product already in cart, increment qty.
          final existing = _cart.firstWhere(
            (e) => e.barcode == value,
            orElse: () => PosCartEntry(barcode: '', name: '', price: 0),
          );
          if (existing.barcode.isNotEmpty) {
            existing.qty += entry.qty;
          } else {
            _cart.add(entry);
          }
          _lastScannedName = entry.name;
        });
        // Play success animation on the overlay indicator.
        _successAnim.forward(from: 0);
        SystemSound.play(SystemSoundType.click);
        SentryMetricsService.scannerAttempt(success: true);
        SentryMetricsService.scanToCartTime(scanTimer.elapsed);
        // Clear the "scanned" label after a moment WITHOUT blocking the next
        // scan — checkout speed is limited only by the per-barcode cooldown.
        _labelClearTimer?.cancel();
        _labelClearTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _lastScannedName = null);
        });
      } else {
        // Not found — brief error haptic.
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        SentryMetricsService.scannerAttempt(success: false);
      }
    } finally {
      _processing = false;
    }
  }

  void _done() {
    Navigator.of(context).pop(_cart);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          const _ScanOverlay(),

          // ── Top bar ──────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: _done,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                widget.title,
                                style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Torch + camera flip
                    _IconBtn(
                        icon: Icons.flash_on,
                        onTap: () => _ctrl.toggleTorch()),
                    const SizedBox(width: 6),
                    _IconBtn(
                        icon: Icons.flip_camera_ios,
                        onTap: () => _ctrl.switchCamera()),
                  ],
                ),
              ),
            ),
          ),

          // ── Scan success indicator ────────────────────────────────────────
          if (_lastScannedName != null)
            Center(
              child: ScaleTransition(
                scale: _successScale,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _lastScannedName!,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Floating mini-cart ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: _cart.isEmpty
                      ? const _ScanHint(key: ValueKey('hint'))
                      : _MiniCart(
                          key: const ValueKey('cart'),
                          itemCount: _totalItems,
                          subtotal: _subtotal,
                          onDone: _done,
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ScanHint extends StatelessWidget {
  const _ScanHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Point camera at barcode or QR code',
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}

class _MiniCart extends StatelessWidget {
  final int itemCount;
  final double subtotal;
  final VoidCallback onDone;

  const _MiniCart({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.onDone,
  });

  String _fmt(double v) {
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                '$itemCount',
                style: GoogleFonts.dmSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t(
                      '$itemCount ${itemCount == 1 ? "item" : "items"} added',
                      '$itemCount ${itemCount == 1 ? "bidhaa" : "bidhaa"} zimeongezwa'),
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  _fmt(subtotal),
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDone,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _t('Done', 'Maliza'),
                style: GoogleFonts.dmSans(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
              Colors.black.withValues(alpha: 0.55), BlendMode.srcOut),
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
        ].map((pos) => Positioned(
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
            )),
      ],
    );
  }
}
