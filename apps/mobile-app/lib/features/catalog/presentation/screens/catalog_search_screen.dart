import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../data/master_catalog_repository.dart';
import '../../domain/models/master_category.dart';
import '../../domain/models/master_product.dart';
import '../../providers/master_catalog_providers.dart';
import 'import_product_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Full-screen catalog browser. Supports:
/// - Real-time search by name, barcode, or keyword
/// - Category chip filter
/// - Import into business inventory
class CatalogSearchScreen extends ConsumerStatefulWidget {
  const CatalogSearchScreen({super.key});

  @override
  ConsumerState<CatalogSearchScreen> createState() =>
      _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends ConsumerState<CatalogSearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    // Reset filters when leaving
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Reset catalog filters on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogSearchQueryProvider.notifier).state = '';
      ref.read(catalogSelectedCategoryProvider.notifier).state = '';
    });
  }

  void _onSearchChanged(String value) {
    ref.read(catalogSearchQueryProvider.notifier).state = value;
  }

  void _onCategorySelected(String categorySlug) {
    final current = ref.read(catalogSelectedCategoryProvider);
    ref.read(catalogSelectedCategoryProvider.notifier).state =
        current == categorySlug ? '' : categorySlug;
  }

  void _openImport(MasterProduct product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      builder: (_) => ImportProductScreen(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(masterCategoriesProvider);
    final resultsAsync = ref.watch(catalogSearchResultsProvider);
    final selectedCatId = ref.watch(catalogSelectedCategoryProvider);
    final query = ref.watch(catalogSearchQueryProvider);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Handle + header ──────────────────────────────────────────────
          SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tr('Product Catalog', 'Katalogi ya Bidhaa'),
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),

          // ── Category chips ───────────────────────────────────────────────
          categoriesAsync.when(
            loading: () => const SizedBox(height: 52),
            error: (err, st) => const SizedBox.shrink(),
            data: (cats) => _CategoryChips(
              categories: cats,
              selectedId: selectedCatId,
              onSelected: _onCategorySelected,
            ),
          ),

          // ── Results header ───────────────────────────────────────────────
          resultsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
            data: (products) => _ResultsHeader(
              count: products.length,
              query: query,
              selectedCatName: selectedCatId.isEmpty
                  ? ''
                  : (categoriesAsync.valueOrNull
                          ?.where((c) => c.categorySlug == selectedCatId)
                          .firstOrNull
                          ?.categoryName ??
                      ''),
            ),
          ),

          // ── Product list ─────────────────────────────────────────────────
          Expanded(
            child: resultsAsync.when(
              loading: () => const _CatalogLoading(),
              error: (e, _) => _CatalogError(
                error: e,
                onRetry: () {
                  ref.invalidate(catalogSearchResultsProvider);
                  ref.invalidate(masterCategoriesProvider);
                },
              ),
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyResults(
                    query: query,
                    hasFilter: selectedCatId.isNotEmpty,
                    onClear: () {
                      _searchCtrl.clear();
                      ref.read(catalogSearchQueryProvider.notifier).state = '';
                      ref
                          .read(catalogSelectedCategoryProvider.notifier)
                          .state = '';
                    },
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => _ProductCard(
                    product: products[i],
                    onImport: () => _openImport(products[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.navyPrimary),
      decoration: InputDecoration(
        hintText: _tr(
          'Search by name, barcode or keyword…',
          'Tafuta kwa jina, msimbo au neno…',
        ),
        hintStyle:
            GoogleFonts.dmSans(fontSize: 14, color: Color(0xFF64748B)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Color(0xFF64748B), size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<MasterCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 52,
      color: const Color(0xFFF8F9FC),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = cat.categorySlug == selectedId;
          return GestureDetector(
            onTap: () => onSelected(cat.categorySlug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.tealAccent : Colors.white,
                border: Border.all(
                  color: selected
                      ? AppColors.tealAccent
                      : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat.categoryName,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final int count;
  final String query;
  final String selectedCatName;

  const _ResultsHeader({
    required this.count,
    required this.query,
    required this.selectedCatName,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (query.isNotEmpty) {
      parts.add(_tr('Results for "$query"', 'Matokeo ya "$query"'));
    }
    if (selectedCatName.isNotEmpty) {
      parts.add(selectedCatName);
    }
    final label = parts.isNotEmpty
        ? parts.join(' · ')
        : _tr('All Products', 'Bidhaa Zote');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MasterProduct product;
  final VoidCallback onImport;

  const _ProductCard({required this.product, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            // Product icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.tealAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.productNameSw.isNotEmpty &&
                      product.productNameSw != product.productName) ...[
                    SizedBox(height: 1),
                    Text(
                      product.productNameSw,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.categorySlug.isNotEmpty)
                        _Pill(
                          label: product.categorySlug
                              .replaceAll('-', ' ')
                              .split(' ')
                              .map((w) => w.isEmpty
                                  ? ''
                                  : '${w[0].toUpperCase()}${w.substring(1)}')
                              .join(' '),
                          color: AppColors.tealAccent,
                          bg: const Color(0xFFE0F2F7),
                        ),
                      if (product.categorySlug.isNotEmpty)
                        const SizedBox(width: 6),
                      _Pill(
                        label: product.unit,
                        color: AppColors.textMuted,
                        bg: const Color(0xFFF1F5F9),
                      ),
                      if (product.prescriptionRequired) ...[
                        const SizedBox(width: 6),
                        _Pill(
                          label: _tr('Rx', 'Rx'),
                          color: const Color(0xFFD97706),
                          bg: const Color(0xFFFEF3C7),
                        ),
                      ],
                      if (product.coldStorage) ...[
                        const SizedBox(width: 6),
                        _Pill(
                          label: _tr('Cold', 'Baridi'),
                          color: const Color(0xFF0284C7),
                          bg: const Color(0xFFE0F2FE),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Import button
            const SizedBox(width: 8),
            _ImportButton(onTap: onImport),
          ],
        ),
      ),
    );
  }

}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ImportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.navyPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _tr('Import', 'Ingiza'),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 8,
      itemBuilder: (context, i) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _CatalogError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isNoCache = error is CatalogOfflineException;
    final isExpired = error is CatalogCacheExpiredException;

    final icon = isNoCache || isExpired
        ? Icons.wifi_off_rounded
        : Icons.error_outline_rounded;

    final title = isNoCache
        ? _tr(
            'Internet required for first use',
            'Muunganiko wa intaneti unahitajika mara ya kwanza',
          )
        : isExpired
            ? _tr(
                'Catalog needs a refresh',
                'Katalogi inahitaji kusasishwa',
              )
            : _tr('Could not load catalog', 'Imeshindikana kupakia katalogi');

    final subtitle = isNoCache
        ? _tr(
            'Connect to the internet once to download your industry catalog. '
            'After that it works offline for 24 hours.',
            'Unganisha intaneti mara moja kupakua katalogi ya tasnia yako. '
            'Baadaye inafanya kazi bila intaneti kwa masaa 24.',
          )
        : isExpired
            ? _tr(
                'Your offline catalog is more than 24 hours old. '
                'Connect briefly to refresh it.',
                'Katalogi yako ya nje ya mtandao ina zaidi ya masaa 24. '
                'Unganisha kwa muda mfupi kuisasisha.',
              )
            : _tr(
                'Check your connection and try again.',
                'Angalia muunganiko wako na ujaribu tena.',
              );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_tr('Try Again', 'Jaribu Tena')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyResults({
    required this.query,
    required this.hasFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? _tr('No results for "$query"',
                      'Hakuna matokeo ya "$query"')
                  : _tr('No products in this category',
                      'Hakuna bidhaa katika kategoria hii'),
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navyPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              _tr(
                'Try a different search term or browse all products.',
                'Jaribu neno tofauti au angalia bidhaa zote.',
              ),
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (query.isNotEmpty || hasFilter) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onClear,
                child: Text(_tr('Clear Search', 'Futa Utafutaji')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
