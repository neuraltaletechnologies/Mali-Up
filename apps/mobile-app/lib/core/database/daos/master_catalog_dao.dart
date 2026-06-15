import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/master_catalog_tables.dart';

part 'master_catalog_dao.g.dart';

@DriftAccessor(tables: [MasterCategoriesTable, MasterProductsTable])
class MasterCatalogDao extends DatabaseAccessor<AppDatabase>
    with _$MasterCatalogDaoMixin {
  MasterCatalogDao(super.db);

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<List<MasterCategoriesTableData>> getCategoriesForType(
    String businessTypeId,
  ) {
    return (select(masterCategoriesTable)
          ..where((t) =>
              t.businessTypeId.equals(businessTypeId) & t.isActive.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.categoryName)]))
        .get();
  }

  Future<int> categoryCount(String businessTypeId) async {
    final rows = await (select(masterCategoriesTable)
          ..where((t) => t.businessTypeId.equals(businessTypeId)))
        .get();
    return rows.length;
  }

  Future<void> upsertCategory(MasterCategoriesTableCompanion entry) async {
    await into(masterCategoriesTable).insertOnConflictUpdate(entry);
  }

  Future<void> upsertCategories(
    List<MasterCategoriesTableCompanion> entries,
  ) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(masterCategoriesTable, entries);
    });
  }

  // ─── Products ──────────────────────────────────────────────────────────────

  Future<List<MasterProductsTableData>> getProductsForType(
    String businessTypeId,
  ) {
    return (select(masterProductsTable)
          ..where((t) =>
              t.businessTypeId.equals(businessTypeId) & t.isActive.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.productName)]))
        .get();
  }

  Future<List<MasterProductsTableData>> getProductsForCategory(
    String businessTypeId,
    String categoryId,
  ) {
    return (select(masterProductsTable)
          ..where((t) =>
              t.businessTypeId.equals(businessTypeId) &
              t.categoryId.equals(categoryId) &
              t.isActive.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.productName)]))
        .get();
  }

  Future<List<MasterProductsTableData>> searchProducts(
    String businessTypeId,
    String query,
  ) async {
    final q = query.toLowerCase();
    final rows = await (select(masterProductsTable)
          ..where((t) =>
              t.businessTypeId.equals(businessTypeId) & t.isActive.equals(1)))
        .get();
    return rows.where((r) {
      if (r.productName.toLowerCase().contains(q)) return true;
      if (r.categoryName.toLowerCase().contains(q)) return true;
      if (r.barcode.contains(q)) return true;
      final kw = jsonDecode(r.searchableKeywords) as List;
      return kw.any((k) => k.toString().toLowerCase().contains(q));
    }).toList();
  }

  Future<int> productCount(String businessTypeId) async {
    final rows = await (select(masterProductsTable)
          ..where((t) => t.businessTypeId.equals(businessTypeId)))
        .get();
    return rows.length;
  }

  Future<void> upsertProduct(MasterProductsTableCompanion entry) async {
    await into(masterProductsTable).insertOnConflictUpdate(entry);
  }

  Future<void> upsertProducts(
    List<MasterProductsTableCompanion> entries,
  ) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(masterProductsTable, entries);
    });
  }
}
