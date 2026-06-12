import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/cash_flow_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/debt_dao.dart';
import 'daos/expense_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/invoice_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/team_dao.dart';
import 'tables/business_settings_table.dart';
import 'tables/cash_accounts_table.dart';
import 'tables/cash_transactions_table.dart';
import 'tables/customers_table.dart';
import 'tables/daily_reconciliations_table.dart';
import 'tables/debt_payments_table.dart';
import 'tables/debts_table.dart';
import 'tables/expenses_table.dart';
import 'tables/inventory_table.dart';
import 'tables/invoice_items_table.dart';
import 'tables/invoices_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/team_members_table.dart';
import 'tables/user_settings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    InvoicesTable,
    InvoiceItemsTable,
    CustomersTable,
    ExpensesTable,
    InventoryTable,
    SyncQueueTable,
    UserSettingsTable,
    BusinessSettingsTable,
    DebtsTable,
    DebtPaymentsTable,
    TeamMembersTable,
    CashAccountsTable,
    CashTransactionsTable,
    DailyReconciliationsTable,
  ],
  daos: [
    InvoiceDao,
    CustomerDao,
    ExpenseDao,
    InventoryDao,
    SyncQueueDao,
    SettingsDao,
    DebtDao,
    TeamDao,
    CashFlowDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
              'ALTER TABLE inventory_items '
              "ADD COLUMN metadata TEXT NOT NULL DEFAULT '{}'",
            );
          }
          if (from < 3) {
            // Add debt, debt_payments, and team_members tables
            await m.createTable(debtsTable);
            await m.createTable(debtPaymentsTable);
            await m.createTable(teamMembersTable);
            await _createV3Indexes();
          }
          if (from < 4) {
            // Customer ownership: who the record is assigned to (RBAC scoping)
            await customStatement(
              'ALTER TABLE customers '
              "ADD COLUMN assigned_to_user_id TEXT NOT NULL DEFAULT ''",
            );
          }
          if (from < 5) {
            // Cash flow goes offline-first: accounts, transactions,
            // daily reconciliations
            await m.createTable(cashAccountsTable);
            await m.createTable(cashTransactionsTable);
            await m.createTable(dailyReconciliationsTable);
            await _createV5Indexes();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_invoices_business_status '
      'ON invoices(business_id, status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_invoices_business_date '
      'ON invoices(business_id, date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_invoices_customer '
      'ON invoices(business_id, customer_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_business '
      'ON customers(business_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_expenses_business_date '
      'ON expenses(business_id, date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inventory_business '
      'ON inventory_items(business_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inventory_barcode '
      'ON inventory_items(business_id, barcode)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status_retry '
      'ON sync_queue(status, next_retry_at)',
    );
    await _createV3Indexes();
    await _createV5Indexes();
  }

  Future<void> _createV3Indexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_business '
      'ON debts(business_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_business_type '
      'ON debts(business_id, type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_business_due '
      'ON debts(business_id, due_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt '
      'ON debt_payments(debt_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_team_members_business '
      'ON team_members(business_id)',
    );
  }

  Future<void> _createV5Indexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cash_accounts_business '
      'ON cash_accounts(business_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cash_transactions_business_date '
      'ON cash_transactions(business_id, date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cash_transactions_from_account '
      'ON cash_transactions(business_id, from_account_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cash_transactions_to_account '
      'ON cash_transactions(business_id, to_account_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_reconciliations_business_account '
      'ON daily_reconciliations(business_id, account_id)',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mali_up_db');
  }
}
