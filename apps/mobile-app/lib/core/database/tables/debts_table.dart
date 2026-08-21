import 'package:drift/drift.dart';

class DebtsTable extends Table {
  @override
  String get tableName => 'debts';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get partyName => text()();
  TextColumn get partyPhone => text().withDefault(const Constant(''))();
  TextColumn get partyId => text().withDefault(const Constant(''))();
  TextColumn get type => text()(); // 'receivable' | 'payable'
  RealColumn get originalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get dueDate => text()();
  TextColumn get status => text().withDefault(const Constant('current'))();
  TextColumn get invoiceRef => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get createdBy => text().withDefault(const Constant(''))();
  TextColumn get debtCreatedAt => text().withDefault(const Constant(''))();
  IntColumn get isWrittenOff => integer().withDefault(const Constant(0))();
  TextColumn get writeOffReason => text().withDefault(const Constant(''))();
  TextColumn get writtenOffBy => text().withDefault(const Constant(''))();
  TextColumn get writtenOffAt => text().withDefault(const Constant(''))();

  // Interest / money-lender support: rate charged per period, the period
  // granularity, simple vs compound accrual, and the date interest starts
  // counting from. Zero rate (the default) means no interest, so existing
  // debts behave exactly as before.
  RealColumn get interestRatePercent =>
      real().withDefault(const Constant(0))();
  TextColumn get interestPeriod =>
      text().withDefault(const Constant('monthly'))();
  TextColumn get interestType =>
      text().withDefault(const Constant('simple'))();
  TextColumn get loanDate => text().withDefault(const Constant(''))();

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
