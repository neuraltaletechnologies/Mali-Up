import 'dart:ui';

import 'package:flutter/material.dart';

/// Lets lists be dragged with the mouse (click and drag up/down) as well as
/// with touch, the trackpad and the scroll wheel. Flutter's default only
/// drags on touch, so on the Windows desktop build a click-drag did nothing.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}
