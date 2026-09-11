import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

String _tr(String en, String sw) => LocalizationService.isSwahili ? sw : en;

/// One step of a spotlight tour: highlights whatever widget [targetKey] is
/// attached to, with a numbered [title] + [description] floating directly on
/// the dimmed screen (no card). [onTap], if given, is called when the user
/// taps the highlighted widget itself — the tour then closes, same as
/// finishing it normally, so tapping "the real thing" both performs the
/// action and ends the walkthrough instead of just advancing it.
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.onTap,
  });
}

/// Hand-built spotlight tour: a full-screen dimmed [Overlay] entry with an
/// oval "hole" punched around the current step's target, a pulsing glow ring,
/// a curved arrow from the text to the target, and Skip / progress dots /
/// Next controls top-right. Built on [Overlay] + [CustomPainter] rather than
/// a tooltip/card package, so the design isn't constrained to a box-near-target
/// layout.
///
/// A screen wanting a tour just needs GlobalKeys on its real widgets and a
/// single [PageTour.maybeAutoStart] call in initState. See
/// main_shell_page.dart for the nav tour as the reference implementation.
class PageTour {
  PageTour._();

  static OverlayEntry? _entry;

  /// True while any tour — the nav tour or a per-page one — currently has
  /// its spotlight showing. [maybeAutoStart] checks this so that navigating
  /// to a screen *as part of* another tour (e.g. tapping "Sales" during the
  /// nav tour) doesn't immediately layer that screen's own tour on top —
  /// it waits for a later, separate visit instead.
  static bool get isActive => _entry != null;

  /// Starts [steps] in order, once ever, the first time this device reaches
  /// a screen on its own (not mid-way through another tour) — [seenKey] is
  /// a unique SharedPreferences flag per tour (e.g.
  /// `'page_tour_seen_sales'`). Most feature screens build their targets
  /// from a live stream (Firestore/Drift) that may still be loading on the
  /// very first frame, so this polls briefly rather than checking once:
  /// retries [maxAttempts] times, [retryInterval] apart, until the first
  /// step's target exists — bailing early, without retrying, the moment
  /// [isActive] is true, since arriving here mid-tour means this screen was
  /// just one of that tour's own stops. [seenKey] is only marked once the
  /// tour actually starts — if it never does (data didn't load in time, or
  /// another tour was running), nothing is marked and it's retried on the
  /// next visit instead of being silently lost forever.
  static Future<void> maybeAutoStart({
    required BuildContext context,
    required String seenKey,
    required List<TourStep> steps,
    int maxAttempts = 8,
    Duration retryInterval = const Duration(milliseconds: 300),
  }) async {
    if (steps.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(seenKey) ?? false) return;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (isActive) return;
      if (steps.first.targetKey.currentContext != null) {
        await prefs.setBool(seenKey, true);
        if (context.mounted) _start(context, steps);
        return;
      }
      await Future.delayed(retryInterval);
    }
  }

  /// Same as [maybeAutoStart] but ignores [seenKey] — wired to an explicit
  /// "show me again" action rather than the automatic first visit.
  static void replay({
    required BuildContext context,
    required List<TourStep> steps,
  }) {
    if (steps.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) _start(context, steps);
    });
  }

  static void _start(BuildContext context, List<TourStep> steps) {
    // Drop any step whose target isn't actually on screen right now (a
    // permission-gated widget, say) rather than showing a spotlight on
    // nothing.
    final validSteps = steps
        .where((s) => s.targetKey.currentContext != null)
        .toList();
    if (validSteps.isEmpty) return;

    _entry?.remove();
    late final OverlayEntry entry;
    void close() {
      entry.remove();
      if (_entry == entry) _entry = null;
    }

    entry = OverlayEntry(
      builder: (_) => _TourOverlay(steps: validSteps, onClose: close),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({required this.steps, required this.onClose});

  final List<TourStep> steps;
  final VoidCallback onClose;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay>
    with TickerProviderStateMixin {
  int _index = 0;
  Rect? _targetRect;
  late final AnimationController _enterCtrl;
  late final AnimationController _glowCtrl;

  TourStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final ctx = _step.targetKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) {
      // Target vanished since the tour started (e.g. a sheet covered it) —
      // skip past it rather than spotlighting nothing.
      _advance();
      return;
    }
    final topLeft = box.localToGlobal(Offset.zero);
    setState(() => _targetRect = topLeft & box.size);
  }

  void _goTo(int newIndex) {
    if (newIndex < 0) return;
    if (newIndex >= widget.steps.length) {
      widget.onClose();
      return;
    }
    setState(() {
      _index = newIndex;
      _targetRect = null;
    });
    _enterCtrl
      ..reset()
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _advance() => _goTo(_index + 1);

  // The only way to move the tour forward: tap the highlighted widget
  // itself. Runs its real action first (if any — navigate there, open its
  // sheet…), then moves to the next step, which closes the tour once past
  // the last one. There's no separate Next button: the highlighted thing
  // *is* the button.
  void _onTargetTap() {
    _step.onTap?.call();
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetRect;
    if (target == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final hole = target.inflate(10);
    final layout = _textLayoutFor(hole, screenSize);

    return Stack(
      children: [
        // Dimmed area outside the hole — absorbs taps so nothing underneath
        // is triggered by accident.
        Positioned.fill(
          child: ClipPath(
            clipper: _OutsideOvalClipper(hole),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _noop,
            ),
          ),
        ),
        // The hole itself: real taps reach the real widget's own action via
        // onTap, so highlighting something means it's still usable.
        Positioned.fromRect(
          rect: hole,
          child: ClipOval(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onTargetTap,
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([_enterCtrl, _glowCtrl]),
            builder: (context, _) => CustomPaint(
              size: screenSize,
              painter: _TourPainter(
                hole: hole,
                arrowStart: layout.arrowStart,
                reveal: _enterCtrl.value,
                glow: _glowCtrl.value,
              ),
            ),
          ),
        ),
        _TourText(
          step: _step,
          index: _index,
          top: layout.textTop,
          left: layout.textLeft,
          width: layout.textWidth,
          reveal: _enterCtrl,
        ),
        Positioned(
          top: topInset + 12,
          right: 16,
          child: _TourControls(
            total: widget.steps.length,
            current: _index,
            onSkip: widget.onClose,
          ),
        ),
      ],
    );
  }

  static void _noop() {}
}

// ── Layout: where the text block + arrow start go, given the target ────────

class _TextLayout {
  const _TextLayout({
    required this.textTop,
    required this.textLeft,
    required this.textWidth,
    required this.arrowStart,
  });

  final double textTop;
  final double textLeft;
  final double textWidth;
  final Offset arrowStart;
}

_TextLayout _textLayoutFor(Rect hole, Size screen) {
  const sideInset = 24.0;
  const textLeft = sideInset;
  final textWidth = screen.width - sideInset * 2;
  const gap = 26.0; // space between the text block and the glow ring
  // Approximate rendered height of the text block (number+title row, then a
  // 2-line description). No second layout pass to measure it exactly — this
  // only has to get the block close to the target, not pixel-perfect.
  const estimatedBlockHeight = 118.0;
  const topSafeMargin = 56.0; // stay clear of the status bar

  // A target in the lower half of the screen (nav bar, a FAB) gets its text
  // hugging just above it; a target near the top (the header menu icon) gets
  // its text just below — always anchored to the target itself, not a fixed
  // screen band, so it reads as pointing at the thing, not floating in the
  // middle of the screen.
  final targetBelowMiddle = hole.center.dy > screen.height * 0.5;
  final maxTextTop = screen.height - estimatedBlockHeight - gap;
  final textTop = targetBelowMiddle
      ? (hole.top - gap - estimatedBlockHeight).clamp(
          topSafeMargin,
          maxTextTop,
        )
      : (hole.bottom + gap).clamp(topSafeMargin, maxTextTop);
  final arrowStartY = targetBelowMiddle
      ? textTop + estimatedBlockHeight
      : textTop;
  final arrowStartX = hole.center.dx.clamp(
    textLeft + 24,
    textLeft + textWidth - 24,
  );
  return _TextLayout(
    textTop: textTop,
    textLeft: textLeft,
    textWidth: textWidth,
    arrowStart: Offset(arrowStartX, arrowStartY),
  );
}

// ── Painter: dimmed backdrop + glow ring + curved arrow ─────────────────────

class _TourPainter extends CustomPainter {
  const _TourPainter({
    required this.hole,
    required this.arrowStart,
    required this.reveal,
    required this.glow,
  });

  final Rect hole;
  final Offset arrowStart;
  final double reveal; // 0..1 step-enter animation
  final double glow; // 0..1 pulsing loop

  @override
  void paint(Canvas canvas, Size size) {
    final bgPath = Path()
      ..addRect(Offset.zero & size)
      ..addOval(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      bgPath,
      Paint()..color = Colors.black.withValues(alpha: 0.72 * reveal),
    );

    // Glow ring — soft blurred stroke that pulses, plus a crisp inner line.
    canvas.drawOval(
      hole.inflate(2 + 3 * glow),
      Paint()
        ..color = AppColors.yellowBrand.withValues(
          alpha: (0.55 + 0.3 * glow) * reveal,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawOval(
      hole,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * reveal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    if (reveal > 0.05) _drawArrow(canvas);
  }

  void _drawArrow(Canvas canvas) {
    final end = _pointOnOvalTowards(hole, arrowStart);
    final mid = Offset.lerp(arrowStart, end, 0.5)!;
    final dir = end - arrowStart;
    final len = dir.distance;
    if (len < 1) return;
    final normal = Offset(-dir.dy, dir.dx) / len;
    final control = mid + normal * (len * 0.18);

    final path = Path()
      ..moveTo(arrowStart.dx, arrowStart.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // Arrowhead, angled off the curve's tangent at `end`.
    final tangent = end - control;
    final tangentLen = tangent.distance == 0 ? 1.0 : tangent.distance;
    final tDir = tangent / tangentLen;
    const headLen = 9.0;
    const spread = 0.5; // radians
    Offset rotated(double angle) => Offset(
      tDir.dx * math.cos(angle) - tDir.dy * math.sin(angle),
      tDir.dx * math.sin(angle) + tDir.dy * math.cos(angle),
    );
    final left = end - rotated(spread) * headLen;
    final right = end - rotated(-spread) * headLen;
    canvas.drawPath(
      Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(end.dx, end.dy)
        ..lineTo(right.dx, right.dy),
      paint,
    );
  }

  /// The point on [oval]'s boundary closest to the direction of [from] —
  /// where the arrow should land so it points into the highlighted target.
  Offset _pointOnOvalTowards(Rect oval, Offset from) {
    final center = oval.center;
    final dir = from - center;
    if (dir.distance == 0) return Offset(center.dx, oval.top);
    final rx = oval.width / 2, ry = oval.height / 2;
    final angle = math.atan2(dir.dy / ry, dir.dx / rx);
    return Offset(
      center.dx + rx * math.cos(angle),
      center.dy + ry * math.sin(angle),
    );
  }

  @override
  bool shouldRepaint(covariant _TourPainter old) =>
      old.hole != hole ||
      old.reveal != reveal ||
      old.glow != glow ||
      old.arrowStart != arrowStart;
}

class _OutsideOvalClipper extends CustomClipper<Path> {
  const _OutsideOvalClipper(this.hole);

  final Rect hole;

  @override
  Path getClip(Size size) => Path()
    ..addRect(Offset.zero & size)
    ..addOval(hole)
    ..fillType = PathFillType.evenOdd;

  @override
  bool shouldReclip(covariant _OutsideOvalClipper oldClipper) =>
      oldClipper.hole != hole;
}

// ── Text: number + title + description, straight on the dimmed screen ──────

class _TourText extends StatelessWidget {
  const _TourText({
    required this.step,
    required this.index,
    required this.top,
    required this.left,
    required this.width,
    required this.reveal,
  });

  final TourStep step;
  final int index;
  final double top;
  final double left;
  final double width;
  final Animation<double> reveal;

  static const _shadows = [
    Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 2)),
  ];

  static String _circled(int n) {
    const glyphs = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩'];
    return n >= 1 && n <= glyphs.length ? glyphs[n - 1] : '$n.';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      width: width,
      child: FadeTransition(
        opacity: reveal,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: reveal, curve: Curves.easeOut),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    _circled(index + 1),
                    style: GoogleFonts.dmSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.yellowBrand,
                      shadows: _shadows,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      step.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                        shadows: _shadows,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                step.description,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.4,
                  shadows: _shadows,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Controls: Skip · progress dots ──────────────────────────────────────────
// No Next button on purpose — the highlighted widget itself is the button.
// Tapping it performs its real action and moves the tour on; Skip is the
// only other way to move without engaging with what's highlighted.

class _TourControls extends StatelessWidget {
  const _TourControls({
    required this.total,
    required this.current,
    required this.onSkip,
  });

  final int total;
  final int current;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onSkip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              _tr('Skip', 'Ruka'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white38,
              ),
            ),
          ),
        ),
        if (total > 1) ...[
          const SizedBox(width: 12),
          Row(
            children: List.generate(total, (i) {
              final active = i == current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: active ? 8 : 6,
                height: active ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.white : Colors.white30,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
