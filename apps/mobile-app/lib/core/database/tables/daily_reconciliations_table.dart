import 'package:drift/drift.dart';

class DailyReconciliationsTable extends Table {
  @override
  String get tableName => 'daily_reconciliations';

  // Deterministic id: '<accountId>_<date>' — makes offline upserts idempotent.
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get accountId => text()();
  TextColumn get date => text()(); // ISO date YYYY-MM-DD
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  RealColumn get closingBalance => real().withDefault(const Constant(0))();
  RealColumn get totalDeposits => real().withDefault(const Constant(0))();
  RealColumn get totalWithdrawals => real().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get reconciledBy => text().withDefault(const Constant(''))();
  IntColumn get isReconciled => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().nullable()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  // (businessId, id) — the deterministic id is '<accountId>_<date>', and for
  // the built-in channels accountId is a fixed value shared across businesses
  // (e.g. 'pm_cash_2026-09-04'). Keying on id alone collided between
  // businesses on a device that holds more than one.
  @override
  Set<Column> get primaryKey => {businessId, id};
}
