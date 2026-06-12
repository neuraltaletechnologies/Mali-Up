import 'package:drift/drift.dart';

class CashTransactionsTable extends Table {
  @override
  String get tableName => 'cash_transactions';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get type => text()(); // 'deposit' | 'withdrawal' | 'transfer'
  RealColumn get amount => real()();
  TextColumn get fromAccountId => text().withDefault(const Constant(''))();
  TextColumn get toAccountId => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get date => text()(); // ISO date string
  TextColumn get reference => text().withDefault(const Constant(''))();
  // 'operating' | 'investing' | 'financing'
  TextColumn get activityCategory =>
      text().withDefault(const Constant('operating'))();
  TextColumn get createdBy => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().nullable()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
