import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/business_id_provider.dart';
import '../../../core/providers/sync_provider.dart';

/// Live list of all notification-log rows for the active business, newest
/// first. Backed by Drift — works fully offline.
final notificationLogListProvider =
    StreamProvider<List<NotificationLogTableData>>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (businessId.isEmpty) return Stream.value(const []);
  return ref.watch(appDatabaseProvider).notificationLogDao.watchAll(businessId);
});

/// Live unread count — drives the bell badge and "Mark all read" enabling.
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (businessId.isEmpty) return Stream.value(0);
  return ref
      .watch(appDatabaseProvider)
      .notificationLogDao
      .watchUnreadCount(businessId);
});
