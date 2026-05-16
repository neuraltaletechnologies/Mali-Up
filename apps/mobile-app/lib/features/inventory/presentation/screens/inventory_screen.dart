import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/page_intro_header.dart';
import '../../../customer/data/customer_providers.dart';
import '../../data/inventory_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ProductType { stock, perishable, service }

// ── Helpers ───────────────────────────────────────────────────────────────────

ProductType _readType(Map<String, dynamic> item) {
  switch (item['productType'] as String?) {
    case 'perishable':
      return ProductType.perishable;
    case 'service':
      return ProductType.service;
    default:
      return ProductType.stock;
  }
}

double _readBuyingPrice(Map<String, dynamic> item) =>
    parseUnitPrice(item['buyingPrice']);

double _readSellingPrice(Map<String, dynamic> item) =>
    parseUnitPrice(item['sellingPrice'] ?? item['price'] ?? item['unitPrice']);

double _profit(double buy, double sell) => sell > 0 ? sell - buy : 0;
double _margin(double buy, double sell) =>
    sell > 0 ? ((sell - buy) / sell) * 100 : 0;

String _fmtAmount(double amount) {
  if (amount >= 1000000) return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
  return 'TSh ${amount.toStringAsFixed(0)}';
}

String _fmtMargin(double margin) => '${margin.toStringAsFixed(0)}%';

({Color bg, Color text, IconData icon, String label}) _typeConfig(
  ProductType t,
) {
  switch (t) {
    case ProductType.stock:
      return (
        bg: const Color(0xFFDBEAFE),
        text: AppColors.navySecondary,
        icon: Icons.inventory_2_outlined,
        label: 'Stock',
      );
    case ProductType.perishable:
      return (
        bg: AppColors.warningBg,
        text: AppColors.warning,
        icon: Icons.eco_outlined,
        label: _tr('Perishable', 'Inayoharibika'),
      );
    case ProductType.service:
      return (
        bg: const Color(0xFFEDE9FE),
        text: AppColors.purpleAccent,
        icon: Icons.handyman_outlined,
        label: _tr('Service', 'Huduma'),
      );
  }
}

({Color bg, Color text, String label}) _stockStatusConfig(
  int stock,
  int reorder,
  ProductType type,
) {
  if (type == ProductType.service) {
    return (
      bg: const Color(0xFFEDE9FE),
      text: AppColors.purpleAccent,
      label: _tr('Available', 'Inapatikana'),
    );
  }
  if (stock == 0) {
    return (
      bg: AppColors.errorBg,
      text: AppColors.error,
      label: _tr('Out of Stock', 'Imeisha'),
    );
  }
  if (stock <= reorder) {
    return (
      bg: AppColors.warningBg,
      text: AppColors.warning,
      label: _tr('Low Stock', 'Stoo Chini'),
    );
  }
  return (
    bg: AppColors.successBg,
    text: AppColors.success,
    label: _tr('In Stock', 'Ipo Stoo'),
  );
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemListProvider);

    return Scaffold(
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet<void>(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            builder: (_) => const _ProductFormSheet(),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.navyPrimary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            _tr('Add Product', 'Ongeza Bidhaa'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: Column(
        children: [
          PageIntroHeader(
            title: _tr('Keep stock healthy', 'Dhibiti stoo iwe salama'),
            subtitle: _tr(
              'Track every product, know your profit, never run out.',
              'Fuatilia bidhaa, jua faida yako, usimalizike.',
            ),
            scene: EmotionalLottieScene.onboarding,
          ),
          Expanded(
            child: inventoryAsync.when(
              loading: () => const InventoryPageSkeleton(),
              error: (_, e) => Center(
                child: Text(
                  _tr(
                    'Unable to load inventory right now.',
                    'Imeshindikana kupakia stoo kwa sasa.',
                  ),
                ),
              ),
              data: (items) => _InventoryBody(items: items),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _InventoryBody extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _InventoryBody({required this.items});

  @override
  Widget build(BuildContext context) {
    // Compute stats
    double totalStockValue = 0;
    double totalPotentialRevenue = 0;
    int lowCount = 0;
    int outCount = 0;

    for (final item in items) {
      final type = _readType(item);
      final buy = _readBuyingPrice(item);
      final sell = _readSellingPrice(item);
      final stock = parseStock(item['stock'] ?? item['currentStock'] ?? item['quantity']);
      final reorder = parseStock(item['reorderPoint']) == 0
          ? 5
          : parseStock(item['reorderPoint']);
      if (type != ProductType.service) {
        totalStockValue += buy * stock;
        totalPotentialRevenue += sell * stock;
        if (stock == 0) { outCount++; }
        else if (stock <= reorder) { lowCount++; }
      }
    }
    final totalProfit = totalPotentialRevenue - totalStockValue;

    final lowItems = items.where((item) {
      final type = _readType(item);
      if (type == ProductType.service) return false;
      final stock = parseStock(item['stock'] ?? item['currentStock'] ?? item['quantity']);
      final reorder = parseStock(item['reorderPoint']) == 0
          ? 5
          : parseStock(item['reorderPoint']);
      return stock > 0 && stock <= reorder;
    }).toList();

    final outItems = items.where((item) {
      final type = _readType(item);
      if (type == ProductType.service) return false;
      final stock = parseStock(item['stock'] ?? item['currentStock'] ?? item['quantity']);
      return stock == 0;
    }).toList();

    return CustomScrollView(
      slivers: [
        // ── Stats Grid ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: _tr('Total Products', 'Bidhaa Zote'),
                        value: '${items.length}',
                        icon: Icons.category_outlined,
                        iconColor: AppColors.navySecondary,
                        iconBg: const Color(0xFFDBEAFE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: _tr('Stock Value', 'Thamani ya Stoo'),
                        value: _fmtAmount(totalStockValue),
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.tealAccent,
                        iconBg: AppColors.infoBg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: _tr('Est. Profit', 'Faida Inayoweza'),
                        value: _fmtAmount(totalProfit),
                        icon: Icons.trending_up_rounded,
                        iconColor: AppColors.success,
                        iconBg: AppColors.successBg,
                        valueColor: totalProfit >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: _tr('Alerts', 'Tahadhari'),
                        value: '${lowCount + outCount}',
                        icon: Icons.warning_amber_rounded,
                        iconColor: lowCount + outCount > 0
                            ? AppColors.warning
                            : AppColors.success,
                        iconBg: lowCount + outCount > 0
                            ? AppColors.warningBg
                            : AppColors.successBg,
                        valueColor: lowCount + outCount > 0
                            ? AppColors.warning
                            : AppColors.success,
                        subtitle: lowCount + outCount > 0
                            ? '$outCount ${_tr("out", "imeisha")} · $lowCount ${_tr("low", "chini")}'
                            : _tr('All good', 'Zote sawa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Alert Banners ────────────────────────────────────────────────────
        if (outItems.isNotEmpty || lowItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (outItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _tr('Out of Stock', 'Imeisha Kabisa'),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: outItems.length,
                      separatorBuilder: (_, i) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _AlertPill(
                        item: outItems[i],
                        isOut: true,
                      ),
                    ),
                  ),
                ],
                if (lowItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _tr('Running Low', 'Inakwisha'),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: lowItems.length,
                      separatorBuilder: (_, i) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _AlertPill(
                        item: lowItems[i],
                        isOut: false,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // ── Section Header ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              _tr('All Products', 'Bidhaa Zote'),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),

        // ── Product List ─────────────────────────────────────────────────────
        items.isEmpty
            ? SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: _tr('No products yet', 'Bado hakuna bidhaa'),
                  subtitle: _tr(
                    'Add your first product to start tracking inventory.',
                    'Ongeza bidhaa ya kwanza kuanza kufuatilia stoo.',
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProductCard(item: items[i]),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color? valueColor;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? AppColors.navyPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert Pill ────────────────────────────────────────────────────────────────

class _AlertPill extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isOut;

  const _AlertPill({required this.item, required this.isOut});

  @override
  Widget build(BuildContext context) {
    final name =
        (item['name'] ?? item['productName'] ?? 'Item').toString();
    final stock = parseStock(
      item['stock'] ?? item['currentStock'] ?? item['quantity'],
    );
    final color = isOut ? AppColors.error : AppColors.warning;
    final bg = isOut ? AppColors.errorBg : AppColors.warningBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOut ? Icons.remove_circle_outline : Icons.warning_amber_rounded,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isOut
                ? _tr('Out of stock', 'Imeisha kabisa')
                : '${_tr("Only", "Zimebaki")} $stock ${_tr("left", "tu")}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  const _ProductCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = _readType(item);
    final buy = _readBuyingPrice(item);
    final sell = _readSellingPrice(item);
    final stock = parseStock(
      item['stock'] ?? item['currentStock'] ?? item['quantity'],
    );
    final reorder =
        parseStock(item['reorderPoint']) == 0 ? 5 : parseStock(item['reorderPoint']);
    final name = (item['name'] ?? item['productName'] ?? 'Item').toString();
    final category = (item['category'] ?? '').toString();
    final unit = (item['unit'] ?? 'pcs').toString();
    final profitAmt = _profit(buy, sell);
    final marginPct = _margin(buy, sell);

    final typeC = _typeConfig(type);
    final stockC = _stockStatusConfig(stock, reorder, type);

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => _ProductDetailSheet(item: item),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top row ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: typeC.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeC.icon, size: 22, color: typeC.text),
                  ),
                  const SizedBox(width: 12),
                  // Name + category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category.isNotEmpty)
                          Text(
                            category,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stock count (right side)
                  if (type != ProductType.service)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$stock',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: stockC.text,
                          ),
                        ),
                        Text(
                          unit,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────────────────────
            Container(height: 1, color: AppColors.border),

            // ── Bottom row: prices + badges ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Prices
                  if (buy > 0) ...[
                    _MiniPriceChip(
                      label: _tr('Buy', 'Nunua'),
                      value: _fmtAmount(buy),
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _MiniPriceChip(
                    label: _tr('Sell', 'Uza'),
                    value: _fmtAmount(sell),
                    color: AppColors.navyPrimary,
                  ),
                  if (buy > 0 && sell > 0) ...[
                    const SizedBox(width: 8),
                    _ProfitBadge(profit: profitAmt, margin: marginPct),
                  ],
                  const Spacer(),
                  // Stock status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: stockC.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stockC.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: stockC.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniPriceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProfitBadge extends StatelessWidget {
  final double profit;
  final double margin;
  const _ProfitBadge({required this.profit, required this.margin});

  @override
  Widget build(BuildContext context) {
    final isPositive = profit >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.successBg : AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 12,
            color: isPositive ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 3),
          Text(
            _fmtMargin(margin),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPositive ? AppColors.success : AppColors.error,
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
  ConsumerState<_ProductDetailSheet> createState() =>
      _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<_ProductDetailSheet> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final id = item['id'] as String? ?? '';
    final type = _readType(item);
    final buy = _readBuyingPrice(item);
    final sell = _readSellingPrice(item);
    final stock = parseStock(
      item['stock'] ?? item['currentStock'] ?? item['quantity'],
    );
    final reorder =
        parseStock(item['reorderPoint']) == 0 ? 5 : parseStock(item['reorderPoint']);
    final name = (item['name'] ?? item['productName'] ?? 'Item').toString();
    final category = (item['category'] ?? '').toString();
    final unit = (item['unit'] ?? 'pcs').toString();
    final sku = (item['sku'] ?? '').toString();
    final profitAmt = _profit(buy, sell);
    final marginPct = _margin(buy, sell);
    final typeC = _typeConfig(type);
    final stockC = _stockStatusConfig(stock, reorder, type);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: Material(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: _editMode
            ? _ProductFormSheet(
                existingItem: item,
                existingId: id,
                onDone: () => Navigator.of(context).pop(),
              )
            : Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Header card ──────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.navyPrimary,
                                  AppColors.navySecondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        typeC.icon,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _editMode = true),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _HeaderBadge(
                                      label: typeC.label,
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                    const SizedBox(width: 8),
                                    _HeaderBadge(
                                      label: stockC.label,
                                      color: stockC.text.withValues(alpha: 0.25),
                                    ),
                                    if (category.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      _HeaderBadge(
                                        label: category,
                                        color:
                                            Colors.white.withValues(alpha: 0.15),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Price breakdown ──────────────────────────────
                          _SectionLabel(_tr('Pricing & Profit', 'Bei na Faida')),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoMetric(
                                  label: _tr('Buying Price', 'Bei ya Kununua'),
                                  value: buy > 0
                                      ? _fmtAmount(buy)
                                      : _tr('Not set', 'Haijawekwa'),
                                  icon: Icons.shopping_cart_outlined,
                                  iconBg: AppColors.surfaceVariant,
                                  iconColor: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InfoMetric(
                                  label: _tr('Selling Price', 'Bei ya Kuuza'),
                                  value: sell > 0
                                      ? _fmtAmount(sell)
                                      : _tr('Not set', 'Haijawekwa'),
                                  icon: Icons.sell_outlined,
                                  iconBg: const Color(0xFFDBEAFE),
                                  iconColor: AppColors.navySecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (buy > 0 && sell > 0)
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoMetric(
                                    label: _tr('Profit/Unit', 'Faida kwa Kipande'),
                                    value: _fmtAmount(profitAmt),
                                    icon: Icons.attach_money_rounded,
                                    iconBg: profitAmt >= 0
                                        ? AppColors.successBg
                                        : AppColors.errorBg,
                                    iconColor: profitAmt >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    valueColor: profitAmt >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _InfoMetric(
                                    label: _tr('Margin', 'Asilimia ya Faida'),
                                    value: _fmtMargin(marginPct),
                                    icon: Icons.pie_chart_outline_rounded,
                                    iconBg: AppColors.warningBg,
                                    iconColor: AppColors.warning,
                                    valueColor: marginPct >= 20
                                        ? AppColors.success
                                        : marginPct >= 10
                                            ? AppColors.warning
                                            : AppColors.error,
                                  ),
                                ),
                              ],
                            ),

                          // ── Stock info ───────────────────────────────────
                          if (type != ProductType.service) ...[
                            const SizedBox(height: 20),
                            _SectionLabel(
                              _tr('Stock Information', 'Taarifa ya Stoo'),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoMetric(
                                    label: _tr(
                                      'Current Stock',
                                      'Stoo Iliyopo Sasa',
                                    ),
                                    value: '$stock $unit',
                                    icon: Icons.inventory_2_outlined,
                                    iconBg: stockC.bg,
                                    iconColor: stockC.text,
                                    valueColor: stockC.text,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _InfoMetric(
                                    label: _tr(
                                      'Reorder Point',
                                      'Kikomo cha Kuagiza',
                                    ),
                                    value: '$reorder $unit',
                                    icon: Icons.flag_outlined,
                                    iconBg: AppColors.warningBg,
                                    iconColor: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (buy > 0)
                              _InfoMetric(
                                label: _tr(
                                  'Total Stock Value',
                                  'Thamani Yote ya Stoo',
                                ),
                                value: _fmtAmount(buy * stock),
                                icon: Icons.account_balance_wallet_outlined,
                                iconBg: AppColors.infoBg,
                                iconColor: AppColors.tealAccent,
                              ),
                            const SizedBox(height: 10),
                            // Stock bar
                            _StockBar(stock: stock, reorder: reorder),
                          ],

                          // ── Other info ───────────────────────────────────
                          if (sku.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _SectionLabel(_tr('Product Details', 'Maelezo ya Bidhaa')),
                            const SizedBox(height: 10),
                            _InfoMetric(
                              label: 'SKU',
                              value: sku,
                              icon: Icons.tag_rounded,
                              iconBg: AppColors.surfaceVariant,
                              iconColor: AppColors.textMuted,
                            ),
                          ],
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

class _HeaderBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color? valueColor;

  const _InfoMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.navyPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBar extends StatelessWidget {
  final int stock;
  final int reorder;
  const _StockBar({required this.stock, required this.reorder});

  @override
  Widget build(BuildContext context) {
    final max = (reorder * 4).clamp(stock + 1, 9999);
    final fraction = (stock / max).clamp(0.0, 1.0);
    final color = stock == 0
        ? AppColors.error
        : stock <= reorder
            ? AppColors.warning
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _tr('Stock Level', 'Kiwango cha Stoo'),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              '$stock / $max',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _tr(
            'Reorder at $reorder units',
            'Agiza upya ukifika vipande $reorder',
          ),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textMuted,
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
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _buyPriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  final _reorderCtrl = TextEditingController(text: '5');
  String _unit = 'pcs';
  bool _isSaving = false;

  static const _units = [
    'pcs',
    'kg',
    'liters',
    'boxes',
    'bottles',
    'bags',
    'meters',
    'sets',
    'dozen',
    'packets',
  ];

  bool get _isEdit => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _type = _readType(item);
      _nameCtrl.text = (item['name'] ?? item['productName'] ?? '').toString();
      _categoryCtrl.text = (item['category'] ?? '').toString();
      _skuCtrl.text = (item['sku'] ?? '').toString();
      final buy = _readBuyingPrice(item);
      final sell = _readSellingPrice(item);
      if (buy > 0) _buyPriceCtrl.text = buy.toStringAsFixed(0);
      if (sell > 0) _sellPriceCtrl.text = sell.toStringAsFixed(0);
      final stock = parseStock(
        item['stock'] ?? item['currentStock'] ?? item['quantity'],
      );
      _stockCtrl.text = '$stock';
      final reorder = parseStock(item['reorderPoint']);
      _reorderCtrl.text = reorder > 0 ? '$reorder' : '5';
      _unit = (item['unit'] ?? 'pcs').toString();
    } else {
      _type = ProductType.stock;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _skuCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _stockCtrl.dispose();
    _reorderCtrl.dispose();
    super.dispose();
  }

  double get _buyPrice =>
      double.tryParse(_buyPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
      0;
  double get _sellPrice =>
      double.tryParse(_sellPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
      0;
  double get _previewProfit => _profit(_buyPrice, _sellPrice);
  double get _previewMargin => _margin(_buyPrice, _sellPrice);

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(_tr('Enter product name', 'Ingiza jina la bidhaa'));
      return;
    }
    if (_sellPrice <= 0) {
      _snack(_tr('Enter a selling price', 'Ingiza bei ya kuuza'));
      return;
    }
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 1;
    final reorder = int.tryParse(_reorderCtrl.text.trim()) ?? 5;

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final col = repo.scopeCollection(
        uid: user.uid,
        context: ctx,
        childCollection: 'inventory_items',
      );

      final data = <String, dynamic>{
        'name': name,
        'productType': _type.name,
        'category':
            _categoryCtrl.text.trim().isNotEmpty
                ? _categoryCtrl.text.trim()
                : 'General',
        'unit': _unit,
        'sellingPrice': _sellPrice,
        'unitPrice': _sellPrice, // backward compat
        if (_buyPrice > 0) 'buyingPrice': _buyPrice,
        if (_type != ProductType.service) ...{
          'currentStock': stock,
          'stock': stock,
          'reorderPoint': reorder,
        },
        if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit && widget.existingId != null) {
        await col.doc(widget.existingId).update(data);
        messenger.showSnackBar(SnackBar(
          content: Text(_tr('Product updated!', 'Bidhaa imesasishwa!')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        if (widget.onDone != null) {
          widget.onDone!();
        } else {
          navigator.pop();
        }
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await col.add(data);
        messenger.showSnackBar(SnackBar(
          content: Text(_tr('Product added!', 'Bidhaa imeongezwa!')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        navigator.pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(
        content: Text(
          _tr(
            'Failed to save product. Try again.',
            'Imeshindikana. Jaribu tena.',
          ),
        ),
      ));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showStock = _type != ProductType.service;
    final profitReady = _buyPrice > 0 && _sellPrice > 0;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: Material(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit
                              ? _tr('Edit Product', 'Hariri Bidhaa')
                              : _tr('Add New Product', 'Ongeza Bidhaa Mpya'),
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        Text(
                          _tr(
                            'Fill in the details below',
                            'Jaza maelezo hapa chini',
                          ),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEdit)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Product Type Selector ──────────────────────────────
                    _SectionLabel(_tr('Product Type', 'Aina ya Bidhaa')),
                    const SizedBox(height: 10),
                    _TypeSelector(
                      selected: _type,
                      onChanged: (t) => setState(() => _type = t),
                    ),

                    const SizedBox(height: 20),

                    // ── Basic Info ─────────────────────────────────────────
                    _SectionLabel(_tr('Basic Info', 'Maelezo ya Msingi')),
                    const SizedBox(height: 10),
                    _Field(
                      ctrl: _nameCtrl,
                      label: _tr('Product Name *', 'Jina la Bidhaa *'),
                      icon: Icons.inventory_2_outlined,
                      caps: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            ctrl: _categoryCtrl,
                            label: _tr('Category', 'Kategoria'),
                            icon: Icons.category_outlined,
                            caps: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _UnitDropdown(
                            value: _unit,
                            units: _units,
                            onChanged: (v) => setState(() => _unit = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      ctrl: _skuCtrl,
                      label: _tr('SKU / Barcode (Optional)', 'SKU (Hiari)'),
                      icon: Icons.tag_outlined,
                      caps: TextCapitalization.characters,
                    ),

                    const SizedBox(height: 20),

                    // ── Pricing ────────────────────────────────────────────
                    _SectionLabel(_tr('Pricing', 'Bei')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            ctrl: _buyPriceCtrl,
                            label: _tr('Buying Price (TSh)', 'Bei ya Kununua'),
                            icon: Icons.shopping_cart_outlined,
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            ctrl: _sellPriceCtrl,
                            label: _tr('Selling Price (TSh) *', 'Bei ya Kuuza *'),
                            icon: Icons.sell_outlined,
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),

                    // ── Live profit preview ────────────────────────────────
                    if (profitReady) ...[
                      const SizedBox(height: 10),
                      _ProfitPreview(
                        profit: _previewProfit,
                        margin: _previewMargin,
                        sell: _sellPrice,
                        buy: _buyPrice,
                      ),
                    ],

                    // ── Stock Info (not for service) ───────────────────────
                    if (showStock) ...[
                      const SizedBox(height: 20),
                      _SectionLabel(
                        _tr('Stock Information', 'Taarifa ya Stoo'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              ctrl: _stockCtrl,
                              label: _tr(
                                'Current Stock Qty',
                                'Kiasi cha Stoo Sasa',
                              ),
                              icon: Icons.inventory_outlined,
                              keyboard: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              ctrl: _reorderCtrl,
                              label: _tr(
                                'Reorder Point',
                                'Kikomo cha Kuagiza',
                              ),
                              icon: Icons.flag_outlined,
                              keyboard: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tr(
                          'You\'ll be alerted when stock reaches the reorder point.',
                          'Utaarifiwa stoo itakapofika kikomo cha kuagiza.',
                        ),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Save button ────────────────────────────────────────
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.navyPrimary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.navyPrimary,
                                ),
                              )
                            : Text(
                                _isEdit
                                    ? _tr(
                                        'Save Changes',
                                        'Hifadhi Mabadiliko',
                                      )
                                    : _tr(
                                        'Add to Inventory',
                                        'Ongeza kwa Hisa',
                                      ),
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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

// ── Type Selector ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final ProductType selected;
  final ValueChanged<ProductType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ProductType.values.map((t) {
        final c = _typeConfig(t);
        final isSelected = t == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: t != ProductType.values.last ? 10 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? c.bg : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? c.text.withValues(alpha: 0.4) : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    c.icon,
                    size: 22,
                    color: isSelected ? c.text : AppColors.textMuted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? c.text : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Profit Preview ────────────────────────────────────────────────────────────

class _ProfitPreview extends StatelessWidget {
  final double profit;
  final double margin;
  final double sell;
  final double buy;

  const _ProfitPreview({
    required this.profit,
    required this.margin,
    required this.sell,
    required this.buy,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = profit >= 0;
    final color = isGood ? AppColors.success : AppColors.error;
    final bg = isGood ? AppColors.successBg : AppColors.errorBg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Profit Preview', 'Tathmini ya Faida'),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_fmtAmount(profit)} per unit · ${_fmtMargin(margin)} margin',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Form Widgets ─────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization caps;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  final String value;
  final List<String> units;
  final ValueChanged<String> onChanged;

  const _UnitDropdown({
    required this.value,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: units.contains(value) ? value : units.first,
      decoration: InputDecoration(
        labelText: _tr('Unit', 'Kitengo'),
        prefixIcon: const Icon(Icons.scale_outlined, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: units
          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}
