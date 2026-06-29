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
    String businessType,
  ) {
    return (select(masterCategoriesTable)
          ..where((t) => t.businessType.equals(businessType))
          ..orderBy([
            (t) => OrderingTerm.asc(t.displayOrder),
            (t) => OrderingTerm.asc(t.categoryName),
          ]))
        .get();
  }

  Future<int> categoryCount(String businessType) async {
    final rows = await (select(masterCategoriesTable)
          ..where((t) => t.businessType.equals(businessType)))
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
    String businessType,
  ) {
    return (select(masterProductsTable)
          ..where((t) => t.businessType.equals(businessType))
          ..orderBy([(t) => OrderingTerm.asc(t.productName)]))
        .get();
  }

  Future<List<MasterProductsTableData>> getProductsForCategory(
    String businessType,
    String categorySlug,
  ) {
    return (select(masterProductsTable)
          ..where((t) =>
              t.businessType.equals(businessType) &
              t.categorySlug.equals(categorySlug))
          ..orderBy([(t) => OrderingTerm.asc(t.productName)]))
        .get();
  }

  Future<List<MasterProductsTableData>> searchProducts(
    String businessType,
    String query,
  ) async {
    final q = query.toLowerCase();
    final rows = await (select(masterProductsTable)
          ..where((t) => t.businessType.equals(businessType)))
        .get();
    return rows.where((r) {
      if (r.productName.toLowerCase().contains(q)) return true;
      if (r.productNameSw.toLowerCase().contains(q)) return true;
      if (r.genericName.toLowerCase().contains(q)) return true;
      // Search JSON arrays
      for (final json in [r.searchKeywords, r.brandNames, r.commonBarcodes]) {
        try {
          final list = jsonDecode(json) as List;
          if (list.any((k) => k.toString().toLowerCase().contains(q))) {
            return true;
          }
        } catch (_) {}
      }
      return false;
    }).toList();
  }

  Future<int> productCount(String businessType) async {
    final rows = await (select(masterProductsTable)
          ..where((t) => t.businessType.equals(businessType)))
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
