import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/barcode_scanner_screen.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../product/data/category_providers.dart';
import '../../../product/domain/models/business_product_config.dart';
import '../../../product/domain/models/product_category.dart';
import '../../data/inventory_providers.dart';
import '../../domain/models/inventory_item.dart';
import '../providers/inventory_providers.dart';
import '../widgets/barcode_view_sheet.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─── Palette (3 semantic tones + white/black) ─────────────────────────────────
// ink   = AppColors.navyPrimary  (#0D1B3E) — primary text, headers
// muted = #64748B                           — secondary text, labels
// line  = #E2E8F0                           — borders, dividers
// accent= AppColors.tealAccent   (#1A6E8A) — interactive / highlight
// alert = AppColors.error        (#DC2626) — danger only
// ok    = AppColors.success      (#059669) — positive only

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ProductType { stock, perishable, service }

enum SortOption { nameAz, nameZa, stockLow, stockHigh, priceLow, priceHigh, marginHigh }

// ── Helpers ───────────────────────────────────────────────────────────────────

ProductType _readType(Map<String, dynamic> item) {
  switch (item['productType'] as String?) {
    case 'perishable': return ProductType.perishable;
    case 'service':    return ProductType.service;
    default:           return ProductType.stock;
  }
}

double _readBuyingPrice(Map<String, dynamic> item) =>
    parseUnitPrice(item['buyingPrice']);

double _readSellingPrice(Map<String, dynamic> item) =>
    parseUnitPrice(item['sellingPrice'] ?? item['price'] ?? item['unitPrice']);

double _profit(double buy, double sell) => sell > 0 ? sell - buy : 0;
double _margin(double buy, double sell) =>
    sell > 0 ? ((sell - buy) / sell) * 100 : 0;

String _fmtAmount(double v) {
  if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
  return 'TSh ${v.toStringAsFixed(0)}';
}

String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

int _reorder(Map<String, dynamic> item) {
  final r = parseStock(item['reorderPoint']);
  return r > 0 ? r : 5;
}

int _stock(Map<String, dynamic> item) =>
    parseStock(item['stock'] ?? item['currentStock'] ?? item['quantity']);

String _typeName(ProductType t) {
  switch (t) {
    case ProductType.stock:      return _tr('Stock', 'Stoo');
    case ProductType.perishable: return _tr('Perishable', 'Inayoharibika');
    case ProductType.service:    return _tr('Service', 'Huduma');
  }
}

IconData _typeIcon(ProductType t) {
  switch (t) {
    case ProductType.stock:      return Icons.inventory_2_outlined;
    case ProductType.perishable: return Icons.eco_outlined;
    case ProductType.service:    return Icons.handyman_outlined;
  }
}

// stock health: 0=service, 1=ok, 2=low, 3=out
int _healthLevel(Map<String, dynamic> item) {
  if (_readType(item) == ProductType.service) return 0;
  final s = _stock(item);
  if (s == 0) return 3;
  if (s <= _reorder(item)) return 2;
  return 1;
}

String _healthLabel(int level) {
  switch (level) {
    case 0: return _tr('Service', 'Huduma');
    case 3: return _tr('Out of Stock', 'Imeisha');
    case 2: return _tr('Low Stock', 'Inakwisha');
    default: return _tr('Healthy Stock', 'Stoo Ipo');
  }
}

// ── Expiry helpers ────────────────────────────────────────────────────────────

bool _isExpiredItem(Map<String, dynamic> item) {
  final expiry = (item['expiryDate'] as String?) ?? '';
  if (expiry.isEmpty) return false;
  final date = DateTime.tryParse(expiry);
  return date != null && date.isBefore(DateTime.now());
}

bool _isExpiringSoonItem(Map<String, dynamic> item) {
  final expiry = (item['expiryDate'] as String?) ?? '';
  if (expiry.isEmpty) return false;
  final date = DateTime.tryParse(expiry);
  if (date == null) return false;
  return date.isAfter(DateTime.now()) &&
      date.isBefore(DateTime.now().add(const Duration(days: 30)));
}

int _daysUntilExpiry(Map<String, dynamic> item) {
  final expiry = (item['expiryDate'] as String?) ?? '';
  if (expiry.isEmpty) return -1;
  final date = DateTime.tryParse(expiry);
  if (date == null) return -1;
  return date.difference(DateTime.now()).inDays;
}

// Full status: 0=service, 1=healthy, 2=low, 3=out, 4=expiring_soon, 5=expired
int _fullStatusLevel(Map<String, dynamic> item) {
  if (_readType(item) == ProductType.service) return 0;
  if (_isExpiredItem(item)) return 5;
  if (_isExpiringSoonItem(item)) return 4;
  final s = _stock(item);
  if (s == 0) return 3;
  if (s <= _reorder(item)) return 2;
  return 1;
}

Color _fullStatusColor(int level) {
  switch (level) {
    case 5: return AppColors.error;
    case 4: return const Color(0xFFD97706);
    case 3: return AppColors.error;
    case 2: return const Color(0xFFD97706);
    case 1: return AppColors.success;
    default: return AppColors.textMuted;
  }
}

String _fullStatusLabel(int level) {
  switch (level) {
    case 5: return _tr('Expired', 'Imeisha Muda');
    case 4: return _tr('Expiring Soon', 'Karibu Kuisha');
    case 3: return _tr('Out of Stock', 'Imeisha');
    case 2: return _tr('Low Stock', 'Inakwisha');
    case 1: return _tr('Healthy Stock', 'Stoo Ipo');
    default: return _tr('Service', 'Huduma');
  }
}

// ── Sort / Filter ─────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _applyFiltersAndSort(
  List<Map<String, dynamic>> src,
  String query,
  Set<ProductType> typeFilter,
  int healthFilter,  // 0=all, 1=ok, 2=low, 3=out
  int expiryFilter,  // 0=none, 1=expiring_soon, 2=expired
  SortOption sort,
) {
  final list = src.where((item) {
    final name = (item['name'] ?? item['productName'] ?? '').toString().toLowerCase();
    final cat  = (item['category'] ?? '').toString().toLowerCase();
    final sku  = (item['sku'] ?? '').toString().toLowerCase();
    final q = query.toLowerCase();
    if (q.isNotEmpty && !name.contains(q) && !cat.contains(q) && !sku.contains(q)) {
      return false;
    }
    if (typeFilter.isNotEmpty && !typeFilter.contains(_readType(item))) return false;
    if (healthFilter > 0 && _healthLevel(item) != healthFilter) return false;
    if (expiryFilter == 1 && !_isExpiringSoonItem(item)) return false;
    if (expiryFilter == 2 && !_isExpiredItem(item)) return false;
    return true;
  }).toList();

  list.sort((a, b) {
    switch (sort) {
      case SortOption.nameAz:
        return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
      case SortOption.nameZa:
        return (b['name'] ?? '').toString().compareTo((a['name'] ?? '').toString());
      case SortOption.stockLow:
        return _stock(a).compareTo(_stock(b));
      case SortOption.stockHigh:
        return _stock(b).compareTo(_stock(a));
      case SortOption.priceLow:
        return _readSellingPrice(a).compareTo(_readSellingPrice(b));
      case SortOption.priceHigh:
        return _readSellingPrice(b).compareTo(_readSellingPrice(a));
      case SortOption.marginHigh:
        return _margin(_readBuyingPrice(b), _readSellingPrice(b))
            .compareTo(_margin(_readBuyingPrice(a), _readSellingPrice(a)));
    }
  });

  return list;
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searchExpanded = false;
  SortOption _sort = SortOption.nameAz;
  Set<ProductType> _typeFilter = {};
  int _healthFilter = 0;
  int _expiryFilter = 0; // 0=none, 1=expiring_soon, 2=expired

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAdd(BuildContext ctx) {
    final mq = MediaQuery.of(ctx).size;
    showModalBottomSheet<void>(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: BoxConstraints(maxWidth: mq.width, maxHeight: mq.height),
      builder: (_) => const _ProductFormSheet(),
    );
  }

  void _openFilterSort(BuildContext ctx, List<Map<String, dynamic>> allItems) {
    showModalBottomSheet<void>(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _FilterSortSheet(
        currentSort: _sort,
        typeFilter: _typeFilter,
        healthFilter: _healthFilter,
        expiryFilter: _expiryFilter,
        onApply: (sort, types, health, expiry) => setState(() {
          _sort = sort;
          _typeFilter = types;
          _healthFilter = health;
          _expiryFilter = expiry;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemListProvider);
    final activeFilters = _typeFilter.length +
        (_healthFilter > 0 ? 1 : 0) +
        (_expiryFilter > 0 ? 1 : 0) +
        (_sort != SortOption.nameAz ? 1 : 0);

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 64,
        ),
        child: FloatingActionButton(
          onPressed: () => _openAdd(context),
          backgroundColor: AppColors.yellowBrand,
          foregroundColor: AppColors.navyPrimary,
          elevation: 3,
          child: const Icon(Icons.add_rounded, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          Expanded(
            child: inventoryAsync.when(
              loading: () => const InventoryPageSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.wifi_off_rounded,
                title: _tr('Could not load inventory', 'Imeshindikana kupakia stoo'),
                subtitle: _tr('Check your connection and try again.', 'Angalia muunganiko wako na ujaribu tena.'),
                actionLabel: _tr('Try again', 'Jaribu tena'),
                onAction: () => ref.invalidate(inventoryItemListProvider),
              ),
              data: (items) {
                final filtered = _applyFiltersAndSort(
                  items, _query, _typeFilter, _healthFilter, _expiryFilter, _sort,
                );
                return Column(
                  children: [
                    // ── Dark header: title + icons + pill straddling edge ─
                    _InventoryDarkHeader(
                      items: items,
                      searchCtrl: _searchCtrl,
                      query: _query,
                      searchExpanded: _searchExpanded,
                      onToggleSearch: () => setState(() {
                        _searchExpanded = !_searchExpanded;
                        if (!_searchExpanded) {
                          _searchCtrl.clear();
                          _query = '';
                        }
                      }),
                      onSearchChanged: (v) => setState(() => _query = v),
                      activeFilters: activeFilters,
                      onFilterTap: () => _openFilterSort(context, items),
                    ),
                    // Space for the pill's lower half that overflows the header
                    const SizedBox(height: _InventoryDarkHeader._pillHalf + 8),

                    // ── Active type filter chips ─────────────────────────
                    if (_typeFilter.isNotEmpty)
                      _ActiveFilterRow(
                        typeFilter: _typeFilter,
                        healthFilter: 0,
                        onClearType: (t) =>
                            setState(() => _typeFilter = {..._typeFilter}..remove(t)),
                        onClearHealth: () => setState(() => _healthFilter = 0),
                      ),

                    // ── List ─────────────────────────────────────────────
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyPlaceholder(hasQuery: _query.isNotEmpty || activeFilters > 0)
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 120),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) => _ProductRow(
                                item: filtered[i],
                                isLast: i == filtered.length - 1,
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// ── Inventory Dark Header (title + search icon) ───────────────────────────────

class _InventoryDarkHeader extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String query;
  final bool searchExpanded;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final int activeFilters;
  final VoidCallback onFilterTap;
  final List<Map<String, dynamic>> items;

  const _InventoryDarkHeader({
    required this.searchCtrl,
    required this.query,
    required this.searchExpanded,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.activeFilters,
    required this.onFilterTap,
    required this.items,
  });

  static const double _pillHalf = 22.0;

  Widget _buildPill() {
    double stockVal = 0, revenue = 0;
    int low = 0, out = 0;
    for (final item in items) {
      if (_readType(item) == ProductType.service) continue;
      final s = _stock(item);
      stockVal += _readBuyingPrice(item) * s;
      revenue  += _readSellingPrice(item) * s;
      if (s == 0) { out++; } else if (s <= _reorder(item)) { low++; }
    }
    final profit = revenue - stockVal;
    final alertCount = low + out;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillStat(label: _tr('Bidhaa', 'Bidhaa'), value: '${items.length}', color: AppColors.tealAccent),
          const _PillDivider(),
          _PillStat(label: _tr('Thamani', 'Thamani'), value: 'TSh ${_fmtShort(stockVal)}', color: AppColors.navyPrimary),
          const _PillDivider(),
          _PillStat(label: _tr('Faida', 'Faida'), value: 'TSh ${_fmtShort(profit)}', color: profit >= 0 ? AppColors.success : AppColors.error),
          const _PillDivider(),
          _PillStat(label: _tr('Tahadhari', 'Tahadhari'), value: '$alertCount', color: alertCount > 0 ? AppColors.warning : AppColors.success),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final hasAlerts = items.any((i) => _fullStatusLevel(i) >= 2);
    final showDot = hasAlerts || activeFilters > 0;
    final dotColor = hasAlerts ? AppColors.error : AppColors.yellowBrand;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dark rounded card
        Container(
          decoration: const BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20 + _pillHalf),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('Inventory', 'Bidhaa'),
                      style: GoogleFonts.dmSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Filter button
                  GestureDetector(
                    onTap: onFilterTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: activeFilters > 0
                            ? AppColors.yellowBrand.withValues(alpha: 0.18)
                            : Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: activeFilters > 0 ? AppColors.yellowBrand : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: activeFilters > 0 ? AppColors.yellowBrand : Colors.white,
                            size: 20,
                          ),
                          if (showDot)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Search button
                  GestureDetector(
                    onTap: onToggleSearch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: searchExpanded
                            ? AppColors.yellowBrand.withValues(alpha: 0.18)
                            : Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: searchExpanded ? AppColors.yellowBrand : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        searchExpanded ? Icons.close_rounded : Icons.search_rounded,
                        color: searchExpanded ? AppColors.yellowBrand : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: searchExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            controller: searchCtrl,
                            autofocus: true,
                            onChanged: onSearchChanged,
                            style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: _tr('Search products…', 'Tafuta bidhaa…'),
                              hintStyle: GoogleFonts.dmSans(fontSize: 14, color: Colors.white38),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.white54),
                              suffixIcon: query.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        searchCtrl.clear();
                                        onSearchChanged('');
                                      },
                                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white12,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.yellowBrand, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        // Pill straddling the rounded bottom edge
        Positioned(
          bottom: -_pillHalf,
          left: 0,
          right: 0,
          child: Center(child: _buildPill()),
        ),
      ],
    );
  }
}


class _PillStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PillStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 1,
        height: 28,
        color: AppColors.border,
      ),
    );
  }
}


// ── Active Filter Row ─────────────────────────────────────────────────────────

class _ActiveFilterRow extends StatelessWidget {
  final Set<ProductType> typeFilter;
  final int healthFilter;
  final ValueChanged<ProductType> onClearType;
  final VoidCallback onClearHealth;

  const _ActiveFilterRow({
    required this.typeFilter,
    required this.healthFilter,
    required this.onClearType,
    required this.onClearHealth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        children: [
          ...typeFilter.map(
            (t) => _FilterChip(
              label: _typeName(t),
              onRemove: () => onClearType(t),
            ),
          ),
          if (healthFilter > 0)
            _FilterChip(
              label: _healthLabel(healthFilter),
              onRemove: onClearHealth,
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ── Empty Placeholder ─────────────────────────────────────────────────────────

class _EmptyPlaceholder extends StatelessWidget {
  final bool hasQuery;
  const _EmptyPlaceholder({required this.hasQuery});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: hasQuery
            ? Icons.search_off_rounded
            : Icons.inventory_2_outlined,
        title: hasQuery
            ? _tr('No matches found', 'Hakuna inayolingana')
            : _tr('Your shelves are empty', 'Rafu zako ziko tupu'),
        subtitle: hasQuery
            ? _tr('Try a different search or remove a filter.',
                'Jaribu utafutaji tofauti au ondoa kichujio.')
            : _tr('Tap + to add your first product.',
                'Bonyeza + kuongeza bidhaa yako ya kwanza.'),
      );
}

// ── Product Row ───────────────────────────────────────────────────────────────

class _ProductRow extends ConsumerWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  const _ProductRow({required this.item, required this.isLast});

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    final id = (item['id'] as String?) ?? '';
    if (id.isEmpty) return;
    try {
      await ref.read(inventoryRepositoryProvider).delete(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Product deleted', 'Bidhaa imefutwa')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Failed to delete. Try again.', 'Imeshindikana kufuta. Jaribu tena.')),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type       = _readType(item);
    final sell       = _readSellingPrice(item);
    final qty        = _stock(item);
    final name       = (item['name'] ?? item['productName'] ?? '—').toString();
    final cat        = (item['category'] ?? '').toString();
    final unit       = (item['unit'] ?? 'pcs').toString();
    final sku        = (item['sku'] ?? '').toString();
    final fullStatus = _fullStatusLevel(item);
    final fColor     = _fullStatusColor(fullStatus);

    String expiryLabel = '';
    if (fullStatus == 4) {
      final days = _daysUntilExpiry(item);
      expiryLabel = days >= 0
          ? _tr('Exp. in $days days', 'Inaisha siku $days')
          : _tr('Expires soon', 'Karibu kuisha');
    } else if (fullStatus == 5) {
      expiryLabel = _tr('Expired', 'Imeisha muda');
    }

    return ListSwipeCard(
      itemKey: ValueKey(item['id'] ?? name),
      onEdit: () async {
        final mq = MediaQuery.of(context).size;
        await showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          constraints: BoxConstraints(maxWidth: mq.width, maxHeight: mq.height),
          builder: (_) => _ProductFormSheet(
            existingItem: item,
            existingId: (item['id'] as String?) ?? '',
          ),
        );
      },
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              _tr('Delete Product?', 'Futa Bidhaa?'),
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppColors.navyPrimary),
            ),
            content: Text(
              _tr('Delete "$name"? This cannot be undone.', 'Futa "$name"? Hii haiwezi kutenduliwa.'),
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(_tr('Cancel', 'Ghairi'), style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(_tr('Delete', 'Futa'), style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await _deleteItem(context, ref);
        }
      },
      child: GestureDetector(
        onTap: () {
          final mq = MediaQuery.of(context).size;
          showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            constraints: BoxConstraints(maxWidth: mq.width, maxHeight: mq.height),
            builder: (_) => _ProductDetailSheet(item: item),
          );
        },
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  // ── Circular avatar ────────────────────────────────
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: fColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: fColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ── Name + subtitle ────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (cat.isNotEmpty) cat,
                            if (sku.isNotEmpty) sku,
                          ].join(' · '),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (expiryLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              expiryLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: fColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Price + stock ──────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtAmount(sell),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (type != ProductType.service)
                        Text(
                          '$qty $unit',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: fColor,
                          ),
                        )
                      else
                        _StatusPill(level: fullStatus),
                    ],
                  ),
                ],
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.only(top: 13, left: 60),
                  child: Divider(height: 1, color: AppColors.border, thickness: 0.8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter / Sort Sheet ───────────────────────────────────────────────────────

class _FilterSortSheet extends StatefulWidget {
  final SortOption currentSort;
  final Set<ProductType> typeFilter;
  final int healthFilter;
  final int expiryFilter;
  final void Function(SortOption, Set<ProductType>, int, int) onApply;

  const _FilterSortSheet({
    required this.currentSort,
    required this.typeFilter,
    required this.healthFilter,
    required this.expiryFilter,
    required this.onApply,
  });

  @override
  State<_FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<_FilterSortSheet> {
  late SortOption _sort;
  late Set<ProductType> _types;
  late int _health;
  late int _expiry;

  @override
  void initState() {
    super.initState();
    _sort   = widget.currentSort;
    _types  = {...widget.typeFilter};
    _health = widget.healthFilter;
    _expiry = widget.expiryFilter;
  }

  void _apply() {
    widget.onApply(_sort, _types, _health, _expiry);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _sort   = SortOption.nameAz;
      _types  = {};
      _health = 0;
      _expiry = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('Sort & Filter', 'Panga na Chuja'),
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _reset,
                    child: Text(
                      _tr('Reset', 'Futa'),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.tealAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Sort ──────────────────────────────────────────────────
              _SheetSectionLabel(_tr('Sort by', 'Panga kwa')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SortChip(
                    label: _tr('Name A–Z', 'Jina A–Z'),
                    selected: _sort == SortOption.nameAz,
                    onTap: () => setState(() => _sort = SortOption.nameAz),
                  ),
                  _SortChip(
                    label: _tr('Name Z–A', 'Jina Z–A'),
                    selected: _sort == SortOption.nameZa,
                    onTap: () => setState(() => _sort = SortOption.nameZa),
                  ),
                  _SortChip(
                    label: _tr('Stock ↑', 'Stoo ↑'),
                    selected: _sort == SortOption.stockHigh,
                    onTap: () => setState(() => _sort = SortOption.stockHigh),
                  ),
                  _SortChip(
                    label: _tr('Stock ↓', 'Stoo ↓'),
                    selected: _sort == SortOption.stockLow,
                    onTap: () => setState(() => _sort = SortOption.stockLow),
                  ),
                  _SortChip(
                    label: _tr('Price ↑', 'Bei ↑'),
                    selected: _sort == SortOption.priceHigh,
                    onTap: () => setState(() => _sort = SortOption.priceHigh),
                  ),
                  _SortChip(
                    label: _tr('Price ↓', 'Bei ↓'),
                    selected: _sort == SortOption.priceLow,
                    onTap: () => setState(() => _sort = SortOption.priceLow),
                  ),
                  _SortChip(
                    label: _tr('Best Margin', 'Faida Zaidi'),
                    selected: _sort == SortOption.marginHigh,
                    onTap: () => setState(() => _sort = SortOption.marginHigh),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Type filter ───────────────────────────────────────────
              _SheetSectionLabel(_tr('Product type', 'Aina ya bidhaaa')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProductType.values.map((t) {
                  final sel = _types.contains(t);
                  return _SortChip(
                    label: _typeName(t),
                    selected: sel,
                    onTap: () => setState(() {
                      if (sel) {
                        _types = {..._types}..remove(t);
                      } else {
                        _types = {..._types, t};
                      }
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Stock health filter ───────────────────────────────────
              _SheetSectionLabel(_tr('Stock status', 'Hali ya stoo')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SortChip(
                    label: _tr('All', 'Zote'),
                    selected: _health == 0,
                    onTap: () => setState(() => _health = 0),
                  ),
                  _SortChip(
                    label: _tr('Healthy Stock', 'Stoo Ipo'),
                    selected: _health == 1,
                    onTap: () => setState(() => _health = 1),
                  ),
                  _SortChip(
                    label: _tr('Low Stock', 'Inakwisha'),
                    selected: _health == 2,
                    onTap: () => setState(() => _health = 2),
                  ),
                  _SortChip(
                    label: _tr('Out of Stock', 'Imeisha'),
                    selected: _health == 3,
                    onTap: () => setState(() => _health = 3),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Expiry filter ─────────────────────────────────────────
              _SheetSectionLabel(_tr('Expiry status', 'Hali ya tarehe')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SortChip(
                    label: _tr('Any', 'Yote'),
                    selected: _expiry == 0,
                    onTap: () => setState(() => _expiry = 0),
                  ),
                  _SortChip(
                    label: _tr('Expiring Soon', 'Karibu Kuisha'),
                    selected: _expiry == 1,
                    onTap: () => setState(() => _expiry = 1),
                  ),
                  _SortChip(
                    label: _tr('Expired', 'Imeisha Muda'),
                    selected: _expiry == 2,
                    onTap: () => setState(() => _expiry = 2),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _tr('Apply', 'Tumia'),
                    style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navyPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Status Pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final int level; // 0=service, 1=healthy, 2=low, 3=out, 4=expiring, 5=expired
  const _StatusPill({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = _fullStatusColor(level);
    final label = _fullStatusLabel(level);
    if (level == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}



// ── Product Detail Sheet ──────────────────────────────────────────────────────

class _ProductDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  const _ProductDetailSheet({required this.item});

  @override
  ConsumerState<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<_ProductDetailSheet> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    if (_editMode) {
      return _ProductFormSheet(
        existingItem: widget.item,
        existingId: widget.item['id'] as String? ?? '',
        onDone: () => Navigator.of(context).pop(),
      );
    }
    return _DetailView(
      item: widget.item,
      onEdit: () => setState(() => _editMode = true),
    );
  }
}

class _DetailView extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  const _DetailView({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final type       = _readType(item);
    final buy        = _readBuyingPrice(item);
    final sell       = _readSellingPrice(item);
    final qty        = _stock(item);
    final reord      = _reorder(item);
    final name       = (item['name'] ?? item['productName'] ?? '—').toString();
    final cat        = (item['category'] ?? '').toString();
    final unit       = (item['unit'] ?? 'pcs').toString();
    final sku        = (item['sku'] ?? '').toString();
    final batch      = (item['batchNumber'] ?? '').toString();
    final supplier   = (item['supplier'] ?? '').toString();
    final expiryDate = (item['expiryDate'] ?? '').toString();
    final profitV    = _profit(buy, sell);
    final marginV    = _margin(buy, sell);
    final fullStatus = _fullStatusLevel(item);
    final hColor     = _fullStatusColor(fullStatus);
    final daysLeft   = _daysUntilExpiry(item);

    final stockFraction = type != ProductType.service
        ? (qty / (reord * 4).clamp(qty + 1, 9999)).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + Edit ──────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          _typeIcon(type),
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _typeName(type),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (cat.isNotEmpty) ...[
                                  Text(
                                    ' · $cat',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Status pill + expiry note
                  Row(
                    children: [
                      _StatusPill(level: fullStatus),
                      if (expiryDate.isNotEmpty && daysLeft >= 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          daysLeft == 0
                              ? _tr('Expires today!', 'Inaisha leo!')
                              : daysLeft < 0
                                  ? _tr('Expired', 'Imeisha muda')
                                  : _tr('$daysLeft days left', 'Siku $daysLeft zimebaki'),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hColor,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 28),
                  _Divider(),

                  // ── Pricing ──────────────────────────────────────────
                  const SizedBox(height: 20),
                  _DetailSectionLabel(_tr('Pricing', 'Bei')),
                  const SizedBox(height: 14),
                  _PricingRow(buy: buy, sell: sell, profit: profitV, margin: marginV),

                  // ── Stock ────────────────────────────────────────────
                  if (type != ProductType.service) ...[
                    const SizedBox(height: 24),
                    _Divider(),
                    const SizedBox(height: 20),
                    _DetailSectionLabel(_tr('Stock', 'Stoo')),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _DetailStat(
                            label: _tr('On Hand', 'Iliyopo'),
                            value: '$qty $unit',
                            valueColor: hColor,
                          ),
                        ),
                        Expanded(
                          child: _DetailStat(
                            label: _tr('Reorder At', 'Agiza tena ukifika'),
                            value: '$reord $unit',
                          ),
                        ),
                        if (buy > 0)
                          Expanded(
                            child: _DetailStat(
                              label: _tr('Stock Value', 'Thamani'),
                              value: _fmtAmount(buy * qty),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Stock bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _tr('Stock level', 'Kiwango cha stoo'),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              _tr(
                                'Reorder at $reord',
                                'Agiza tena ukifika $reord',
                              ),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: stockFraction,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(hColor),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Details (SKU, batch, supplier, expiry) ───────────
                  if (sku.isNotEmpty || batch.isNotEmpty || supplier.isNotEmpty || expiryDate.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Divider(),
                    const SizedBox(height: 20),
                    _DetailSectionLabel(_tr('Details', 'Maelezo')),
                    const SizedBox(height: 14),
                    if (sku.isNotEmpty) ...[
                      _KeyValue(k: 'SKU', v: sku),
                      const SizedBox(height: 10),
                    ],
                    if (batch.isNotEmpty) ...[
                      _KeyValue(k: _tr('Batch', 'Kundi'), v: batch),
                      const SizedBox(height: 10),
                    ],
                    if (supplier.isNotEmpty) ...[
                      _KeyValue(k: _tr('Supplier', 'Msambazaji'), v: supplier),
                      const SizedBox(height: 10),
                    ],
                    if (expiryDate.isNotEmpty) ...[
                      _KeyValue(
                        k: _tr('Expiry', 'Mwisho'),
                        v: expiryDate,
                        valueColor: hColor,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (sku.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => BarcodeViewSheet.show(
                            context,
                            productName: name,
                            sku: sku,
                            price: sell,
                          ),
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: Text(_tr('View / Print Barcode', 'Ona / Chapa Nambari')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.tealAccent,
                            side: const BorderSide(color: AppColors.tealAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 28),

                  // ── Edit button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 17),
                      label: Text(
                        _tr('Edit Product', 'Hariri Bidhaaa'),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyPrimary,
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail sub-widgets ────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.border);
}

class _DetailSectionLabel extends StatelessWidget {
  final String text;
  const _DetailSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.navyPrimary,
          ),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String k;
  final String v;
  final Color? valueColor;
  const _KeyValue({required this.k, required this.v, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            k,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.navyPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  final double buy;
  final double sell;
  final double profit;
  final double margin;
  const _PricingRow({
    required this.buy,
    required this.sell,
    required this.profit,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final profitColor = profit >= 0 ? AppColors.success : AppColors.error;
    return Column(
      children: [
        _PriceLine(
          label: _tr('Buying price', 'Bei ya kununua'),
          value: buy > 0 ? _fmtAmount(buy) : '—',
          dim: true,
        ),
        const SizedBox(height: 10),
        _PriceLine(
          label: _tr('Selling price', 'Bei ya kuuza'),
          value: sell > 0 ? _fmtAmount(sell) : '—',
          bold: true,
        ),
        if (buy > 0 && sell > 0) ...[
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          _PriceLine(
            label: _tr('Profit / unit', 'Faida kwa kipande'),
            value: _fmtAmount(profit),
            valueColor: profitColor,
            bold: true,
          ),
          const SizedBox(height: 4),
          _PriceLine(
            label: _tr('Margin', 'Asilimia ya faida'),
            value: '${margin.toStringAsFixed(1)}%',
            valueColor: margin >= 20
                ? AppColors.success
                : margin >= 10
                    ? const Color(0xFFD97706)
                    : AppColors.error,
          ),
        ],
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final bool dim;
  const _PriceLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: dim ? AppColors.textMuted : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? (dim ? AppColors.textMuted : AppColors.navyPrimary),
          ),
        ),
      ],
    );
  }
}

// ── Product Form Sheet (Add / Edit) ───────────────────────────────────────────

class _ProductFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingItem;
  final String? existingId;
  final VoidCallback? onDone;

  const _ProductFormSheet({this.existingItem, this.existingId, this.onDone});

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  late ProductType _type;

  final _nameCtrl    = TextEditingController();
  final _skuCtrl     = TextEditingController();
  final _buyCtrl     = TextEditingController();
  final _sellCtrl    = TextEditingController();
  final _stockCtrl   = TextEditingController(text: '1');
  final _reorderCtrl = TextEditingController(text: '5');
  final _batchCtrl   = TextEditingController();
  final _brandCtrl   = TextEditingController();
  final _warrantyCtrl = TextEditingController();

  String _unit = 'pcs';
  bool _saving = false;

  // Category state
  String _selectedCategoryId = '';
  String _selectedCategoryName = '';

  // Expiry date state
  DateTime? _expiryDate;

  static const _units = [
    'pcs','kg','liters','boxes','bottles','bags','meters','sets','dozen','packets',
  ];

  bool get _isEdit => widget.existingItem != null;

  double get _buyVal =>
      double.tryParse(_buyCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  double get _sellVal =>
      double.tryParse(_sellCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _type = _readType(item);
      _nameCtrl.text   = (item['name'] ?? item['productName'] ?? '').toString();
      _skuCtrl.text    = (item['sku'] ?? '').toString();
      _batchCtrl.text  = (item['batchNumber'] ?? '').toString();
      _brandCtrl.text  = (item['brand'] ?? '').toString();
      _warrantyCtrl.text = (item['warrantyPeriod'] ?? '').toString();

      _selectedCategoryId   = (item['categoryId']   ?? '').toString();
      _selectedCategoryName = (item['categoryName'] ?? item['category'] ?? '').toString();

      final expiry = item['expiryDate'] as String? ?? '';
      if (expiry.isNotEmpty) _expiryDate = DateTime.tryParse(expiry);

      final b = _readBuyingPrice(item);
      final s = _readSellingPrice(item);
      if (b > 0) _buyCtrl.text  = b.toStringAsFixed(0);
      if (s > 0) _sellCtrl.text = s.toStringAsFixed(0);
      final stk = _stock(item);
      _stockCtrl.text   = '$stk';
      final r = parseStock(item['reorderPoint']);
      _reorderCtrl.text = r > 0 ? '$r' : '5';
      _unit = (item['unit'] ?? 'pcs').toString();
    } else {
      _type = ProductType.stock;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();   _skuCtrl.dispose();
    _buyCtrl.dispose();    _sellCtrl.dispose();
    _stockCtrl.dispose();  _reorderCtrl.dispose();
    _batchCtrl.dispose();  _brandCtrl.dispose();
    _warrantyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(_tr('Enter product name', 'Ingiza jina la bidhaa'));
      return;
    }
    if (_sellVal <= 0) {
      _snack(_tr('Enter a selling price', 'Ingiza bei ya kuuza'));
      return;
    }

    final bizType = ref.read(currentBusinessTypeProvider).valueOrNull ?? '';
    final config  = BusinessProductConfig.forBusinessType(bizType);
    if (config.isExpiryRequired && _expiryDate == null) {
      _snack(_tr('Expiry date is required', 'Tarehe ya mwisho inahitajika'));
      return;
    }

    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);

    try {
      final resolvedCatName = _selectedCategoryName.isNotEmpty
          ? _selectedCategoryName
          : _tr('General', 'Jumla');

      final now = DateTime.now().toIso8601String();
      final existing = widget.existingItem;
      final expiryStr = _expiryDate != null
          ? '${_expiryDate!.year}-'
              '${_expiryDate!.month.toString().padLeft(2, '0')}-'
              '${_expiryDate!.day.toString().padLeft(2, '0')}'
          : '';

      final item = InventoryItem(
        id: widget.existingId ?? '',
        name: name,
        productType: _type.name,
        category: resolvedCatName,
        categoryId: _selectedCategoryId,
        categoryName: resolvedCatName,
        sku: _skuCtrl.text.trim(),
        currentStock: _type != ProductType.service
            ? (double.tryParse(_stockCtrl.text) ?? 0)
            : 0,
        reorderPoint: _type != ProductType.service
            ? (double.tryParse(_reorderCtrl.text) ?? 5)
            : 0,
        unitPrice: _sellVal,
        costPrice: _buyVal,
        unit: _unit,
        expiryDate: expiryStr,
        batchNumber: _batchCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        warrantyPeriod: _warrantyCtrl.text.trim(),
        supplier: (existing?['supplier'] as String?) ?? '',
        lastRestocked: (existing?['lastRestocked'] as String?) ?? '',
        createdAt: (existing?['createdAt'] as String?) ?? now,
        updatedAt: now,
      );

      await ref.read(inventoryRepositoryProvider).save(item);

      if (!mounted) return;
      msg.showSnackBar(SnackBar(
        content: Text(_isEdit
            ? _tr('Product updated', 'Bidhaa imesasishwa')
            : _tr('Product added', 'Bidhaa imeongezwa')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      widget.onDone != null ? widget.onDone!() : nav.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      msg.showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(_tr(
            'Could not save product. Please try again.',
            'Imeshindikana kuhifadhi bidhaa. Jaribu tena.')),
      ));
    }
  }

  Future<void> _scanSku() async {
    final scanned = await BarcodeScannerScreen.show(
      context,
      title: _tr('Scan Product Barcode', 'Skani Nambari ya Bidhaa'),
    );
    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() => _skuCtrl.text = scanned);
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
      helpText: _tr('Select Expiry Date', 'Chagua Tarehe ya Mwisho'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyPrimary,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _openCategoryPicker(List<ProductCategory> categories) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        selectedId: _selectedCategoryId,
        onSelect: (cat) {
          setState(() {
            _selectedCategoryId   = cat.id;
            _selectedCategoryName = cat.name;
          });
        },
        onAddNew: (name) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          final bizId = ref.read(currentBusinessIdProvider).valueOrNull ?? '';
          if (bizId.isEmpty) return;
          final repo = ref.read(contextFirestoreRepositoryProvider);
          final id = await addCategory(
            uid: user.uid,
            bizId: bizId,
            businessType: ref.read(currentBusinessTypeProvider).valueOrNull ?? '',
            name: name,
            repo: repo,
          );
          setState(() {
            _selectedCategoryId   = id;
            _selectedCategoryName = name;
          });
        },
      ),
    );
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final bizTypeAsync    = ref.watch(currentBusinessTypeProvider);
    final bizType = bizTypeAsync.valueOrNull ?? '';
    final config  = BusinessProductConfig.forBusinessType(bizType);

    final showStock  = _type != ProductType.service && config.showStock;
    final showProfit = _buyVal > 0 && _sellVal > 0;
    final profitAmt  = _profit(_buyVal, _sellVal);
    final marginAmt  = _margin(_buyVal, _sellVal);
    final sheetWidth = MediaQuery.sizeOf(context).width;

    final categories = categoriesAsync.valueOrNull ?? const <ProductCategory>[];

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: sheetWidth,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Handle + Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isEdit
                                ? _tr('Edit Product', 'Hariri Bidhaa')
                                : _tr('Add Product', 'Ongeza Bidhaa'),
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
                    const SizedBox(height: 16),
                    // ── Type pills ────────────────────────────────────────
                    Row(
                      children: ProductType.values.map((t) {
                        final sel = t == _type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _type = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.only(
                                right: t != ProductType.values.last ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.navyPrimary : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel ? AppColors.navyPrimary : AppColors.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(_typeIcon(t), size: 18,
                                      color: sel ? Colors.white : AppColors.textMuted),
                                  const SizedBox(height: 4),
                                  Text(
                                    _typeName(t),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Container(height: 1, color: AppColors.border),

              // ── Scrollable form ──────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24, 20, 24,
                    MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Product name
                      _FormLabel('${BusinessProductConfig.productNameLabel(
                        bizType,
                        isSwahili: LocalizationService.isSwahili,
                      )} *'),
                      const SizedBox(height: 6),
                      _FormField(
                        ctrl: _nameCtrl,
                        hint: _tr('e.g. Unga wa mahindi 2kg', 'k.m. Unga wa mahindi 2kg'),
                        caps: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),

                      // Category dropdown + Unit
                      Row(
                        children: [
                          if (config.showCategory) ...[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormLabel(_tr('Category', 'Kategoria')),
                                  const SizedBox(height: 6),
                                  _CategoryDropdownButton(
                                    selectedName: _selectedCategoryName,
                                    categories: categories,
                                    loading: categoriesAsync.isLoading,
                                    onTap: () => _openCategoryPicker(categories),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FormLabel(_tr('Unit', 'Kitengo')),
                                const SizedBox(height: 6),
                                _UnitDropdown(
                                  value: _unit,
                                  units: _units,
                                  onChanged: (v) => setState(() => _unit = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // SKU / Barcode
                      _FormLabel('SKU / ${_tr("Barcode", "Nambari")} (${_tr("optional", "hiari")})'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              ctrl: _skuCtrl,
                              hint: 'e.g. ABC-001',
                              caps: TextCapitalization.characters,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48, height: 48,
                            child: OutlinedButton(
                              onPressed: _scanSku,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                side: const BorderSide(color: AppColors.tealAccent),
                                foregroundColor: AppColors.tealAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                            ),
                          ),
                        ],
                      ),

                      // ── Business-type-specific fields ──────────────────────

                      // Expiry date (pharmacy required, perishable optional)
                      if (config.showExpiryDate) ...[
                        const SizedBox(height: 14),
                        _FormLabel(config.isExpiryRequired
                            ? _tr('Expiry Date *', 'Tarehe ya Mwisho *')
                            : _tr('Expiry Date (optional)', 'Tarehe ya Mwisho (hiari)')),
                        const SizedBox(height: 6),
                        _ExpiryDateButton(
                          date: _expiryDate,
                          isRequired: config.isExpiryRequired,
                          onTap: _pickExpiryDate,
                          onClear: () => setState(() => _expiryDate = null),
                        ),
                      ],

                      // Batch number (pharmacy / health)
                      if (config.showBatchNumber) ...[
                        const SizedBox(height: 14),
                        _FormLabel('${_tr('Batch Number', 'Nambari ya Kundi')} (${_tr("optional", "hiari")})'),
                        const SizedBox(height: 6),
                        _FormField(
                          ctrl: _batchCtrl,
                          hint: 'e.g. BN-2024-001',
                          caps: TextCapitalization.characters,
                        ),
                      ],

                      // Brand (electronics / pharmacy)
                      if (config.showBrand) ...[
                        const SizedBox(height: 14),
                        _FormLabel('${_tr('Brand', 'Chapa')} (${_tr("optional", "hiari")})'),
                        const SizedBox(height: 6),
                        _FormField(
                          ctrl: _brandCtrl,
                          hint: 'e.g. Samsung, Dawa Ltd',
                          caps: TextCapitalization.words,
                        ),
                      ],

                      // Warranty period (electronics)
                      if (config.showWarrantyPeriod) ...[
                        const SizedBox(height: 14),
                        _FormLabel('${_tr('Warranty Period', 'Kipindi cha Dhamana')} (${_tr("optional", "hiari")})'),
                        const SizedBox(height: 6),
                        _FormField(
                          ctrl: _warrantyCtrl,
                          hint: _tr('e.g. 12 months', 'k.m. miezi 12'),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Container(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      // ── Pricing ───────────────────────────────────────────
                      _FormSectionLabel(_tr('Pricing', 'Bei')),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FormLabel(_tr('Buying price', 'Bei ya kununua')),
                                const SizedBox(height: 6),
                                _FormField(
                                  ctrl: _buyCtrl,
                                  hint: '0',
                                  prefix: 'TSh',
                                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FormLabel(_tr('Selling price *', 'Bei ya kuuza *')),
                                const SizedBox(height: 6),
                                _FormField(
                                  ctrl: _sellCtrl,
                                  hint: '0',
                                  prefix: 'TSh',
                                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (showProfit) ...[
                        const SizedBox(height: 10),
                        _ProfitStrip(profit: profitAmt, margin: marginAmt),
                      ],

                      // ── Stock ─────────────────────────────────────────────
                      if (showStock) ...[
                        const SizedBox(height: 20),
                        Container(height: 1, color: AppColors.border),
                        const SizedBox(height: 20),
                        _FormSectionLabel(_tr('Stock', 'Stoo')),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormLabel(_tr('Quantity', 'Kiasi')),
                                  const SizedBox(height: 6),
                                  _FormField(
                                    ctrl: _stockCtrl,
                                    hint: '1',
                                    keyboard: TextInputType.number,
                                    formatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormLabel(_tr('Reorder point', 'Kikomo')),
                                  const SizedBox(height: 6),
                                  _FormField(
                                    ctrl: _reorderCtrl,
                                    hint: '5',
                                    keyboard: TextInputType.number,
                                    formatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tr(
                            'Alert me when stock drops to the reorder point.',
                            'Nitaarifiwe stoo inapofika kikomo cha kuagiza.',
                          ),
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyPrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.navyPrimary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isEdit
                                      ? _tr('Save changes', 'Hifadhi mabadiliko')
                                      : _tr('Add to inventory', 'Ongeza kwenye bidhaa'),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category dropdown button ──────────────────────────────────────────────────

class _CategoryDropdownButton extends StatelessWidget {
  final String selectedName;
  final List<ProductCategory> categories;
  final bool loading;
  final VoidCallback onTap;

  const _CategoryDropdownButton({
    required this.selectedName,
    required this.categories,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: loading
                  ? Row(children: [
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tr('Loading…', 'Inapakia…'),
                        style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textDisabled,
                        ),
                      ),
                    ])
                  : Text(
                      selectedName.isNotEmpty
                          ? selectedName
                          : (categories.isEmpty
                              ? _tr('No categories yet', 'Bado hakuna kategoria')
                              : _tr('category', 'kategoria')),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: selectedName.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedName.isNotEmpty
                            ? AppColors.navyPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Category Picker bottom sheet ──────────────────────────────────────────────

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  final List<ProductCategory> categories;
  final String selectedId;
  final ValueChanged<ProductCategory> onSelect;
  final Future<void> Function(String name) onAddNew;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  ConsumerState<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _newCtrl    = TextEditingController();
  String _query = '';
  bool _showAdd = false;
  bool _adding  = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  List<ProductCategory> get _filtered {
    if (_query.isEmpty) return widget.categories;
    return widget.categories
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  Future<void> _addCategory() async {
    final name = _newCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _adding = true);
    await widget.onAddNew(name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Category', 'Kategoria'),
                    style: GoogleFonts.dmSans(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showAdd = !_showAdd),
                  icon: Icon(
                    _showAdd ? Icons.close_rounded : Icons.add_rounded,
                    size: 18,
                    color: AppColors.tealAccent,
                  ),
                  label: Text(
                    _showAdd
                        ? _tr('Cancel', 'Ghairi')
                        : _tr('Add New', 'Ongeza Mpya'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.tealAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add new category field
          if (_showAdd) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCtrl,
                      textCapitalization: TextCapitalization.words,
                      autofocus: true,
                      style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.navyPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _tr('Category name', 'Jina la kategoria'),
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textDisabled,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.tealAccent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _adding ? null : _addCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _adding
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_tr('Save', 'Hifadhi'),
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.navyPrimary),
              decoration: InputDecoration(
                hintText: _tr('Search categories…', 'Tafuta kategoria…'),
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textDisabled),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 36, color: AppColors.border),
                        const SizedBox(height: 10),
                        Text(
                          _tr(
                            'No categories found.\nTap "+ Add New" to create one.',
                            'Hakuna category zilizopo.\nBonyeza "+ Ongeza Mpya" kuunda moja.',
                          ),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final cat = _filtered[i];
                      final isSelected = cat.id == widget.selectedId;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.navyPrimary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.navyPrimary
                                  : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            Icons.label_rounded,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                        title: Text(
                          cat.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded,
                                size: 20, color: AppColors.success)
                            : null,
                        onTap: () {
                          widget.onSelect(cat);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Expiry date picker button ─────────────────────────────────────────────────

class _ExpiryDateButton extends StatelessWidget {
  final DateTime? date;
  final bool isRequired;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ExpiryDateButton({
    required this.date,
    required this.isRequired,
    required this.onTap,
    required this.onClear,
  });

  bool get _isExpired =>
      date != null && date!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final hasDate   = date != null;
    final expired   = _isExpired;
    final expireSoon = hasDate && !expired &&
        date!.isBefore(DateTime.now().add(const Duration(days: 30)));

    Color borderColor = AppColors.border;
    Color iconColor   = AppColors.textMuted;
    if (expired)     { borderColor = AppColors.error;   iconColor = AppColors.error; }
    else if (expireSoon) { borderColor = AppColors.warning; iconColor = AppColors.warning; }
    else if (hasDate) { borderColor = AppColors.success;  iconColor = AppColors.success; }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: hasDate ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDate
                    ? '${date!.day.toString().padLeft(2, '0')} / '
                        '${date!.month.toString().padLeft(2, '0')} / '
                        '${date!.year}'
                        '${expired ? '  ⚠ ${_tr("Expired", "Imeisha")}' : ''}'
                        '${expireSoon ? '  ⚠ ${_tr("Expires soon", "Karibu kumalizika")}' : ''}'
                    : (isRequired
                        ? _tr('Tap to set expiry date *', 'Gusa kuweka tarehe ya mwisho *')
                        : _tr('Tap to set expiry date', 'Gusa kuweka tarehe ya mwisho')),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                  color: expired
                      ? AppColors.error
                      : expireSoon
                          ? AppColors.warning
                          : hasDate
                              ? AppColors.navyPrimary
                              : AppColors.textDisabled,
                ),
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Form helpers ──────────────────────────────────────────────────────────────

class _FormSectionLabel extends StatelessWidget {
  final String text;
  const _FormSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final String? prefix;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization caps;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.ctrl,
    required this.hint,
    this.prefix,
    this.keyboard,
    this.formatters,
    this.caps = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      textCapitalization: caps,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.navyPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textDisabled,
        ),
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.tealAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  final String value;
  final List<String> units;
  final ValueChanged<String> onChanged;
  const _UnitDropdown({required this.value, required this.units, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: units.contains(value) ? value : units.first,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.tealAccent, width: 1.5),
        ),
      ),
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.navyPrimary,
      ),
      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}

class _ProfitStrip extends StatelessWidget {
  final double profit;
  final double margin;
  const _ProfitStrip({required this.profit, required this.margin});

  @override
  Widget build(BuildContext context) {
    final ok = profit >= 0;
    final color = ok ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '${_tr("Profit", "Faida")} ${_fmtAmount(profit)} · ${margin.toStringAsFixed(0)}% ${_tr("margin", "ya bei")}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
