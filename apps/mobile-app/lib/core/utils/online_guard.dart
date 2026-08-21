import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../services/localization_service.dart';
import '../../shared/widgets/app_notification.dart';

/// Connectivity gate for flows that must not run while offline
/// (registration, team invites, plan payments, complex sale edits).
///
/// Core business CRUD — customers, inventory, sales, debts, expenses — must
/// NEVER use this guard: those writes go through the Drift + sync-queue
/// repositories and are expected to work fully offline.
class OnlineGuard {
  OnlineGuard._();

  /// Live connectivity check (does not depend on Riverpod being in scope).
  static Future<bool> isDeviceOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Returns true when the device is online. When offline, shows the
  /// "needs internet" notification and returns false.
  ///
  /// Prefer [runIfOnline] at the entry point of a flow (the button that
  /// opens a form) — checking here, deep inside a save/submit handler, only
  /// catches the case after the user has already spent time filling the
  /// form in. This method still exists as the underlying check and as a
  /// safety net for the rare case connectivity drops while a sheet is open.
  static Future<bool> ensureOnline(BuildContext context) async {
    if (await isDeviceOnline()) return true;
    if (context.mounted) {
      AppNotification.info(
        context,
        LocalizationService.tr(
          en: 'This action requires internet. Connect and try again.',
          sw: 'Hatua hii inahitaji intaneti. Unganisha mtandao kisha ujaribu tena.',
        ),
      );
    }
    return false;
  }

  /// Checks connectivity *before* starting an online-only flow, and only
  /// runs [action] if online. Use this to wrap the button/tap handler that
  /// opens a form or sheet for an online-only action (invite a team member,
  /// create an invoice, add a business, sign in, upgrade a plan…) so an
  /// offline user is told immediately — before typing anything — instead of
  /// finding out only after filling in the whole form and tapping Save.
  ///
  /// ```dart
  /// onPressed: () => OnlineGuard.runIfOnline(context, () => _showInviteSheet(context)),
  /// ```
  static Future<void> runIfOnline(
    BuildContext context,
    FutureOr<void> Function() action,
  ) async {
    if (!await ensureOnline(context)) return;
    await action();
  }
}
