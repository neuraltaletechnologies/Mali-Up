import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/barcode_scanner_screen.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/validation_banner.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/domain/models/debt.dart';
import '../../../finance/data/payment_account_service.dart';
import '../../../finance/domain/models/cash_account.dart';
import '../../../finance/domain/payment_method_accounts.dart';
import '../../../finance/presentation/widgets/activate_account_sheet.dart';
import '../../../finance/presentation/widgets/payment_account_chips.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../inventory/presentation/widgets/category_picker_sheet.dart';
import '../../domain/models/master_category.dart';
import '../../domain/models/master_product.dart';
import '../../providers/master_catalog_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

enum _ErrorField { name, cost, sell, payment, general }

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

  // Kategoria: null = tumia kategoria ya bidhaa asili kutoka katalogi kuu;
  // ikichaguliwa, hii inabatilisha kategoria wakati wa kuingiza.
  MasterCategory? _categoryOverride;

  // Asili ya Stoo: 'existing' = stoki niliyo nayo, 'purchased' = nimenunua
  String _stockOrigin = 'purchased';
  // Malipo: 'paid' = nimelipia kikamilifu, 'partial' = nimelipa kiasi
  // (kiasi cha 0 kinamaanisha sijalipia kabisa).
  String _paymentStatus = 'paid';
  CashAccount? _selectedAccount;

  final _supplierNameCtrl = TextEditingController();
  final _supplierPhoneCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController(text: '0');

  String? _errorMsg;
  _ErrorField _errorField = _ErrorField.general;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p.productName);
    _costCtrl = TextEditingController();
    _sellCtrl = TextEditingController();
    _stockCtrl = TextEditingController(text: '1');
    _skuCtrl = TextEditingController(
      text: p.commonBarcodes.isNotEmpty ? p.commonBarcodes.first : '',
    );
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
  double get _purchaseTotal => _costVal * _stockVal;

  double get _margin => _sellVal > 0 && _costVal > 0
      ? ((_sellVal - _costVal) / _sellVal) * 100
      : 0;

  bool get _isPurchased => _stockOrigin == 'purchased';

  /// Finds the [MasterCategory] whose slug matches this product's original
  /// catalog category, so the picker starts pre-selected on the right one.
  MasterCategory? _matchingCategory(List<MasterCategory> categories) {
    for (final c in categories) {
      if (c.categorySlug == widget.product.categorySlug) return c;
    }
    return null;
  }

  /// The category to save with — the user's override if they picked one
  /// (including a brand-new custom category), otherwise the product's
  /// original catalog category.
  ({String slug, String name}) _resolveCategory(List<MasterCategory> categories) {
    final category = _categoryOverride ?? _matchingCategory(categories);
    if (category != null) {
      return (slug: category.categorySlug, name: category.displayName);
    }
    return (slug: widget.product.categorySlug, name: widget.product.categorySlug);
  }

  Future<void> _scanSku() async {
    final scanned = await BarcodeScannerScreen.show(
      context,
      title: _tr('Scan Barcode', 'Skani Nambari'),
    );
    if (scanned == null || scanned.isEmpty || !mounted) return;
    setState(() => _skuCtrl.text = scanned);
  }

  Future<void> _showActivateAccountSheet(PaymentMethodSpec spec) async {
    final result = await showAppSheet<bool>(
      context,
      builder: (_) => ActivateAccountSheet(spec: spec),
    );
    if (result == true && mounted) {
      _showError(
        _tr(
          '${spec.nameFor(LocalizationService.isSwahili ? 'sw' : 'en')} activated',
          '${spec.nameFor(LocalizationService.isSwahili ? 'sw' : 'en')} imewashwa',
        ),
        _ErrorField.payment,
      );
    }
  }

  Future<void> _import() async {
    if (_errorMsg != null) setState(() => _errorMsg = null);

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError(_tr('Enter product name', 'Ingiza jina la bidhaa'), _ErrorField.name);
      return;
    }
    if (_costVal <= 0) {
      _showError(_tr('Enter a cost price', 'Ingiza bei ya kununua'), _ErrorField.cost);
      return;
    }
    if (_sellVal <= 0) {
      _showError(_tr('Enter a selling price', 'Ingiza bei ya kuuza'), _ErrorField.sell);
      return;
    }

    // How much money actually leaves an account right now.
    double amountPaid = 0;
    if (_isPurchased && _purchaseTotal > 0) {
      if (_paymentStatus == 'paid') {
        amountPaid = _purchaseTotal;
      } else {
        final entered = double.tryParse(
                _amountPaidCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
        amountPaid = entered.clamp(0.0, _purchaseTotal);
      }
      // Money paid now must land in a chosen, activated payment account —
      // PaymentAccountChips only lets an activated built-in or custom
      // account become selected.
      if (amountPaid > 0 && _selectedAccount == null) {
        _showError(
          _tr('Select a payment account', 'Chagua akaunti ya malipo'),
          _ErrorField.payment,
        );
        return;
      }
    }

    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);
    try {
      final now = DateTime.now().toIso8601String();
      final categories =
          ref.read(masterCategoriesProvider).valueOrNull ?? const <MasterCategory>[];
      final resolvedCategory = _resolveCategory(categories);
      final item = InventoryItem(
        id: '',
        name: name,
        category: resolvedCategory.slug,
        categoryName: resolvedCategory.name,
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

      final user = FirebaseAuth.instance.currentUser;
      final debtAmount =
          _isPurchased ? (_purchaseTotal - amountPaid).clamp(0.0, _purchaseTotal) : 0.0;
      final hasDebt = debtAmount > 0;

      // Money paid now leaves the chosen account — Drift balance moves
      // instantly, the queued op replays on Firestore idempotently.
      if (_isPurchased && amountPaid > 0 && _selectedAccount != null) {
        await moveMoneyForAccount(
          ref,
          accountId: _selectedAccount!.id,
          amount: amountPaid,
          isDeposit: false,
          description: _tr('Purchase: $name', 'Ununuzi: $name'),
          reference: _skuCtrl.text.trim(),
          createdBy: user?.uid ?? '',
        );
      }

      // Create payable debt for whatever remains unpaid.
      if (hasDebt) {
        final dueDate = DateTime.now().add(const Duration(days: 30));
        final dueDateStr =
            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
        await ref.read(debtRepositoryProvider).save(Debt(
              id: '',
              partyName: _supplierNameCtrl.text.trim(),
              partyPhone: _supplierPhoneCtrl.text.trim(),
              type: 'payable',
              originalAmount: _purchaseTotal,
              paidAmount: amountPaid,
              dueDate: dueDateStr,
              note: _tr('Purchase: $name', 'Ununuzi: $name'),
              createdBy: user?.uid ?? '',
              createdAt: DateTime.now().toIso8601String(),
            ));
      }

      unawaited(ref.read(syncServiceProvider).syncNow());

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
        _showError(
          _tr('Failed to import product', 'Imeshindikana kuingiza bidhaa'),
          _ErrorField.general,
        );
      }
    }
  }

  void _showError(String message, _ErrorField field) => setState(() {
        _errorMsg = message;
        _errorField = field;
      });

  Widget _banner(_ErrorField field) => ValidationBanner(
        message: _errorField == field ? _errorMsg : null,
        onDismiss: () => setState(() => _errorMsg = null),
      );

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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Import Product', 'Ingiza Bidhaa'),
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
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
              padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Product name ──────────────────────────────────────────
                  _FieldLabel(_tr('Product Name', 'Jina la Bidhaa')),
                  const SizedBox(height: 6),
                  _TextField(
                    controller: _nameCtrl,
                    hint: _tr('Enter product name', 'Ingiza jina la bidhaa'),
                  ),
                  _banner(_ErrorField.name),
                  const SizedBox(height: 14),

                  // ── SKU / barcode ────────────────────────────────────────
                  _FieldLabel(_tr('SKU / Barcode (Optional)', 'SKU / Barcode (Hiari)')),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TextField(
                          controller: _skuCtrl,
                          hint: _tr('Scan or enter manually', 'Skani au ingiza mwenyewe'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _scanSku,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: AppColors.tealAccent),
                            foregroundColor: AppColors.tealAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, size: 21),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Category ─────────────────────────────────────────────
                  _FieldLabel(_tr('Category', 'Kategoria')),
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    final categoriesAsync = ref.watch(masterCategoriesProvider);
                    final categories =
                        categoriesAsync.valueOrNull ?? const <MasterCategory>[];
                    final selected = _categoryOverride ?? _matchingCategory(categories);
                    return _CategoryField(
                      label: selected?.displayName ?? widget.product.categorySlug,
                      loading: categoriesAsync.isLoading,
                      onTap: () async {
                        final result = await showCategoryPicker(
                          context: context,
                          categories: categories,
                          selected: selected,
                        );
                        if (result != null) {
                          setState(() => _categoryOverride = result);
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 20),

                  // ── Pricing ──────────────────────────────────────────────
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
                              onChanged: (_) => setState(() {
                                if (_errorField == _ErrorField.cost) _errorMsg = null;
                              }),
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
                              onChanged: (_) => setState(() {
                                if (_errorField == _ErrorField.sell) _errorMsg = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _banner(_ErrorField.cost),
                  _banner(_ErrorField.sell),
                  if (_sellVal > 0 && _costVal > 0) ...[
                    const SizedBox(height: 10),
                    _MarginBadge(margin: _margin),
                  ],
                  const SizedBox(height: 20),

                  // ── Stock ────────────────────────────────────────────────
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
                  const SizedBox(height: 20),

                  // ── Stock origin ─────────────────────────────────────────
                  _FieldLabel(_tr('Stock Origin', 'Asili ya Stoo')),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _SegButton(
                          label: _tr('Already had', 'Niliyo nayo'),
                          icon: Icons.inventory_2_outlined,
                          active: _stockOrigin == 'existing',
                          activeColor: AppColors.tealAccent,
                          onTap: () => setState(() => _stockOrigin = 'existing'),
                        ),
                        const SizedBox(width: 4),
                        _SegButton(
                          label: _tr('Purchased', 'Nimenunua'),
                          icon: Icons.shopping_cart_outlined,
                          active: _stockOrigin == 'purchased',
                          activeColor: AppColors.navyPrimary,
                          onTap: () => setState(() {
                            _stockOrigin = 'purchased';
                            _paymentStatus = 'paid';
                          }),
                        ),
                      ],
                    ),
                  ),

                  // ── Payment (shown only when purchased) ─────────────────
                  if (_isPurchased) ...[
                    const SizedBox(height: 20),
                    _FieldLabel(_tr('Payment Status', 'Hali ya Malipo')),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _SegButton(
                            label: _tr('Paid in full', 'Nimelipia'),
                            icon: Icons.check_circle_outline_rounded,
                            active: _paymentStatus == 'paid',
                            activeColor: AppColors.success,
                            onTap: () => setState(() => _paymentStatus = 'paid'),
                          ),
                          const SizedBox(width: 4),
                          _SegButton(
                            label: _tr('Partially paid', 'Nimelipa kiasi'),
                            icon: Icons.timelapse_rounded,
                            active: _paymentStatus == 'partial',
                            activeColor: AppColors.warning,
                            onTap: () => setState(() {
                              _paymentStatus = 'partial';
                              _amountPaidCtrl.text = '0';
                            }),
                          ),
                        ],
                      ),
                    ),

                    if (_paymentStatus == 'partial') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountPaidCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.navyPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: _tr(
                            // A 0 here just means nothing has been paid yet.
                            'Amount paid now (0 = not paid at all)',
                            'Kiasi ulicholipa sasa (0 = sijalipia kabisa)',
                          ),
                          prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _supplierNameCtrl,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.navyPrimary),
                        decoration: InputDecoration(
                          labelText:
                              _tr('Supplier Name (Optional)', 'Jina la Muuzaji (Hiari)'),
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
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
                            fontSize: 14, color: AppColors.navyPrimary),
                        decoration: InputDecoration(
                          labelText:
                              _tr('Supplier Phone (Optional)', 'Simu ya Muuzaji (Hiari)'),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      if (_purchaseTotal > 0) ...[
                        const SizedBox(height: 10),
                        _DebtSummary(
                          total: _purchaseTotal,
                          paid: (double.tryParse(_amountPaidCtrl.text
                                      .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                                  0)
                              .clamp(0.0, _purchaseTotal),
                        ),
                      ],
                    ],

                    // Money leaving now (full or partial) needs an account.
                    if (_paymentStatus == 'paid' || _paymentStatus == 'partial') ...[
                      const SizedBox(height: 16),
                      _FieldLabel(_tr('Payment Method', 'Njia ya Malipo')),
                      const SizedBox(height: 8),
                      PaymentAccountChips(
                        selectedAccountId: _selectedAccount?.id,
                        onSelectAccount: (account) => setState(() {
                          _selectedAccount = account;
                          if (_errorField == _ErrorField.payment) _errorMsg = null;
                        }),
                        onActivationRequired: (message) =>
                            _showError(message, _ErrorField.payment),
                        onActivateMethod: (spec) => _showActivateAccountSheet(spec),
                      ),
                      _banner(_ErrorField.payment),
                    ],
                  ],

                  const SizedBox(height: 24),
                  _banner(_ErrorField.general),

                  // ── Import button ────────────────────────────────────────
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.download_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _tr('Import to My Inventory', 'Ingiza kwenye Stoo Yangu'),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

// ── Reusable small widgets ────────────────────────────────────────────────────

class _SegButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _SegButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
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

class _CategoryField extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _CategoryField({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
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

class _DebtSummary extends StatelessWidget {
  final double total;
  final double paid;
  const _DebtSummary({required this.total, required this.paid});

  @override
  Widget build(BuildContext context) {
    final debt = (total - paid).clamp(0.0, total);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(
              'Total: TZS ${total.toStringAsFixed(0)}  |  Paid: TZS ${paid.toStringAsFixed(0)}',
              'Jumla: TZS ${total.toStringAsFixed(0)}  |  Ulicholipa: TZS ${paid.toStringAsFixed(0)}',
            ),
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            _tr(
              'Debt to record: TZS ${debt.toStringAsFixed(0)}',
              'Deni la kurekodi: TZS ${debt.toStringAsFixed(0)}',
            ),
            style: GoogleFonts.jetBrainsMono(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
