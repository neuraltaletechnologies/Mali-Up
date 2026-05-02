import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
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
          try {
            final inventory =
                ref.read(inventoryItemListProvider).value ?? const [];
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _QuickSaleSheet(inventory: inventory),
            ).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${error.toString()}')),
              );
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error opening sales form: ${e.toString()}')),
            );
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tr('Sale', 'Uza'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 4,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Sales', 'Mauzo'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
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
                    .where((i) => readInvoiceStatus(i).toLowerCase() == 'paid')
                    .toList();
                final pending = items
                    .where((i) => readInvoiceStatus(i).toLowerCase() != 'paid')
                    .toList();
                final totalSales = items.fold<double>(
                  0,
                  (s, i) => s + parseNumericAmount(i['amount']),
                );
                final paidSales = paid.fold<double>(
                  0,
                  (s, i) => s + parseNumericAmount(i['amount']),
                );
                final pendingSales = pending.fold<double>(
                  0,
                  (s, i) => s + parseNumericAmount(i['amount']),
                );

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _OverviewStat(
                            label: _tr('Total', 'Jumla'),
                            value: _fmtAmount(totalSales),
                            color: AppColors.primaryLight,
                            compact: true,
                          ),
                          _OverviewStat(
                            label: _tr('Pending', 'Inasubiri'),
                            value: _fmtAmount(pendingSales),
                            color: AppColors.secondary,
                            compact: true,
                          ),
                          _OverviewStat(
                            label: _tr('Paid', 'Imelipwa'),
                            value: _fmtAmount(paidSales),
                            color: AppColors.success,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? const _EmptySalesState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                8,
                                24,
                                104,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final status = readInvoiceStatus(item);
                                final amount = parseNumericAmount(
                                  item['amount'],
                                );
                                final id =
                                    (item['invoiceNumber'] ?? item['id'] ?? '')
                                        .toString();
                                final customer =
                                    (item['customerName'] ??
                                            item['customer'] ??
                                            item['partyName'] ??
                                            _tr(
                                              'Unknown customer',
                                              'Mteja hajulikani',
                                            ))
                                        .toString();
                                final date = readTimestamp(
                                  item['createdAt'] ?? item['date'],
                                );
                                return _InvoiceListItem(
                                  id: id.isEmpty ? '#${index + 1}' : '#$id',
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
            _tr('Tap + Sale to get started', 'Bonyeza + Rekodi Mauzo kuanza'),
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
    final text = _priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
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
      final itemName =
          ((_selectedItem!['name'] ?? _selectedItem!['productName'] ?? '')
              as String);
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
          final name = ((item['name'] ?? item['productName'] ?? '') as String)
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
    final name = (item['name'] ?? item['productName'] ?? '') as String;
    final price = parseUnitPrice(
      item['unitPrice'] ?? item['price'] ?? item['unit_price'],
    );
    _productFocus.unfocus();
    setState(() {
      _selectedItem = item;
      _productController.text = name;
      _priceController.text = price > 0 ? price.toStringAsFixed(0) : '';
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _showAddProductSheet(BuildContext context) {
    final productName = _productController.text.trim();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProductSheet(
        initialProductName: productName,
        onProductAdded: (product) {
          setState(() {
            _selectedItem = product;
            _productController.text =
                (product['name'] ?? product['productName'] ?? '') as String;
            _priceController.text =
                parseUnitPrice(product['unitPrice'] ?? product['price'] ?? 0)
                    .toStringAsFixed(0);
            _suggestions = [];
            _showSuggestions = false;
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    final productName = _productController.text.trim();
    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('Enter a product name.', 'Ingiza jina la bidhaa.')),
        ),
      );
      return;
    }
    if (_unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('Enter a valid price.', 'Ingiza bei sahihi.')),
        ),
      );
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
              'inventoryItemId': (_selectedItem!['id'] as String?) ?? '',
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Decrement stock if sale was for an inventory item
      if (_selectedItem != null) {
        final itemId = (_selectedItem!['id'] as String?)?.trim() ?? '';
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(_tr('Sale recorded!', 'Mauzo yamerekodiwa!')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Failed to save. Try again.',
              'Imeshindikana kuhifadhi. Jaribu tena.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
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
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isCash
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _isCash
                          ? _tr('Cash · Paid', 'Taslimu · Imelipwa')
                          : _tr('Credit · Pending', 'Mkopo · Inasubiri'),
                      style: TextStyle(
                        color: _isCash ? AppColors.success : AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _productController,
                focusNode: _productFocus,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _tr('Product / Item *', 'Bidhaa / Kitu *'),
                  hintText: _tr(
                    'Search inventory or type new...',
                    'Tafuta hisa au andika mpya...',
                  ),
                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                  suffixIcon: _selectedItem != null
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        )
                      : (_productController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
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
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
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
                    children: _suggestions.asMap().entries.map((entry) {
                      final isLast = entry.key == _suggestions.length - 1;
                      final item = entry.value;
                      final name = (item['name'] ?? item['productName'] ?? '') as String;
                      final price = parseUnitPrice(
                        item['unitPrice'] ?? item['price'] ?? item['unit_price'],
                      );
                      final stock = parseStock(
                        item['currentStock'] ?? item['stock'] ?? item['quantity'],
                      );

                      return Column(
                        children: [
                          InkWell(
                            onTap: () => _selectInventoryItem(item),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        Text(
                                          'TSh ${price.toStringAsFixed(0)} · $stock ${_tr('in stock', 'stokuni')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.north_west_rounded,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: AppColors.border,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (_productController.text.isNotEmpty && _selectedItem == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showAddProductSheet(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _tr(
                                  'Add "${_productController.text}"',
                                  'Ongeza "${_productController.text}"',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _tr('Unit Price (TSh) *', 'Bei ya Kitengo *'),
                        prefixIcon: const Icon(Icons.payments_outlined, size: 20),
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
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyButton(
                              icon: Icons.remove_rounded,
                              onTap: _qty > 1 ? () => setState(() => _qty--) : null,
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
                              onTap: () => setState(() => _qty++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _customerController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _tr('Customer (optional)', 'Mteja (si lazima)'),
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
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
                        onTap: () => setState(() => _isCash = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: _isCash ? AppColors.success : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                size: 15,
                                color: _isCash ? Colors.white : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _tr('Cash  ·  Paid', 'Taslimu · Imelipwa'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _isCash ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isCash = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: !_isCash ? AppColors.warning : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 15,
                                color: !_isCash ? Colors.white : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _tr('Credit  ·  Pending', 'Mkopo · Inasubiri'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: !_isCash ? Colors.white : AppColors.textMuted,
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
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
            color: onTap != null ? AppColors.secondary : AppColors.border,
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
  final bool compact;

  const _OverviewStat({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }
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
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.article_outlined, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      id,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  customer,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

// ── Add Product Bottom Sheet ─────────────────────────────────────────────────

class _AddProductSheet extends ConsumerStatefulWidget {
  final String initialProductName;
  final Function(Map<String, dynamic>) onProductAdded;

  const _AddProductSheet({
    required this.initialProductName,
    required this.onProductAdded,
  });

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProductName);
    _priceController = TextEditingController();
    _categoryController = TextEditingController();
    _stockController = TextEditingController(text: '1');
    _skuController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final priceText =
        _priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final price = double.tryParse(priceText) ?? 0;
    final category = _categoryController.text.trim();
    final stockText = _stockController.text.trim();
    final stock = int.tryParse(stockText) ?? 1;
    final sku = _skuController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('Enter product name', 'Ingiza jina la bidhaa')),
        ),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('Enter a valid price', 'Ingiza bei sahihi')),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repository = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repository.resolveContextForUser(user.uid);

      final inventoryRef = repository.scopeCollection(
        uid: user.uid,
        context: ctx,
        childCollection: 'inventory_items',
      );

      final docRef = await inventoryRef.add({
        'name': name,
        'productName': name,
        'unitPrice': price,
        'price': price,
        'category': category.isNotEmpty ? category : 'General',
        'currentStock': stock,
        'stock': stock,
        'quantity': stock,
        if (sku.isNotEmpty) 'sku': sku,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final newProduct = {
        'id': docRef.id,
        'name': name,
        'productName': name,
        'unitPrice': price,
        'price': price,
        'category': category.isNotEmpty ? category : 'General',
        'currentStock': stock,
        'stock': stock,
        'quantity': stock,
        if (sku.isNotEmpty) 'sku': sku,
      };

      if (mounted) {
        Navigator.pop(context);
        widget.onProductAdded(newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr('Product added!', 'Bidhaa imeongezwa!'),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('Failed to add product', 'Imeshindikana kuongeza bidhaa'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
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
        child: SizedBox(
          width: double.infinity,
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

              // Title
              Text(
                _tr('Add New Product', 'Ongeza Bidhaa Mpya'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),

              // Product Name
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _tr('Product Name *', 'Jina la Bidhaa *'),
                  hintText: _tr('Enter product name', 'Ingiza jina la bidhaa'),
                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Unit Price
              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: _tr('Unit Price (TSh) *', 'Bei Kwa Kitengo (TSh) *'),
                  hintText: _tr('Enter unit price', 'Ingiza bei kwa kitengo'),
                  prefixIcon: const Icon(Icons.sell_outlined, size: 20),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Category & Stock (Row)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText:
                            _tr('Category', 'Kategoria'),
                        hintText: _tr('e.g. Electronics', 'v.g. Elektroniki'),
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: _tr('Stock', 'Stoku'),
                        hintText: '1',
                        prefixIcon:
                            const Icon(Icons.inventory_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // SKU (Optional)
              TextField(
                controller: _skuController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: _tr('SKU (Optional)', 'SKU (Hiari)'),
                  hintText: _tr('e.g. PROD-001', 'v.g. PROD-001'),
                  prefixIcon: const Icon(Icons.tag_outlined, size: 20),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.secondary,
                            ),
                          ),
                        )
                      : Text(
                          _tr('Add Product', 'Ongeza Bidhaa'),
                          style: const TextStyle(
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
    );
  }
}
