import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_settings_table.dart';
import '../tables/business_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [UserSettingsTable, BusinessSettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  static const int _singleRowId = 1;

  // ─── User Settings ─────────────────────────────────────────────────────────

  Stream<UserSettingsTableData?> watchUserSettings() {
    return (select(userSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .watchSingleOrNull();
  }

  Future<UserSettingsTableData?> getUserSettings() {
    return (select(userSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .getSingleOrNull();
  }

  Future<void> upsertUserSettings(UserSettingsTableCompanion entry) async {
    await into(userSettingsTable).insertOnConflictUpdate(
      entry.copyWith(id: const Value(_singleRowId)),
    );
  }

  Future<void> updateLastSyncAt(int timestampMs) async {
    await (update(userSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .write(UserSettingsTableCompanion(lastSyncAt: Value(timestampMs)));
  }

  Future<void> updateLastOnlineAt(int timestampMs) async {
    await (update(userSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .write(
      UserSettingsTableCompanion(
        lastOnlineAt: Value(timestampMs),
        offlineSince: const Value(null),
      ),
    );
  }

  Future<void> setOfflineSince(int timestampMs) async {
    await (update(userSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .write(
      UserSettingsTableCompanion(offlineSince: Value(timestampMs)),
    );
  }

  Future<void> clearOfflineSince() async {
    await (update(userSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .write(
      const UserSettingsTableCompanion(offlineSince: Value(null)),
    );
  }

  // ─── Business Settings ─────────────────────────────────────────────────────

  Stream<BusinessSettingsTableData?> watchBusinessSettings() {
    return (select(businessSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .watchSingleOrNull();
  }

  Future<BusinessSettingsTableData?> getBusinessSettings() {
    return (select(businessSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .getSingleOrNull();
  }

  Future<void> upsertBusinessSettings(
    BusinessSettingsTableCompanion entry,
  ) async {
    await into(businessSettingsTable).insertOnConflictUpdate(
      entry.copyWith(id: const Value(_singleRowId)),
    );
  }

  Future<int> incrementAndGetNextInvoiceNumber() async {
    final settings = await getBusinessSettings();
    final next = (settings?.nextInvoiceNumber ?? 0) + 1;
    await (update(businessSettingsTable)
          ..where((t) => t.id.equals(_singleRowId)))
        .write(
      BusinessSettingsTableCompanion(nextInvoiceNumber: Value(next)),
    );
    return next;
  }
}
