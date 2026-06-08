import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/settings_dao.dart';

/// Tracks how long the device has been offline and enforces policy thresholds.
///
/// < 24 h  → normal; banner shows pending-count warning
/// 24–48 h → warning; banner escalates
/// > 48 h  → restriction mode: write operations are blocked (read-only)
///
/// The [offlineSince] timestamp is persisted in Drift so it survives app
/// restarts and battery loss. SyncService clears it on every successful sync.
class OfflinePolicyNotifier extends ChangeNotifier {
  final SettingsDao _settings;

  DateTime? _offlineSince;
  bool _initialized = false;

  OfflinePolicyNotifier({required AppDatabase db})
      : _settings = db.settingsDao;

  /// Must be called once after the DB is open (typically from SyncProvider).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final row = await _settings.getUserSettings();
    if (row?.offlineSince != null) {
      _offlineSince =
          DateTime.fromMillisecondsSinceEpoch(row!.offlineSince!);
    }
    notifyListeners();
  }

  /// Called by SyncService when connectivity is lost.
  Future<void> markOffline() async {
    if (_offlineSince != null) return; // already tracking
    _offlineSince = DateTime.now();
    await _settings.setOfflineSince(_offlineSince!.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// Called by SyncService after a successful sync cycle.
  Future<void> markOnline() async {
    _offlineSince = null;
    await _settings.clearOfflineSince();
    notifyListeners();
  }

  // ─── State queries ────────────────────────────────────────────────────────

  DateTime? get offlineSince => _offlineSince;

  bool get isOffline => _offlineSince != null;

  Duration get offlineDuration {
    if (_offlineSince == null) return Duration.zero;
    return DateTime.now().difference(_offlineSince!);
  }

  OfflineLevel get level {
    final h = offlineDuration.inHours;
    if (h >= 48) return OfflineLevel.restricted;
    if (h >= 24) return OfflineLevel.warning;
    return OfflineLevel.normal;
  }

  /// Throws [OfflineRestrictionException] if the device has been offline for
  /// more than 48 hours. Call this from every write operation in the
  /// SyncRepository layer.
  void assertCanWrite() {
    if (level == OfflineLevel.restricted) {
      throw const OfflineRestrictionException();
    }
  }
}

enum OfflineLevel { normal, warning, restricted }

/// Thrown when a write is attempted after 48 hours offline.
/// The UI catches this and shows the OfflineRestrictionScreen.
class OfflineRestrictionException implements Exception {
  const OfflineRestrictionException();

  @override
  String toString() =>
      'OfflineRestrictionException: writes blocked after 48 h offline';
}
