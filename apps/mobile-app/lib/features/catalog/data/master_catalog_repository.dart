import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'catalog_submission_service.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/master_category.dart';
import '../domain/models/master_product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MasterCatalogRepository
//
// Source of truth: Firestore global collections (master_categories,
// master_products), filtered by businessTypes (array of human-readable
// catalog names — an item may belong to more than one business type).
//
// Cache: local Drift SQLite — valid for 24 hours per normalised business-type.
// The cache key is the app's normalised token (e.g. "retail", "pharmacy")
// while Firestore stores the human-readable value ("Retail", "Pharmacy & Healthcare").
//
// First use REQUIRES a network connection. After that the app works
// fully offline for up to 24 hours using the cached rows.
// ─────────────────────────────────────────────────────────────────────────────

const _cacheTtlMs = 24 * 60 * 60 * 1000; // 24 hours

class CatalogOfflineException implements Exception {
  final String businessType;
  const CatalogOfflineException(this.businessType);

  @override
  String toString() =>
      'CatalogOfflineException: no cached catalog for "$businessType". '
      'Connect to the internet to load the product catalog.';
}

class CatalogCacheExpiredException implements Exception {
  const CatalogCacheExpiredException();

  @override
  String toString() =>
      'CatalogCacheExpiredException: catalog cache is older than 24 hours. '
      'Connect to refresh.';
}

// ─────────────────────────────────────────────────────────────────────────────
// Business-type name mapping
// The app normalises business type into a small set of keys (e.g. "retail").
// The catalog stores them as full human-readable names (e.g. "Retail").
// ─────────────────────────────────────────────────────────────────────────────

List<String> _catalogTypeNames(String normalizedKey) {
  switch (normalizedKey) {
    case 'retail':
      return ['Retail'];
    case 'wholesale':
      return ['Wholesale', 'Supermarket', 'Grocery & Convenience'];
    case 'restaurant':
      return ['Restaurant', 'Cafe & Bakery', 'Street Food', 'Catering'];
    case 'electronics':
      return ['Electronics & Mobile Phones'];
    case 'tailoring':
      return ['Fashion & Boutique', 'Tailoring & Textiles'];
    case 'salon':
      return ['Beauty & Cosmetics', 'Salon & Barber'];
    case 'hardware':
      return ['Hardware & Building Materials'];
    case 'construction':
      return ['Construction'];
    case 'pharmacy':
      return ['Pharmacy & Healthcare', 'Clinic & Laboratory'];
    case 'agriculture':
      return [
        'Agriculture',
        'Agribusiness',
        'Livestock & Poultry',
        'Fishing',
        'Agricultural Inputs',
      ];
    case 'transport':
      return [
        'Transportation & Logistics',
        'Automotive & Spare Parts',
        'Fuel & Lubricants',
        'Auto Repair',
      ];
    case 'service':
      return [
        'Education & Training',
        'Real Estate',
        'Financial Services',
        'ICT & Software',
        'Printing & Stationery',
        'Entertainment & Events',
        'Cleaning Services',
        'Security Services',
        'NGO & Community Services',
        'Export & Import',
        'Media & Communications',
        'Jewelry & Crafts',
        'Furniture & Carpentry',
        'Water & Beverages',
        'Travel & Tours',
        'Hotel & Accommodation',
        'Manufacturing',
        'E-Commerce',
      ];
    default:
      return ['Retail'];
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class MasterCatalogRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final CatalogSubmissionService _submissions;

  MasterCatalogRepository({
    required AppDatabase db,
    FirebaseFirestore? firestore,
    CatalogSubmissionService? submissions,
  }) : _db = db,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _submissions = submissions ?? CatalogSubmissionService();

  // ── Public read API ────────────────────────────────────────────────────────

  Future<List<MasterCategory>> getCategoriesForType(String businessType) async {
    await _ensureFresh(businessType);
    final rows = await _db.masterCatalogDao.getCategoriesForType(businessType);
    return rows
        .map(
          (r) => MasterCategory(
            id: r.id,
            businessType: r.businessType,
            categoryName: r.categoryName,
            categoryNameSw: r.categoryNameSw,
            categorySlug: r.categorySlug,
            icon: r.icon,
            displayOrder: r.displayOrder,
          ),
        )
        .toList();
  }

  Future<List<MasterProduct>> getProductsForType(String businessType) async {
    await _ensureFresh(businessType);
    final rows = await _db.masterCatalogDao.getProductsForType(businessType);
    return rows.map(_rowToProduct).toList();
  }

  Future<List<MasterProduct>> getProductsForCategory(
    String businessType,
    String categorySlug,
  ) async {
    await _ensureFresh(businessType);
    final rows = await _db.masterCatalogDao.getProductsForCategory(
      businessType,
      categorySlug,
    );
    return rows.map(_rowToProduct).toList();
  }

  Future<List<MasterProduct>> searchProducts(
    String businessType,
    String query,
  ) async {
    await _ensureFresh(businessType);
    if (query.trim().isEmpty) return getProductsForType(businessType);
    final rows = await _db.masterCatalogDao.searchProducts(
      businessType,
      query.trim(),
    );
    return rows.map(_rowToProduct).toList();
  }

  // ── Cache management ───────────────────────────────────────────────────────

  Future<void> _ensureFresh(String businessType) async {
    final catCount = await _db.masterCatalogDao.categoryCount(businessType);

    if (catCount == 0) {
      await _fetchFromFirestore(businessType);
      return;
    }

    final ageMs = await _cacheAgeMs(businessType);
    if (ageMs == null || ageMs > _cacheTtlMs) {
      await _fetchFromFirestore(businessType);
    }
  }

  Future<int?> _cacheAgeMs(String businessType) async {
    final rows = await _db.masterCatalogDao.getCategoriesForType(businessType);
    if (rows.isEmpty) return null;
    final cachedAt = rows.first.cachedAt;
    if (cachedAt == 0) return null;
    return DateTime.now().millisecondsSinceEpoch - cachedAt;
  }

  Future<void> _fetchFromFirestore(String businessType) async {
    final hasCacheAlready =
        await _db.masterCatalogDao.categoryCount(businessType) > 0;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      const opts = GetOptions(source: Source.server);

      final catalogNames = _catalogTypeNames(businessType);

      // ── Categories ──────────────────────────────────────────────────────
      final catSnap = await _firestore
          .collection('master_categories')
          .where('businessTypes', arrayContainsAny: catalogNames)
          .get(opts);

      final cats = catSnap.docs.map((d) {
        final data = d.data();
        return MasterCategoriesTableCompanion(
          id: Value(d.id),
          businessType: Value(businessType), // store normalised key
          categoryName: Value(data['categoryName'] as String? ?? ''),
          categoryNameSw: Value(data['categoryNameSw'] as String? ?? ''),
          categorySlug: Value(data['categorySlug'] as String? ?? d.id),
          icon: Value(data['icon'] as String? ?? ''),
          displayOrder: Value((data['displayOrder'] as num?)?.toInt() ?? 0),
          cachedAt: Value(now),
        );
      }).toList();

      if (cats.isNotEmpty) {
        await _db.masterCatalogDao.upsertCategories(cats);
      }

      // ── Products ─────────────────────────────────────────────────────────
      final prodSnap = await _firestore
          .collection('master_products')
          .where('businessTypes', arrayContainsAny: catalogNames)
          .get(opts);

      List<String> strList(dynamic v) =>
          v is List ? v.map((e) => e.toString()).toList() : <String>[];

      final prods = prodSnap.docs.map((d) {
        final data = d.data();
        return MasterProductsTableCompanion(
          id: Value(d.id),
          businessType: Value(businessType), // store normalised key
          categorySlug: Value(
            data['categorySlug'] as String? ??
                data['categoryId'] as String? ??
                '',
          ),
          productName: Value(data['productName'] as String? ?? ''),
          productNameSw: Value(data['productNameSw'] as String? ?? ''),
          productSlug: Value(data['productSlug'] as String? ?? d.id),
          genericName: Value(data['genericName'] as String? ?? ''),
          brandNames: Value(jsonEncode(strList(data['brandNames']))),
          unit: Value(
            data['unit'] as String? ??
                data['defaultUnit'] as String? ??
                'Piece',
          ),
          unitAlternatives: Value(
            jsonEncode(strList(data['unitAlternatives'])),
          ),
          commonBarcodes: Value(jsonEncode(strList(data['commonBarcodes']))),
          searchKeywords: Value(
            jsonEncode(
              strList(data['searchKeywords'] ?? data['searchableKeywords']),
            ),
          ),
          tags: Value(jsonEncode(strList(data['tags']))),
          prescriptionRequired: Value(
            (data['prescriptionRequired'] as bool? ?? false) ? 1 : 0,
          ),
          coldStorage: Value((data['coldStorage'] as bool? ?? false) ? 1 : 0),
          cachedAt: Value(now),
        );
      }).toList();

      if (prods.isNotEmpty) {
        await _db.masterCatalogDao.upsertProducts(prods);
      }
    } catch (e) {
      debugPrint('[MasterCatalog] fetch failed for "$businessType": $e');
      final isOffline =
          e is FirebaseException &&
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

  Future<MasterCategory> addCommunityCategory({
    required String businessType, // normalised key
    required String categoryName,
    required String addedByUid,
    String? businessId,
  }) async {
    final trimmed = categoryName.trim();
    final slug = _slugify(trimmed);
    final id = '${slug}_${businessType}_community';
    final catalogName = _catalogTypeNames(businessType).first;

    // The product form is offline-first. Persist the category locally before
    // attempting either community Firestore write, otherwise a denied or
    // offline request makes the Save button appear to do nothing.
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.masterCatalogDao.upsertCategories([
      MasterCategoriesTableCompanion(
        id: Value(id),
        businessType: Value(businessType),
        categoryName: Value(trimmed),
        categoryNameSw: const Value(''),
        categorySlug: Value(slug),
        icon: const Value(''),
        displayOrder: const Value(999),
        cachedAt: Value(now),
      ),
    ]);

    // Best-effort community contribution. The locally saved category remains
    // immediately usable even when this request is offline or not permitted.
    _firestore.collection('master_categories').doc(id).set({
      'businessTypes': [catalogName],
      'categoryName': trimmed,
      'categoryNameSw': '',
      'categorySlug': slug,
      'icon': '',
      'displayOrder': 999,
      'source': 'community',
      'addedByUid': addedByUid,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).ignore();

    // Submit to community submissions for admin awareness — fire and forget
    _submissions
        .submitCategory(
          categoryName: trimmed,
          businessType: businessType,
          businessTypeName: catalogName,
          submittedByUid: addedByUid,
          submittedByBusinessId: businessId ?? '',
        )
        .ignore();

    return MasterCategory(
      id: id,
      businessType: businessType,
      categoryName: trimmed,
      categorySlug: slug,
    );
  }

  String _slugify(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  // ── Mapping ────────────────────────────────────────────────────────────────

  MasterProduct _rowToProduct(MasterProductsTableData r) {
    List<String> decode(String json) {
      try {
        return (jsonDecode(json) as List).map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }

    return MasterProduct(
      id: r.id,
      businessType: r.businessType,
      categorySlug: r.categorySlug,
      productName: r.productName,
      productNameSw: r.productNameSw,
      productSlug: r.productSlug,
      genericName: r.genericName,
      brandNames: decode(r.brandNames),
      unit: r.unit,
      unitAlternatives: decode(r.unitAlternatives),
      commonBarcodes: decode(r.commonBarcodes),
      searchKeywords: decode(r.searchKeywords),
      tags: decode(r.tags),
      prescriptionRequired: r.prescriptionRequired == 1,
      coldStorage: r.coldStorage == 1,
    );
  }
}
