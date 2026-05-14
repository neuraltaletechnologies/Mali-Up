import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../customer/domain/models/customer.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../data/sales_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

enum _PayStatus { paid, partial, unpaid }

// ── Sales Screen ─────────────────────────────────────────────────────────────

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  static Future<Map<String, String>> _loadReceiptMeta({
    required String uid,
    required String? businessId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    String businessName = 'Business';
    String printedBy = 'User';

    try {
      final userDoc = await firestore.collection('users').doc(uid).get(const GetOptions());
      final userData = userDoc.data();
      printedBy = ((userData?['displayName'] ?? userData?['name']) as String?)?.trim().isNotEmpty ==
              true
          ? ((userData?['displayName'] ?? userData?['name']) as String).trim()
          : 'User';

      final profileBusinesses = userData?['businesses'];
      if (profileBusinesses is List && businessId != null && businessId.isNotEmpty) {
        for (final raw in profileBusinesses) {
          if (raw is Map && (raw['id']?.toString().trim() ?? '') == businessId) {
            final fromProfile = (raw['name'] as String?)?.trim();
            if (fromProfile != null && fromProfile.isNotEmpty) {
              businessName = fromProfile;
              break;
            }
          }
        }
      }
    } catch (_) {}

    if (businessId != null && businessId.isNotEmpty && businessName == 'Business') {
      try {
        final businessDoc = await firestore
            .collection('tenants')
            .doc(uid)
            .collection('businesses')
            .doc(businessId)
            .get(const GetOptions());
        final data = businessDoc.data();
        final fromTenant = (data?['businessName'] as String?)?.trim();
        if (fromTenant != null && fromTenant.isNotEmpty) {
          businessName = fromTenant;
        }
      } catch (_) {}
    }

    return {
      'businessName': businessName,
      'printedBy': printedBy,
    };
  }

  static String _buildReceiptText({
    required Map<String, dynamic> sale,
    required String businessName,
    required String printedBy,
  }) {
    final invoiceNo = (sale['invoiceNumber'] ?? sale['id'] ?? '-').toString();
    final customer = (sale['customerName'] ?? _tr('Walk-in', 'Mteja wa kawaida')).toString();
    final createdAt = readTimestamp(sale['createdAt'] ?? sale['date']);
    final amount = parseNumericAmount(sale['amount']);
    final amountPaid = parseNumericAmount(sale['amountPaid']);
    final outstanding = (amount - amountPaid).clamp(0, amount);
    final status = readInvoiceStatus(sale);
    final items = (sale['items'] as List?)?.whereType<Map>().toList() ?? const [];

    final b = StringBuffer();
    b.writeln('==============================');
    b.writeln(businessName.toUpperCase());
    b.writeln('RECEIPT / INVOICE');
    b.writeln('No: $invoiceNo');
    if (createdAt != null) {
      b.writeln(
        'Date: ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
      );
    }
    b.writeln('Customer: $customer');
    b.writeln('Status: $status');
    b.writeln('------------------------------');
    if (items.isNotEmpty) {
      for (final item in items) {
        final name = (item['name'] ?? '-').toString();
        final qty = (item['qty'] ?? item['quantity'] ?? 1).toString();
        final unitPrice = parseNumericAmount(item['unitPrice']);
        final total = parseNumericAmount(item['total']);
        b.writeln(name);
        b.writeln('  $qty x ${unitPrice.toStringAsFixed(0)} = ${total.toStringAsFixed(0)}');
      }
      b.writeln('------------------------------');
    }
    b.writeln('Total: TSh ${amount.toStringAsFixed(0)}');
    b.writeln('Paid:  TSh ${amountPaid.toStringAsFixed(0)}');
    b.writeln('Due:   TSh ${outstanding.toStringAsFixed(0)}');
    b.writeln('Printed by: $printedBy');
    b.writeln('------------------------------');
    b.writeln('Powered by Mali Up');
    b.writeln('[Mali Up logo]');
    b.writeln('==============================');
    return b.toString();
  }

  static Future<void> _openReceiptActions({
    required BuildContext context,
    required Map<String, dynamic> sale,
    required WidgetRef ref,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final repo = ref.read(contextFirestoreRepositoryProvider);
    final ctx = await repo.resolveContextForUser(user.uid);
    final meta = await _loadReceiptMeta(uid: user.uid, businessId: ctx.businessId);
    final receipt = _buildReceiptText(
      sale: sale,
      businessName: meta['businessName'] ?? 'Business',
      printedBy: meta['printedBy'] ?? 'User',
    );

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr('Receipt Actions', 'Vitendo vya risiti'),
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.message_outlined, color: AppColors.primary),
                title: Text(_tr('Share to WhatsApp', 'Tuma kwa WhatsApp')),
                onTap: () async {
                  final url = 'https://wa.me/?text=${Uri.encodeComponent(receipt)}';
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sms_outlined, color: AppColors.primary),
                title: Text(_tr('Share by SMS', 'Tuma kwa SMS')),
                onTap: () async {
                  final uri = Uri.parse('sms:?body=${Uri.encodeComponent(receipt)}');
                  await launchUrl(uri);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.print_outlined, color: AppColors.primary),
                title: Text(_tr('Print receipt', 'Chapisha risiti')),
                subtitle: Text(
                  _tr(
                    'Opens share/copy flow for wired or wireless receipt-printer apps.',
                    'Fungua mtiririko wa kushiriki/kunakili kwa app za printer za waya au zisizo na waya.',
                  ),
                ),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: receipt));
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        _tr(
                          'Receipt copied. Paste into your printer app to print.',
                          'Risiti imenakiliwa. Bandika kwenye app ya printer kuchapisha.',
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.copy_all_rounded, color: AppColors.primary),
                title: Text(_tr('Copy receipt text', 'Nakili maandishi ya risiti')),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: receipt));
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text(_tr('Copied.', 'Imenakiliwa.'))),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesInvoiceListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useSafeArea: true,
              builder: (_) => const _QuickSaleSheet(),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _tr(
                    'Could not open sell screen. Please try again.',
                    'Imeshindikana kufungua skrini ya mauzo. Tafadhali jaribu tena.',
                  ),
                ),
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        elevation: 4,
        child: const Icon(Icons.shopping_cart),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Text(
              _tr('Sales', 'Mauzo'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const SalesPageSkeleton(),
              error: (_, _) => Center(
                child: Text(
                  _tr(
                    'Unable to load sales right now.',
                    'Imeshindikana kupakia mauzo kwa sasa.',
                  ),
                ),
              ),
              data: (items) {
                final totalSales = items.fold<double>(
                  0,
                  (s, i) => s + parseNumericAmount(i['amount']),
                );
                final paidSales = items
                    .where((i) =>
                        readInvoiceStatus(i).toLowerCase() == 'paid')
                    .fold<double>(
                      0,
                      (s, i) => s + parseNumericAmount(i['amount']),
                    );
                final pendingSales = totalSales - paidSales;

                return Column(
                  children: [
                    _SummaryBar(
                      total: totalSales,
                      paid: paidSales,
                      pending: pendingSales,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? const _EmptySalesState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 104),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final status = readInvoiceStatus(item);
                                final amount = parseNumericAmount(item['amount']);
                                final amountPaid =
                                    parseNumericAmount(item['amountPaid']);
                                final id = (item['invoiceNumber'] ??
                                        item['id'] ??
                                        '')
                                    .toString();
                                final customer = (item['customerName'] ??
                                        item['customer'] ??
                                        _tr('Walk-in', 'Mteja Wa Kawaida'))
                                    .toString();
                                final date = readTimestamp(
                                    item['createdAt'] ?? item['date']);
                                return _InvoiceCard(
                                  id: id.isEmpty ? '#${index + 1}' : '#$id',
                                  customer: customer,
                                  amount: amount,
                                  amountPaid: amountPaid,
                                  status: status,
                                  date: _fmtDate(date),
                                  onReceiptActions: () => _openReceiptActions(
                                    context: context,
                                    sale: item,
                                    ref: ref,
                                  ),
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

  static String _fmtDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ── Summary bar ──────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final double total;
  final double paid;
  final double pending;

  const _SummaryBar({
    required this.total,
    required this.paid,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatChip(label: _tr('Total', 'Jumla'), value: _fmt(total), color: AppColors.primary),
          _vDivider(),
          _StatChip(label: _tr('Paid', 'Imelipwa'), value: _fmt(paid), color: AppColors.success),
          _vDivider(),
          _StatChip(label: _tr('Pending', 'Inasubiri'), value: _fmt(pending), color: AppColors.warning),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.15),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  static String _fmt(double v) {
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

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
            child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.primary),
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
            _tr('Tap New Sale to get started', 'Bonyeza Mauzo Mapya kuanza'),
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Invoice list card ─────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final String id;
  final String customer;
  final double amount;
  final double amountPaid;
  final String status;
  final String date;
  final VoidCallback onReceiptActions;

  const _InvoiceCard({
    required this.id,
    required this.customer,
    required this.amount,
    required this.amountPaid,
    required this.status,
    required this.date,
    required this.onReceiptActions,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (s == 'paid') {
      statusColor = AppColors.success;
      statusLabel = _tr('Paid in Full', 'Imelipwa Kabisa');
      statusIcon = Icons.check_circle_rounded;
    } else if (s == 'partial') {
      statusColor = AppColors.warning;
      statusLabel = _tr('Half Paid', 'Nusu Imelipwa');
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = AppColors.error;
      statusLabel = _tr('Not Paid', 'Haijaliwa');
      statusIcon = Icons.cancel_outlined;
    }

    final outstanding = amount - amountPaid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowCard, blurRadius: 6, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(id,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    Text(date,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  customer,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondary),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _fmtAmt(amount),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                    if (s == 'partial' && outstanding > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· ${_tr("Bal", "Baki")}: ${_fmtAmt(outstanding)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onReceiptActions,
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: Text(
                  _tr('Receipt', 'Risiti'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtAmt(double v) {
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }
}

// ── Quick Sale Bottom Sheet ───────────────────────────────────────────────────

class _QuickSaleSheet extends ConsumerStatefulWidget {
  const _QuickSaleSheet();

  @override
  ConsumerState<_QuickSaleSheet> createState() => _QuickSaleSheetState();
}

class _QuickSaleSheetState extends ConsumerState<_QuickSaleSheet> {
  final _productCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _amtPaidCtrl = TextEditingController();
  final _productFocus = FocusNode();
  final _customerFocus = FocusNode();

  Map<String, dynamic>? _selectedItem;
  double? _basePrice;
  int _qty = 1;

  Customer? _selectedCustomer;

  List<Map<String, dynamic>> _productSuggs = [];
  bool _showProductSuggs = false;

  List<Customer> _customerSuggs = [];
  bool _showCustomerSuggs = false;

  _PayStatus _payStatus = _PayStatus.paid;
  bool _isSaving = false;

  double get _unitPrice {
    final t = _priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(t) ?? 0;
  }

  double get _total => _unitPrice * _qty;

  int get _maxStock {
    if (_selectedItem == null) return 9999;
    return parseStock(_selectedItem!['currentStock'] ?? _selectedItem!['stock']);
  }

  bool get _isOutOfStock => _selectedItem != null && _maxStock <= 0;

  double? get _priceDeltaPct {
    if (_basePrice == null || _basePrice! <= 0 || _unitPrice <= 0) return null;
    return ((_unitPrice - _basePrice!) / _basePrice!) * 100;
  }

  @override
  void initState() {
    super.initState();
    _productCtrl.addListener(_onProductChanged);
    _customerCtrl.addListener(_onCustomerChanged);
  }

  @override
  void dispose() {
    _productCtrl
      ..removeListener(_onProductChanged)
      ..dispose();
    _customerCtrl
      ..removeListener(_onCustomerChanged)
      ..dispose();
    _priceCtrl.dispose();
    _amtPaidCtrl.dispose();
    _productFocus.dispose();
    _customerFocus.dispose();
    super.dispose();
  }

  void _onProductChanged() {
    final query = _productCtrl.text.trim();
    final inventory = ref.read(inventoryItemListProvider).value ?? [];

    if (_selectedItem != null) {
      final name = (_selectedItem!['name'] ?? '') as String;
      if (query.toLowerCase() != name.toLowerCase()) {
        _selectedItem = null;
        _basePrice = null;
      }
    }

    if (query.isEmpty || _selectedItem != null) {
      if (_showProductSuggs || _productSuggs.isNotEmpty) {
        setState(() {
          _productSuggs = [];
          _showProductSuggs = false;
        });
      }
      return;
    }

    final matched = inventory
        .where((item) =>
            (item['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
        .take(6)
        .toList();

    setState(() {
      _productSuggs = matched;
      _showProductSuggs = matched.isNotEmpty;
    });
  }

  void _onCustomerChanged() {
    final query = _customerCtrl.text.trim();
    final customers = ref.read(customerListProvider).value ?? [];

    if (_selectedCustomer != null) {
      if (query.toLowerCase() != _selectedCustomer!.name.toLowerCase()) {
        _selectedCustomer = null;
      }
    }

    if (_selectedCustomer != null) {
      if (_showCustomerSuggs) setState(() => _showCustomerSuggs = false);
      return;
    }

    final matched = customers
        .where((c) =>
            c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.phone.contains(query))
        .take(5)
        .toList();

    setState(() {
      _customerSuggs = matched;
      _showCustomerSuggs = query.isNotEmpty;
    });
  }

  void _selectItem(Map<String, dynamic> item) {
    final name = (item['name'] ?? '') as String;
    final price = parseUnitPrice(item['unitPrice'] ?? item['price'] ?? 0);
    _productFocus.unfocus();
    setState(() {
      _selectedItem = item;
      _basePrice = price;
      _productCtrl.text = name;
      _priceCtrl.text = price > 0 ? price.toStringAsFixed(0) : '';
      _productSuggs = [];
      _showProductSuggs = false;
      _qty = 1;
    });
  }

  void _selectCustomer(Customer c) {
    _customerFocus.unfocus();
    setState(() {
      _selectedCustomer = c;
      _customerCtrl.text = c.name;
      _customerSuggs = [];
      _showCustomerSuggs = false;
    });
  }

  void _openAddProductSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _AddProductSheet(
        initialName: _productCtrl.text.trim(),
        onAdded: _selectItem,
      ),
    );
  }

  void _openAddCustomerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _QuickAddCustomerSheet(
        initialName: _customerCtrl.text.trim(),
        onAdded: _selectCustomer,
      ),
    );
  }

  Future<void> _save() async {
    final productName = _productCtrl.text.trim();
    if (productName.isEmpty) {
      _snack(_tr('Enter a product name.', 'Ingiza jina la bidhaa.'));
      return;
    }
    if (_unitPrice <= 0) {
      _snack(_tr('Enter a valid price.', 'Ingiza bei sahihi.'));
      return;
    }
    if (_isOutOfStock) {
      _snack(_tr('This product is out of stock.', 'Bidhaa hii imekwisha stokuni.'));
      return;
    }
    if (_selectedItem != null && _qty > _maxStock) {
      _snack(_tr('Only $_maxStock units available.', 'Vitengo $_maxStock tu vinapatikana.'));
      return;
    }

    double amountPaid;
    if (_payStatus == _PayStatus.paid) {
      amountPaid = _total;
    } else if (_payStatus == _PayStatus.partial) {
      final t = _amtPaidCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      amountPaid = double.tryParse(t) ?? 0;
      if (amountPaid <= 0) {
        _snack(_tr('Enter amount paid.', 'Ingiza kiasi kilicholipwa.'));
        return;
      }
      if (amountPaid >= _total) amountPaid = _total;
    } else {
      amountPaid = 0;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final invoicesRef =
          repo.scopeCollection(uid: user.uid, context: ctx, childCollection: 'sales_invoices');

      final now = DateTime.now();
      final invoiceNumber = 'INV-${now.millisecondsSinceEpoch.toString().substring(6)}';

      final statusStr = _payStatus == _PayStatus.paid
          ? 'Paid'
          : _payStatus == _PayStatus.partial
              ? 'Partial'
              : 'Unpaid';

      final customerName = _selectedCustomer?.name ??
          (_customerCtrl.text.trim().isNotEmpty ? _customerCtrl.text.trim() : null);

      await invoicesRef.add({
        'invoiceNumber': invoiceNumber,
        if (customerName != null) 'customerName': customerName,
        if (_selectedCustomer != null) ...{
          'customerId': _selectedCustomer!.id,
          'customerPhone': _selectedCustomer!.phone,
          'isOrganisation': _selectedCustomer!.isOrganisation,
          if (_selectedCustomer!.tinNumber.isNotEmpty) 'customerTin': _selectedCustomer!.tinNumber,
        },
        'amount': _total,
        'amountPaid': amountPaid,
        'status': statusStr,
        'items': [
          {
            'name': productName,
            'qty': _qty,
            'unitPrice': _unitPrice,
            'basePrice': _basePrice ?? _unitPrice,
            'total': _total,
            if (_selectedItem != null)
              'inventoryItemId': (_selectedItem!['id'] as String?) ?? '',
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Decrement stock
      if (_selectedItem != null) {
        final itemId = ((_selectedItem!['id'] as String?) ?? '').trim();
        if (itemId.isNotEmpty) {
          try {
            await repo
                .scopeCollection(
                    uid: user.uid, context: ctx, childCollection: 'inventory_items')
                .doc(itemId)
                .update({
              'currentStock': FieldValue.increment(-_qty),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }
      }

      // Update customer balance (amount still outstanding)
      if (_selectedCustomer != null) {
        final outstanding = _total - amountPaid;
        try {
          await repo
              .scopeCollection(
                  uid: user.uid, context: ctx, childCollection: 'customers')
              .doc(_selectedCustomer!.id)
              .update({
            'lastTransactionDate': FieldValue.serverTimestamp(),
            'balance': FieldValue.increment(outstanding),
          });
        } catch (_) {}
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
      messenger.showSnackBar(SnackBar(
        content: Text(_tr('Failed to save. Try again.', 'Imeshindikana. Jaribu tena.')),
      ));
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: sh * 0.93,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dragHandle(),
              _header(),
              const SizedBox(height: 20),
              _productField(),
              if (_showProductSuggs) _productSuggestions(),
              if (_productCtrl.text.isNotEmpty && _selectedItem == null) _addProductHint(),
              const SizedBox(height: 14),
              _priceAndQty(),
              if (_selectedItem != null) ...[
                const SizedBox(height: 6),
                _stockBadge(),
              ],
              const SizedBox(height: 14),
              _customerField(),
              if (_showCustomerSuggs) _customerSuggestions(),
              const SizedBox(height: 14),
              _paymentToggle(),
              if (_payStatus == _PayStatus.partial) ...[
                const SizedBox(height: 12),
                _amountPaidField(),
              ],
              const SizedBox(height: 24),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────

  Widget _dragHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 20),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );

  Widget _header() {
    final Color sc;
    final String sl;
    switch (_payStatus) {
      case _PayStatus.paid:
        sc = AppColors.success;
        sl = _tr('Paid in Full', 'Imelipwa Kabisa');
      case _PayStatus.partial:
        sc = AppColors.warning;
        sl = _tr('Half Paid', 'Nusu Imelipwa');
      case _PayStatus.unpaid:
        sc = AppColors.error;
        sl = _tr('Not Paid', 'Haijaliwa');
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            _tr('Record a Sale', 'Rekodi Mauzo'),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.secondary),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: sc.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(sl,
              style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _productField() {
    return TextField(
      controller: _productCtrl,
      focusNode: _productFocus,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => setState(() {}),
      decoration: _dec(
        label: _tr('Product / Item *', 'Bidhaa / Kitu *'),
        hint: _tr('Search inventory…', 'Tafuta kwenye hisa…'),
        prefix: Icons.inventory_2_outlined,
        suffix: _selectedItem != null
            ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
            : (_productCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _productCtrl.clear();
                      setState(() {
                        _selectedItem = null;
                        _basePrice = null;
                        _productSuggs = [];
                        _showProductSuggs = false;
                      });
                    },
                  )
                : null),
      ),
    );
  }

  Widget _productSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: _productSuggs.asMap().entries.map((e) {
          final isLast = e.key == _productSuggs.length - 1;
          final item = e.value;
          final name = (item['name'] ?? '') as String;
          final price = parseUnitPrice(item['unitPrice'] ?? item['price'] ?? 0);
          final stock = parseStock(item['currentStock'] ?? item['stock'] ?? 0);
          final oos = stock <= 0;

          return Column(
            children: [
              InkWell(
                onTap: oos ? null : () => _selectItem(item),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (oos ? AppColors.error : AppColors.primary)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.inventory_2_rounded,
                            size: 18, color: oos ? AppColors.error : AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: oos ? AppColors.textMuted : AppColors.secondary,
                              ),
                            ),
                            Text(
                              oos
                                  ? _tr('Out of Stock', 'Haipatikani Stokuni')
                                  : 'TSh ${price.toStringAsFixed(0)} · $stock ${_tr("in stock", "stokuni")}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: oos ? AppColors.error : AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (oos)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_tr('Out', 'Imekwisha'),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700)),
                        )
                      else
                        const Icon(Icons.north_west_rounded,
                            size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _addProductHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: _openAddProductSheet,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tr(
                    'Add "${_productCtrl.text}" to inventory',
                    'Ongeza "${_productCtrl.text}" kwa hisa',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceAndQty() {
    final delta = _priceDeltaPct;
    final isUp = (delta ?? 0) > 0;
    final deltaColor = isUp ? AppColors.error : AppColors.success;
    final deltaLabel = delta == null
        ? null
        : '${isUp ? "+" : ""}${delta.toStringAsFixed(1)}% '
            '${isUp ? _tr("above list price", "juu ya bei ya orodha") : _tr("discount", "punguzo")}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                onChanged: (_) => setState(() {}),
                decoration: _dec(
                  label: _tr('Unit Price (TSh) *', 'Bei ya Kitengo *'),
                  prefix: Icons.payments_outlined,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _QtyWidget(
              qty: _qty,
              maxQty: _maxStock,
              onDecrement: _qty > 1 ? () => setState(() => _qty--) : null,
              onIncrement: (_selectedItem == null || _qty < _maxStock)
                  ? () => setState(() => _qty++)
                  : null,
            ),
          ],
        ),
        if (deltaLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: deltaColor,
              ),
              const SizedBox(width: 4),
              Text(deltaLabel,
                  style: TextStyle(
                      fontSize: 12, color: deltaColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _stockBadge() {
    final Color color;
    final String label;
    if (_isOutOfStock) {
      color = AppColors.error;
      label = _tr('Out of Stock — cannot sell', 'Imekwisha — haiwezekani kuuza');
    } else if (_maxStock <= 5) {
      color = AppColors.warning;
      label = _tr('Low stock: $_maxStock left', 'Stoku ndogo: $_maxStock zilizobaki');
    } else {
      color = AppColors.success;
      label = '$_maxStock ${_tr("available in stock", "zinapatikana stokuni")}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _customerField() {
    return TextField(
      controller: _customerCtrl,
      focusNode: _customerFocus,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => setState(() {}),
      decoration: _dec(
        label: _tr('Customer (optional)', 'Mteja (hiari)'),
        hint: _tr('Search or type name…', 'Tafuta au andika jina…'),
        prefix: _selectedCustomer?.isOrganisation == true
            ? Icons.business_outlined
            : Icons.person_outline_rounded,
        suffix: _selectedCustomer != null
            ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
            : (_customerCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _customerCtrl.clear();
                      setState(() {
                        _selectedCustomer = null;
                        _customerSuggs = [];
                        _showCustomerSuggs = false;
                      });
                    },
                  )
                : null),
      ),
    );
  }

  Widget _customerSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ..._customerSuggs.asMap().entries.map((e) {
            final c = e.value;
            return Column(
              children: [
                InkWell(
                  onTap: () => _selectCustomer(c),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            c.isOrganisation
                                ? Icons.business_outlined
                                : Icons.person_outline_rounded,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.secondary)),
                              if (c.displaySubtitle.isNotEmpty)
                                Text(c.displaySubtitle,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        if (c.isOrganisation)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_tr('Org', 'Shirika'),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.border),
              ],
            );
          }),
          // Add new customer
          InkWell(
            onTap: _openAddCustomerSheet,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _tr('Add new customer', 'Ongeza mteja mpya'),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Payment Status', 'Hali ya Malipo'),
          style: const TextStyle(
              fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _PayBtn(
                label: _tr('Paid', 'Imelipwa'),
                icon: Icons.check_circle_outline_rounded,
                active: _payStatus == _PayStatus.paid,
                activeColor: AppColors.success,
                onTap: () => setState(() => _payStatus = _PayStatus.paid),
              ),
              const SizedBox(width: 4),
              _PayBtn(
                label: _tr('Half Paid', 'Nusu'),
                icon: Icons.timelapse_rounded,
                active: _payStatus == _PayStatus.partial,
                activeColor: AppColors.warning,
                onTap: () => setState(() => _payStatus = _PayStatus.partial),
              ),
              const SizedBox(width: 4),
              _PayBtn(
                label: _tr('Not Paid', 'Haijaliwa'),
                icon: Icons.cancel_outlined,
                active: _payStatus == _PayStatus.unpaid,
                activeColor: AppColors.error,
                onTap: () => setState(() => _payStatus = _PayStatus.unpaid),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountPaidField() {
    return TextField(
      controller: _amtPaidCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: (_) => setState(() {}),
      decoration: _dec(
        label: _tr('Amount Paid (TSh)', 'Kiasi Kilicholipwa (TSh)'),
        hint: _tr('Enter amount paid so far', 'Ingiza kiasi kilicholipwa'),
        prefix: Icons.payments_outlined,
      ),
    );
  }

  Widget _footer() {
    final t = _total;
    final String display;
    if (t >= 1000000) {
      display = 'TSh ${(t / 1000000).toStringAsFixed(2)}M';
    } else if (t >= 1000) {
      display = 'TSh ${(t / 1000).toStringAsFixed(1)}K';
    } else {
      display = 'TSh ${t.toStringAsFixed(0)}';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tr('Total', 'Jumla'),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
              Text(
                display,
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
            onPressed: _isSaving || _isOutOfStock ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
              disabledBackgroundColor: _isOutOfStock
                  ? AppColors.error.withValues(alpha: 0.6)
                  : AppColors.primary.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.secondary),
                  )
                : Text(
                    _isOutOfStock
                        ? _tr('Out of Stock', 'Imekwisha')
                        : _tr('Save Sale', 'Hifadhi Mauzo'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    required IconData prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefix, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

// ── Qty widget ────────────────────────────────────────────────────────────────

class _QtyWidget extends StatelessWidget {
  final int qty;
  final int maxQty;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _QtyWidget({
    required this.qty,
    required this.maxQty,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_tr('Qty', 'Idadi'),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
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
              _Btn(icon: Icons.remove_rounded, onTap: onDecrement),
              SizedBox(
                width: 36,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.secondary),
                ),
              ),
              _Btn(icon: Icons.add_rounded, onTap: onIncrement),
            ],
          ),
        ),
        if (maxQty < 9999)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('/ $maxQty',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _Btn({required this.icon, this.onTap});

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
          child: Icon(icon, size: 18,
              color: onTap != null ? AppColors.secondary : AppColors.border),
        ),
      ),
    );
  }
}

// ── Payment toggle button ─────────────────────────────────────────────────────

class _PayBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _PayBtn({
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: active ? Colors.white : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Product Sheet ─────────────────────────────────────────────────────────

class _AddProductSheet extends ConsumerStatefulWidget {
  final String initialName;
  final void Function(Map<String, dynamic>) onAdded;

  const _AddProductSheet({required this.initialName, required this.onAdded});

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  late final TextEditingController _nameCtrl;
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  final _categoryCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  String _selectedUnit = 'pcs';
  bool _isSaving = false;

  final List<String> _units = [
    'pcs', 'kg', 'liters', 'boxes', 'bottles', 'bags', 'meters', 'sets',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    _skuCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 1;
    final category = _categoryCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('Enter product name', 'Ingiza jina la bidhaa'))));
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('Enter a valid price', 'Ingiza bei sahihi'))));
      return;
    }

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final inventoryRef =
          repo.scopeCollection(uid: user.uid, context: ctx, childCollection: 'inventory_items');

      final docRef = await inventoryRef.add({
        'name': name,
        'unitPrice': price,
        'category': category.isNotEmpty ? category : 'General',
        'currentStock': stock,
        'reorderPoint': 5,
        'unit': _selectedUnit,
        if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      navigator.pop();
      widget.onAdded({
        'id': docRef.id,
        'name': name,
        'unitPrice': price,
        'category': category.isNotEmpty ? category : 'General',
        'currentStock': stock,
        'unit': _selectedUnit,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Failed to add product', 'Imeshindikana kuongeza bidhaa'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 28),
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
                      color: AppColors.border, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const Text('Add New Product',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.secondary)),
              const SizedBox(height: 20),
              _field(ctrl: _nameCtrl, label: _tr('Product Name *', 'Jina la Bidhaa *'),
                  icon: Icons.inventory_2_outlined, caps: TextCapitalization.words),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _field(
                      ctrl: _priceCtrl,
                      label: _tr('Unit Price (TSh) *', 'Bei ya Kitengo *'),
                      icon: Icons.sell_outlined,
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      ctrl: _stockCtrl,
                      label: _tr('Stock', 'Stoku'),
                      icon: Icons.inventory_outlined,
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      ctrl: _categoryCtrl,
                      label: _tr('Category', 'Kategoria'),
                      icon: Icons.category_outlined,
                      caps: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: _tr('Unit', 'Kitengo'),
                        prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: _units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _field(ctrl: _skuCtrl, label: _tr('SKU (Optional)', 'SKU (Hiari)'),
                  icon: Icons.tag_outlined, caps: TextCapitalization.characters),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.secondary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.secondary))
                      : Text(_tr('Add to Inventory', 'Ongeza kwa Hisa'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    TextCapitalization caps = TextCapitalization.none,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        inputFormatters: formatters,
        textCapitalization: caps,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

// ── Quick Add Customer Sheet ──────────────────────────────────────────────────

class _QuickAddCustomerSheet extends ConsumerStatefulWidget {
  final String initialName;
  final void Function(Customer) onAdded;

  const _QuickAddCustomerSheet({required this.initialName, required this.onAdded});

  @override
  ConsumerState<_QuickAddCustomerSheet> createState() =>
      _QuickAddCustomerSheetState();
}

class _QuickAddCustomerSheetState extends ConsumerState<_QuickAddCustomerSheet> {
  late final TextEditingController _nameCtrl;
  final _phoneCtrl = TextEditingController();
  final _tinCtrl = TextEditingController();
  bool _isOrg = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _tinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_tr('Enter name', 'Ingiza jina'))));
      return;
    }

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final customersRef =
          repo.scopeCollection(uid: user.uid, context: ctx, childCollection: 'customers');

      final tin = _tinCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      final docRef = await customersRef.add({
        'name': name,
        'phone': phone,
        'email': '',
        'balance': '0',
        'lastTransactionDate': '',
        'tags': const <String>[],
        'isOrganisation': _isOrg,
        if (tin.isNotEmpty) 'tinNumber': tin,
      });

      navigator.pop();
      widget.onAdded(Customer(
        id: docRef.id,
        name: name,
        phone: phone,
        isOrganisation: _isOrg,
        tinNumber: tin,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Failed to add customer', 'Imeshindikana kuongeza mteja'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 28),
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
                      color: AppColors.border, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Text(
                _tr('New Customer', 'Mteja Mpya'),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
              // Type toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _TypeBtn(
                      label: _tr('Individual', 'Binafsi'),
                      icon: Icons.person_outline_rounded,
                      active: !_isOrg,
                      onTap: () => setState(() => _isOrg = false),
                    ),
                    const SizedBox(width: 4),
                    _TypeBtn(
                      label: _tr('Organisation', 'Shirika'),
                      icon: Icons.business_outlined,
                      active: _isOrg,
                      onTap: () => setState(() => _isOrg = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _isOrg
                      ? _tr('Organisation Name *', 'Jina la Shirika *')
                      : _tr('Customer Name *', 'Jina la Mteja *'),
                  prefixIcon: Icon(
                      _isOrg ? Icons.business_outlined : Icons.person_outline_rounded,
                      size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _tr('Phone Number', 'Namba ya Simu'),
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              if (_isOrg) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _tinCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: _tr('TIN Number (Optional)', 'Namba ya TIN (Hiari)'),
                    hintText: 'e.g. 100-123-456',
                    prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(_tr('Add Customer', 'Ongeza Mteja'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual / Org type toggle button ───────────────────────────────────────

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: active ? Colors.white : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
