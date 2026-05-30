import 'package:drift/drift.dart';

class BusinessSettingsTable extends Table {
  @override
  String get tableName => 'business_settings';

  // Always a single row with id = 1
  IntColumn get id => integer()();
  TextColumn get businessId => text()();
  TextColumn get businessName => text()();
  TextColumn get businessType => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get tinNumber => text().withDefault(const Constant(''))();
  IntColumn get vatRegistered =>
      integer().withDefault(const Constant(0))();
  RealColumn get vatRate => real().withDefault(const Constant(0.18))();
  TextColumn get currency =>
      text().withDefault(const Constant('TZS'))();
  TextColumn get invoicePrefix =>
      text().withDefault(const Constant('INV'))();
  // Starts at 0; increment-and-get returns 1 for the first invoice.
  IntColumn get nextInvoiceNumber =>
      integer().withDefault(const Constant(0))();
  TextColumn get logoUrl => text().withDefault(const Constant(''))();
  TextColumn get plan =>
      text().withDefault(const Constant('starter'))();
  IntColumn get planExpiresAt => integer().nullable()();

  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();

  @override
  Set<Column> get primaryKey => {id};
}
