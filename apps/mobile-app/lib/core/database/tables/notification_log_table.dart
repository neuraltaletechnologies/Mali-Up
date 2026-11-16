import 'package:drift/drift.dart';

/// Local, device-only log of in-app alerts (low stock, overdue debts,
/// overdue invoices, sync failures) plus admin broadcasts the admin chose
/// to keep in the inbox. Never pushed to Firestore: alerts are re-derivable
/// from data already on-device, and broadcasts are pulled read-only from
/// `inbox_broadcasts` (see broadcast_inbox_sync.dart).
class NotificationLogTable extends Table {
  @override
  String get tableName => 'notification_log';

  TextColumn get id => text()();
  TextColumn get businessId => text()();

  /// 'low_stock' | 'overdue_debt' | 'overdue_invoice' | 'sync_failure' |
  /// 'broadcast'
  TextColumn get type => text()();

  /// The inventory/debt/invoice id this alert refers to, or the broadcast
  /// id. Null for sync_failure, which is a single per-business row, not
  /// per-entity.
  TextColumn get entityId => text().nullable()();

  /// In-app route to open on tap (broadcasts only; alerts route by [type]).
  TextColumn get route => text().nullable()();

  TextColumn get title => text()();
  TextColumn get body => text()();

  // 0 = unread, 1 = read
  IntColumn get isRead => integer().withDefault(const Constant(0))();

  // unix ms — first time this condition was detected
  IntColumn get createdAt => integer()();
  // unix ms — last time this row was refreshed by a reconciliation pass
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
