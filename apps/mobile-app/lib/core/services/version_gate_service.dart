import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Whether the running build should be blocked, nagged, or left alone,
/// based on the remote `platform_config/version_gate` doc.
enum VersionGateTier { ok, softNag, hardBlock }

class VersionGateStatus {
  final VersionGateTier tier;
  final String messageEn;
  final String messageSw;
  final String updateUrlAndroid;
  final String updateUrlIOS;
  // Carried through so the soft-nag banner can key its "dismissed until"
  // SharedPreferences state off the specific version being recommended,
  // rather than dismissing forever.
  final int? recommendedBuildNumber;

  const VersionGateStatus({
    required this.tier,
    this.messageEn = '',
    this.messageSw = '',
    this.updateUrlAndroid = '',
    this.updateUrlIOS = '',
    this.recommendedBuildNumber,
  });

  static const ok = VersionGateStatus(tier: VersionGateTier.ok);
}

/// Checks the current build against a remotely-configured minimum/recommended
/// build number, so users on old app builds can be blocked or nudged to
/// update instead of writing incompatible data to Firestore indefinitely.
///
/// Fail-open by design: any error, missing doc, or timeout resolves to
/// [VersionGateStatus.ok] so a bad config push or offline device never
/// bricks the app — Drift remains the source of truth regardless of this
/// check's outcome.
class VersionGateService {
  VersionGateService._();

  static final ValueNotifier<VersionGateStatus> statusNotifier =
      ValueNotifier<VersionGateStatus>(VersionGateStatus.ok);

  /// Fire-and-forget from app startup. Must never block or throw into the
  /// caller — failures just leave [statusNotifier] at its `ok` default.
  static Future<void> initialize() async {
    try {
      final status = await _check().timeout(const Duration(seconds: 6));
      statusNotifier.value = status;
    } catch (_) {
      // Offline, timed out, or malformed doc — fail open.
    }
  }

  static Future<VersionGateStatus> _check() async {
    final doc = await FirebaseFirestore.instance
        .collection('platform_config')
        .doc('version_gate')
        .get();
    if (!doc.exists) return VersionGateStatus.ok;

    final data = doc.data()!;
    final minBuild = _asInt(data['minSupportedBuildNumber']);
    final recommendedBuild = _asInt(data['recommendedBuildNumber']);
    if (minBuild == null && recommendedBuild == null) {
      return VersionGateStatus.ok;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber);
    if (currentBuild == null) return VersionGateStatus.ok;

    final tier = (minBuild != null && currentBuild < minBuild)
        ? VersionGateTier.hardBlock
        : (recommendedBuild != null && currentBuild < recommendedBuild)
            ? VersionGateTier.softNag
            : VersionGateTier.ok;
    if (tier == VersionGateTier.ok) return VersionGateStatus.ok;

    return VersionGateStatus(
      tier: tier,
      messageEn: (data['messageEn'] as String?) ?? '',
      messageSw: (data['messageSw'] as String?) ?? '',
      updateUrlAndroid: (data['updateUrlAndroid'] as String?) ?? '',
      updateUrlIOS: (data['updateUrlIOS'] as String?) ?? '',
      recommendedBuildNumber: recommendedBuild,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
