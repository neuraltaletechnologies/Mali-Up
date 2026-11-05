import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../inventory/data/inventory_providers.dart';

/// Point-of-sale building blocks for the Sales screen's "Sell" mode:
/// a product grid with image cards (wide screens), a product list with round
/// images (phones), the Sell | History toggle and the phone cart bar.
///
/// Products are the inventory maps from `inventoryItemListProvider`.

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

String _money(double v) {
  final s = v.toStringAsFixed(0);
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'TSh $b';
}

/// One product in the phone cart, before checkout.
class PosCartLine {
  final Map<String, dynamic> item;
  int qty;

  PosCartLine(this.item, {this.qty = 1});

  String get id => (item['id'] ?? '').toString();
  double get price => parseUnitPrice(item['unitPrice'] ?? item['price'] ?? 0);
  double get total => price * qty;
}

/// Read-only helpers over an inventory map.
extension PosProduct on Map<String, dynamic> {
  String get posName => (this['name'] ?? '').toString();
  String get posCategory =>
      (this['categoryName'] ?? this['category'] ?? '').toString().trim();
  String get posImageUrl => (this['imageUrl'] ?? '').toString().trim();
  double get posPrice =>
      parseUnitPrice(this['unitPrice'] ?? this['price'] ?? 0);
  bool get posIsService => (this['productType'] ?? '').toString() == 'service';
  int get posStock => parseStock(this['currentStock'] ?? this['stock'] ?? 0);
  bool get posOutOfStock => !posIsService && posStock <= 0;
  bool get posIsActive => this['isActive'] != false;
}

/// Active products matching [query] (name, SKU, barcode) and [category],
/// in-stock first, then by name.
List<Map<String, dynamic>> filterPosProducts(
  List<Map<String, dynamic>> products, {
  String query = '',
  String? category,
}) {
  final q = query.trim().toLowerCase();
  bool matches(Map<String, dynamic> p) {
    if (!p.posIsActive) return false;
    if (category != null && p.posCategory != category) return false;
    if (q.isEmpty) return true;
    return p.posName.toLowerCase().contains(q) ||
        (p['sku'] ?? '').toString().toLowerCase().contains(q) ||
        (p['barcode'] ?? '').toString().toLowerCase().contains(q);
  }

  return products.where(matches).toList()..sort((a, b) {
    if (a.posOutOfStock != b.posOutOfStock) return a.posOutOfStock ? 1 : -1;
    return a.posName.toLowerCase().compareTo(b.posName.toLowerCase());
  });
}

List<String> posCategories(List<Map<String, dynamic>> products) {
  final set = <String>{
    for (final p in products)
      if (p.posIsActive && p.posCategory.isNotEmpty) p.posCategory,
  };
  return set.toList()..sort();
}

// ── Sell | History toggle ────────────────────────────────────────────────────

/// Sell | History switch for the navy Sales header, sitting beside the
/// search button. A 40px capsule matching [HeaderIconButton]: icons only on
/// phones, icon + label on wide or landscape screens.
class PosModeToggle extends StatelessWidget {
  final bool historyMode;
  final ValueChanged<bool> onChanged;

  const PosModeToggle({
    super.key,
    required this.historyMode,
    required this.onChanged,
  });

  static bool _showLabels(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 600 || size.width > size.height;
  }

  @override
  Widget build(BuildContext context) {
    final labels = _showLabels(context);

    Widget seg(String label, IconData icon, bool selected, bool value) {
      final fg = selected ? AppColors.navyPrimary : Colors.white70;
      final button = GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          padding: EdgeInsets.symmetric(horizontal: labels ? 12 : 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              if (labels) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      return Semantics(
        button: true,
        selected: selected,
        child: labels ? button : Tooltip(message: label, child: button),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(
            _tr('Sell', 'Uza'),
            Icons.point_of_sale_rounded,
            !historyMode,
            false,
          ),
          seg(
            _tr('History', 'Historia'),
            Icons.receipt_long_rounded,
            historyMode,
            true,
          ),
        ],
      ),
    );
  }
}

// ── Category chips ───────────────────────────────────────────────────────────

class PosCategoryBar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final EdgeInsetsGeometry padding;

  const PosCategoryBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    Widget chip(String label, String? value) {
      final isSel = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelected(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSel ? AppColors.navyPrimary : Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: isSel ? AppColors.navyPrimary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSel ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          chip(_tr('All', 'Zote'), null),
          for (final c in categories) chip(c, c),
        ],
      ),
    );
  }
}

// ── Product image / placeholder ──────────────────────────────────────────────

const _tileColors = [
  Color(0xFFE0F2FE),
  Color(0xFFFEF3C7),
  Color(0xFFDCFCE7),
  Color(0xFFFCE7F3),
  Color(0xFFEDE9FE),
  Color(0xFFFFEDD5),
];

Color _tileColorFor(String name) =>
    _tileColors[name.isEmpty ? 0 : name.codeUnitAt(0) % _tileColors.length];

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
}

/// Product photo when there is one, otherwise a soft coloured tile with the
/// product's initials (or a service icon).
class PosProductImage extends StatelessWidget {
  final Map<String, dynamic> product;
  final double fontSize;

  const PosProductImage({super.key, required this.product, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    final url = product.posImageUrl;
    final placeholder = Container(
      color: _tileColorFor(product.posName),
      alignment: Alignment.center,
      child: product.posIsService
          ? Icon(
              Icons.design_services_outlined,
              size: fontSize * 1.2,
              color: AppColors.navyPrimary,
            )
          : Text(
              _initials(product.posName),
              style: GoogleFonts.dmSans(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary.withValues(alpha: 0.75),
              ),
            ),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

String _stockLabel(Map<String, dynamic> p) {
  if (p.posIsService) return _tr('Service', 'Huduma');
  if (p.posOutOfStock) return _tr('Out of stock', 'Imeisha');
  return _tr('${p.posStock} in stock', 'Zipo ${p.posStock}');
}

Color _stockColor(Map<String, dynamic> p) {
  if (p.posIsService) return AppColors.tealAccent;
  if (p.posOutOfStock) return AppColors.error;
  final reorder = parseStock(p['reorderPoint'] ?? 0);
  if (reorder > 0 && p.posStock <= reorder) return AppColors.warning;
  return AppColors.success;
}

// ── Wide screens: product card grid ──────────────────────────────────────────

class PosProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final ValueChanged<Map<String, dynamic>> onTap;
  final EdgeInsetsGeometry padding;

  const PosProductGrid({
    super.key,
    required this.products,
    required this.onTap,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const _PosEmpty();
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) =>
          _PosProductCard(product: products[i], onTap: onTap),
    );
  }
}

class _PosProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final ValueChanged<Map<String, dynamic>> onTap;

  const _PosProductCard({required this.product, required this.onTap});

  @override
  State<_PosProductCard> createState() => _PosProductCardState();
}

class _PosProductCardState extends State<_PosProductCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final disabled = p.posOutOfStock;
    return MouseRegion(
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: disabled ? null : () => widget.onTap(p),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hover && !disabled
                    ? AppColors.tealAccent.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
              boxShadow: _hover && !disabled
                  ? const [
                      BoxShadow(
                        color: Color(0x1A0D1B3E),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Opacity(
              opacity: disabled ? 0.5 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: PosProductImage(product: p, fontSize: 26)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.posName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _money(p.posPrice),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tealAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _stockLabel(p),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _stockColor(p),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Phones: product list with round images ───────────────────────────────────

class PosProductList extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  /// Quantity of each product (by id) already in the cart.
  final Map<String, int> cartQty;
  final ValueChanged<Map<String, dynamic>> onAdd;
  final ValueChanged<Map<String, dynamic>> onRemove;
  final EdgeInsetsGeometry padding;

  const PosProductList({
    super.key,
    required this.products,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const _PosEmpty();
    return ListView.separated(
      padding: padding,
      itemCount: products.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(left: 76),
        child: Divider(height: 1, color: AppColors.borderLight),
      ),
      itemBuilder: (_, i) {
        final p = products[i];
        final qty = cartQty[(p['id'] ?? '').toString()] ?? 0;
        return _PosProductRow(
          product: p,
          qty: qty,
          onAdd: () => onAdd(p),
          onRemove: () => onRemove(p),
        );
      },
    );
  }
}

class _PosProductRow extends StatelessWidget {
  final Map<String, dynamic> product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PosProductRow({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final disabled = p.posOutOfStock;
    final inCart = qty > 0;
    return Material(
      color: inCart
          ? AppColors.tealAccent.withValues(alpha: 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onAdd,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: PosProductImage(product: p, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.posName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stockLabel(p),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _stockColor(p),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _money(p.posPrice),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                if (inCart)
                  _QtyStepper(qty: qty, onAdd: onAdd, onRemove: onRemove)
                else
                  _RoundIconButton(
                    icon: Icons.add_rounded,
                    filled: true,
                    onTap: disabled ? null : onAdd,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QtyStepper({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(icon: Icons.remove_rounded, onTap: onRemove),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary,
            ),
          ),
        ),
        _RoundIconButton(icon: Icons.add_rounded, filled: true, onTap: onAdd),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, this.filled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.yellowBrand : Colors.white,
      shape: CircleBorder(
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: AppColors.navyPrimary),
        ),
      ),
    );
  }
}

// ── Phones: cart bar ─────────────────────────────────────────────────────────

class PosCartBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;
  final VoidCallback onClear;

  const PosCartBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onCheckout,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navyPrimary,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      shadowColor: const Color(0x400D1B3E),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onCheckout,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onClear,
                tooltip: _tr('Clear cart', 'Futa kikapu'),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.yellowBrand,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$itemCount',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _money(total),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                _tr('Checkout', 'Lipia'),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellowBrand,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.yellowBrand,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosEmpty extends StatelessWidget {
  const _PosEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _tr('No products found', 'Hakuna bidhaa'),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _tr(
                'Add products in Stock to sell them here.',
                'Ongeza bidhaa kwenye ukurasa wa Bidhaa ili uziuze hapa.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
