import 'package:drift/drift.dart';

/// Local cache of global Firestore `master_categories` collection.
/// Keyed internally by the app's normalised business-type token (e.g. "retail").
class MasterCategoriesTable extends Table {
  @override
  String get tableName => 'master_categories';

  TextColumn get id => text()();
  TextColumn get businessType => text()(); // normalised key ("retail", "pharmacy" …)
  TextColumn get categoryName => text()();
  TextColumn get categoryNameSw => text().withDefault(const Constant(''))();
  TextColumn get categorySlug => text().withDefault(const Constant(''))();
  TextColumn get icon => text().withDefault(const Constant(''))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  IntColumn get cachedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of global Firestore `master_products` collection.
class MasterProductsTable extends Table {
  @override
  String get tableName => 'master_products';

  TextColumn get id => text()();
  TextColumn get businessType => text()(); // normalised key
  TextColumn get categorySlug => text().withDefault(const Constant(''))();
  TextColumn get productName => text()();
  TextColumn get productNameSw => text().withDefault(const Constant(''))();
  TextColumn get productSlug => text().withDefault(const Constant(''))();
  TextColumn get genericName => text().withDefault(const Constant(''))();
  // JSON arrays stored as TEXT
  TextColumn get brandNames => text().withDefault(const Constant('[]'))();
  TextColumn get unit => text().withDefault(const Constant('Piece'))();
  TextColumn get unitAlternatives => text().withDefault(const Constant('[]'))();
  TextColumn get commonBarcodes => text().withDefault(const Constant('[]'))();
  TextColumn get searchKeywords => text().withDefault(const Constant('[]'))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  IntColumn get prescriptionRequired => integer().withDefault(const Constant(0))();
  IntColumn get coldStorage => integer().withDefault(const Constant(0))();
  IntColumn get cachedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
