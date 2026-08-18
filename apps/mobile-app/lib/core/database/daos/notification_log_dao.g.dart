// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_log_dao.dart';

// ignore_for_file: type=lint
mixin _$NotificationLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotificationLogTableTable get notificationLogTable =>
      attachedDatabase.notificationLogTable;
  NotificationLogDaoManager get managers => NotificationLogDaoManager(this);
}

class NotificationLogDaoManager {
  final _$NotificationLogDaoMixin _db;
  NotificationLogDaoManager(this._db);
  $$NotificationLogTableTableTableManager get notificationLogTable =>
      $$NotificationLogTableTableTableManager(
        _db.attachedDatabase,
        _db.notificationLogTable,
      );
}
