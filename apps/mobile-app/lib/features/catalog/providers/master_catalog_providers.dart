import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../product/data/category_providers.dart';
import '../data/master_catalog_repository.dart';
import '../domain/models/master_category.dart';
import '../domain/models/master_product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

final masterCatalogRepositoryProvider =
    Provider<MasterCatalogRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MasterCatalogRepository(db: db);
});

// ─────────────────────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────────────────────

/// Master categories for the active business type.
final masterCategoriesProvider =
    FutureProvider<List<MasterCategory>>((ref) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);

  // Await the stream's first emission so that:
  //  (a) we use the real business type, not the 'retail' fallback, and
  //  (b) the Firebase Auth token has been applied to the Firestore connection
  //      before we hit the master_categories collection.
  final bizTypeFuture = ref.watch(currentBusinessTypeProvider.future);
  String bizType;
  try {
    bizType = await bizTypeFuture;
  } catch (_) {
    bizType = '';
  }
  if (bizType.isEmpty) bizType = 'retail';

  return repo.getCategoriesForType(bizType);
});

// ─────────────────────────────────────────────────────────────────────────────
// Products
// ─────────────────────────────────────────────────────────────────────────────

/// All master products for the active business type.
final masterProductsProvider =
    FutureProvider<List<MasterProduct>>((ref) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizTypeFuture = ref.watch(currentBusinessTypeProvider.future);
  String bizType;
  try {
    bizType = await bizTypeFuture;
  } catch (_) {
    bizType = '';
  }
  if (bizType.isEmpty) bizType = 'retail';

  return repo.getProductsForType(bizType);
});

/// Master products filtered by category slug.
final masterProductsByCategoryProvider =
    FutureProvider.family<List<MasterProduct>, String>((ref, categorySlug) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizTypeFuture = ref.watch(currentBusinessTypeProvider.future);
  String bizType;
  try {
    bizType = await bizTypeFuture;
  } catch (_) {
    bizType = '';
  }
  if (bizType.isEmpty) bizType = 'retail';

  if (categorySlug.isEmpty) return repo.getProductsForType(bizType);
  return repo.getProductsForCategory(bizType, categorySlug);
});

// ─────────────────────────────────────────────────────────────────────────────
// Catalog search state
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the current catalog search query.
final catalogSearchQueryProvider = StateProvider<String>((ref) => '');

/// Holds the currently selected category slug filter ('' = all).
final catalogSelectedCategoryProvider = StateProvider<String>((ref) => '');

/// Filtered + searched master products based on query and category filter.
final catalogSearchResultsProvider =
    FutureProvider<List<MasterProduct>>((ref) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizTypeFuture = ref.watch(currentBusinessTypeProvider.future);
  final query = ref.watch(catalogSearchQueryProvider);
  final categorySlug = ref.watch(catalogSelectedCategoryProvider);

  String bizType;
  try {
    bizType = await bizTypeFuture;
  } catch (_) {
    bizType = '';
  }
  if (bizType.isEmpty) bizType = 'retail';

  if (query.isEmpty && categorySlug.isEmpty) {
    return repo.getProductsForType(bizType);
  }
  if (query.isEmpty && categorySlug.isNotEmpty) {
    return repo.getProductsForCategory(bizType, categorySlug);
  }

  // Search across all products first, then optionally filter by category
  final results = await repo.searchProducts(bizType, query);
  if (categorySlug.isEmpty) return results;
  return results.where((p) => p.categorySlug == categorySlug).toList();
});
