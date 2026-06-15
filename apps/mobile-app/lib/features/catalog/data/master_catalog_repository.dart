import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/master_category.dart';
import '../domain/models/master_product.dart';
import 'catalog_seed_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MasterCatalogRepository
//
// The master catalog is global (not scoped to any tenant/business).
// Firestore collections: master_categories / master_products
//
// Strategy:
//   1. On first call, seed the local Drift cache from bundled static data.
//   2. Attempt a background refresh from Firestore (non-blocking).
//   3. All reads come from the local Drift cache — fully offline capable.
// ─────────────────────────────────────────────────────────────────────────────

class MasterCatalogRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  MasterCatalogRepository({
    required AppDatabase db,
    FirebaseFirestore? firestore,
  })  : _db = db,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Read API ───────────────────────────────────────────────────────────────

  Future<List<MasterCategory>> getCategoriesForType(
    String businessTypeId,
  ) async {
    await _ensureSeeded(businessTypeId);
    final rows = await _db.masterCatalogDao.getCategoriesForType(businessTypeId);
    return rows
        .map((r) => MasterCategory(
              id: r.id,
              businessTypeId: r.businessTypeId,
              categoryName: r.categoryName,
              description: r.description,
              icon: r.icon,
              isActive: r.isActive == 1,
            ))
        .toList();
  }

  Future<List<MasterProduct>> getProductsForType(String businessTypeId) async {
    await _ensureSeeded(businessTypeId);
    final rows = await _db.masterCatalogDao.getProductsForType(businessTypeId);
    return rows.map(_rowToProduct).toList();
  }

  Future<List<MasterProduct>> getProductsForCategory(
    String businessTypeId,
    String categoryId,
  ) async {
    await _ensureSeeded(businessTypeId);
    final rows = await _db.masterCatalogDao
        .getProductsForCategory(businessTypeId, categoryId);
    return rows.map(_rowToProduct).toList();
  }

  Future<List<MasterProduct>> searchProducts(
    String businessTypeId,
    String query,
  ) async {
    await _ensureSeeded(businessTypeId);
    if (query.trim().isEmpty) return getProductsForType(businessTypeId);
    final rows = await _db.masterCatalogDao
        .searchProducts(businessTypeId, query.trim());
    return rows.map(_rowToProduct).toList();
  }

  // ── Seed / Refresh ─────────────────────────────────────────────────────────

  /// Ensures local cache has data for [businessTypeId].
  /// Seeding is idempotent — runs once, then checks Firestore for updates.
  Future<void> _ensureSeeded(String businessTypeId) async {
    final catCount =
        await _db.masterCatalogDao.categoryCount(businessTypeId);
    if (catCount == 0) {
      await _seedFromBundledData(businessTypeId);
      // Non-blocking Firestore refresh — updates cache if online.
      _refreshFromFirestore(businessTypeId);
    }
  }

  /// Writes bundled static seed data into Drift for [businessTypeId].
  Future<void> _seedFromBundledData(String businessTypeId) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final cats = masterCatalogCategories
        .where((c) => c.businessTypeId == businessTypeId)
        .map((c) => MasterCategoriesTableCompanion(
              id: Value(c.id),
              businessTypeId: Value(c.businessTypeId),
              categoryName: Value(c.categoryName),
              description: Value(c.description),
              icon: Value(c.icon),
              isActive: const Value(1),
              cachedAt: Value(now),
            ))
        .toList();

    final prods = masterCatalogProducts
        .where((p) => p.businessTypeId == businessTypeId)
        .map((p) => MasterProductsTableCompanion(
              id: Value(p.id),
              businessTypeId: Value(p.businessTypeId),
              categoryId: Value(p.categoryId),
              categoryName: Value(p.categoryName),
              productName: Value(p.productName),
              skuTemplate: Value(p.skuTemplate),
              barcode: Value(p.barcode),
              defaultUnit: Value(p.defaultUnit),
              suggestedCostPrice: Value(p.suggestedCostPrice),
              suggestedSellingPrice: Value(p.suggestedSellingPrice),
              searchableKeywords:
                  Value(jsonEncode(p.searchableKeywords)),
              isActive: const Value(1),
              cachedAt: Value(now),
            ))
        .toList();

    if (cats.isNotEmpty) {
      await _db.masterCatalogDao.upsertCategories(cats);
    }
    if (prods.isNotEmpty) {
      await _db.masterCatalogDao.upsertProducts(prods);
    }
  }

  /// Tries to fetch fresh data from Firestore global collections.
  /// Falls back silently on network failure.
  Future<void> _refreshFromFirestore(String businessTypeId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Fetch categories
      final catSnap = await _firestore
          .collection('master_categories')
          .where('businessTypeId', isEqualTo: businessTypeId)
          .where('isActive', isEqualTo: true)
          .get();

      if (catSnap.docs.isNotEmpty) {
        final cats = catSnap.docs
            .map((d) {
              final data = d.data();
              return MasterCategoriesTableCompanion(
                id: Value(d.id),
                businessTypeId:
                    Value(data['businessTypeId'] as String? ?? businessTypeId),
                categoryName:
                    Value(data['categoryName'] as String? ?? ''),
                description:
                    Value(data['description'] as String? ?? ''),
                icon: Value(data['icon'] as String? ?? ''),
                isActive: const Value(1),
                cachedAt: Value(now),
              );
            })
            .toList();
        await _db.masterCatalogDao.upsertCategories(cats);
      }

      // Fetch products
      final prodSnap = await _firestore
          .collection('master_products')
          .where('businessTypeId', isEqualTo: businessTypeId)
          .where('isActive', isEqualTo: true)
          .get();

      if (prodSnap.docs.isNotEmpty) {
        final prods = prodSnap.docs
            .map((d) {
              final data = d.data();
              final rawKw = data['searchableKeywords'];
              final kwJson = rawKw is List
                  ? jsonEncode(rawKw)
                  : '[]';
              return MasterProductsTableCompanion(
                id: Value(d.id),
                businessTypeId:
                    Value(data['businessTypeId'] as String? ?? businessTypeId),
                categoryId:
                    Value(data['categoryId'] as String? ?? ''),
                categoryName:
                    Value(data['categoryName'] as String? ?? ''),
                productName:
                    Value(data['productName'] as String? ?? ''),
                skuTemplate:
                    Value(data['skuTemplate'] as String? ?? ''),
                barcode: Value(data['barcode'] as String? ?? ''),
                defaultUnit:
                    Value(data['defaultUnit'] as String? ?? 'pcs'),
                suggestedCostPrice: Value(
                    (data['suggestedCostPrice'] as num?)?.toDouble() ?? 0),
                suggestedSellingPrice: Value(
                    (data['suggestedSellingPrice'] as num?)?.toDouble() ?? 0),
                searchableKeywords: Value(kwJson),
                isActive: const Value(1),
                cachedAt: Value(now),
              );
            })
            .toList();
        await _db.masterCatalogDao.upsertProducts(prods);
      }
    } catch (_) {
      // Network failure — local seed data remains available.
    }
  }

  // ── Mapping ────────────────────────────────────────────────────────────────

  MasterProduct _rowToProduct(MasterProductsTableData r) {
    final kw = jsonDecode(r.searchableKeywords) as List;
    return MasterProduct(
      id: r.id,
      businessTypeId: r.businessTypeId,
      categoryId: r.categoryId,
      categoryName: r.categoryName,
      productName: r.productName,
      skuTemplate: r.skuTemplate,
      barcode: r.barcode,
      defaultUnit: r.defaultUnit,
      suggestedCostPrice: r.suggestedCostPrice,
      suggestedSellingPrice: r.suggestedSellingPrice,
      searchableKeywords: kw.map((e) => e.toString()).toList(),
      isActive: r.isActive == 1,
    );
  }
}
