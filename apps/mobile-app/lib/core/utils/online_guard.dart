import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../services/localization_service.dart';

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

  /// Returns true when the device is online. When offline, shows a bilingual
  /// snackbar explaining that the action needs internet and returns false.
  static Future<bool> ensureOnline(BuildContext context) async {
    if (await isDeviceOnline()) return true;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LocalizationService.tr(
          en: 'This action needs an internet connection. '
              'Connect and try again.',
          sw: 'Hatua hii inahitaji intaneti. '
              'Unganisha mtandao kisha ujaribu tena.',
        )),
      ));
    }
    return false;
  }
}
