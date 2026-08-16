import 'package:drift/drift.dart';

/// Local, device-only log of in-app alerts (low stock, overdue debts,
/// overdue invoices, sync failures). Never synced to Firestore — every
/// row here is re-derivable from data already on-device, so there is
/// nothing to push and nothing to pull.
class NotificationLogTable extends Table {
  @override
  String get tableName => 'notification_log';

  TextColumn get id => text()();
  TextColumn get businessId => text()();

  /// 'low_stock' | 'overdue_debt' | 'overdue_invoice' | 'sync_failure'
  TextColumn get type => text()();

  /// The inventory/debt/invoice id this alert refers to. Null for
  /// sync_failure, which is a single per-business row, not per-entity.
  TextColumn get entityId => text().nullable()();

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
