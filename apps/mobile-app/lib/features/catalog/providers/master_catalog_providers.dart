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
  final bizType =
      ref.watch(currentBusinessTypeProvider).valueOrNull ?? 'retail';
  return repo.getCategoriesForType(bizType);
});

// ─────────────────────────────────────────────────────────────────────────────
// Products
// ─────────────────────────────────────────────────────────────────────────────

/// All master products for the active business type.
final masterProductsProvider =
    FutureProvider<List<MasterProduct>>((ref) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizType =
      ref.watch(currentBusinessTypeProvider).valueOrNull ?? 'retail';
  return repo.getProductsForType(bizType);
});

/// Master products filtered by category.
final masterProductsByCategoryProvider =
    FutureProvider.family<List<MasterProduct>, String>((ref, categoryId) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizType =
      ref.watch(currentBusinessTypeProvider).valueOrNull ?? 'retail';
  if (categoryId.isEmpty) return repo.getProductsForType(bizType);
  return repo.getProductsForCategory(bizType, categoryId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Catalog search state
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the current catalog search query.
final catalogSearchQueryProvider = StateProvider<String>((ref) => '');

/// Holds the currently selected category filter ('': all).
final catalogSelectedCategoryProvider = StateProvider<String>((ref) => '');

/// Filtered + searched master products based on query and category filter.
final catalogSearchResultsProvider =
    FutureProvider<List<MasterProduct>>((ref) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizType =
      ref.watch(currentBusinessTypeProvider).valueOrNull ?? 'retail';
  final query = ref.watch(catalogSearchQueryProvider);
  final categoryId = ref.watch(catalogSelectedCategoryProvider);

  if (query.isEmpty && categoryId.isEmpty) {
    return repo.getProductsForType(bizType);
  }
  if (query.isEmpty && categoryId.isNotEmpty) {
    return repo.getProductsForCategory(bizType, categoryId);
  }

  // Search across all products first, then optionally filter by category
  final results = await repo.searchProducts(bizType, query);
  if (categoryId.isEmpty) return results;
  return results.where((p) => p.categoryId == categoryId).toList();
});
