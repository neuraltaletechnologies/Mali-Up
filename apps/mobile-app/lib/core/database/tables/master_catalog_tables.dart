import 'package:drift/drift.dart';

/// Local cache of global Firestore `master_categories` collection.
/// Read-only from the business side — no sync queue needed.
class MasterCategoriesTable extends Table {
  @override
  String get tableName => 'master_categories';

  TextColumn get id => text()();
  TextColumn get businessTypeId => text()();
  TextColumn get categoryName => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get icon => text().withDefault(const Constant(''))();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get cachedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of global Firestore `master_products` collection.
/// Read-only from the business side — no sync queue needed.
class MasterProductsTable extends Table {
  @override
  String get tableName => 'master_products';

  TextColumn get id => text()();
  TextColumn get businessTypeId => text()();
  TextColumn get categoryId => text()();
  TextColumn get categoryName => text().withDefault(const Constant(''))();
  TextColumn get productName => text()();
  TextColumn get skuTemplate => text().withDefault(const Constant(''))();
  TextColumn get barcode => text().withDefault(const Constant(''))();
  TextColumn get defaultUnit => text().withDefault(const Constant('pcs'))();
  RealColumn get suggestedCostPrice =>
      real().withDefault(const Constant(0))();
  RealColumn get suggestedSellingPrice =>
      real().withDefault(const Constant(0))();
  // JSON array of keyword strings for offline full-text search
  TextColumn get searchableKeywords =>
      text().withDefault(const Constant('[]'))();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get cachedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
