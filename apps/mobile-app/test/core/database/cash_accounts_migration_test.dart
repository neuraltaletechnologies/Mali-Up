import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/database/app_database.dart';

/// v17 re-keys `cash_accounts` and `daily_reconciliations` from `{id}` to
/// `{business_id, id}` so the built-in payment channels (pm_cash, pm_mpesa, …)
/// stop shadowing each other between businesses on one device. This exercises
/// the real upgrade path and checks that existing rows survive the rebuild.
void main() {
  test('v17 migration re-keys cash tables on (business_id, id) and keeps rows',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // A fresh in-memory db is already at the current schema. Drop the two
    // tables and recreate them in their pre-v17 shape (primary key on `id`
    // alone), then drop in rows the way v16 would have stored them.
    await db.customStatement('DROP TABLE cash_accounts');
    await db.customStatement('DROP TABLE daily_reconciliations');
    await db.customStatement('''
      CREATE TABLE cash_accounts (
        id TEXT NOT NULL PRIMARY KEY,
        business_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        account_number TEXT NOT NULL DEFAULT '',
        currency TEXT NOT NULL DEFAULT 'TZS',
        last_reconciled TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        server_updated_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'pending_create',
        local_version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.customStatement('''
      CREATE TABLE daily_reconciliations (
        id TEXT NOT NULL PRIMARY KEY,
        business_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        date TEXT NOT NULL,
        opening_balance REAL NOT NULL DEFAULT 0,
        closing_balance REAL NOT NULL DEFAULT 0,
        total_deposits REAL NOT NULL DEFAULT 0,
        total_withdrawals REAL NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        reconciled_by TEXT NOT NULL DEFAULT '',
        is_reconciled INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        server_updated_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'pending_create',
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.customStatement(
      'INSERT INTO cash_accounts '
      '(id, business_id, name, type, balance, created_at, updated_at, '
      'sync_status, local_version, is_deleted) '
      "VALUES ('pm_mpesa', 'biz-1', 'M-Pesa', 'Mobile Money', 5000, 1, 1, "
      "'synced', 1, 0)",
    );
    await db.customStatement(
      'INSERT INTO daily_reconciliations '
      '(id, business_id, account_id, date, created_at, updated_at, '
      'sync_status, is_deleted) '
      "VALUES ('pm_mpesa_2026-09-04', 'biz-1', 'pm_mpesa', '2026-09-04', "
      "1, 1, 'synced', 0)",
    );

    // Run the real upgrade path.
    await db.migration.onUpgrade(Migrator(db), 16, 17);

    // The legacy rows survived the table rebuild.
    final migrated = await db.cashFlowDao.getAccountById('biz-1', 'pm_mpesa');
    expect(migrated, isNotNull);
    expect(migrated!.balance, 5000);

    // …and a second business can now hold the same built-in id.
    await db.cashFlowDao.upsertAccount(
      CashAccountsTableCompanion.insert(
        id: 'pm_mpesa',
        businessId: 'biz-2',
        name: 'M-Pesa',
        type: 'Mobile Money',
        balance: const Value(9999),
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    expect(
      (await db.cashFlowDao.getAccountById('biz-2', 'pm_mpesa'))!.balance,
      9999,
    );
    expect(
      (await db.cashFlowDao.getAccountById('biz-1', 'pm_mpesa'))!.balance,
      5000,
    );

    await db.cashFlowDao.upsertReconciliation(
      DailyReconciliationsTableCompanion.insert(
        id: 'pm_mpesa_2026-09-04',
        businessId: 'biz-2',
        accountId: 'pm_mpesa',
        date: '2026-09-04',
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    expect(
      await db.cashFlowDao.watchReconciliations('biz-1').first,
      hasLength(1),
    );
    expect(
      await db.cashFlowDao.watchReconciliations('biz-2').first,
      hasLength(1),
    );
  });
}
