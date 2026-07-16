import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../services/localization_service.dart';
import '../theme/app_colors.dart';

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
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.tealAccent,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    LocalizationService.tr(
                      en: 'This action requires internet. Connect and try again.',
                      sw: 'Hatua hii inahitaji intaneti. Unganisha mtandao kisha ujaribu tena.',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
    return false;
  }
}
