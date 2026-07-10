import 'package:drift/drift.dart';

class ExpensesTable extends Table {
  @override
  String get tableName => 'expenses';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get date => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get recipient => text().withDefault(const Constant(''))();
  IntColumn get isRecurring => integer().withDefault(const Constant(0))();
  TextColumn get recurrenceType => text().withDefault(const Constant(''))();
  TextColumn get nextDueDate => text().withDefault(const Constant(''))();
  TextColumn get templateId => text().withDefault(const Constant(''))();
  TextColumn get receiptUrl => text().withDefault(const Constant(''))();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('cash'))();
  TextColumn get paymentAccountId => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('approved'))();
  TextColumn get approvedBy => text().withDefault(const Constant(''))();
  TextColumn get createdBy => text().withDefault(const Constant(''))();

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
