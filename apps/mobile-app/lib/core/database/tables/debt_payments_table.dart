import 'package:drift/drift.dart';

class DebtPaymentsTable extends Table {
  @override
  String get tableName => 'debt_payments';

  TextColumn get id => text()();
  TextColumn get debtId => text()();
  TextColumn get businessId => text()();
  RealColumn get amount => real()();
  TextColumn get date => text()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get recordedBy => text().withDefault(const Constant(''))();
  TextColumn get accountId => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().nullable()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
