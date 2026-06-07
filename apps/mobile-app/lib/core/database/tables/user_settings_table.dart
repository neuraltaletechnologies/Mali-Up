import 'package:drift/drift.dart';

class UserSettingsTable extends Table {
  @override
  String get tableName => 'user_settings';

  // Always a single row with id = 1
  IntColumn get id => integer()();
  TextColumn get userId => text()();
  TextColumn get businessId => text()();
  // unix ms of the last successful sync — null = never synced
  IntColumn get lastSyncAt => integer().nullable()();
  // unix ms of the last moment the device had connectivity
  IntColumn get lastOnlineAt => integer().nullable()();
  // unix ms when connectivity was lost — null means currently online
  IntColumn get offlineSince => integer().nullable()();
  // 1 = only sync on WiFi, 0 = sync on any connection
  IntColumn get syncOnWifiOnly =>
      integer().withDefault(const Constant(0))();
  // seconds between automatic background sync attempts
  IntColumn get autoSyncInterval =>
      integer().withDefault(const Constant(30))();
  TextColumn get language => text().withDefault(const Constant('sw'))();
  // JSON blob for push/sound notification preferences
  TextColumn get notificationSettings =>
      text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
