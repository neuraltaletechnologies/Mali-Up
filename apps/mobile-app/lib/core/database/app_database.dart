import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/cash_flow_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/debt_dao.dart';
import 'daos/expense_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/invoice_dao.dart';
import 'daos/master_catalog_dao.dart';
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
import 'tables/master_catalog_tables.dart';
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
    MasterCategoriesTable,
    MasterProductsTable,
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
    MasterCatalogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 10;

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
          if (from < 6) {
            // Sales refinement: payment + quotation fields so partial
            // balances, payment methods and doc types survive offline.
            await customStatement(
              "ALTER TABLE invoices ADD COLUMN customer_phone TEXT NOT NULL DEFAULT ''",
            );
            await customStatement(
              "ALTER TABLE invoices ADD COLUMN doc_type TEXT NOT NULL DEFAULT 'invoice'",
            );
            await customStatement(
              'ALTER TABLE invoices ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0',
            );
            await customStatement(
              'ALTER TABLE invoices ADD COLUMN amount_paid REAL NOT NULL DEFAULT 0',
            );
            await customStatement(
              "ALTER TABLE invoices ADD COLUMN payment_method TEXT NOT NULL DEFAULT ''",
            );
          }
          if (from < 7) {
            // Industry Master Catalog: global read-only product/category cache.
            await m.createTable(masterCategoriesTable);
            await m.createTable(masterProductsTable);
            // v8 will drop+recreate with the new schema, so skip v7 indexes
          }
          if (from < 8) {
            // New master catalog schema: businessType (human-readable name),
            // categorySlug, productNameSw, genericName, brandNames, unit,
            // unitAlternatives, commonBarcodes, searchKeywords, tags,
            // prescriptionRequired, coldStorage. Pricing fields removed.
            // Cache tables are read-only so a drop+recreate is safe.
            await customStatement('DROP TABLE IF EXISTS master_categories');
            await customStatement('DROP TABLE IF EXISTS master_products');
            await m.createTable(masterCategoriesTable);
            await m.createTable(masterProductsTable);
            await _createV8Indexes();
          }
          if (from < 9) {
            // Master catalog items can now belong to multiple business types
            // (Firestore `businessTypes` array). Primary key becomes
            // (id, business_type) so the same item can be cached once per
            // business-type context. Cache tables are read-only — safe to
            // drop and let the next fetch repopulate.
            await customStatement('DROP TABLE IF EXISTS master_categories');
            await customStatement('DROP TABLE IF EXISTS master_products');
            await m.createTable(masterCategoriesTable);
            await m.createTable(masterProductsTable);
            await _createV8Indexes();
          }
          if (from < 10) {
            // Custom cash accounts: invoices and debt repayments now record
            // the exact CashAccount they moved money through (not just the
            // fixed cash/mpesa/bank/card method string), so a later
            // "Mark as Paid" or repayment lookup resolves the same custom
            // account even if it was renamed.
            await customStatement(
              "ALTER TABLE invoices ADD COLUMN payment_account_id TEXT NOT NULL DEFAULT ''",
            );
            await customStatement(
              "ALTER TABLE debt_payments ADD COLUMN account_id TEXT NOT NULL DEFAULT ''",
            );
            await customStatement(
              "ALTER TABLE expenses ADD COLUMN payment_account_id TEXT NOT NULL DEFAULT ''",
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  Future<void> _createV8Indexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_master_categories_type '
      'ON master_categories(business_type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_master_products_type '
      'ON master_products(business_type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_master_products_category '
      'ON master_products(business_type, category_slug)',
    );
  }

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
    await _createV8Indexes();
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
