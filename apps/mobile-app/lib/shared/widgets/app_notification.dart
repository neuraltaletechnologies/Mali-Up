import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Severity of an [AppNotification]. Each maps to a fixed background color
/// so meaning is always readable at a glance, everywhere in the app.
enum AppNotificationType { info, success, error, warning }

/// The single reusable "toast" used for every transient notification in the
/// app — success confirmations, errors, warnings, and neutral status
/// updates (e.g. "Importing 5 contacts…", "This action needs internet").
///
/// Deliberately NOT built on `ScaffoldMessenger`/`SnackBar`: a SnackBar is
/// painted into the Overlay entry of whichever Scaffold's route is behind
/// it, so it renders *underneath* a modal bottom sheet (sheets are pushed
/// as their own, later route — see [showAppSheet]'s `useRootNavigator`).
/// That made every notification fired while a sheet was open invisible.
/// This instead inserts directly into the app's root [Overlay], the same
/// one sheets are pushed onto, so a freshly-shown notification always
/// paints on top of whatever is currently open, sheet included.
class AppNotification {
  AppNotification._();

  static const Duration _defaultDuration = Duration(seconds: 4);
  static const Duration _transitionDuration = Duration(milliseconds: 220);

  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;
  static _AppToastState? _currentState;

  static Color _backgroundFor(AppNotificationType type) => switch (type) {
    AppNotificationType.info => AppColors.secondary, // navy — app default
    AppNotificationType.success => AppColors.success,
    AppNotificationType.error => AppColors.error,
    AppNotificationType.warning => AppColors.warning,
  };

  static IconData? _iconFor(AppNotificationType type) => switch (type) {
    AppNotificationType.info => null,
    AppNotificationType.success => Icons.check_circle_rounded,
    AppNotificationType.error => Icons.error_rounded,
    AppNotificationType.warning => Icons.warning_amber_rounded,
  };

  /// Shows a notification card. Safe to call fire-and-forget; no-ops if
  /// [context] is no longer mounted or has no [Overlay] ancestor.
  ///
  /// [type] picks the background color and default icon. Pass [icon] to
  /// override the default icon (or [showIcon]=false to force none), and
  /// [action] for an optional trailing button (e.g. "Retry", "Undo").
  static void show(
    BuildContext context,
    String message, {
    AppNotificationType type = AppNotificationType.info,
    Duration? duration,
    IconData? icon,
    bool showIcon = true,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    showVia(
      overlay,
      message,
      type: type,
      duration: duration,
      icon: icon,
      showIcon: showIcon,
      action: action,
    );
  }

  /// Same as [show], but takes an already-resolved [OverlayState] instead
  /// of a [BuildContext] — for flows that capture the overlay before a
  /// `Navigator.pop` (or before handing off to a detached background task)
  /// so the notification still lands after the context that triggered it
  /// is gone. Capture with `Overlay.of(context, rootOverlay: true)`.
  static void showVia(
    OverlayState overlay,
    String message, {
    AppNotificationType type = AppNotificationType.info,
    Duration? duration,
    IconData? icon,
    bool showIcon = true,
    SnackBarAction? action,
  }) {
    _dismissCurrent();

    final resolvedIcon = showIcon ? (icon ?? _iconFor(type)) : null;
    final resolvedDuration = duration ?? _defaultDuration;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppToast(
        message: message,
        background: _backgroundFor(type),
        icon: resolvedIcon,
        action: action,
        onStateCreated: (state) => _currentState = state,
        onDismissed: () {
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
            _currentState = null;
          }
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
    _currentTimer = Timer(resolvedDuration, () => _currentState?.dismiss());
  }

  static void _dismissCurrent() {
    _currentTimer?.cancel();
    _currentTimer = null;
    // Remove instantly (no exit animation) — a new notification is about to
    // take its place immediately, mirroring hideCurrentSnackBar() before
    // showing the next one.
    _currentEntry?.remove();
    _currentEntry = null;
    _currentState = null;
  }

  /// Neutral status update — navy background, no icon by default. This is
  /// the app's default notification look (e.g. "Importing 5 contacts…").
  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
    SnackBarAction? action,
  }) => show(
    context,
    message,
    duration: duration,
    icon: icon,
    showIcon: icon != null,
    action: action,
  );

  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    context,
    message,
    type: AppNotificationType.success,
    duration: duration,
    action: action,
  );

  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    context,
    message,
    type: AppNotificationType.error,
    duration: duration,
    action: action,
  );

  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    context,
    message,
    type: AppNotificationType.warning,
    duration: duration,
    action: action,
  );

  /// Hides whatever notification is currently showing, if any.
  static void hide(BuildContext context) => _currentState?.dismiss();
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast widget — animates itself in/out; positioned above everything else
// via the root Overlay, including any open modal bottom sheet.
// ─────────────────────────────────────────────────────────────────────────────

class _AppToast extends StatefulWidget {
  final String message;
  final Color background;
  final IconData? icon;
  final SnackBarAction? action;
  final ValueChanged<_AppToastState> onStateCreated;
  final VoidCallback onDismissed;

  const _AppToast({
    required this.message,
    required this.background,
    required this.icon,
    required this.action,
    required this.onStateCreated,
    required this.onDismissed,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast> {
  bool _visible = false;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void dismiss() {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    setState(() => _visible = false);
    Future.delayed(AppNotification._transitionDuration, widget.onDismissed);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = (media.viewInsets.bottom > 0
            ? media.viewInsets.bottom
            : media.padding.bottom) +
        16;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomInset,
      child: SafeArea(
        top: false,
        bottom: false,
        child: IgnorePointer(
          ignoring: !_visible,
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, 0.25),
            duration: AppNotification._transitionDuration,
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: AppNotification._transitionDuration,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: dismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: widget.background,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: AppColors.inverseText,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.dmSans(
                              color: AppColors.inverseText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (widget.action != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              widget.action!.onPressed();
                              dismiss();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  widget.action!.textColor ??
                                  AppColors.inverseText,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              widget.action!.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
