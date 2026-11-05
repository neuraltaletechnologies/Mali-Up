import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/utils/responsive.dart';

/// Counts currently-open modal bottom sheets.
/// The shell's bottom nav bar collapses to zero height while this is > 0.
final sheetOpenNotifier = ValueNotifier<int>(0);

/// The single app-wide cap for every slide-up sheet: 80 % of the screen
/// height. Kept as one constant (rather than a per-call parameter) so every
/// sheet stops at the same line regardless of who opens it.
const double kAppSheetMaxHeightFactor = 0.8;

/// Width of the right-hand side panel that replaces slide-up sheets on wide
/// screens (see [showAppSheet]).
const double kAppSidePanelWidth = 460;

/// Tells sheet content how it is being presented, so the few sheets that
/// care (drag handle, bottom alignment, drag-to-resize) can adapt.
class AppSheetScope extends InheritedWidget {
  /// True when shown as the wide-screen side panel rather than a bottom sheet.
  final bool isSidePanel;

  const AppSheetScope({
    super.key,
    required this.isSidePanel,
    required super.child,
  });

  static bool isSidePanelOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppSheetScope>()
          ?.isSidePanel ??
      false;

  @override
  bool updateShouldNotify(AppSheetScope oldWidget) =>
      isSidePanel != oldWidget.isSidePanel;
}

/// Shows a sheet. Use this everywhere instead of [showModalBottomSheet].
///
/// - Phones: a bottom sheet capped at [kAppSheetMaxHeightFactor] of the
///   screen height.
/// - Wide screens (laptop, desktop, tablet in landscape —
///   [Responsive.isWide]): the same content slides in from the right as a
///   full-height side panel next to the page, instead of rising from the
///   bottom. Closing works the same (`Navigator.pop(context, result)`), and
///   clicking the page beside it closes it.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  Color backgroundColor = Colors.transparent,
  bool showDragHandle = false,
  ShapeBorder? shape,
}) {
  if (Responsive.isWide(context)) {
    return _showSidePanel<T>(
      context,
      builder: builder,
      backgroundColor: backgroundColor,
    );
  }
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
      maxHeight: MediaQuery.sizeOf(context).height * kAppSheetMaxHeightFactor,
    ),
    builder: builder,
  );
}

Future<T?> _showSidePanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required Color backgroundColor,
}) {
  final reduceMotion = AppMotion.reduceMotion(context);
  return showGeneralDialog<T>(
    context: context,
    // showGeneralDialog already uses the root navigator, as the bottom sheet
    // above does on purpose.
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // A faint tint only: the page stays readable beside the panel so it
    // reads as part of the same screen, not a popup over it.
    barrierColor: const Color(0x140D1B3E),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260),
    transitionBuilder: (context, animation, _, child) {
      if (reduceMotion) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
    pageBuilder: (dialogContext, _, _) {
      final mq = MediaQuery.of(dialogContext);
      // Flush to the right edge and full height — a real side sheet, not a
      // floating card — rounded only on its inner (left) corners.
      final width = math.min(kAppSidePanelWidth, mq.size.width * 0.9);
      final contentHeight = mq.size.height - mq.padding.vertical;
      final panelColor = backgroundColor == Colors.transparent
          ? Colors.white
          : backgroundColor;
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: width,
          height: mq.size.height,
          child: Material(
            color: panelColor,
            clipBehavior: Clip.antiAlias,
            elevation: 12,
            shadowColor: const Color(0x330D1B3E),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            child: Padding(
              // Keep content clear of the status bar / system nav while the
              // panel's surface itself runs edge to edge.
              padding: EdgeInsets.only(
                top: mq.padding.top,
                bottom: mq.padding.bottom,
              ),
              child: MediaQuery(
                // Sheet content sizes itself from MediaQuery (e.g. "80 % of
                // the screen height", "full screen width"). Report the
                // panel's own size so those maths land inside the panel.
                data: mq.copyWith(
                  size: Size(width, contentHeight),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: AppSheetScope(
                  isSidePanel: true,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Builder(builder: builder),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
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
