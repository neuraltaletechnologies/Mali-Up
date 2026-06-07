// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_dao.dart';

// ignore_for_file: type=lint
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserSettingsTableTable get userSettingsTable =>
      attachedDatabase.userSettingsTable;
  $BusinessSettingsTableTable get businessSettingsTable =>
      attachedDatabase.businessSettingsTable;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.userSettingsTable,
      );
  $$BusinessSettingsTableTableTableManager get businessSettingsTable =>
      $$BusinessSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.businessSettingsTable,
      );
}
