import 'package:flutter/widgets.dart';

/// Wraps an onboarding step so the Android hardware back button runs the
/// same action as the on-screen back arrow.
///
/// Every onboarding screen is a top-level `context.go()` route with no
/// navigation stack behind it, so without this the system back button falls
/// straight through to closing the app instead of stepping back through the
/// flow.
class OnboardingBackHandler extends StatelessWidget {
  const OnboardingBackHandler({
    super.key,
    required this.onBack,
    required this.child,
  });

  /// Invoked when the user presses the system back button. Pass `null` to
  /// swallow the gesture entirely (terminal steps such as the success
  /// screen, where there is nowhere sensible to go back to).
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBack?.call();
      },
      child: child,
    );
  }
}
