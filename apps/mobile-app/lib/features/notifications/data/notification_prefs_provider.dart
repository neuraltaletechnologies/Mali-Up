import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/business_id_provider.dart';
import '../../../core/providers/sync_provider.dart';
import '../../../core/services/notification_prefs.dart';

/// Live per-category notification toggle state for the signed-in user.
final notificationPrefsProvider = StreamProvider<NotificationPrefs>((ref) {
  final dao = ref.watch(appDatabaseProvider).settingsDao;
  return dao
      .watchUserSettings()
      .map((row) => NotificationPrefs.fromJson(row?.notificationSettings ?? '{}'));
});

final notificationPrefsControllerProvider =
    Provider<NotificationPrefsController>((ref) {
  return NotificationPrefsController(ref);
});

class NotificationPrefsController {
  final Ref _ref;
  NotificationPrefsController(this._ref);

  Future<void> update(
    NotificationPrefs Function(NotificationPrefs current) transform,
  ) async {
    final db = _ref.read(appDatabaseProvider);
    final dao = db.settingsDao;
    final current = await dao.getUserSettings();
    final prefs = NotificationPrefs.fromJson(current?.notificationSettings ?? '{}');
    final next = transform(prefs);

    if (current == null) {
      // First-ever write to user_settings — userId/businessId are required
      // (NOT NULL, no default), so seed them along with the prefs blob.
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final bizId = _ref.read(currentBusinessIdProvider).valueOrNull ?? '';
      await dao.upsertUserSettings(
        UserSettingsTableCompanion.insert(
          userId: uid,
          businessId: bizId,
          notificationSettings: Value(next.toJson()),
        ),
      );
      return;
    }

    await dao.upsertUserSettings(
      UserSettingsTableCompanion(notificationSettings: Value(next.toJson())),
    );
  }
}
