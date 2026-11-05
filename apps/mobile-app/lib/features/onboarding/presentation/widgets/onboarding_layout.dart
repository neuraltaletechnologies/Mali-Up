import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';

/// Shared layout for the image + sheet onboarding/auth screens (language,
/// phone entry, PIN, create account, business details, …). Both widgets
/// go directly in the screen's root `Stack`, in place of the header-image
/// `Positioned` and the `DraggableScrollableSheet`.
///
/// - Phones: image across the top, form sheet rising from the bottom. The
///   sheet starts at [_phoneSheetSize] of the screen so a good part of the
///   image stays visible; drag or scroll it up to [_phoneSheetMax].
/// - Wide (laptop/desktop, tablet in landscape — [Responsive.isWide]): the
///   form is a floating rounded card on the right and the image fills the
///   rest of the screen at full height, so it is seen whole instead of as a
///   thin cropped strip.
class OnboardingLayout {
  OnboardingLayout._();

  static const double _phoneSheetSize = 0.58;
  static const double _phoneSheetMax = 0.8;

  /// Phone header-image height; reaches under the sheet's rounded top.
  static const double _phoneHeroFraction = 0.46;

  static const double _wideInset = 24;

  static double _wideCardWidth(Size size) =>
      (size.width * 0.42).clamp(380.0, 480.0);
}

/// The header image. [child] is the image itself (fills its box).
class OnboardingHero extends StatelessWidget {
  final Widget child;

  const OnboardingHero({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (Responsive.isWide(context)) {
      return Positioned(
        left: 0,
        top: 0,
        right: OnboardingLayout._wideCardWidth(size) +
            OnboardingLayout._wideInset * 2,
        bottom: 0,
        child: child,
      );
    }
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: size.height * OnboardingLayout._phoneHeroFraction,
      child: child,
    );
  }
}

/// The form. [builder] gets the scroll controller to hand to the content's
/// scroll view — same contract as [DraggableScrollableSheet.builder].
class OnboardingSheet extends StatefulWidget {
  final ScrollableWidgetBuilder builder;

  const OnboardingSheet({super.key, required this.builder});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  // Wide layout only; on phones DraggableScrollableSheet owns the controller.
  final _wideScroll = ScrollController();

  @override
  void dispose() {
    _wideScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isWide(context)) {
      return DraggableScrollableSheet(
        initialChildSize: OnboardingLayout._phoneSheetSize,
        minChildSize: OnboardingLayout._phoneSheetSize,
        maxChildSize: OnboardingLayout._phoneSheetMax,
        builder: widget.builder,
      );
    }
    final mq = MediaQuery.of(context);
    const inset = OnboardingLayout._wideInset;
    // Deliberately NOT a Positioned: a Stack takes its size from its
    // non-positioned children, and on phones the DraggableScrollableSheet
    // is what made it fill the screen. With the image positioned too, a
    // positioned card would shrink the Stack to the top button row (image
    // squashed into a strip, card zero height). SizedBox.expand keeps the
    // Stack full-screen; the card is then placed inside it.
    return SizedBox.expand(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            // Leave room above the card for the screen's back / help buttons.
            mq.padding.top + 72,
            inset,
            inset + mq.padding.bottom,
          ),
          child: SizedBox(
            width: OnboardingLayout._wideCardWidth(mq.size),
            height: double.infinity,
            child: _card(),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0D1B3E),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: widget.builder(context, _wideScroll),
      ),
    );
  }
}
