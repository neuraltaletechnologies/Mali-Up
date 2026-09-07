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
  // The recommended version string (normalised "x.y.z"), carried through so
  // the soft-nag banner can key its "dismissed until" SharedPreferences state
  // off the specific version being recommended rather than dismissing forever.
  final String? recommendedVersion;

  const VersionGateStatus({
    required this.tier,
    this.messageEn = '',
    this.messageSw = '',
    this.updateUrlAndroid = '',
    this.updateUrlIOS = '',
    this.recommendedVersion,
  });

  static const ok = VersionGateStatus(tier: VersionGateTier.ok);
}

/// Checks the running app's version name against a remotely-configured
/// minimum/recommended version, so users on old builds can be blocked or
/// nudged to update instead of writing incompatible data to Firestore
/// indefinitely.
///
/// The comparison is on the **version name** (`pubspec.yaml`'s `version:`
/// minus the `+build` suffix — e.g. `1.1.2`), which is what users see in the
/// store and what an admin types into the portal's Version Gate page. The
/// Android `versionCode` is deliberately not used: CI stamps it with
/// epoch-minutes, so it carries no human-meaningful ordering.
///
/// Fail-open by design: any error, missing doc, unparseable version, or
/// timeout resolves to [VersionGateStatus.ok] so a bad config push or offline
/// device never bricks the app — Drift remains the source of truth regardless
/// of this check's outcome.
class VersionGateService {
  VersionGateService._();

  static final ValueNotifier<VersionGateStatus> statusNotifier =
      ValueNotifier<VersionGateStatus>(VersionGateStatus.ok);

  /// Fire-and-forget from app startup (and again on resume). Must never block
  /// or throw into the caller — failures just leave [statusNotifier] at its
  /// last value (`ok` by default). Safe to call repeatedly.
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
    final minVersion = _parseVersion(data['minSupportedVersion']);
    final recommendedVersion = _parseVersion(data['recommendedVersion']);
    if (minVersion == null && recommendedVersion == null) {
      return VersionGateStatus.ok;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = _parseVersion(packageInfo.version);
    if (currentVersion == null) return VersionGateStatus.ok;

    final tier = (minVersion != null && _compare(currentVersion, minVersion) < 0)
        ? VersionGateTier.hardBlock
        : (recommendedVersion != null &&
                _compare(currentVersion, recommendedVersion) < 0)
            ? VersionGateTier.softNag
            : VersionGateTier.ok;
    if (tier == VersionGateTier.ok) return VersionGateStatus.ok;

    return VersionGateStatus(
      tier: tier,
      messageEn: (data['messageEn'] as String?) ?? '',
      messageSw: (data['messageSw'] as String?) ?? '',
      updateUrlAndroid: (data['updateUrlAndroid'] as String?) ?? '',
      updateUrlIOS: (data['updateUrlIOS'] as String?) ?? '',
      recommendedVersion:
          recommendedVersion == null ? null : _format(recommendedVersion),
    );
  }

  /// Parses a dotted version ("1.2.3", "1.2", "1") into a `[major, minor,
  /// patch]` triple, ignoring any pre-release or build suffix ("1.2.3-beta",
  /// "1.2.3+4"). Returns null when there is no leading number to read, which
  /// callers treat as "don't gate".
  @visibleForTesting
  static List<int>? parseVersion(Object? value) => _parseVersion(value);

  static List<int>? _parseVersion(Object? value) {
    if (value is! String) return null;
    final core = value.trim().split(RegExp(r'[-+ ]')).first;
    if (core.isEmpty) return null;
    final parts = core.split('.');
    final out = <int>[0, 0, 0];
    var sawNumber = false;
    for (var i = 0; i < 3 && i < parts.length; i++) {
      final n = int.tryParse(parts[i]);
      if (n == null) break;
      out[i] = n;
      sawNumber = true;
    }
    return sawNumber ? out : null;
  }

  static int _compare(List<int> a, List<int> b) {
    for (var i = 0; i < 3; i++) {
      final d = a[i].compareTo(b[i]);
      if (d != 0) return d;
    }
    return 0;
  }

  static String _format(List<int> v) => '${v[0]}.${v[1]}.${v[2]}';
}
