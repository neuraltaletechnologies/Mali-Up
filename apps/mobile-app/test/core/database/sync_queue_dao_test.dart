import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/database/app_database.dart';
import 'package:mali_up/core/database/daos/sync_queue_dao.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late SyncQueueDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = db.syncQueueDao;
  });

  tearDown(() async => db.close());

  SyncQueueTableCompanion makeEntry({
    String operationId = 'op-1',
    String entityType = 'invoice',
    String entityId = 'inv-1',
    String operation = 'create',
    String status = 'pending',
    int nextRetryAt = 0,
    int attempts = 0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return SyncQueueTableCompanion.insert(
      operationId: operationId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: '{"id":"$entityId"}',
      status: Value(status),
      nextRetryAt: Value(nextRetryAt),
      attempts: Value(attempts),
      createdAt: now,
      updatedAt: now,
      checksum: 'abc123',
      localVersion: 1,
    );
  }

  group('enqueue / fetchPending', () {
    test('enqueued entry appears in fetchPending', () async {
      await dao.enqueue(makeEntry());

      final pending = await dao.fetchPending(limit: 10);
      expect(pending.length, 1);
      expect(pending.first.operationId, 'op-1');
    });

    test('enqueue with duplicate operationId updates the existing entry',
        () async {
      await dao.enqueue(makeEntry());
      await dao.enqueue(makeEntry(operation: 'update'));

      final pending = await dao.fetchPending(limit: 10);
      expect(pending.length, 1);
      expect(pending.first.operation, 'update');
    });

    test('fetchPending respects nextRetryAt backoff window', () async {
      final futureMs =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
      await dao.enqueue(makeEntry(nextRetryAt: futureMs));

      final pending = await dao.fetchPending(limit: 10);
      expect(pending, isEmpty);
    });

    test('fetchPending returns entries in FIFO order', () async {
      await dao.enqueue(makeEntry(operationId: 'op-A'));
      await dao.enqueue(makeEntry(operationId: 'op-B'));
      await dao.enqueue(makeEntry(operationId: 'op-C'));

      final pending = await dao.fetchPending(limit: 10);
      expect(pending.map((e) => e.operationId).toList(),
          ['op-A', 'op-B', 'op-C']);
    });
  });

  group('watchPendingCount', () {
    test('count increases as entries are enqueued', () async {
      expect(await dao.watchPendingCount().first, 0);

      await dao.enqueue(makeEntry());
      expect(await dao.watchPendingCount().first, 1);

      await dao.enqueue(makeEntry(operationId: 'op-2'));
      expect(await dao.watchPendingCount().first, 2);
    });

    test('completed entries are excluded from count', () async {
      await dao.enqueue(makeEntry());
      final rows = await dao.fetchPending(limit: 1);
      await dao.markCompleted(rows.first.id);

      expect(await dao.watchPendingCount().first, 0);
    });

    test('conflict entries are included in count', () async {
      await dao.enqueue(makeEntry());
      final rows = await dao.fetchPending(limit: 1);
      await dao.markConflict(rows.first.id, 'server has newer version');

      expect(await dao.watchPendingCount().first, 1);
    });
  });

  group('scheduleRetry', () {
    test('increments attempts and sets nextRetryAt', () async {
      await dao.enqueue(makeEntry());
      final rows = await dao.fetchPending(limit: 1);
      final entry = rows.first;

      await dao.scheduleRetry(
          entry.id, 1, const Duration(seconds: 30));

      // Entry is now in backoff — should not appear in fetchPending
      final pending = await dao.fetchPending(limit: 10);
      expect(pending, isEmpty);
    });
  });

  group('recoverStaleProcessing', () {
    test('resets processing entries back to pending', () async {
      await dao.enqueue(makeEntry(status: 'processing'));

      // 'processing' entries are excluded from fetchPending
      expect(await dao.fetchPending(limit: 10), isEmpty);

      await dao.recoverStaleProcessing();

      // After recovery they should be fetchable again
      final pending = await dao.fetchPending(limit: 10);
      expect(pending.length, 1);
      expect(pending.first.status, 'pending');
    });
  });

  group('cancelForEntity', () {
    test('cancels all pending entries for a given entity', () async {
      await dao.enqueue(makeEntry());
      await dao.enqueue(makeEntry(operationId: 'op-2'));
      await dao.enqueue(makeEntry(operationId: 'op-3', entityId: 'inv-2'));

      await dao.cancelForEntity('inv-1');

      final pending = await dao.fetchPending(limit: 10);
      expect(pending.length, 1);
      expect(pending.first.entityId, 'inv-2');
    });
  });
}
