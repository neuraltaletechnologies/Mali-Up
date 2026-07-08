import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Counts currently-open modal bottom sheets.
/// The shell's bottom nav bar collapses to zero height while this is > 0.
final sheetOpenNotifier = ValueNotifier<int>(0);

/// Shows a bottom sheet capped at 80 % of the screen height.
/// Use this everywhere instead of [showModalBottomSheet] directly.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  Color backgroundColor = Colors.transparent,
  bool showDragHandle = false,
  ShapeBorder? shape,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // Attach to the root Navigator, not the nearest one. Screens like
    // ManageBusinessesScreen live inside a ShellRoute's own nested Navigator,
    // and GoRouter reconciles that Navigator's page stack on every redirect
    // (system back button included). If the sheet were pushed onto that same
    // nested Navigator, a back-button pop could tear down the underlying
    // page's Elements while the sheet's subtree above it is still live,
    // tripping the `_dependents.isEmpty` assertion in InheritedElement.
    useRootNavigator: true,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    showDragHandle: showDragHandle,
    shape: shape,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    builder: builder,
  );
}

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
