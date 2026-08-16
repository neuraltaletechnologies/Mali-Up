import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/database/app_database.dart';
import 'package:mali_up/core/database/daos/notification_log_dao.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late NotificationLogDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = db.notificationLogDao;
  });

  tearDown(() async {
    await db.close();
  });

  const businessId = 'biz-1';

  group('upsertByKey', () {
    test('inserts a new row and reports it as new', () async {
      final isNew = await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'Low stock: Sugar',
        body: 'Only 2 kg left',
      );

      expect(isNew, isTrue);
      final rows = await dao.watchAll(businessId).first;
      expect(rows, hasLength(1));
      expect(rows.single.title, 'Low stock: Sugar');
      expect(rows.single.isRead, 0);
    });

    test('re-detecting the same key refreshes body without re-notifying', () async {
      await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'Low stock: Sugar',
        body: 'Only 2 kg left',
      );
      final isNewAgain = await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'Low stock: Sugar',
        body: 'Only 1 kg left',
      );

      expect(isNewAgain, isFalse);
      final rows = await dao.watchAll(businessId).first;
      expect(rows, hasLength(1));
      expect(rows.single.body, 'Only 1 kg left');
    });

    test('marking a row read survives a refresh of the same key', () async {
      await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'Low stock: Sugar',
        body: 'Only 2 kg left',
      );
      final row = await dao.findByKey(businessId, 'low_stock', 'item-1');
      await dao.markAsRead(row!.id);

      await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'Low stock: Sugar',
        body: 'Only 1 kg left',
      );

      final refreshed = await dao.findByKey(businessId, 'low_stock', 'item-1');
      expect(refreshed!.isRead, 1);
    });

    test('supports a null entityId (sync_failure single-row-per-business key)', () async {
      final isNew = await dao.upsertByKey(
        businessId: businessId,
        type: 'sync_failure',
        title: 'Sync problem detected',
        body: 'Some changes could not sync',
      );

      expect(isNew, isTrue);
      final found = await dao.findByKey(businessId, 'sync_failure', null);
      expect(found, isNotNull);
    });
  });

  group('watchUnreadCount', () {
    test('counts only unread rows for the business', () async {
      await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'a',
        body: 'a',
      );
      await dao.upsertByKey(
        businessId: businessId,
        type: 'overdue_debt',
        entityId: 'debt-1',
        title: 'b',
        body: 'b',
      );
      final second = await dao.findByKey(businessId, 'overdue_debt', 'debt-1');
      await dao.markAsRead(second!.id);

      final count = await dao.watchUnreadCount(businessId).first;
      expect(count, 1);
    });
  });

  group('markAllAsRead', () {
    test('marks every unread row for the business as read', () async {
      await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'a',
        body: 'a',
      );
      await dao.upsertByKey(
        businessId: businessId,
        type: 'overdue_debt',
        entityId: 'debt-1',
        title: 'b',
        body: 'b',
      );

      await dao.markAllAsRead(businessId);

      final count = await dao.watchUnreadCount(businessId).first;
      expect(count, 0);
    });
  });

  group('pruneStaleForType', () {
    test('deletes rows whose entityId is no longer valid', () async {
      await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'a',
        body: 'a',
      );
      await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-2',
        title: 'b',
        body: 'b',
      );

      // item-1 restocked above threshold — only item-2 is still valid.
      await dao.pruneStaleForType(businessId, 'low_stock', {'item-2'});

      final rows = await dao.watchAll(businessId).first;
      expect(rows.map((r) => r.entityId), ['item-2']);
    });

    test('deletes every row of the type when nothing is valid anymore', () async {
      await dao.upsertByKey(
        businessId: businessId,
        type: 'low_stock',
        entityId: 'item-1',
        title: 'a',
        body: 'a',
      );

      await dao.pruneStaleForType(businessId, 'low_stock', {});

      final rows = await dao.watchAll(businessId).first;
      expect(rows, isEmpty);
    });
  });

  group('deleteByKey', () {
    test('removes the row for a resolved condition', () async {
      await dao.upsertByKey(
        businessId: businessId,
        type: 'sync_failure',
        title: 'Sync problem detected',
        body: 'x',
      );

      await dao.deleteByKey(businessId, 'sync_failure', null);

      final found = await dao.findByKey(businessId, 'sync_failure', null);
      expect(found, isNull);
    });
  });
}
