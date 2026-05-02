import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/page_intro_header.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../data/sales_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesInvoiceListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final inventory =
              ref.read(inventoryItemListProvider).value ?? const [];
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _QuickSaleSheet(inventory: inventory),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tr('Record Sale', 'Rekodi Mauzo'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 4,
      ),
      body: Column(
        children: [
          PageIntroHeader(
            title: _tr('Track sales momentum', 'Fuatilia kasi ya mauzo'),
            subtitle: _tr(
              'Monitor invoices, pending collections, and paid revenue in one place.',
              'Fuatilia ankara, makusanyo yanayosubiri, na mapato yaliyolipwa sehemu moja.',
            ),
            scene: EmotionalLottieScene.dashboard,
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: SkeletonList(),
              ),
              error: (_, _) => Center(
                child: Text(
                  _tr(
                    'Unable to load sales right now.',
                    'Imeshindikana kupakia mauzo kwa sasa.',
                  ),
                ),
              ),
              data: (items) {
                final paid = items
                    .where((i) =>
                        readInvoiceStatus(i).toLowerCase() == 'paid')
                    .toList();
                final pending = items
                    .where((i) =>
                        readInvoiceStatus(i).toLowerCase() != 'paid')
                    .toList();
                final totalSales = items.fold<double>(
                    0, (s, i) => s + parseNumericAmount(i['amount']));
                final paidSales = paid.fold<double>(
                    0, (s, i) => s + parseNumericAmount(i['amount']));
                final pendingSales = pending.fold<double>(
                    0, (s, i) => s + parseNumericAmount(i['amount']));

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _OverviewStat(
                            label: _tr('Total Sales', 'Jumla ya Mauzo'),
                            value: _fmtAmount(totalSales),
                            color: AppColors.primaryLight,
                          ),
                          _OverviewStat(
                            label: _tr('Pending', 'Inasubiri'),
                            value: _fmtAmount(pendingSales),
                            color: AppColors.secondary,
                          ),
                          _OverviewStat(
                            label: _tr('Paid', 'Imelipwa'),
                            value: _fmtAmount(paidSales),
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: items.isEmpty
                          ? const _EmptySalesState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  24, 8, 24, 104),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final status = readInvoiceStatus(item);
                                final amount =
                                    parseNumericAmount(item['amount']);
                                final id =
                                    (item['invoiceNumber'] ??
                                            item['id'] ??
                                            '')
                                        .toString();
                                final customer = (item['customerName'] ??
                                        item['customer'] ??
                                        item['partyName'] ??
                                        _tr('Unknown customer',
                                            'Mteja hajulikani'))
                                    .toString();
                                final date = readTimestamp(
                                    item['createdAt'] ?? item['date']);
                                return _InvoiceListItem(
                                  id: id.isEmpty
                                      ? '#${index + 1}'
                                      : '#$id',
                                  customer: customer,
                                  amount: _fmtAmount(amount),
                                  status: status,
                                  date: _fmtDate(date),
                                );
                              },
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

  static String _fmtAmount(double amount) {
    if (amount >= 1_000_000) {
      return 'TSh ${(amount / 1_000_000).toStringAsFixed(1)}M';
    }
    if (amount >= 1_000) {
      return 'TSh ${(amount / 1_000).toStringAsFixed(0)}K';
    }
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  static String _fmtDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptySalesState extends StatelessWidget {
  const _EmptySalesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _tr('No sales recorded yet', 'Bado hakuna mauzo yaliyorekodiwa'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tr(
              'Tap + Record Sale to get started',
              'Bonyeza + Rekodi Mauzo kuanza',
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Quick sale bottom sheet ──────────────────────────────────────────────────

class _QuickSaleSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> inventory;

  const _QuickSaleSheet({required this.inventory});

  @override
  ConsumerState<_QuickSaleSheet> createState() => _QuickSaleSheetState();
}

class _QuickSaleSheetState extends ConsumerState<_QuickSaleSheet> {
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _customerController = TextEditingController();
  final _productFocus = FocusNode();

  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic>? _selectedItem;
  int _qty = 1;
  bool _isCash = true;
  bool _isSaving = false;
  bool _showSuggestions = false;

  double get _unitPrice {
    final text =
        _priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(text) ?? 0;
  }

  double get _total => _unitPrice * _qty;

  @override
  void initState() {
    super.initState();
    _productController.addListener(_onProductChanged);
  }

  @override
  void dispose() {
    _productController.removeListener(_onProductChanged);
    _productController.dispose();
    _priceController.dispose();
    _customerController.dispose();
    _productFocus.dispose();
    super.dispose();
  }

  void _onProductChanged() {
    final query = _productController.text.trim();

    // Deselect inventory item if user changed the name
    if (_selectedItem != null) {
      final itemName = ((_selectedItem!['name'] ??
              _selectedItem!['productName'] ??
              '') as String);
      if (query.toLowerCase() != itemName.toLowerCase()) {
        _selectedItem = null;
      }
    }

    if (query.isEmpty || _selectedItem != null) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final matched = widget.inventory
        .where((item) {
          final name = ((item['name'] ?? item['productName'] ?? '')
                  as String)
              .toLowerCase();
          return name.contains(query.toLowerCase());
        })
        .take(5)
        .toList();

    setState(() {
      _suggestions = matched;
      _showSuggestions = matched.isNotEmpty;
    });
  }

  void _selectInventoryItem(Map<String, dynamic> item) {
    final name =
        (item['name'] ?? item['productName'] ?? '') as String;
    final price = parseUnitPrice(
        item['unitPrice'] ?? item['price'] ?? item['unit_price']);
    _productFocus.unfocus();
    setState(() {
      _selectedItem = item;
      _productController.text = name;
      _priceController.text =
          price > 0 ? price.toStringAsFixed(0) : '';
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  Future<void> _save() async {
    final productName = _productController.text.trim();
    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _tr('Enter a product name.', 'Ingiza jina la bidhaa.')),
      ));
      return;
    }
    if (_unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _tr('Enter a valid price.', 'Ingiza bei sahihi.')),
      ));
      return;
    }

    setState(() => _isSaving = true);

    // Capture refs before async gap to avoid context-after-pop issues
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repository = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repository.resolveContextForUser(user.uid);

      final invoicesRef = repository.scopeCollection(
        uid: user.uid,
        context: ctx,
        childCollection: 'sales_invoices',
      );

      final now = DateTime.now();
      final invoiceNumber =
          'INV-${now.millisecondsSinceEpoch.toString().substring(6)}';
      final customerName = _customerController.text.trim();

      await invoicesRef.add({
        'invoiceNumber': invoiceNumber,
        if (customerName.isNotEmpty) 'customerName': customerName,
        'amount': _total,
        'status': _isCash ? 'Paid' : 'Pending',
        'paymentMethod': _isCash ? 'cash' : 'credit',
        'items': [
          {
            'name': productName,
            'qty': _qty,
            'unitPrice': _unitPrice,
            'total': _total,
            if (_selectedItem != null)
              'inventoryItemId':
                  (_selectedItem!['id'] as String?) ?? '',
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Decrement stock if sale was for an inventory item
      if (_selectedItem != null) {
        final itemId =
            (_selectedItem!['id'] as String?)?.trim() ?? '';
        if (itemId.isNotEmpty) {
          final inventoryRef = repository.scopeCollection(
            uid: user.uid,
            context: ctx,
            childCollection: 'inventory_items',
          );
          try {
            await inventoryRef.doc(itemId).update({
              'currentStock': FieldValue.increment(-_qty),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {
            // Stock update is best-effort; don't fail the sale
          }
        }
      }

      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_tr('Sale recorded!', 'Mauzo yamerekodiwa!')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(
        content: Text(_tr(
          'Failed to save. Try again.',
          'Imeshindikana kuhifadhi. Jaribu tena.',
        )),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // Title + status pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Record a Sale', 'Rekodi Mauzo'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isCash
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _isCash
                        ? _tr('Cash · Paid', 'Taslimu · Imelipwa')
                        : _tr('Credit · Pending',
                            'Mkopo · Inasubiri'),
                    style: TextStyle(
                      color: _isCash
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Product search ──────────────────────────────────────
            TextField(
              controller: _productController,
              focusNode: _productFocus,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText:
                    _tr('Product / Item *', 'Bidhaa / Kitu *'),
                hintText: _tr(
                  'Search inventory or type new...',
                  'Tafuta hisa au andika mpya...',
                ),
                prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    size: 20),
                suffixIcon: _selectedItem != null
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20)
                    : (_productController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                                Icons.clear_rounded,
                                size: 18),
                            onPressed: () {
                              _productController.clear();
                              setState(() {
                                _selectedItem = null;
                                _suggestions = [];
                                _showSuggestions = false;
                              });
                            },
                          )
                        : null),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),

            // Inventory suggestions
            if (_showSuggestions && _suggestions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: _suggestions.asMap().entries.map((e) {
                    final isLast =
                        e.key == _suggestions.length - 1;
                    final item = e.value;
                    final name = (item['name'] ??
                            item['productName'] ??
                            '') as String;
                    final price = parseUnitPrice(
                        item['unitPrice'] ??
                            item['price'] ??
                            item['unit_price']);
                    final stock = parseStock(
                        item['currentStock'] ??
                            item['stock'] ??
                            item['quantity']);

                    return Column(
                      children: [
                        InkWell(
                          onTap: () =>
                              _selectInventoryItem(item),
                          borderRadius:
                              BorderRadius.circular(14),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(
                                            10),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .inventory_2_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        name,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors
                                              .secondary,
                                        ),
                                      ),
                                      Text(
                                        'TSh ${price.toStringAsFixed(0)} · '
                                        '$stock ${_tr('in stock', 'stokuni')}',
                                        style:
                                            const TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                    Icons.north_west_rounded,
                                    size: 14,
                                    color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: AppColors.border),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ── Price + Qty ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'))
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _tr(
                          'Unit Price (TSh) *',
                          'Bei ya Kitengo *'),
                      prefixIcon: const Icon(
                          Icons.payments_outlined,
                          size: 20),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2)),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      _tr('Qty', 'Idadi'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyButton(
                            icon: Icons.remove_rounded,
                            onTap: _qty > 1
                                ? () =>
                                    setState(() => _qty--)
                                : null,
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '$_qty',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          _QtyButton(
                            icon: Icons.add_rounded,
                            onTap: () =>
                                setState(() => _qty++),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Customer (optional) ─────────────────────────────────
            TextField(
              controller: _customerController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _tr(
                    'Customer (optional)', 'Mteja (si lazima)'),
                prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    size: 20),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 14),

            // ── Payment toggle ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isCash = true),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            vertical: 11),
                        decoration: BoxDecoration(
                          color: _isCash
                              ? AppColors.success
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 15,
                              color: _isCash
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tr('Cash  ·  Paid',
                                  'Taslimu · Imelipwa'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _isCash
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isCash = false),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            vertical: 11),
                        decoration: BoxDecoration(
                          color: !_isCash
                              ? AppColors.warning
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: !_isCash
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tr('Credit  ·  Pending',
                                  'Mkopo · Inasubiri'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: !_isCash
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Total + Save button ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('Total', 'Jumla'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        _fmtTotal(_total),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.secondary,
                            ),
                          )
                        : Text(
                            _tr('Save Sale', 'Hifadhi Mauzo'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTotal(double amount) {
    if (amount >= 1_000_000) {
      return 'TSh ${(amount / 1_000_000).toStringAsFixed(2)}M';
    }
    if (amount >= 1_000) {
      return 'TSh ${(amount / 1_000).toStringAsFixed(1)}K';
    }
    return 'TSh ${amount.toStringAsFixed(0)}';
  }
}

// ── Qty +/- button ───────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 46,
          child: Icon(
            icon,
            size: 18,
            color:
                onTap != null ? AppColors.secondary : AppColors.border,
          ),
        ),
      ),
    );
  }
}

// ── Invoice list card ────────────────────────────────────────────────────────

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewStat({
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final String id;
  final String customer;
  final String amount;
  final String status;
  final String date;

  const _InvoiceListItem({
    required this.id,
    required this.customer,
    required this.amount,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase();
    final statusColor = statusLower == 'paid'
        ? AppColors.success
        : statusLower == 'pending'
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.article_outlined,
                color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      id,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                    ),
                    Text(
                      date,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  customer,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
