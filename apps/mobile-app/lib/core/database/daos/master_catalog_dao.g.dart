// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'master_catalog_dao.dart';

// ignore_for_file: type=lint
mixin _$MasterCatalogDaoMixin on DatabaseAccessor<AppDatabase> {
  $MasterCategoriesTableTable get masterCategoriesTable =>
      attachedDatabase.masterCategoriesTable;
  $MasterProductsTableTable get masterProductsTable =>
      attachedDatabase.masterProductsTable;
  MasterCatalogDaoManager get managers => MasterCatalogDaoManager(this);
}

class MasterCatalogDaoManager {
  final _$MasterCatalogDaoMixin _db;
  MasterCatalogDaoManager(this._db);
  $$MasterCategoriesTableTableTableManager get masterCategoriesTable =>
      $$MasterCategoriesTableTableTableManager(
        _db.attachedDatabase,
        _db.masterCategoriesTable,
      );
  $$MasterProductsTableTableTableManager get masterProductsTable =>
      $$MasterProductsTableTableTableManager(
        _db.attachedDatabase,
        _db.masterProductsTable,
      );
}
