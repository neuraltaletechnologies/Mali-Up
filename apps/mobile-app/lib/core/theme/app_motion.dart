import 'package:flutter/material.dart';

import '../services/motion_service.dart';

/// Mali Up's motion language.
///
/// Primary destinations use a restrained fade-through, while routes pushed
/// deeper into the information hierarchy use a horizontal shared axis.
/// Motion is removed when either the in-app preference or the platform
/// accessibility preference requests it.
abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration emphasized = Duration(milliseconds: 300);
  static const Duration reverse = Duration(milliseconds: 220);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  static bool reduceMotion(BuildContext context) {
    final platformReduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MotionService.reducedMotionNotifier.value || platformReduced;
  }

  static Widget fadeThrough(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion(context)) return child;

    final enter = CurvedAnimation(parent: animation, curve: enterCurve);
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: exitCurve);

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(enter),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(enter),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(exit),
          child: child,
        ),
      ),
    );
  }

  static Widget sharedAxisHorizontal(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion(context)) return child;

    final enter = CurvedAnimation(parent: animation, curve: enterCurve);
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: exitCurve);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(enter),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(enter),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.02, 0),
          ).animate(exit),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.92).animate(exit),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget rise(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion(context)) return child;

    final enter = CurvedAnimation(parent: animation, curve: enterCurve);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(enter),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(enter),
        child: child,
      ),
    );
  }

  static Widget celebration(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion(context)) return child;

    final enter = CurvedAnimation(parent: animation, curve: enterCurve);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(enter),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(enter),
        child: child,
      ),
    );
  }

  static PageRoute<T> detailRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: standard,
      reverseTransitionDuration: reverse,
      transitionsBuilder: sharedAxisHorizontal,
    );
  }

  static PageRoute<T> taskRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      reverseTransitionDuration: reverse,
      transitionsBuilder: rise,
      fullscreenDialog: true,
    );
  }

  static PageRoute<T> celebrationRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      reverseTransitionDuration: reverse,
      transitionsBuilder: celebration,
    );
  }
}

/// Applies Mali Up hierarchy motion to ordinary [MaterialPageRoute] pushes.
class MaliPageTransitionsBuilder extends PageTransitionsBuilder {
  const MaliPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.standard;

  @override
  Duration get reverseTransitionDuration => AppMotion.reverse;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppMotion.sharedAxisHorizontal(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
