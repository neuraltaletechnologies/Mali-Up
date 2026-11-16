import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/business_id_provider.dart';
import '../../../core/providers/sync_provider.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../rbac/data/rbac_providers.dart' show userProfileStreamProvider;

/// Pulls admin broadcasts the admin chose to keep in the in-app inbox
/// (`inbox_broadcasts`, written by the `sendAdminBroadcast` Cloud Function)
/// into the local notification log, so they show under the bell.
///
/// Pull, not "log on push receipt": a push the user swiped away, or one sent
/// while the device was off, still lands in the inbox, and desktop/web builds
/// (no FCM) get broadcasts too. A broadcast sent with "keep in inbox" off has
/// no `inbox_broadcasts` doc, so it is tray-only.
///
/// Runs when the active business is known, on app resume, and whenever a
/// push marked `saveToInbox` arrives. A per-business cursor (last seen
/// `createdAt`) keeps each pull to just the new docs.
class BroadcastInboxSync {
  BroadcastInboxSync._();

  /// How far back a business's very first pull looks.
  static const _firstPullLookback = Duration(days: 30);
  static const _pageSize = 50;
  static const _minInterval = Duration(minutes: 2);

  static final Map<String, DateTime> _lastRun = {};
  static final Set<String> _running = {};

  static String _cursorKey(String businessId) =>
      'broadcast_inbox_cursor_$businessId';

  static Future<void> pull(
    Ref ref, {
    required String businessId,
    required bool isOwner,
    bool force = false,
  }) async {
    if (businessId.isEmpty || _running.contains(businessId)) return;
    final last = _lastRun[businessId];
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minInterval) {
      return;
    }
    _running.add(businessId);
    _lastRun[businessId] = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      var cursorMs = prefs.getInt(_cursorKey(businessId)) ??
          DateTime.now().subtract(_firstPullLookback).millisecondsSinceEpoch;
      final dao = ref.read(appDatabaseProvider).notificationLogDao;
      final isSwahili =
          LocalizationService.languageNotifier.value == AppLanguage.swahili;

      while (true) {
        final snap = await FirebaseFirestore.instance
            .collection('inbox_broadcasts')
            .where('targets', arrayContainsAny: ['all', 'biz_$businessId'])
            .where(
              'createdAt',
              isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(cursorMs),
            )
            .orderBy('createdAt')
            .limit(_pageSize)
            .get()
            .timeout(const Duration(seconds: 20));

        for (final doc in snap.docs) {
          final d = doc.data();
          final createdAt = d['createdAt'];
          if (createdAt is! Timestamp) continue;
          cursorMs = createdAt.millisecondsSinceEpoch;
          // Owner-only (billing/plan) messages skip team members.
          if (d['ownersOnly'] == true && !isOwner) continue;

          final titleEn = (d['titleEn'] as String?) ?? '';
          final bodyEn = (d['bodyEn'] as String?) ?? '';
          final titleSw = (d['titleSw'] as String?)?.trim() ?? '';
          final bodySw = (d['bodySw'] as String?)?.trim() ?? '';
          final route = (d['route'] as String?)?.trim();
          await dao.insertBroadcastIfAbsent(
            businessId: businessId,
            broadcastId: doc.id,
            title: isSwahili && titleSw.isNotEmpty ? titleSw : titleEn,
            body: isSwahili && bodySw.isNotEmpty ? bodySw : bodyEn,
            route: route != null && route.startsWith('/') ? route : null,
            createdAt: cursorMs,
          );
        }
        await prefs.setInt(_cursorKey(businessId), cursorMs);
        if (snap.docs.length < _pageSize) break;
      }
    } catch (e) {
      // Offline / index still building — the next trigger retries from the
      // saved cursor, so nothing is skipped.
      _lastRun.remove(businessId);
      debugPrint('[BroadcastInboxSync] $e');
    } finally {
      _running.remove(businessId);
    }
  }
}

/// Activation hook — watch once in the authenticated shell, next to
/// notificationAggregatorActivatorProvider.
final broadcastInboxSyncActivatorProvider = Provider<void>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (businessId.isEmpty) return;
  final profileAsync = ref.watch(userProfileStreamProvider);
  // Wait for the profile so an owner-only message isn't skipped (cursor
  // advanced past it) while we briefly can't tell owner from team member.
  if (profileAsync.isLoading && !profileAsync.hasValue) return;
  final isOwner = profileAsync.valueOrNull?['isTeamMember'] != true;

  void run({bool force = false}) => unawaited(
        BroadcastInboxSync.pull(
          ref,
          businessId: businessId,
          isOwner: isOwner,
          force: force,
        ),
      );

  run(force: true);

  final lifecycle = AppLifecycleListener(onResume: run);
  final sub = PushNotificationService.inboxBroadcastStream
      .listen((_) => run(force: true));
  ref.onDispose(() {
    lifecycle.dispose();
    sub.cancel();
  });
});
