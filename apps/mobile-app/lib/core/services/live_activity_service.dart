import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

import '../sync/sync_service.dart';

/// Drives the iOS Dynamic Island Live Activity that mirrors the app's sync state.
///
/// Lifecycle:
///   1. Call [initialize] once at app start (no-op on Android).
///   2. Call [onSyncStateChanged] whenever [SyncState] changes.
///   3. The activity auto-ends a few seconds after sync completes or errors.
class LiveActivityService {
  static const _appGroupId  = 'group.com.neuraltale.maliup';
  static const _activityKey = 'maliup_sync';

  final _plugin = LiveActivities();

  bool   _initialized = false;
  Timer? _autoEndTimer;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (!Platform.isIOS) return;
    try {
      await _plugin.init(appGroupId: _appGroupId);
      _initialized = true;
      debugPrint('[LiveActivity] initialized');
    } catch (e) {
      debugPrint('[LiveActivity] init failed: $e');
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> onSyncStateChanged(
    SyncState state, {
    String businessName = '',
  }) async {
    if (!_initialized) return;
    _autoEndTimer?.cancel();

    switch (state) {
      case SyncState.syncing:
        await _upsert(status: 'syncing', businessName: businessName);

      case SyncState.idle:
        await _upsert(status: 'done', businessName: businessName);
        _autoEndTimer = Timer(const Duration(seconds: 3), _endAll);

      case SyncState.error:
        await _upsert(status: 'error', businessName: businessName);
        _autoEndTimer = Timer(const Duration(seconds: 5), _endAll);

      case SyncState.offline:
        await _endAll();
    }
  }

  Future<void> dispose() async {
    _autoEndTimer?.cancel();
    await _endAll();
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  Future<void> _upsert({
    required String status,
    required String businessName,
  }) async {
    try {
      await _plugin.createOrUpdateActivity(
        _activityKey,
        {'status': status, 'businessName': businessName},
      );
      debugPrint('[LiveActivity] upsert → $status');
    } catch (e) {
      debugPrint('[LiveActivity] upsert failed: $e');
    }
  }

  Future<void> _endAll() async {
    try {
      await _plugin.endAllActivities();
      await _plugin.dispose();
      debugPrint('[LiveActivity] ended all');
    } catch (e) {
      debugPrint('[LiveActivity] end failed: $e');
    }
  }
}
