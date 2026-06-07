import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/customer_dao.dart';
import 'daos/expense_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/invoice_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'tables/business_settings_table.dart';
import 'tables/customers_table.dart';
import 'tables/expenses_table.dart';
import 'tables/inventory_table.dart';
import 'tables/invoice_items_table.dart';
import 'tables/invoices_table.dart';
import 'tables/sync_queue_table.dart';
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
  ],
  daos: [
    InvoiceDao,
    CustomerDao,
    ExpenseDao,
    InventoryDao,
    SyncQueueDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Add metadata JSON column for extended InventoryItem fields
            // (categoryId, categoryName, supplier, expiryDate, etc.)
            await customStatement(
              'ALTER TABLE inventory_items '
              "ADD COLUMN metadata TEXT NOT NULL DEFAULT '{}'",
            );
          }
        },
        beforeOpen: (details) async {
          // Enforce foreign key constraints
          await customStatement('PRAGMA foreign_keys = ON');
          // WAL mode for concurrent reads alongside sync writes
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
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mali_up_db');
  }
}
