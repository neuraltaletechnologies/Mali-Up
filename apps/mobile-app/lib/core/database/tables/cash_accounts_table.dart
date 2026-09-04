import 'package:drift/drift.dart';

class CashAccountsTable extends Table {
  @override
  String get tableName => 'cash_accounts';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'Cash' | 'Mobile Money' | 'Bank'
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get accountNumber => text().withDefault(const Constant(''))();
  TextColumn get currency => text().withDefault(const Constant('TZS'))();
  TextColumn get lastReconciled => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().nullable()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();
  IntColumn get localVersion => integer().withDefault(const Constant(1))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  // (businessId, id) — the built-in payment channels use fixed ids
  // (pm_cash, pm_mpesa, pm_bank, pm_card) that are only unique *within* a
  // business, and this one device holds rows for every business the user has
  // opened. Keying on id alone let one business's `pm_mpesa` shadow another's,
  // so activating a channel in the second business silently no-op'd.
  @override
  Set<Column> get primaryKey => {businessId, id};
}
