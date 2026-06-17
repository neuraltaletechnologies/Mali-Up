import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/master_category.dart';
import '../domain/models/master_product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MasterCatalogRepository
//
// Source of truth: Firestore global collections (master_categories,
// master_products), filtered by businessTypeId.
//
// Cache: local Drift SQLite — valid for 24 hours per business type.
//
// First use REQUIRES a network connection. After that the app works
// fully offline for up to 24 hours using the cached rows.
//
// After 24 hours without connectivity the caller receives a
// [CatalogCacheExpiredException] so the UI can tell the user to reconnect.
// ─────────────────────────────────────────────────────────────────────────────

const _cacheTtlMs = 24 * 60 * 60 * 1000; // 24 hours

class CatalogOfflineException implements Exception {
  final String businessTypeId;
  const CatalogOfflineException(this.businessTypeId);

  @override
  String toString() =>
      'CatalogOfflineException: no cached catalog for "$businessTypeId". '
      'Connect to the internet to load the product catalog.';
}

class CatalogCacheExpiredException implements Exception {
  const CatalogCacheExpiredException();

  @override
  String toString() =>
      'CatalogCacheExpiredException: catalog cache is older than 24 hours. '
      'Connect to refresh.';
}

class MasterCatalogRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  MasterCatalogRepository({
    required AppDatabase db,
    FirebaseFirestore? firestore,
  })  : _db = db,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Public read API ────────────────────────────────────────────────────────

  Future<List<MasterCategory>> getCategoriesForType(
    String businessTypeId,
  ) async {
    await _ensureFresh(businessTypeId);
    final rows =
        await _db.masterCatalogDao.getCategoriesForType(businessTypeId);
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

  Future<List<MasterProduct>> getProductsForType(
    String businessTypeId,
  ) async {
    await _ensureFresh(businessTypeId);
    final rows =
        await _db.masterCatalogDao.getProductsForType(businessTypeId);
    return rows.map(_rowToProduct).toList();
  }

  Future<List<MasterProduct>> getProductsForCategory(
    String businessTypeId,
    String categoryId,
  ) async {
    await _ensureFresh(businessTypeId);
    final rows = await _db.masterCatalogDao
        .getProductsForCategory(businessTypeId, categoryId);
    return rows.map(_rowToProduct).toList();
  }

  Future<List<MasterProduct>> searchProducts(
    String businessTypeId,
    String query,
  ) async {
    await _ensureFresh(businessTypeId);
    if (query.trim().isEmpty) return getProductsForType(businessTypeId);
    final rows =
        await _db.masterCatalogDao.searchProducts(businessTypeId, query.trim());
    return rows.map(_rowToProduct).toList();
  }

  // ── Cache management ───────────────────────────────────────────────────────

  /// Ensures the local cache for [businessTypeId] is populated and not older
  /// than 24 hours.
  ///
  /// - No cache → fetch from Firestore. Throws [CatalogOfflineException] if
  ///   the device is offline and the cache is empty.
  /// - Cache exists but is stale (> 24 h) → attempt Firestore refresh.
  ///   If refresh fails (offline), throws [CatalogCacheExpiredException].
  /// - Cache is fresh → use as-is, no network call.
  Future<void> _ensureFresh(String businessTypeId) async {
    final catCount =
        await _db.masterCatalogDao.categoryCount(businessTypeId);

    if (catCount == 0) {
      // No cache at all — must go online.
      await _fetchFromFirestore(businessTypeId);
      return;
    }

    final ageMs = await _cacheAgeMs(businessTypeId);
    if (ageMs == null || ageMs > _cacheTtlMs) {
      // Cache is stale — try to refresh; if offline throw so UI can warn.
      await _fetchFromFirestore(businessTypeId);
    }
  }

  /// Returns how old the cache is in milliseconds, or null if no rows exist.
  Future<int?> _cacheAgeMs(String businessTypeId) async {
    final rows =
        await _db.masterCatalogDao.getCategoriesForType(businessTypeId);
    if (rows.isEmpty) return null;
    final cachedAt = rows.first.cachedAt;
    if (cachedAt == 0) return null;
    return DateTime.now().millisecondsSinceEpoch - cachedAt;
  }

  /// Fetches categories + products for [businessTypeId] from Firestore and
  /// writes them into Drift. Throws on network failure.
  Future<void> _fetchFromFirestore(String businessTypeId) async {
    final hasCacheAlready =
        await _db.masterCatalogDao.categoryCount(businessTypeId) > 0;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Always fetch from server — persistence is disabled so the SDK
      // in-memory cache is irrelevant; being explicit avoids ambiguity.
      const opts = GetOptions(source: Source.server);

      // ── Categories ────────────────────────────────────────────────────────
      final catSnap = await _firestore
          .collection('master_categories')
          .where('businessTypeId', isEqualTo: businessTypeId)
          .where('isActive', isEqualTo: true)
          .get(opts);

      final cats = catSnap.docs.map((d) {
        final data = d.data();
        return MasterCategoriesTableCompanion(
          id: Value(d.id),
          businessTypeId:
              Value(data['businessTypeId'] as String? ?? businessTypeId),
          categoryName: Value(data['categoryName'] as String? ?? ''),
          description: Value(data['description'] as String? ?? ''),
          icon: Value(data['icon'] as String? ?? ''),
          isActive: const Value(1),
          cachedAt: Value(now),
        );
      }).toList();

      if (cats.isNotEmpty) {
        await _db.masterCatalogDao.upsertCategories(cats);
      }

      // ── Products ──────────────────────────────────────────────────────────
      final prodSnap = await _firestore
          .collection('master_products')
          .where('businessTypeId', isEqualTo: businessTypeId)
          .where('isActive', isEqualTo: true)
          .get(opts);

      final prods = prodSnap.docs.map((d) {
        final data = d.data();
        final rawKw = data['searchableKeywords'];
        final kwJson = rawKw is List ? jsonEncode(rawKw) : '[]';
        return MasterProductsTableCompanion(
          id: Value(d.id),
          businessTypeId:
              Value(data['businessTypeId'] as String? ?? businessTypeId),
          categoryId: Value(data['categoryId'] as String? ?? ''),
          categoryName: Value(data['categoryName'] as String? ?? ''),
          productName: Value(data['productName'] as String? ?? ''),
          skuTemplate: Value(data['skuTemplate'] as String? ?? ''),
          barcode: Value(data['barcode'] as String? ?? ''),
          defaultUnit: Value(data['defaultUnit'] as String? ?? 'pcs'),
          suggestedCostPrice:
              Value((data['suggestedCostPrice'] as num?)?.toDouble() ?? 0),
          suggestedSellingPrice:
              Value((data['suggestedSellingPrice'] as num?)?.toDouble() ?? 0),
          searchableKeywords: Value(kwJson),
          isActive: const Value(1),
          cachedAt: Value(now),
        );
      }).toList();

      if (prods.isNotEmpty) {
        await _db.masterCatalogDao.upsertProducts(prods);
      }
    } catch (e) {
      // Only treat genuine network/connectivity errors as offline.
      // permission-denied, failed-precondition, etc. are NOT offline errors —
      // catching them as offline was hiding the real cause from the user.
      debugPrint('[MasterCatalog] fetch failed for "$businessTypeId": $e');
      final isOffline = e is FirebaseException &&
          (e.code == 'unavailable' ||
              e.code == 'deadline-exceeded' ||
              e.code == 'network-request-failed');

      if (!hasCacheAlready) {
        if (isOffline) throw const CatalogOfflineException('');
        rethrow;
      } else {
        if (isOffline) throw const CatalogCacheExpiredException();
        rethrow;
      }
    }
  }

  // ── Community contributions ────────────────────────────────────────────────

  /// Writes a user-contributed category to the shared [master_categories]
  /// collection (source = 'community') and upserts it into the local cache
  /// so it appears immediately without waiting for the next TTL refresh.
  Future<MasterCategory> addCommunityCategory({
    required String businessTypeId,
    required String categoryName,
    required String addedByUid,
  }) async {
    final trimmed = categoryName.trim();
    final slug = _slugify(trimmed);
    final id = '${slug}_${businessTypeId}_community';

    await _firestore.collection('master_categories').doc(id).set({
      'businessTypeId': businessTypeId,
      'categoryName': trimmed,
      'description': '',
      'icon': '',
      'isActive': true,
      'source': 'community',
      'addedByUid': addedByUid,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.masterCatalogDao.upsertCategories([
      MasterCategoriesTableCompanion(
        id: Value(id),
        businessTypeId: Value(businessTypeId),
        categoryName: Value(trimmed),
        description: const Value(''),
        icon: const Value(''),
        isActive: const Value(1),
        cachedAt: Value(now),
      ),
    ]);

    return MasterCategory(
      id: id,
      businessTypeId: businessTypeId,
      categoryName: trimmed,
    );
  }

  String _slugify(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

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
