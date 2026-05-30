import 'package:drift/drift.dart';

class InventoryTable extends Table {
  @override
  String get tableName => 'inventory_items';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().withDefault(const Constant(''))();
  TextColumn get barcode => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  // Tracks quantity changes made offline that haven't been synced yet.
  // On conflict, the delta is applied on top of the server quantity rather
  // than replacing it — this prevents concurrent POS sales from overwriting
  // each other's stock movements.
  RealColumn get quantityDelta => real().withDefault(const Constant(0))();
  RealColumn get lowStockThreshold => real().withDefault(const Constant(0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0))();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().withDefault(const Constant(''))();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
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
