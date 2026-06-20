import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Counts currently-open modal bottom sheets.
/// The shell's bottom nav bar collapses to zero height while this is > 0.
final sheetOpenNotifier = ValueNotifier<int>(0);

/// Register this on the GoRouter (via [GoRouter.observers]) so that every
/// [ModalBottomSheetRoute] push/pop automatically updates [sheetOpenNotifier].
class AppSheetObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalBottomSheetRoute) {
      sheetOpenNotifier.value++;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalBottomSheetRoute) {
      sheetOpenNotifier.value = math.max(0, sheetOpenNotifier.value - 1);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalBottomSheetRoute) {
      sheetOpenNotifier.value = math.max(0, sheetOpenNotifier.value - 1);
    }
  }
}
