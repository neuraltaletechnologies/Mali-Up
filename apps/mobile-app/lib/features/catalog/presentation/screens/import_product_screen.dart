import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/master_product.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Screen shown after the user taps "Import" on a master product.
///
/// Allows editing cost price, selling price, initial stock, and SKU before
/// saving a brand-new business-owned [InventoryItem].
/// The master product record is NEVER modified.
class ImportProductScreen extends ConsumerStatefulWidget {
  final MasterProduct product;

  const ImportProductScreen({super.key, required this.product});

  @override
  ConsumerState<ImportProductScreen> createState() =>
      _ImportProductScreenState();
}

class _ImportProductScreenState extends ConsumerState<ImportProductScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _sellCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _skuCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p.productName);
    _costCtrl = TextEditingController(
      text: p.suggestedCostPrice > 0
          ? p.suggestedCostPrice.toStringAsFixed(0)
          : '',
    );
    _sellCtrl = TextEditingController(
      text: p.suggestedSellingPrice > 0
          ? p.suggestedSellingPrice.toStringAsFixed(0)
          : '',
    );
    _stockCtrl = TextEditingController(text: '1');
    _skuCtrl = TextEditingController(text: p.skuTemplate);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    super.dispose();
  }

  double get _costVal =>
      double.tryParse(_costCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  double get _sellVal =>
      double.tryParse(_sellCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  double get _stockVal => double.tryParse(_stockCtrl.text) ?? 1;

  double get _margin => _sellVal > 0 && _costVal > 0
      ? ((_sellVal - _costVal) / _sellVal) * 100
      : 0;

  Future<void> _import() async {
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
      final now = DateTime.now().toIso8601String();
      final item = InventoryItem(
        id: '',
        name: name,
        category: widget.product.categoryName,
        categoryName: widget.product.categoryName,
        sku: _skuCtrl.text.trim(),
        currentStock: _stockVal,
        reorderPoint: 5,
        unitPrice: _sellVal,
        costPrice: _costVal,
        unit: widget.product.defaultUnit,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(inventoryRepositoryProvider).save(item);

      if (!mounted) return;
      msg.showSnackBar(SnackBar(
        content: Text(
          _tr('Product imported successfully!', 'Bidhaa imeingizwa kwa mafanikio!'),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      // Pop back to catalog, then pop catalog to return to inventory
      nav.pop();
      nav.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(_tr('Failed to import product', 'Imeshindikana kuingiza bidhaa'));
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navyPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Import Product', 'Ingiza Bidhaa'),
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
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // ── Source info card ──────────────────────────────────────────
            _SourceCard(product: widget.product),
            const SizedBox(height: 24),

            // ── Section: Product details ──────────────────────────────────
            _SectionLabel(_tr('Product Details', 'Maelezo ya Bidhaa')),
            const SizedBox(height: 12),

            _FieldLabel(_tr('Product Name', 'Jina la Bidhaa')),
            const SizedBox(height: 6),
            _TextField(
              controller: _nameCtrl,
              hint: _tr('Enter product name', 'Ingiza jina la bidhaa'),
            ),
            const SizedBox(height: 14),

            _FieldLabel(_tr('SKU (Optional)', 'SKU (Hiari)')),
            const SizedBox(height: 6),
            _TextField(
              controller: _skuCtrl,
              hint: _tr('Leave blank to auto-generate', 'Acha tupu ili izalishwe otomatiki'),
            ),
            const SizedBox(height: 24),

            // ── Section: Pricing ──────────────────────────────────────────
            _SectionLabel(_tr('Pricing', 'Bei')),
            const SizedBox(height: 4),
            Text(
              _tr(
                'Suggested prices are pre-filled. You must set your own prices.',
                'Bei iliyopendekezwa imejazwa. Lazima uweke bei yako mwenyewe.',
              ),
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(_tr('Cost Price (TSh)', 'Bei ya Kununua (TSh)')),
                      const SizedBox(height: 6),
                      _NumericField(
                        controller: _costCtrl,
                        hint: '0',
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
                      _FieldLabel(_tr('Selling Price (TSh)', 'Bei ya Kuuza (TSh)')),
                      const SizedBox(height: 6),
                      _NumericField(
                        controller: _sellCtrl,
                        hint: '0',
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Margin indicator
            if (_sellVal > 0 && _costVal > 0) ...[
              const SizedBox(height: 10),
              _MarginBadge(margin: _margin),
            ],

            const SizedBox(height: 24),

            // ── Section: Stock ────────────────────────────────────────────
            _SectionLabel(_tr('Initial Stock', 'Stoo ya Awali')),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(
                        _tr(
                          'Quantity (${widget.product.defaultUnit})',
                          'Idadi (${widget.product.defaultUnit})',
                        ),
                      ),
                      const SizedBox(height: 6),
                      _NumericField(
                        controller: _stockCtrl,
                        hint: '1',
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
                      _FieldLabel(_tr('Unit', 'Kitengo')),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FC),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          widget.product.defaultUnit,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.navyPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Import button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _import,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.download_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _tr('Import to My Inventory',
                                'Ingiza kwenye Stoo Yangu'),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              _tr(
                'This creates an independent product in your inventory. '
                'Changes here do not affect the master catalog.',
                'Hii inaunda bidhaa huru kwenye stoo yako. '
                'Mabadiliko hapa hayaathiri katalogi kuu.',
              ),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
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

// ── Reusable small widgets ────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  final MasterProduct product;
  const _SourceCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded,
              color: AppColors.tealAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Importing from Master Catalog',
                      'Inaingizwa kutoka Katalogi Kuu'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.productName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.categoryName,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
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
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.navyPrimary,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _TextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.navyPrimary,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.tealAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _NumericField({
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.navyPrimary,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.tealAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _MarginBadge extends StatelessWidget {
  final double margin;
  const _MarginBadge({required this.margin});

  @override
  Widget build(BuildContext context) {
    final isGood = margin >= 20;
    final color = isGood ? AppColors.success : const Color(0xFFD97706);
    final bg = isGood ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood
                ? Icons.trending_up_rounded
                : Icons.trending_flat_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _tr(
              'Margin: ${margin.toStringAsFixed(1)}%',
              'Faida: ${margin.toStringAsFixed(1)}%',
            ),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
