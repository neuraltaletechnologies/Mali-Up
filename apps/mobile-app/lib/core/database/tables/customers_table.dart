import 'package:drift/drift.dart';

class CustomersTable extends Table {
  @override
  String get tableName => 'customers';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().withDefault(const Constant(''))();
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get lastTransactionDate =>
      text().withDefault(const Constant(''))();
  // JSON array of strings, e.g. '["vip","wholesale"]'
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  IntColumn get isOrganisation => integer().withDefault(const Constant(0))();
  TextColumn get tinNumber => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  RealColumn get creditLimit => real().withDefault(const Constant(0))();
  TextColumn get createdBy => text().withDefault(const Constant(''))();
  TextColumn get assignedToUserId => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().nullable()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();
  IntColumn get localVersion => integer().withDefault(const Constant(1))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
