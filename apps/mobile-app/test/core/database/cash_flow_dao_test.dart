import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/database/app_database.dart';
import 'package:mali_up/core/database/daos/cash_flow_dao.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late CashFlowDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = db.cashFlowDao;
  });

  tearDown(() async {
    await db.close();
  });

  // ─── Helpers ────────────────────────────────────────────────────────────────

  CashAccountsTableCompanion account({
    String id = 'acc-1',
    String businessId = 'biz-1',
    String name = 'Main Cash Drawer',
    String type = 'Cash',
    double balance = 100000,
    String syncStatus = 'synced',
    int isDeleted = 0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return CashAccountsTableCompanion.insert(
      id: id,
      businessId: businessId,
      name: name,
      type: type,
      balance: Value(balance),
      createdAt: now,
      updatedAt: now,
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
    );
  }

  CashTransactionsTableCompanion txn({
    String id = 'txn-1',
    String businessId = 'biz-1',
    String type = 'deposit',
    double amount = 5000,
    String fromAccountId = '',
    String toAccountId = 'acc-1',
    String date = '2026-07-01',
    int? createdAt,
    int isDeleted = 0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return CashTransactionsTableCompanion.insert(
      id: id,
      businessId: businessId,
      type: type,
      amount: amount,
      fromAccountId: Value(fromAccountId),
      toAccountId: Value(toAccountId),
      date: date,
      createdAt: createdAt ?? now,
      updatedAt: now,
      isDeleted: Value(isDeleted),
    );
  }

  DailyReconciliationsTableCompanion recon({
    String id = 'acc-1_2026-07-01',
    String businessId = 'biz-1',
    String accountId = 'acc-1',
    String date = '2026-07-01',
    double openingBalance = 100000,
    double closingBalance = 105000,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return DailyReconciliationsTableCompanion.insert(
      id: id,
      businessId: businessId,
      accountId: accountId,
      date: date,
      openingBalance: Value(openingBalance),
      closingBalance: Value(closingBalance),
      createdAt: now,
      updatedAt: now,
    );
  }

  // ─── Accounts ───────────────────────────────────────────────────────────────

  group('accounts', () {
    test('upsert inserts and updates on id conflict', () async {
      await dao.upsertAccount(account());
      await dao.upsertAccount(account(name: 'Till', balance: 50000));

      final result = await dao.getAccountById('acc-1');
      expect(result!.name, 'Till');
      expect(result.balance, 50000);
    });

    test('watchAccounts is scoped to business and excludes deleted',
        () async {
      await dao.upsertAccount(account());
      await dao.upsertAccount(account(id: 'acc-2', isDeleted: 1));
      await dao.upsertAccount(account(id: 'acc-3', businessId: 'biz-other'));

      final rows = await dao.watchAccounts('biz-1').first;
      expect(rows.map((r) => r.id), ['acc-1']);
    });

    test('adjustAccountBalance applies deltas without touching syncStatus',
        () async {
      await dao.upsertAccount(account());

      await dao.adjustAccountBalance('acc-1', 5000);
      await dao.adjustAccountBalance('acc-1', -20000);

      final result = await dao.getAccountById('acc-1');
      expect(result!.balance, 85000);
      expect(result.syncStatus, 'synced');
    });

    test('softDeleteAccount hides the row and marks it pending_delete',
        () async {
      await dao.upsertAccount(account());
      await dao.softDeleteAccount('acc-1');

      final rows = await dao.watchAccounts('biz-1').first;
      expect(rows, isEmpty);
      final raw = await dao.getAccountById('acc-1');
      expect(raw!.syncStatus, 'pending_delete');
      expect(raw.isDeleted, 1);
    });

    test('applyRemoteAccountDeletion hides the row but leaves it synced',
        () async {
      await dao.upsertAccount(account());
      await dao.applyRemoteAccountDeletion('acc-1', serverUpdatedAt: 123456);

      final rows = await dao.watchAccounts('biz-1').first;
      expect(rows, isEmpty);
      final raw = await dao.getAccountById('acc-1');
      expect(raw!.syncStatus, 'synced');
      expect(raw.isDeleted, 1);
      expect(raw.serverUpdatedAt, 123456);
    });
  });

  // ─── Transactions ───────────────────────────────────────────────────────────

  group('transactions', () {
    test('watchTransactions orders by date desc, createdAt desc tie-break',
        () async {
      // 'same-day-*' rows share the helper's default date of 2026-07-01.
      await dao.upsertTransaction(
          txn(id: 'old-day', date: '2026-06-30', createdAt: 10));
      await dao.upsertTransaction(txn(id: 'same-day-early', createdAt: 20));
      await dao.upsertTransaction(txn(id: 'same-day-late', createdAt: 30));

      final rows = await dao.watchTransactions('biz-1').first;
      expect(rows.map((r) => r.id),
          ['same-day-late', 'same-day-early', 'old-day']);
    });

    test('watchTransactions excludes deleted and other businesses', () async {
      await dao.upsertTransaction(txn());
      await dao.upsertTransaction(txn(id: 'txn-2', isDeleted: 1));
      await dao.upsertTransaction(txn(id: 'txn-3', businessId: 'biz-other'));

      final rows = await dao.watchTransactions('biz-1').first;
      expect(rows.map((r) => r.id), ['txn-1']);
    });

    test('markTransactionSynced flips status and stores server timestamp',
        () async {
      await dao.upsertTransaction(txn());
      await dao.markTransactionSynced('txn-1', serverUpdatedAt: 999);

      final raw = await dao.getTransactionById('txn-1');
      expect(raw!.syncStatus, 'synced');
      expect(raw.serverUpdatedAt, 999);
    });
  });

  // ─── Reconciliations ────────────────────────────────────────────────────────

  group('reconciliations', () {
    test('upsert is idempotent on the deterministic id', () async {
      await dao.upsertReconciliation(recon());
      await dao.upsertReconciliation(recon(closingBalance: 110000));

      final rows = await dao.watchReconciliations('biz-1').first;
      expect(rows.length, 1);
      expect(rows.single.closingBalance, 110000);
    });

    test('updateAccountLastReconciled stamps the account', () async {
      await dao.upsertAccount(account());
      await dao.updateAccountLastReconciled('acc-1', '2026-07-01');

      final raw = await dao.getAccountById('acc-1');
      expect(raw!.lastReconciled, '2026-07-01');
    });
  });
}
