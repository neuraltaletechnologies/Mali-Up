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
// Business type resolution
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves the current business type, or `null` while it's still unknown.
///
/// Watches [currentBusinessTypeProvider] itself (not just its `.future`) so
/// dependents rebuild on *every* emission — including a later change of
/// business type — not just the first one. Watching only `.future` on a
/// [StreamProvider] resolves once and then goes stale: switching business
/// type in Settings updated the stream, but callers that only awaited
/// `.future` never rebuilt, so the category/product pickers kept showing the
/// previous business type's catalog until the app restarted.
///
/// Deliberately returns `null` (never a hardcoded vertical like 'retail')
/// when the real type hasn't resolved yet — e.g. still loading, or the 4s
/// offline timeout in [currentBusinessTypeProvider] emitting ''. A pharmacy
/// account on a slow connection must never see another vertical's catalog
/// (e.g. "Unga") just because its own business type hadn't loaded yet;
/// callers should show no suggestions instead until the real value arrives.
Future<String?> _resolveBizType(Ref ref) async {
  final bizTypeAsync = ref.watch(currentBusinessTypeProvider);
  String bizType;
  if (bizTypeAsync.hasValue) {
    bizType = bizTypeAsync.value!;
  } else {
    try {
      bizType = await ref.watch(currentBusinessTypeProvider.future);
    } catch (_) {
      bizType = '';
    }
  }
  return bizType.isEmpty ? null : bizType;
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────────────────────

/// Master categories for the active business type.
final masterCategoriesProvider =
    FutureProvider<List<MasterCategory>>((ref) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizType = await _resolveBizType(ref);
  if (bizType == null) return const [];
  return repo.getCategoriesForType(bizType);
});

// ─────────────────────────────────────────────────────────────────────────────
// Products
// ─────────────────────────────────────────────────────────────────────────────

/// All master products for the active business type.
final masterProductsProvider =
    FutureProvider<List<MasterProduct>>((ref) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizType = await _resolveBizType(ref);
  if (bizType == null) return const [];
  return repo.getProductsForType(bizType);
});

/// Master products filtered by category slug.
final masterProductsByCategoryProvider =
    FutureProvider.family<List<MasterProduct>, String>((ref, categorySlug) async {
  final repo = ref.watch(masterCatalogRepositoryProvider);
  final bizType = await _resolveBizType(ref);
  if (bizType == null) return const [];

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
  final query = ref.watch(catalogSearchQueryProvider);
  final categorySlug = ref.watch(catalogSelectedCategoryProvider);
  final bizType = await _resolveBizType(ref);
  if (bizType == null) return const [];

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
