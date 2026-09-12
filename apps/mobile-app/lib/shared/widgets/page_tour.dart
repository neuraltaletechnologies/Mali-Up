import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

/// One step of a spotlight tour: highlights whatever widget [targetKey] is
/// attached to, with a numbered [title] + [description] floating directly on
/// the dimmed screen (no card).
///
/// For a button/icon step, leave [inputController] null: a tap on the
/// highlighted widget reaches the real widget underneath (see the
/// "translucent hole" note on `_TourOverlayState`) and advances the tour at
/// once — the highlighted thing *is* the button.
///
/// For a text-field step, pass the field's own [inputController]: tapping
/// still focuses the real field for typing (nothing of the tour's own sits
/// in the way), but the tour does **not** advance on that tap — it waits
/// until the controller's text is actually non-empty, i.e. until the user
/// has entered something, before moving to the next step on its own.
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final TextEditingController? inputController;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.inputController,
  });
}

/// Hand-built spotlight tour: a full-screen dimmed [Overlay] entry with a
/// "hole" punched around the current step's target (a stadium shape — a
/// true circle on a square-ish target like a nav icon, a fully-rounded pill
/// on a wide one like a text field, always covering the target's real
/// bounds with no corners left dimmed), a pulsing glow ring, a curved arrow
/// from the text to the target, and Back / Skip / progress dots. Built on
/// [Overlay] + [CustomPainter] rather than a tooltip/card package, so the
/// design isn't constrained to a box-near-target layout.
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
  ///
  /// [onFullyComplete], if given, fires once the user reaches the end of
  /// [steps] — whether by genuinely finishing every step or by tapping Skip
  /// enough times to pass the last one. It does *not* fire on Skip alone
  /// (Skip only advances one step at a time now, it doesn't end the tour) —
  /// see [OnboardingJourney] for how screens chain onto one another with it.
  static Future<void> maybeAutoStart({
    required BuildContext context,
    required String seenKey,
    required List<TourStep> steps,
    VoidCallback? onFullyComplete,
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
        if (context.mounted) {
          _start(context, steps, onFullyComplete: onFullyComplete);
        }
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
    VoidCallback? onFullyComplete,
  }) {
    if (steps.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _start(context, steps, onFullyComplete: onFullyComplete);
      }
    });
  }

  static void _start(
    BuildContext context,
    List<TourStep> steps, {
    VoidCallback? onFullyComplete,
  }) {
    // Drop any step whose target isn't actually on screen right now (a
    // permission-gated widget, or a product-type-specific field, say)
    // rather than showing a spotlight on nothing.
    final validSteps = steps
        .where((s) => s.targetKey.currentContext != null)
        .toList();
    if (validSteps.isEmpty) return;

    _entry?.remove();
    late final OverlayEntry entry;
    void close() {
      entry.remove();
      if (_entry == entry) _entry = null;
      onFullyComplete?.call();
    }

    entry = OverlayEntry(
      builder: (_) => _TourOverlay(steps: validSteps, onClose: close),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

/// Chains several screens' tours into one guided first-run journey — e.g.
/// "finish the nav tour → go set up Cash Flow → go add a product → go make
/// a sale → done." Each stop is just that screen's own [PageTour], already
/// wired to auto-start for a new owner; this only adds the "and then
/// navigate to the next stop" hop once a stop's tour genuinely finishes.
///
/// State (which stop is active) lives in SharedPreferences so it survives
/// navigating between screens. A screen that isn't the current stop ignores
/// [advanceFrom] entirely, so this never interferes with someone just using
/// the app normally — it only ever drives navigation while a journey that
/// was explicitly started is still in progress.
class OnboardingJourney {
  OnboardingJourney._();

  static const _currentStopKey = 'onboarding_journey_stop';

  /// Begins the journey at [firstStop] by navigating there right away —
  /// only for a hand-off with no real widget of its own to tap (there
  /// usually is one; see [prime] for that far more common case).
  static Future<void> start(BuildContext context, String firstStop) async {
    if (!context.mounted) return;
    // Captured now, while context is definitely still mounted — GoRouter
    // itself is a long-lived singleton, so the reference stays good even if
    // this particular context is torn down later (see the note below).
    final router = GoRouter.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentStopKey, firstStop);
    router.go(firstStop);
  }

  /// Records [firstStop] as the journey's current stop **without**
  /// navigating anywhere — for the far more common case where the very
  /// next thing to do is highlight a real widget (a drawer's menu item, a
  /// FAB) and let the user's own tap both perform the real navigation and
  /// advance that highlight's own single-step tour, exactly like every
  /// other step in this whole tour system. Silent auto-navigation has no
  /// highlighted target for the user to associate the hop with, so it isn't
  /// used for a stop's *first* hand-off — only [advanceFrom] auto-navigates
  /// later, once a stop's own tour has already had the user tap something
  /// real to get there.
  static Future<void> prime(String firstStop) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentStopKey, firstStop);
  }

  /// Call from a stop's [PageTour.maybeAutoStart] `onFullyComplete`. Moves
  /// on to [nextStop] (or ends the journey if [nextStop] is null) — but only
  /// if [thisStop] is actually the journey's current stop right now, so a
  /// screen visited outside of an active journey never triggers a hop.
  /// Waits a beat before navigating, giving the screen's own save-and-close
  /// (its last step's tap both saves for real and finishes the tour) time to
  /// settle first.
  ///
  /// [context] is typically a sheet/dialog's own context, which the save it
  /// just triggered is racing to pop — by the time the beat above has
  /// passed, that context is very likely unmounted. [GoRouter.of(context)]
  /// is looked up now, synchronously, before any of that has a chance to
  /// happen, and the router instance it returns is the app's single
  /// long-lived router — still perfectly valid to call .go() on later even
  /// once the context that found it is long gone.
  static Future<void> advanceFrom(
    BuildContext context,
    String thisStop,
    String? nextStop,
  ) async {
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_currentStopKey) != thisStop) return;
    if (nextStop == null) {
      await prefs.remove(_currentStopKey);
      return;
    }
    await prefs.setString(_currentStopKey, nextStop);
    await Future.delayed(const Duration(milliseconds: 500));
    router.go(nextStop);
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

  // Wired up per-step when the target is a text field (see
  // TourStep.inputController) — advances the tour once the user actually
  // finishes entering something, instead of on tap. See
  // _scheduleDebouncedAdvance for how "finishes" is decided.
  TextEditingController? _listenedController;
  Timer? _inputDebounce;
  static const _inputDebounceDelay = Duration(milliseconds: 700);

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // A tour's very first step often targets something inside a sheet or
      // dialog that has *just* been pushed (a per-page FAB tour opening its
      // sheet's own continuation tour, say) — that sheet is still sliding
      // into place for its first ~250-300ms. Measuring immediately (the
      // very next frame after this widget mounts) captures the target
      // mid-slide, not where it settles, so the spotlight ends up looking
      // like it landed on the wrong field entirely. A short wait here, once,
      // before the very first measurement, lets that entrance transition
      // finish first. Later steps don't need this — by then the sheet is
      // already fully open and settled.
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _prepareStep();
    });
  }

  @override
  void dispose() {
    _detachInputListener();
    _enterCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  /// Dismisses any keyboard left over from the previous step first (so the
  /// scroll below measures against the *full* viewport, not one shrunk by
  /// an open keyboard), scrolls the target into view (a Save button below
  /// the fold in a long sheet, say), *then* measures it and wires up its
  /// completion signal. Skips to the next step if the target has vanished
  /// entirely.
  Future<void> _prepareStep() async {
    if (!mounted) return;
    final ctx = _step.targetKey.currentContext;
    if (ctx == null) {
      _advance();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    } catch (_) {
      // No ancestor Scrollable, or it raced with a dispose — fine, just
      // measure wherever the target already is.
    }
    if (!mounted || !ctx.mounted) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) {
      // Target vanished since the tour started (e.g. a sheet covered it) —
      // skip past it rather than spotlighting nothing.
      _advance();
      return;
    }
    final topLeft = box.localToGlobal(Offset.zero);
    setState(() => _targetRect = topLeft & box.size);
    _attachInputListenerIfNeeded();
  }

  void _attachInputListenerIfNeeded() {
    _detachInputListener();
    final controller = _step.inputController;
    if (controller == null) return;
    controller.addListener(_scheduleDebouncedAdvance);
    _listenedController = controller;
    // Deliberately no "already has a value → advance right away" case here
    // anymore — a field can carry a sensible non-empty default (Inventory's
    // Stock step starts at '1') without the user having actually looked at
    // or confirmed it yet. Tapping such a step now runs through the exact
    // same debounced path as typing (see the hole's Listener in build()),
    // so either accepting the default with a tap, or tapping in to change
    // it, behaves the same way: the countdown below is what actually moves
    // the tour on, not the tap or keystroke itself.
  }

  /// Shared by both a keystroke (the controller listener above) and a tap on
  /// an input step's own hole (see `isInputStep` in build()) — either one
  /// restarts the same short "quiet period" countdown rather than advancing
  /// immediately. That's what lets a tap on a field that already has a
  /// sensible default (Stock, pre-filled with '1') advance on its own after
  /// a moment — accepting the default — while a tap that's actually the
  /// start of editing just restarts the same timer on every subsequent
  /// keystroke, so the user gets the *entire* pause after their last
  /// keystroke to keep typing before it fires, not just after the first one.
  void _scheduleDebouncedAdvance() {
    _inputDebounce?.cancel();
    final controller = _step.inputController;
    if (controller == null) return;
    _inputDebounce = Timer(_inputDebounceDelay, () {
      if (mounted && controller.text.trim().isNotEmpty) _advance();
    });
  }

  void _detachInputListener() {
    _inputDebounce?.cancel();
    _inputDebounce = null;
    final controller = _listenedController;
    if (controller != null) {
      try {
        controller.removeListener(_scheduleDebouncedAdvance);
      } catch (_) {
        // Controller may already be disposed if the sheet closed out from
        // under the tour (e.g. via Skip) — nothing left to detach from.
      }
    }
    _listenedController = null;
  }

  void _goTo(int newIndex) {
    if (newIndex < 0) return;
    _detachInputListener();
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareStep());
  }

  void _advance() => _goTo(_index + 1);
  void _goBack() => _goTo(_index - 1);

  // For a button/icon step: the only way to move the tour forward is
  // tapping the highlighted widget itself. The tap also reaches the real
  // widget underneath (translucent hole, below), so this just needs to
  // move to the next step — closing the tour once past the last one.
  // There's no separate Next button: the highlighted thing *is* the button.
  void _onTargetTap() => _advance();

  @override
  Widget build(BuildContext context) {
    final target = _targetRect;
    if (target == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final hole = target.inflate(10);
    final holeRadius = hole.shortestSide / 2;
    final layout = _textLayoutFor(_step, hole, screenSize);
    final isInputStep = _step.inputController != null;

    return Stack(
      children: [
        // Dimmed area outside the hole — absorbs taps so nothing underneath
        // is triggered by accident.
        Positioned.fill(
          child: ClipPath(
            clipper: _OutsideHoleClipper(hole, holeRadius),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _noop,
            ),
          ),
        ),
        // The hole itself — always a Listener, never a GestureDetector.
        // Translucent hit-testing alone lets a tap reach the real widget
        // underneath, but tap *recognition* is separate — a second
        // GestureDetector here would register its own TapGestureRecognizer
        // in the same gesture arena as the real widget's, and only one
        // recognizer can win that arena (whichever is hit-tested first,
        // i.e. this one, on top — meaning the real widget's onPressed would
        // never fire). Listener sidesteps the arena entirely: it gets the
        // raw pointer event without competing for it, so the real widget
        // beneath still wins its own tap (or its own focus-for-typing)
        // normally, on top of this also feeding the tour.
        //
        // Button/icon/picker step: that raw tap advances the tour at once.
        // Text-field step: the tap *doesn't* advance directly — it instead
        // restarts the same debounced "quiet period" countdown that typing
        // does (see _scheduleDebouncedAdvance), so tapping in to edit a
        // field doesn't itself end the step, and a field that already
        // carries a sensible default can still be accepted with a plain tap.
        Positioned.fromRect(
          rect: hole,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(holeRadius),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (_) => isInputStep
                  ? _scheduleDebouncedAdvance()
                  : _onTargetTap(),
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
                holeRadius: holeRadius,
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
        // Top-right only — top-left is exactly where the real app's own
        // menu/back button usually lives on every screen this tour can
        // appear on, and a control sitting there reads as fighting with (or
        // hiding) whatever the current step is actually pointing at.
        Positioned(
          top: topInset + 12,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_index > 0) ...[
                _BackButton(onTap: _goBack),
                const SizedBox(width: 8),
              ],
              _TourControls(
                total: widget.steps.length,
                current: _index,
                // Skip only steps past this one — it isn't an exit anymore.
                // On the last step there's nothing left to skip *to*, so
                // _advance naturally finishes the tour the same as
                // completing it for real would.
                onSkip: _advance,
              ),
            ],
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

// Mirrors _TourText's own styles exactly — used only to *measure* text via
// TextPainter, never rendered directly, so the height computed here matches
// what actually gets painted to the pixel.
TextStyle get _titleStyle => GoogleFonts.dmSans(
  fontSize: 24,
  fontWeight: FontWeight.w800,
  height: 1.1,
);
TextStyle get _descriptionStyle =>
    GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4);
const _numberFontSize = 26.0;
const _numberGap = 10.0; // between the circled number and the title
const _titleDescGap = 10.0; // between the title row and the description

/// Real (not estimated) height of the step's text block, so the glow ring
/// around the target never ends up overlapping the tour's own text — the
/// two visibly crossing is what previously looked like stray lines drawn
/// under the description whenever a step's copy ran to 2-3 lines.
double _measureBlockHeight(TourStep step, double width) {
  final titlePainter = TextPainter(
    text: TextSpan(text: step.title, style: _titleStyle),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: math.max(0, width - _numberFontSize - _numberGap));
  final descPainter = TextPainter(
    text: TextSpan(text: step.description, style: _descriptionStyle),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final titleRowHeight = math.max(titlePainter.height, _numberFontSize);
  return titleRowHeight + _titleDescGap + descPainter.height;
}

_TextLayout _textLayoutFor(TourStep step, Rect hole, Size screen) {
  const sideInset = 24.0;
  const textLeft = sideInset;
  final textWidth = screen.width - sideInset * 2;
  const gap = 26.0; // space between the text block and the glow ring
  const topSafeMargin = 56.0; // stay clear of the status bar
  final blockHeight = _measureBlockHeight(step, textWidth);

  // A target in the lower half of the screen (nav bar, a FAB) gets its text
  // hugging just above it; a target near the top (the header menu icon) gets
  // its text just below — always anchored to the target itself, not a fixed
  // screen band, so it reads as pointing at the thing, not floating in the
  // middle of the screen.
  final targetBelowMiddle = hole.center.dy > screen.height * 0.5;
  final maxTextTop = screen.height - blockHeight - gap;
  final textTop = targetBelowMiddle
      ? (hole.top - gap - blockHeight).clamp(topSafeMargin, maxTextTop)
      : (hole.bottom + gap).clamp(topSafeMargin, maxTextTop);
  final arrowStartY = targetBelowMiddle ? textTop + blockHeight : textTop;
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
    required this.holeRadius,
    required this.arrowStart,
    required this.reveal,
    required this.glow,
  });

  final Rect hole;
  // Corner radius for the hole's stadium shape — hole.shortestSide / 2, so a
  // square-ish target (a nav icon) reads as a true circle and a wide one (a
  // text field) reads as a fully-rounded pill that still covers its corners,
  // unlike a plain inscribed oval would.
  final double holeRadius;
  final Offset arrowStart;
  final double reveal; // 0..1 step-enter animation
  final double glow; // 0..1 pulsing loop

  @override
  void paint(Canvas canvas, Size size) {
    final holeRRect = RRect.fromRectAndRadius(
      hole,
      Radius.circular(holeRadius),
    );
    final bgPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(holeRRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      bgPath,
      Paint()..color = Colors.black.withValues(alpha: 0.72 * reveal),
    );

    // Glow ring — soft blurred stroke that pulses, plus a crisp inner line.
    final glowInflate = 2 + 3 * glow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        hole.inflate(glowInflate),
        Radius.circular(holeRadius + glowInflate),
      ),
      Paint()
        ..color = AppColors.yellowBrand.withValues(
          alpha: (0.55 + 0.3 * glow) * reveal,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
      holeRRect,
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
  /// An ellipse approximation of the (now stadium-shaped) hole — close
  /// enough for where a decorative arrow lands, not meant to be exact.
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
      old.holeRadius != holeRadius ||
      old.reveal != reveal ||
      old.glow != glow ||
      old.arrowStart != arrowStart;
}

class _OutsideHoleClipper extends CustomClipper<Path> {
  const _OutsideHoleClipper(this.hole, this.holeRadius);

  final Rect hole;
  final double holeRadius;

  @override
  Path getClip(Size size) => Path()
    ..addRect(Offset.zero & size)
    ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(holeRadius)))
    ..fillType = PathFillType.evenOdd;

  @override
  bool shouldReclip(covariant _OutsideHoleClipper oldClipper) =>
      oldClipper.hole != hole || oldClipper.holeRadius != holeRadius;
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

  // Kept on the title only — description and the step number read cleanly
  // in plain white/yellow without it.
  static const _titleShadow = [
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
                      fontSize: _numberFontSize,
                      fontWeight: FontWeight.w800,
                      color: AppColors.yellowBrand,
                    ),
                  ),
                  const SizedBox(width: _numberGap),
                  Flexible(
                    child: Text(
                      step.title,
                      style: _titleStyle.copyWith(
                        color: Colors.white,
                        shadows: _titleShadow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _titleDescGap),
              Text(
                step.description,
                style: _descriptionStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Back: plain underlined text, matching Skip's own styling exactly (not
// a pill/chip button) ───────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          LocalizationService.tr(en: 'Back', sw: 'Nyuma'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white38,
          ),
        ),
      ),
    );
  }
}

// ── Controls: Skip · progress dots ──────────────────────────────────────────
// No Next button on purpose — the highlighted widget itself is the button.
// Tapping it performs its real action and moves the tour on. Skip moves on
// too, one step at a time, for whoever doesn't want to engage with what's
// currently highlighted — it's no longer a way to exit the whole tour.

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
              LocalizationService.tr(en: 'Skip', sw: 'Ruka'),
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
