import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/domain/models/debt.dart';
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

  // Asili ya Stoo: 'existing' = stoki niliyo nayo, 'purchased' = nimenunua
  String _stockOrigin = 'existing';
  // Malipo: 'paid' = nimelipia, 'partial' = nimelipa kiasi, 'unpaid' = sijalipia
  String _paymentStatus = 'paid';

  final _supplierNameCtrl = TextEditingController();
  final _supplierPhoneCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p.productName);
    _costCtrl = TextEditingController();
    _sellCtrl = TextEditingController();
    _stockCtrl = TextEditingController(text: '1');
    _skuCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    _supplierNameCtrl.dispose();
    _supplierPhoneCtrl.dispose();
    _amountPaidCtrl.dispose();
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
        category: widget.product.categorySlug,
        categoryName: widget.product.categorySlug,
        sku: _skuCtrl.text.trim(),
        currentStock: _stockVal,
        reorderPoint: 5,
        unitPrice: _sellVal,
        costPrice: _costVal,
        unit: widget.product.unit,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(inventoryRepositoryProvider).save(item);

      // Create payable debt when purchased and not fully paid
      final hasDebt = _stockOrigin == 'purchased' &&
          (_paymentStatus == 'unpaid' || _paymentStatus == 'partial');
      if (hasDebt && _costVal > 0 && _stockVal > 0) {
        final total = _costVal * _stockVal;
        final alreadyPaid = _paymentStatus == 'partial'
            ? (double.tryParse(
                    _amountPaidCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0)
            : 0.0;
        final debtAmount = (total - alreadyPaid).clamp(0.0, total);
        if (debtAmount > 0) {
          final dueDate = DateTime.now().add(const Duration(days: 30));
          final dueDateStr =
              '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
          await ref.read(debtRepositoryProvider).save(Debt(
            id: '',
            partyName: _supplierNameCtrl.text.trim(),
            partyPhone: _supplierPhoneCtrl.text.trim(),
            type: 'payable',
            originalAmount: debtAmount,
            dueDate: dueDateStr,
            note: _tr(
                'Purchase: ${_nameCtrl.text.trim()}',
                'Ununuzi: ${_nameCtrl.text.trim()}'),
            createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      }

      if (!mounted) return;
      msg.showSnackBar(SnackBar(
        content: Text(
          hasDebt
              ? _tr(
                  'Product imported – debt recorded in Payables',
                  'Bidhaa imeingizwa – deni limerekodiwa kwenye Madeni',
                )
              : _tr('Product imported successfully!', 'Bidhaa imeingizwa kwa mafanikio!'),
        ),
        backgroundColor: hasDebt ? AppColors.warning : AppColors.success,
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
                'Set your own cost and selling prices for this product.',
                'Weka bei yako ya kununua na kuuza kwa bidhaa hii.',
              ),
              style:
                  GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
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
                          'Quantity (${widget.product.unit})',
                          'Idadi (${widget.product.unit})',
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
                          widget.product.unit,
                          style: GoogleFonts.dmSans(
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
            const SizedBox(height: 24),

            // ── Section: Asili ya Stoo ────────────────────────────────────
            _SectionLabel(_tr('Stock Origin', 'Asili ya Stoo')),
            const SizedBox(height: 10),
            _OriginOption(
              value: 'existing',
              groupValue: _stockOrigin,
              label: _tr('Stock I already had', 'Stoki niliyo nayo'),
              subtitle: _tr(
                'This stock was already in my possession',
                'Stoki hii ilikuwepo kwangu tayari',
              ),
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.tealAccent,
              onChanged: (v) => setState(() => _stockOrigin = v!),
            ),
            const SizedBox(height: 8),
            _OriginOption(
              value: 'purchased',
              groupValue: _stockOrigin,
              label: _tr('I purchased it', 'Nimenunua'),
              subtitle: _tr(
                'I bought this stock from a supplier',
                'Nilinunua stoo hii kutoka kwa muuzaji',
              ),
              icon: Icons.shopping_cart_outlined,
              iconColor: AppColors.navyPrimary,
              onChanged: (v) => setState(() {
                _stockOrigin = v!;
                // default to paid when first switching to purchased
                _paymentStatus = 'paid';
              }),
            ),

            // ── Payment status (shown only when purchased) ────────────────
            if (_stockOrigin == 'purchased') ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _paymentStatus == 'unpaid'
                      ? AppColors.error.withValues(alpha: 0.05)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _paymentStatus == 'unpaid'
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Text(
                        _tr('Payment Status', 'Hali ya Malipo'),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ),
                    _PaymentOption(
                      value: 'paid',
                      groupValue: _paymentStatus,
                      label: _tr('Already paid in full', 'Nimelipia'),
                      subtitle: _tr(
                        'Payment completed at time of purchase',
                        'Nililipa kikamilifu wakati wa ununuzi',
                      ),
                      color: AppColors.success,
                      onChanged: (v) =>
                          setState(() => _paymentStatus = v!),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14,
                        color: Color(0xFFE2E8F0)),
                    _PaymentOption(
                      value: 'partial',
                      groupValue: _paymentStatus,
                      label: _tr('Partially paid', 'Nimelipa kiasi'),
                      subtitle: _tr(
                        'I paid some – remaining balance is a debt',
                        'Nililipa kiasi – baki ni deni',
                      ),
                      color: AppColors.warning,
                      onChanged: (v) => setState(() {
                        _paymentStatus = v!;
                        _amountPaidCtrl.text = '0';
                      }),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14,
                        color: Color(0xFFE2E8F0)),
                    _PaymentOption(
                      value: 'unpaid',
                      groupValue: _paymentStatus,
                      label: _tr('Not paid at all', 'Sijalipia'),
                      subtitle: _tr(
                        'Full amount is owed – record as payable debt',
                        'Deni la jumla – rekodia kama deni la kulipa',
                      ),
                      color: AppColors.error,
                      onChanged: (v) =>
                          setState(() => _paymentStatus = v!),
                    ),

                    // Supplier + amount fields (shown when partial or unpaid)
                    if (_paymentStatus == 'partial' ||
                        _paymentStatus == 'unpaid') ...[
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _supplierNameCtrl,
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: AppColors.navyPrimary),
                              decoration: InputDecoration(
                                labelText: _tr(
                                    'Supplier Name (Optional)',
                                    'Jina la Muuzaji (Hiari)'),
                                prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _supplierPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: AppColors.navyPrimary),
                              decoration: InputDecoration(
                                labelText: _tr(
                                    'Supplier Phone (Optional)',
                                    'Simu ya Muuzaji (Hiari)'),
                                prefixIcon: const Icon(
                                    Icons.phone_outlined, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            // Amount paid field (partial only)
                            if (_paymentStatus == 'partial') ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _amountPaidCtrl,
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]')),
                                ],
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: AppColors.navyPrimary,
                                    fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: _tr(
                                    'Amount already paid (TZS)',
                                    'Kiasi ulicholipa tayari (TZS)',
                                  ),
                                  prefixIcon: const Icon(
                                      Icons.payments_outlined, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],

                            // Debt summary
                            if (_costVal > 0 && _stockVal > 0) ...[
                              const SizedBox(height: 10),
                              Builder(builder: (_) {
                                final total = _costVal * _stockVal;
                                final paid = _paymentStatus == 'partial'
                                    ? (double.tryParse(
                                            _amountPaidCtrl.text
                                                .replaceAll(
                                                    RegExp(r'[^0-9.]'),
                                                    '')) ??
                                        0)
                                    : 0.0;
                                final debt =
                                    (total - paid).clamp(0.0, total);
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.error
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_paymentStatus == 'partial')
                                        Text(
                                          _tr(
                                            'Total: TZS ${total.toStringAsFixed(0)}  |  Paid: TZS ${paid.toStringAsFixed(0)}',
                                            'Jumla: TZS ${total.toStringAsFixed(0)}  |  Ulicholipa: TZS ${paid.toStringAsFixed(0)}',
                                          ),
                                          style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              color: AppColors.textMuted),
                                        ),
                                      if (_paymentStatus == 'partial')
                                        const SizedBox(height: 4),
                                      Text(
                                        _tr(
                                          'Debt to record: TZS ${debt.toStringAsFixed(0)}',
                                          'Deni la kurekodi: TZS ${debt.toStringAsFixed(0)}',
                                        ),
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.error),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

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
                            style: GoogleFonts.dmSans(
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
              style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.productName,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.productNameSw.isNotEmpty &&
                    product.productNameSw != product.productName)
                  Text(
                    product.productNameSw,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (product.genericName.isNotEmpty)
                  Text(
                    product.genericName,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (product.brandNames.isNotEmpty)
                  Text(
                    product.brandNames.take(3).join(', '),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      style: GoogleFonts.dmSans(
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
      style: GoogleFonts.dmSans(
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
      style: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppColors.navyPrimary,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF94A3B8)),
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
      style: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppColors.navyPrimary,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF94A3B8)),
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

class _OriginOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<String?> onChanged;

  const _OriginOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? iconColor.withValues(alpha: 0.07)
              : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? iconColor : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? iconColor.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 20,
                  color: selected ? iconColor : AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? iconColor : AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: iconColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final String subtitle;
  final Color color;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : AppColors.navyPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textMuted),
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
            style: GoogleFonts.dmSans(
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
