import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notification_log_table.dart';

part 'notification_log_dao.g.dart';

@DriftAccessor(tables: [NotificationLogTable])
class NotificationLogDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationLogDaoMixin {
  NotificationLogDao(super.db);

  // ─── Watches ───────────────────────────────────────────────────────────────

  Stream<List<NotificationLogTableData>> watchAll(String businessId) {
    return (select(notificationLogTable)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<int> watchUnreadCount(String businessId) {
    final countExpr = notificationLogTable.id.count();
    return (selectOnly(notificationLogTable)
          ..addColumns([countExpr])
          ..where(
            notificationLogTable.businessId.equals(businessId) &
                notificationLogTable.isRead.equals(0),
          ))
        .watchSingle()
        .map((row) => row.read(countExpr) ?? 0);
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  Future<NotificationLogTableData?> findByKey(
    String businessId,
    String type,
    String? entityId,
  ) {
    return (select(notificationLogTable)
          ..where((t) => _keyMatches(t, businessId, type, entityId))
          ..limit(1))
        .getSingleOrNull();
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  /// Inserts a new row for [businessId]/[type]/[entityId] if none exists yet;
  /// otherwise refreshes [title]/[body]/`updatedAt` on the existing row
  /// without touching `isRead` or `createdAt`.
  ///
  /// Returns true only when a brand-new row was inserted — callers use this
  /// to decide whether to also fire a system tray notification, so a
  /// still-true condition never re-notifies on every reconciliation pass.
  Future<bool> upsertByKey({
    required String businessId,
    required String type,
    String? entityId,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await findByKey(businessId, type, entityId);
    if (existing == null) {
      await into(notificationLogTable).insert(
        NotificationLogTableCompanion.insert(
          id: '${DateTime.now().microsecondsSinceEpoch}-$businessId-$type-${entityId ?? ''}',
          businessId: businessId,
          type: type,
          entityId: Value(entityId),
          title: title,
          body: body,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return true;
    }
    await (update(notificationLogTable)..where((t) => t.id.equals(existing.id)))
        .write(
      NotificationLogTableCompanion(
        title: Value(title),
        body: Value(body),
        updatedAt: Value(now),
      ),
    );
    return false;
  }

  Future<void> markAsRead(String id) async {
    await (update(notificationLogTable)..where((t) => t.id.equals(id))).write(
      const NotificationLogTableCompanion(isRead: Value(1)),
    );
  }

  Future<void> markAllAsRead(String businessId) async {
    await (update(notificationLogTable)
          ..where(
            (t) => t.businessId.equals(businessId) & t.isRead.equals(0),
          ))
        .write(const NotificationLogTableCompanion(isRead: Value(1)));
  }

  /// Deletes the row for a key whose underlying condition has cleared
  /// (restocked / paid off / invoice paid / sync recovered).
  Future<void> deleteByKey(
    String businessId,
    String type,
    String? entityId,
  ) async {
    await (delete(notificationLogTable)
          ..where((t) => _keyMatches(t, businessId, type, entityId)))
        .go();
  }

  /// Deletes every row of [type] for [businessId] whose entityId is not in
  /// [validEntityIds] — reconciles alerts whose underlying condition
  /// resolved between reconciliation passes (restocked, paid off, etc.).
  Future<void> pruneStaleForType(
    String businessId,
    String type,
    Set<String> validEntityIds,
  ) async {
    if (validEntityIds.isEmpty) {
      await (delete(notificationLogTable)
            ..where(
              (t) => t.businessId.equals(businessId) & t.type.equals(type),
            ))
          .go();
      return;
    }
    await (delete(notificationLogTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.type.equals(type) &
                t.entityId.isNotIn(validEntityIds),
          ))
        .go();
  }

  /// Housekeeping: deletes already-read rows older than [olderThan] so the
  /// table doesn't grow unbounded. Safe to call on every app start.
  Future<void> pruneOldRead(String businessId, DateTime olderThan) async {
    await (delete(notificationLogTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.isRead.equals(1) &
                t.updatedAt.isSmallerThanValue(
                  olderThan.millisecondsSinceEpoch,
                ),
          ))
        .go();
  }

  Expression<bool> _keyMatches(
    $NotificationLogTableTable t,
    String businessId,
    String type,
    String? entityId,
  ) {
    final base = t.businessId.equals(businessId) & t.type.equals(type);
    return entityId == null
        ? base & t.entityId.isNull()
        : base & t.entityId.equals(entityId);
  }
}
