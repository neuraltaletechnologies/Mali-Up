import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Publishes the height of the shell's floating pill nav bar to descendants.
///
/// `MainShellPage` uses `extendBody: true`, so screen bodies extend behind the
/// bottom nav. Scaffold injects the nav height into the body's
/// `MediaQuery.padding.bottom`, but it also *strips* all MediaQuery padding
/// from every `floatingActionButton` slot, so a FAB can never read that value
/// directly. The shell instead wraps its body in this inherited widget, which
/// survives the slot's MediaQuery rewrite.
class NavBarLift extends InheritedWidget {
  /// Total bottom overlap of the shell nav, including the device safe area.
  final double lift;

  const NavBarLift({super.key, required this.lift, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavBarLift>()?.lift ?? 0.0;

  @override
  bool updateShouldNotify(NavBarLift oldWidget) => lift != oldWidget.lift;
}

/// Lifts a floating action button clear of the shell's floating pill nav bar.
///
/// The FAB already clears the device safe area (`viewPadding.bottom`) on its
/// own, so only the remainder of the nav overlap is added. On screens shown
/// without the shell nav there is no [NavBarLift] ancestor and this is a
/// no-op, and while the keyboard covers the nav the lift collapses as well.
class NavAwareFab extends StatelessWidget {
  final Widget child;

  const NavAwareFab({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final lift = math.max(
      0.0,
      NavBarLift.of(context) -
          math.max(mq.viewPadding.bottom, mq.viewInsets.bottom),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: lift),
      child: child,
    );
  }
}
