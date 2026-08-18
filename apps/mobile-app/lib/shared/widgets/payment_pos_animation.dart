// Card-tap POS payment animation, driven by real payment status rather than
// a fixed timer. Wraps `assets/lottie/Payment.json` (185 frames @ 24fps).
//
// The source file's frame layout (verified against the raw Lottie JSON, not
// guessed):
//   0   -> 20   Card fades in and slides up into the POS slot ("intro").
//   33  -> 84   One full hourglass rotation, built as its own 512x512
//               precomp ("HOUR GLASS 3"). The file repeats the identical
//               precomp a second time from 84 -> 136 ("HOUR GLASS 4") to
//               pad out a fixed-length preview -- we ignore that second
//               copy and loop the first cycle indefinitely instead, since
//               it's a self-contained unit.
//   130 -> 160  Green checkmark circle pops in (scale 0->70, opacity
//               0->100 by frame 141) and holds fully visible until 160.
//   160 -> 171  Checkmark fades back OUT (opacity 100->0) while the card
//               simultaneously ejects back off-screen (position + opacity
//               keyframes both end at frame 171). By frame 185 the scene
//               is just the empty POS body again.
//
// See the class doc on [PaymentPosAnimationController] for how the waiting
// loop and the jump into the success section are handled, and why a
// perfectly seamless loop-to-success transition isn't possible with this
// particular file.
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Frame numbers read directly from `Payment.json` (fr: 24, ip: 0, op: 185).
/// Kept separate from the controller so they're easy to re-verify against
/// the source file if it's ever swapped out.
abstract class PaymentPosAnimationFrames {
  static const int total = 185;

  static const int introStart = 0;
  static const int introEnd = 20;

  /// One hourglass rotation cycle. Loop `[waitLoopStart, waitLoopEnd]`
  /// indefinitely while payment is pending -- see controller doc.
  static const int waitLoopStart = 33;
  static const int waitLoopEnd = 84;

  /// Checkmark starts popping in here.
  static const int successStart = 130;

  /// Checkmark at full scale/opacity, card still docked -- the last frame
  /// that reads unambiguously as "payment succeeded" before the built-in
  /// fade-out/eject begins. This is where playback stops by default.
  static const int successHold = 160;

  /// Checkmark fully faded out and card fully ejected -- the natural end
  /// of the file's built-in success beat. Only reached if the caller opts
  /// into [PaymentPosAnimationController.setSuccess]'s `playFullFadeOut`.
  static const int successFadeEnd = 171;
}

enum PaymentAnimStatus { idle, intro, waiting, success, failed }

/// Drives [PaymentPosAnimation] from real payment state instead of a timer.
///
/// Owns the [AnimationController]; the caller's [State] must mix in
/// `SingleTickerProviderStateMixin` (or `TickerProviderStateMixin`) and pass
/// itself as `vsync`.
///
/// ### Known limitation: the waiting loop can't hand off to success 100%
/// seamlessly
///
/// The file only contains two back-to-back copies of the hourglass rotation
/// (frames 33-84 and 84-136) before the checkmark starts at frame 130 --
/// it wasn't authored for an indefinite wait. To wait longer than ~4.7s we
/// repeat the first cycle (`[33, 84]`) with [AnimationController.repeat],
/// which loops perfectly on itself. When [setSuccess] is called, we let the
/// *current* loop iteration finish (so playback is always sitting exactly on
/// `waitLoopEnd`, never stopped mid-rotation) and then jump straight to
/// `successStart`, skipping the file's second, redundant hourglass turn.
/// That jump does snap the hourglass's rotation angle for one frame, but
/// it's immediately covered by the checkmark's pop-in, so in practice it
/// reads as instant rather than glitchy. If you'd rather have zero jump at
/// the cost of a slower success reveal, see the comment on [setSuccess].
class PaymentPosAnimationController extends ChangeNotifier {
  PaymentPosAnimationController({required TickerProvider vsync})
    : _controller = AnimationController(vsync: vsync);

  final AnimationController _controller;
  LottieComposition? _composition;

  PaymentAnimStatus _status = PaymentAnimStatus.idle;
  PaymentAnimStatus get status => _status;

  /// Guards against `setSuccess`/`setFailed` racing a `startPayment` that
  /// hasn't reached the waiting loop yet.
  int _sessionId = 0;

  AnimationController get rawController => _controller;

  bool get isReady => _composition != null;

  void attachComposition(LottieComposition composition) {
    _composition = composition;
    _controller.duration = composition.duration;
  }

  double _progressOf(int frame) {
    final composition = _composition;
    if (composition == null) return 0;
    final start = composition.startFrame;
    final end = composition.endFrame;
    return ((frame - start) / (end - start)).clamp(0.0, 1.0);
  }

  Duration _durationOfFrames(int frameCount) {
    final composition = _composition;
    if (composition == null) return Duration.zero;
    final totalFrames = composition.endFrame - composition.startFrame;
    if (totalFrames <= 0) return Duration.zero;
    final micros =
        composition.duration.inMicroseconds * frameCount / totalFrames;
    return Duration(microseconds: micros.round());
  }

  /// 1. Payment starts: play the card-enters-POS intro once, then move
  /// straight into the indefinitely-looping waiting state.
  Future<void> startPayment() async {
    if (!isReady) return;
    final session = ++_sessionId;
    _status = PaymentAnimStatus.intro;
    notifyListeners();

    await _controller.animateTo(
      _progressOf(PaymentPosAnimationFrames.introEnd),
      duration: _durationOfFrames(
        PaymentPosAnimationFrames.introEnd - PaymentPosAnimationFrames.introStart,
      ),
      curve: Curves.easeOut,
    );
    if (session != _sessionId) return; // superseded by a reset/new payment
    setWaiting();
  }

  /// 2. Payment is waiting/pending: loop the hourglass rotation forever,
  /// independent of how long the real transaction takes.
  void setWaiting() {
    if (!isReady) return;
    _status = PaymentAnimStatus.waiting;
    notifyListeners();
    _controller.repeat(
      min: _progressOf(PaymentPosAnimationFrames.waitLoopStart),
      max: _progressOf(PaymentPosAnimationFrames.waitLoopEnd),
    );
  }

  /// 3. Payment succeeded: stop the wait loop and play the checkmark once.
  ///
  /// By default this holds on [PaymentPosAnimationFrames.successHold]
  /// (checkmark fully visible, card still docked) rather than playing all
  /// the way through the file's built-in fade-out/eject -- that fade ends
  /// on an almost-empty frame, which reads as "nothing happened" if your UI
  /// doesn't immediately cut away. Pass `playFullFadeOut: true` if you do
  /// want the card to visibly eject before your own success UI takes over.
  Future<void> setSuccess({bool playFullFadeOut = false}) async {
    if (!isReady) return;
    if (_status != PaymentAnimStatus.waiting &&
        _status != PaymentAnimStatus.intro) {
      return;
    }
    final session = _sessionId; // don't bump: this continues the same run
    _status = PaymentAnimStatus.success;
    notifyListeners();

    // Let the current wait-loop iteration land exactly on its boundary
    // before doing anything else, so we never cut a rotation mid-way.
    _controller.stop();
    if (_controller.value < _progressOf(PaymentPosAnimationFrames.waitLoopEnd)) {
      await _controller.animateTo(
        _progressOf(PaymentPosAnimationFrames.waitLoopEnd),
        duration: _durationOfFrames(
          ((_progressOf(PaymentPosAnimationFrames.waitLoopEnd) - _controller.value) *
                  PaymentPosAnimationFrames.total)
              .round(),
        ),
      );
    }
    if (session != _sessionId) return;

    // Skip the file's redundant second hourglass turn (84 -> 130) and jump
    // straight to the checkmark. See the class doc for the trade-off.
    _controller.value = _progressOf(PaymentPosAnimationFrames.successStart);

    final target = playFullFadeOut
        ? PaymentPosAnimationFrames.successFadeEnd
        : PaymentPosAnimationFrames.successHold;
    await _controller.animateTo(
      _progressOf(target),
      duration: _durationOfFrames(target - PaymentPosAnimationFrames.successStart),
      curve: Curves.easeOut,
    );
  }

  /// 4. Payment failed: freeze exactly where the waiting animation is --
  /// never advance into the checkmark frames. The Lottie file has no
  /// dedicated failure section, so the surrounding UI (message + "Try
  /// Again") carries the failure state, as requested.
  void setFailed() {
    if (!isReady) return;
    _sessionId++; // invalidate any in-flight startPayment/setSuccess future
    _status = PaymentAnimStatus.failed;
    _controller.stop();
    notifyListeners();
  }

  /// Resets to the very first frame so a "Try Again" tap can call
  /// [startPayment] again cleanly.
  void reset() {
    _sessionId++;
    _controller.stop();
    _controller.value = 0;
    _status = PaymentAnimStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Renders `assets/lottie/Payment.json` under the frames driven by
/// [PaymentPosAnimationController]. Purely presentational -- all the state
/// logic lives on the controller so it can be unit tested without a widget
/// tree.
class PaymentPosAnimation extends StatelessWidget {
  const PaymentPosAnimation({
    super.key,
    required this.controller,
    this.size = 220,
  });

  final PaymentPosAnimationController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/lottie/Payment.json',
        controller: controller.rawController,
        onLoaded: controller.attachComposition,
        fit: BoxFit.contain,
      ),
    );
  }
}
