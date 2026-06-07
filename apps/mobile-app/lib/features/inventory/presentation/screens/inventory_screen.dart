import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/barcode_scanner_screen.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../data/inventory_providers.dart';
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

Color _healthColor(int level) {
  switch (level) {
    case 3: return AppColors.error;
    case 2: return const Color(0xFFD97706); // amber — single warning tone
    default: return AppColors.success;
  }
}

String _healthLabel(int level) {
  switch (level) {
    case 0: return _tr('Service', 'Huduma');
    case 3: return _tr('Out', 'Imeisha');
    case 2: return _tr('Low', 'Chini');
    default: return _tr('OK', 'Ipo');
  }
}

// ── Sort / Filter ─────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _applyFiltersAndSort(
  List<Map<String, dynamic>> src,
  String query,
  Set<ProductType> typeFilter,
  int healthFilter,  // 0=all, 1=ok, 2=low, 3=out
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
  SortOption _sort = SortOption.nameAz;
  Set<ProductType> _typeFilter = {};
  int _healthFilter = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAdd(BuildContext ctx) {
    showModalBottomSheet<void>(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
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
        onApply: (sort, types, health) => setState(() {
          _sort = sort;
          _typeFilter = types;
          _healthFilter = health;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemListProvider);
    final activeFilters =
        _typeFilter.length + (_healthFilter > 0 ? 1 : 0) + (_sort != SortOption.nameAz ? 1 : 0);

    return Scaffold(
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton(
          onPressed: () => _openAdd(ctx),
          backgroundColor: AppColors.navyPrimary,
          foregroundColor: Colors.white,
          elevation: 3,
          child: const Icon(Icons.add_rounded, size: 26),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: inventoryAsync.when(
              loading: () => const InventoryPageSkeleton(),
              error: (e, _) => Center(
                child: Text(
                  _tr('Unable to load inventory.', 'Imeshindikana kupakia stoo.'),
                  style: GoogleFonts.dmSans(color: AppColors.textMuted),
                ),
              ),
              data: (items) {
                final filtered = _applyFiltersAndSort(
                  items, _query, _typeFilter, _healthFilter, _sort,
                );
                return Column(
                  children: [
                    // ── Stats strip ──────────────────────────────────────
                    _StatsStrip(items: items),

                    // ── Search + Filter bar ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SearchBar(
                              ctrl: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Builder(
                            builder: (ctx) => _FilterButton(
                              activeCount: activeFilters,
                              onTap: () => _openFilterSort(ctx, items),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Active filter chips ──────────────────────────────
                    if (_typeFilter.isNotEmpty || _healthFilter > 0)
                      _ActiveFilterRow(
                        typeFilter: _typeFilter,
                        healthFilter: _healthFilter,
                        onClearType: (t) =>
                            setState(() => _typeFilter = {..._typeFilter}..remove(t)),
                        onClearHealth: () =>
                            setState(() => _healthFilter = 0),
                      ),

                    // ── List ─────────────────────────────────────────────
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyPlaceholder(hasQuery: _query.isNotEmpty || activeFilters > 0)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
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

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.navyPrimary),
        decoration: InputDecoration(
          hintText: _tr('Search products…', 'Tafuta bidhaa…'),
          hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          suffixIcon: ctrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    ctrl.clear();
                    onChanged('');
                  },
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.zero,
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
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: activeCount > 0 ? AppColors.navyPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activeCount > 0 ? AppColors.navyPrimary : AppColors.border,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 20,
              color: activeCount > 0 ? Colors.white : AppColors.textMuted,
            ),
            if (activeCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _StatsStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    double stockVal = 0, revenue = 0;
    int low = 0, out = 0;
    for (final item in items) {
      if (_readType(item) == ProductType.service) continue;
      final s = _stock(item);
      stockVal += _readBuyingPrice(item) * s;
      revenue  += _readSellingPrice(item) * s;
      if (s == 0) {
        out++;
      } else if (s <= _reorder(item)) {
        low++;
      }
    }
    final profit = revenue - stockVal;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Strip(label: _tr('Products', 'Bidhaa'), value: '${items.length}'),
          _StripDiv(),
          _Strip(label: _tr('Stock Value', 'Thamani'), value: 'TSh ${_fmtShort(stockVal)}'),
          _StripDiv(),
          _Strip(
            label: _tr('Est. Profit', 'Faida'),
            value: 'TSh ${_fmtShort(profit)}',
            valueColor: profit >= 0 ? AppColors.success : AppColors.error,
          ),
          _StripDiv(),
          _Strip(
            label: _tr('Alerts', 'Tahadhari'),
            value: '${low + out}',
            valueColor: low + out > 0 ? const Color(0xFFD97706) : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Strip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: Colors.white12);
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
        borderRadius: BorderRadius.circular(20),
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
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            size: 40,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery
                ? _tr('No products match', 'Hakuna bidhaa inayolingana')
                : _tr('No products yet', 'Bado hakuna bidhaa'),
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasQuery
                ? _tr('Try a different search or filter', 'Jaribu utafutaji tofauti')
                : _tr('Tap + to add your first product', 'Bonyeza + kuongeza bidhaa ya kwanza'),
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo
          .scopeCollection(uid: user.uid, context: ctx, childCollection: 'inventory_items')
          .doc(id)
          .delete();
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
    final type    = _readType(item);
    final buy     = _readBuyingPrice(item);
    final sell    = _readSellingPrice(item);
    final qty     = _stock(item);
    final name    = (item['name'] ?? item['productName'] ?? '—').toString();
    final cat     = (item['category'] ?? '').toString();
    final unit    = (item['unit'] ?? 'pcs').toString();
    final marginV = _margin(buy, sell);
    final health  = _healthLevel(item);
    final hColor  = _healthColor(health);

    return Dismissible(
      key: ValueKey(item['id'] ?? name),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Right swipe → Edit
          await showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            builder: (_) => _ProductFormSheet(
              existingItem: item,
              existingId: (item['id'] as String?) ?? '',
            ),
          );
          return false;
        } else {
          // Left swipe → Delete confirmation
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                _tr('Delete Product?', 'Futa Bidhaa?'),
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
              content: Text(
                _tr(
                  'Delete "$name"? This cannot be undone.',
                  'Futa "$name"? Hii haiwezi kutenduliwa.',
                ),
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    _tr('Cancel', 'Ghairi'),
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: Text(
                    _tr('Delete', 'Futa'),
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await _deleteItem(context, ref);
            return true;
          }
          return false;
        }
      },
      background: Container(
        color: AppColors.tealAccent.withValues(alpha: 0.08),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: AppColors.tealAccent, size: 22),
            const SizedBox(height: 4),
            Text(
              _tr('Edit', 'Hariri'),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.tealAccent,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: AppColors.error.withValues(alpha: 0.08),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            const SizedBox(height: 4),
            Text(
              _tr('Delete', 'Futa'),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (_) => _ProductDetailSheet(item: item),
        ),
        child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : AppColors.border,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              // ── Left: type dot + name ────────────────────────────────
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 12, top: 1),
                decoration: BoxDecoration(
                  color: hColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _typeName(type),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (cat.isNotEmpty) ...[
                          Text(
                            ' · $cat',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // ── Right: price + stock + margin ────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtAmount(sell),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (type != ProductType.service) ...[
                        Text(
                          '$qty $unit',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: hColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (buy > 0 && sell > 0)
                        Text(
                          '${marginV.toStringAsFixed(0)}%',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: marginV >= 20
                                ? AppColors.success
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.border,
              ),
            ],
          ),
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
  final void Function(SortOption, Set<ProductType>, int) onApply;

  const _FilterSortSheet({
    required this.currentSort,
    required this.typeFilter,
    required this.healthFilter,
    required this.onApply,
  });

  @override
  State<_FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<_FilterSortSheet> {
  late SortOption _sort;
  late Set<ProductType> _types;
  late int _health;

  @override
  void initState() {
    super.initState();
    _sort   = widget.currentSort;
    _types  = {...widget.typeFilter};
    _health = widget.healthFilter;
  }

  void _apply() {
    widget.onApply(_sort, _types, _health);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _sort   = SortOption.nameAz;
      _types  = {};
      _health = 0;
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
              _SheetSectionLabel(_tr('Product type', 'Aina ya bidhaa')),
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
                children: [
                  _SortChip(
                    label: _tr('All', 'Zote'),
                    selected: _health == 0,
                    onTap: () => setState(() => _health = 0),
                  ),
                  _SortChip(
                    label: _tr('In Stock', 'Ipo'),
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
    final type    = _readType(item);
    final buy     = _readBuyingPrice(item);
    final sell    = _readSellingPrice(item);
    final qty     = _stock(item);
    final reord   = _reorder(item);
    final name    = (item['name'] ?? item['productName'] ?? '—').toString();
    final cat     = (item['category'] ?? '').toString();
    final unit    = (item['unit'] ?? 'pcs').toString();
    final sku     = (item['sku'] ?? '').toString();
    final profitV = _profit(buy, sell);
    final marginV = _margin(buy, sell);
    final health  = _healthLevel(item);
    final hColor  = _healthColor(health);

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

                  const SizedBox(height: 6),

                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: hColor, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _healthLabel(health),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hColor,
                          ),
                        ),
                      ],
                    ),
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

                  // ── Metadata ─────────────────────────────────────────
                  if (sku.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Divider(),
                    const SizedBox(height: 20),
                    _DetailSectionLabel(_tr('Details', 'Maelezo')),
                    const SizedBox(height: 14),
                    _KeyValue(k: 'SKU', v: sku),
                    const SizedBox(height: 12),
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

                  const SizedBox(height: 28),

                  // ── Edit button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 17),
                      label: Text(
                        _tr('Edit Product', 'Hariri Bidhaa'),
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
  const _KeyValue({required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          k,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(width: 12),
        Text(
          v,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyPrimary,
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
  final _catCtrl     = TextEditingController();
  final _skuCtrl     = TextEditingController();
  final _buyCtrl     = TextEditingController();
  final _sellCtrl    = TextEditingController();
  final _stockCtrl   = TextEditingController(text: '1');
  final _reorderCtrl = TextEditingController(text: '5');
  String _unit = 'pcs';
  bool _saving = false;

  static const _units = [
    'pcs','kg','liters','boxes','bottles','bags','meters','sets','dozen','packets',
  ];

  bool get _isEdit => widget.existingItem != null;

  double get _buyVal  =>
      double.tryParse(_buyCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  double get _sellVal =>
      double.tryParse(_sellCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _type = _readType(item);
      _nameCtrl.text  = (item['name'] ?? item['productName'] ?? '').toString();
      _catCtrl.text   = (item['category'] ?? '').toString();
      _skuCtrl.text   = (item['sku'] ?? '').toString();
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
    _nameCtrl.dispose(); _catCtrl.dispose(); _skuCtrl.dispose();
    _buyCtrl.dispose();  _sellCtrl.dispose();
    _stockCtrl.dispose(); _reorderCtrl.dispose();
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

    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx  = await repo.resolveContextForUser(user.uid);
      final col  = repo.scopeCollection(
        uid: user.uid, context: ctx, childCollection: 'inventory_items',
      );

      final data = <String, dynamic>{
        'name':         name,
        'productType':  _type.name,
        'category':     _catCtrl.text.trim().isNotEmpty ? _catCtrl.text.trim() : 'General',
        'unit':         _unit,
        'sellingPrice': _sellVal,
        'unitPrice':    _sellVal,
        if (_buyVal > 0) 'buyingPrice': _buyVal,
        if (_type != ProductType.service) ...{
          'currentStock': int.tryParse(_stockCtrl.text) ?? 1,
          'stock':        int.tryParse(_stockCtrl.text) ?? 1,
          'reorderPoint': int.tryParse(_reorderCtrl.text) ?? 5,
        },
        if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
        'isActive':   true,
        'updatedAt':  FieldValue.serverTimestamp(),
      };

      if (_isEdit && widget.existingId != null) {
        await col.doc(widget.existingId).update(data);
        msg.showSnackBar(SnackBar(
          content: Text(_tr('Updated', 'Imesasishwa')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        widget.onDone != null ? widget.onDone!() : nav.pop();
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await col.add(data);
        msg.showSnackBar(SnackBar(
          content: Text(_tr('Product added', 'Bidhaa imeongezwa')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        nav.pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      msg.showSnackBar(SnackBar(
        content: Text(_tr('Failed. Try again.', 'Imeshindikana. Jaribu tena.')),
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

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final showStock  = _type != ProductType.service;
    final showProfit = _buyVal > 0 && _sellVal > 0;
    final profitAmt  = _profit(_buyVal, _sellVal);
    final marginAmt  = _margin(_buyVal, _sellVal);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
          // Handle + Header ────────────────────────────────────────────
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

                // ── Type pills ──────────────────────────────────────
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
                              Icon(
                                _typeIcon(t),
                                size: 18,
                                color: sel ? Colors.white : AppColors.textMuted,
                              ),
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

          // ── Scrollable form ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic info
                  _FormLabel(_tr('Product name *', 'Jina la bidhaa *')),
                  const SizedBox(height: 6),
                  _FormField(
                    ctrl: _nameCtrl,
                    hint: _tr('e.g. Maize flour 2kg', 'k.m. Unga wa mahindi 2kg'),
                    caps: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(_tr('Category', 'Kategoria')),
                            const SizedBox(height: 6),
                            _FormField(
                              ctrl: _catCtrl,
                              hint: _tr('e.g. Food', 'k.m. Chakula'),
                              caps: TextCapitalization.words,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
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
                        height: 48,
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

                  const SizedBox(height: 20),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 20),

                  // Pricing
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

                  // Live profit strip
                  if (showProfit) ...[
                    const SizedBox(height: 10),
                    _ProfitStrip(profit: profitAmt, margin: marginAmt),
                  ],

                  // Stock info
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
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
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
                                strokeWidth: 2, color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit
                                  ? _tr('Save changes', 'Hifadhi mabadiliko')
                                  : _tr('Add to inventory', 'Ongeza kwa hisa'),
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
