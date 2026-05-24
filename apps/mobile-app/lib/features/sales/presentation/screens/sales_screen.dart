import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/barcode_scanner_screen.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../customer/domain/models/customer.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../data/sales_providers.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _PayStatus { paid, partial, unpaid }

enum _SalesFilter { all, paid, sent, overdue, draft, cancelled }

extension _SalesFilterX on _SalesFilter {
  String get label => switch (this) {
        _SalesFilter.all => _tr('All', 'Zote'),
        _SalesFilter.paid => _tr('Paid', 'Imelipwa'),
        _SalesFilter.sent => _tr('Sent', 'Imetumwa'),
        _SalesFilter.overdue => _tr('Overdue', 'Imechelewa'),
        _SalesFilter.draft => _tr('Draft', 'Rasimu'),
        _SalesFilter.cancelled => _tr('Cancelled', 'Imefutwa'),
      };

  Color get activeColor => switch (this) {
        _SalesFilter.all => AppColors.navyPrimary,
        _SalesFilter.paid => AppColors.success,
        _SalesFilter.sent => AppColors.tealAccent,
        _SalesFilter.overdue => AppColors.error,
        _SalesFilter.draft => AppColors.textMuted,
        _SalesFilter.cancelled => AppColors.textDisabled,
      };
}

// ── Status helpers ────────────────────────────────────────────────────────────

String _normalizeStatus(Map<String, dynamic> item) {
  final raw = readInvoiceStatus(item).toLowerCase().trim();
  return switch (raw) {
    'paid' => 'paid',
    'partial' => 'partial',
    'unpaid' => 'unpaid',
    'sent' => 'sent',
    'draft' => 'draft',
    'overdue' => 'overdue',
    'cancelled' => 'cancelled',
    _ => 'sent',
  };
}

bool _isOverdue(Map<String, dynamic> item) {
  final s = _normalizeStatus(item);
  if (s == 'paid' || s == 'cancelled' || s == 'draft') return false;
  if (s == 'overdue') return true;
  final dueDate = readTimestamp(item['dueDate']);
  if (dueDate == null) return false;
  return dueDate.isBefore(DateTime.now());
}

bool _matchesFilter(Map<String, dynamic> item, _SalesFilter filter) {
  if (filter == _SalesFilter.all) return true;
  final s = _normalizeStatus(item);
  return switch (filter) {
    _SalesFilter.paid => s == 'paid',
    _SalesFilter.sent =>
      (s == 'sent' || s == 'unpaid' || s == 'partial') && !_isOverdue(item),
    _SalesFilter.overdue => _isOverdue(item),
    _SalesFilter.draft => s == 'draft',
    _SalesFilter.cancelled => s == 'cancelled',
    _SalesFilter.all => true,
  };
}

Color _statusColor(Map<String, dynamic> item) {
  if (_isOverdue(item)) return AppColors.error;
  final s = _normalizeStatus(item);
  return switch (s) {
    'paid' => AppColors.success,
    'draft' => AppColors.textMuted,
    'cancelled' => AppColors.textDisabled,
    _ => AppColors.tealAccent,
  };
}

String _fmtAmt(double v) {
  if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
  return 'TSh ${v.toStringAsFixed(0)}';
}

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${d.day} ${months[d.month - 1]}';
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  _SalesFilter _filter = _SalesFilter.all;
  bool _searchActive = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> items) {
    var list = items.where((i) => _matchesFilter(i, _filter)).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((i) {
        final cn = (i['customerName'] ?? '').toString().toLowerCase();
        final inv = (i['invoiceNumber'] ?? i['id'] ?? '').toString().toLowerCase();
        return cn.contains(q) || inv.contains(q);
      }).toList();
    }
    return list;
  }

  Map<_SalesFilter, int> _buildCounts(List<Map<String, dynamic>> items) {
    return {
      _SalesFilter.all: items.length,
      _SalesFilter.paid:
          items.where((i) => _normalizeStatus(i) == 'paid').length,
      _SalesFilter.sent:
          items.where((i) => _matchesFilter(i, _SalesFilter.sent)).length,
      _SalesFilter.overdue: items.where(_isOverdue).length,
      _SalesFilter.draft:
          items.where((i) => _normalizeStatus(i) == 'draft').length,
      _SalesFilter.cancelled:
          items.where((i) => _normalizeStatus(i) == 'cancelled').length,
    };
  }

  Future<void> _showNewSaleSheet(BuildContext ctx) async {
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _tr('New Sale', 'Uza / Ankara Mpya'),
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _NewSaleOption(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.navyPrimary,
                iconBg: AppColors.primary,
                title: _tr('Quick Sale', 'Mauzo ya Haraka'),
                subtitle: _tr(
                  'Single item, fast checkout',
                  'Bidhaa moja, malipo ya haraka',
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final plan = await ref.read(planStatusProvider.future);
                  if (!ctx.mounted) return;
                  if (!plan.canCreateInvoice) {
                    await showUpgradeSheet(ctx,
                        currentStatus: plan,
                        triggerReason: _tr(
                          'You\'ve reached the ${plan.limits.monthlyInvoices}-invoice monthly limit.',
                          'Umefika kikomo cha ankara ${plan.limits.monthlyInvoices} kwa mwezi.',
                        ));
                    return;
                  }
                  if (!ctx.mounted) return;
                  await showModalBottomSheet<void>(
                    context: ctx,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    useSafeArea: true,
                    builder: (_) => const _QuickSaleSheet(),
                  );
                },
              ),
              const SizedBox(height: 10),
              _NewSaleOption(
                icon: Icons.receipt_long_rounded,
                iconColor: Colors.white,
                iconBg: AppColors.navyPrimary,
                title: _tr('Full Invoice', 'Ankara Kamili'),
                subtitle: _tr(
                  'Multiple items · VAT · Discount · Quotation',
                  'Bidhaa nyingi · VAT · Punguzo · Nukuu',
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final plan = await ref.read(planStatusProvider.future);
                  if (!ctx.mounted) return;
                  if (!plan.canCreateInvoice) {
                    await showUpgradeSheet(ctx,
                        currentStatus: plan,
                        triggerReason: _tr(
                          'You\'ve reached the ${plan.limits.monthlyInvoices}-invoice monthly limit.',
                          'Umefika kikomo cha ankara ${plan.limits.monthlyInvoices} kwa mwezi.',
                        ));
                    return;
                  }
                  if (!ctx.mounted) return;
                  await Navigator.of(ctx).push(MaterialPageRoute(
                    builder: (_) => const CreateInvoiceScreen(),
                    fullscreenDialog: true,
                  ));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesInvoiceListProvider);

    return Scaffold(
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          onPressed: () => _showNewSaleSheet(ctx),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.navyPrimary,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            _tr('New Sale', 'Mauzo Mapya'),
            style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary),
          ),
        ),
      ),
      body: salesAsync.when(
        loading: () => const SalesPageSkeleton(),
        error: (_, __) => Center(
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: _tr('Could not load sales', 'Imeshindikana kupakia mauzo'),
            subtitle: _tr('Check your connection and try again.',
                'Angalia muunganiko wako na ujaribu tena.'),
          ),
        ),
        data: (items) {
          final counts = _buildCounts(items);
          final filtered = _applyFilters(items);

          final today = DateTime.now();
          final todayRevenue = items.where((i) {
            final d = readTimestamp(i['createdAt'] ?? i['date']);
            return d != null &&
                d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          }).fold<double>(0, (s, i) => s + parseNumericAmount(i['amount']));

          final pendingTotal = items
              .where((i) => _matchesFilter(i, _SalesFilter.sent))
              .fold<double>(
                  0,
                  (s, i) =>
                      s +
                      (parseNumericAmount(i['amount']) -
                          parseNumericAmount(i['amountPaid'])));

          final overdueCount = counts[_SalesFilter.overdue] ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tr('Sales', 'Mauzo'),
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _searchActive
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchActive = !_searchActive;
                          if (!_searchActive) {
                            _searchQuery = '';
                            _searchCtrl.clear();
                            _searchFocus.unfocus();
                          } else {
                            WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _searchFocus.requestFocus());
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ── Stats card
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _SalesStatsCard(
                  todayRevenue: todayRevenue,
                  pendingTotal: pendingTotal,
                  overdueCount: overdueCount,
                ),
              ),

              const SizedBox(height: 14),

              // ── Filter pills
              _FilterPills(
                selected: _filter,
                counts: counts,
                onSelect: (f) => setState(() => _filter = f),
              ),

              // ── Search bar
              if (_searchActive) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: _tr(
                        'Customer name or invoice number…',
                        'Jina la mteja au namba ya ankara…',
                      ),
                      hintStyle: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // ── List
              Expanded(
                child: filtered.isEmpty
                    ? _EmptySalesState(filter: _filter)
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(24, 4, 24, 104),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          final docId =
                              (item['id'] as String?) ?? '';
                          return _InvoiceCard(
                            item: item,
                            onTap: () => Navigator.of(ctx).push(
                              MaterialPageRoute(
                                builder: (_) => InvoiceDetailScreen(
                                  invoiceId: docId,
                                  invoice: Map<String, dynamic>.from(item),
                                ),
                              ),
                            ),
                            onReceiptAction: () =>
                                _openReceiptActions(
                              context: ctx,
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
    );
  }

  // ── Receipt utilities ──────────────────────────────────────────────────────

  static Future<Map<String, String>> _loadReceiptMeta({
    required String uid,
    required String? businessId,
  }) async {
    final fs = FirebaseFirestore.instance;
    String businessName = 'Business';
    String printedBy = 'User';
    try {
      final doc = await fs.collection('users').doc(uid).get();
      final data = doc.data();
      printedBy =
          ((data?['displayName'] ?? data?['name']) as String?)?.trim() ??
              'User';
      final list = data?['businesses'];
      if (list is List && businessId != null) {
        for (final b in list) {
          if (b is Map &&
              (b['id']?.toString() ?? '') == businessId &&
              (b['name'] as String?)?.trim().isNotEmpty == true) {
            businessName = (b['name'] as String).trim();
            break;
          }
        }
      }
    } catch (_) {}
    if (businessName == 'Business' &&
        businessId != null &&
        businessId.isNotEmpty) {
      try {
        final doc = await fs
            .collection('tenants')
            .doc(uid)
            .collection('businesses')
            .doc(businessId)
            .get();
        final n = (doc.data()?['businessName'] as String?)?.trim();
        if (n != null && n.isNotEmpty) businessName = n;
      } catch (_) {}
    }
    return {'businessName': businessName, 'printedBy': printedBy};
  }

  static String _buildReceiptText({
    required Map<String, dynamic> sale,
    required String businessName,
    required String printedBy,
  }) {
    final invoiceNo =
        (sale['invoiceNumber'] ?? sale['id'] ?? '-').toString();
    final customer =
        (sale['customerName'] ?? _tr('Walk-in', 'Mteja wa kawaida'))
            .toString();
    final createdAt = readTimestamp(sale['createdAt'] ?? sale['date']);
    final dueDate = readTimestamp(sale['dueDate']);
    final amount = parseNumericAmount(sale['amount']);
    final amountPaid = parseNumericAmount(sale['amountPaid']);
    final outstanding = (amount - amountPaid).clamp(0, amount);
    final status = readInvoiceStatus(sale);
    final items =
        (sale['items'] as List?)?.whereType<Map>().toList() ?? const [];
    final isQuotation =
        (sale['type'] ?? '').toString().toLowerCase() == 'quotation';
    final docType =
        isQuotation ? _tr('QUOTATION', 'NUKUU') : _tr('INVOICE', 'ANKARA');
    final payMethod =
        (sale['paymentMethod'] ?? '').toString().toLowerCase();

    const line = '────────────────────────────';
    const dline = '════════════════════════════';

    final b = StringBuffer();
    b.writeln('*$docType*');
    b.writeln(dline);
    b.writeln('*${businessName.toUpperCase()}*');
    b.writeln(dline);

    if (createdAt != null) {
      b.writeln(
          '*${_tr("Date", "Tarehe")}:* ${_fmtDate(createdAt)} ${createdAt.year}');
    }
    if (dueDate != null && !isQuotation) {
      b.writeln(
          '*${_tr("Due", "Malipo")}:* ${_fmtDate(dueDate)} ${dueDate.year}');
    }
    b.writeln('*${_tr("No", "Na")}.:* $invoiceNo');
    b.writeln('*${_tr("Customer", "Mteja")}:* $customer');
    b.writeln(line);

    if (items.isNotEmpty) {
      b.writeln('*${_tr("ITEMS", "BIDHAA")}:*');
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final name = (item['name'] ?? '-').toString();
        final qty =
            (item['qty'] ?? item['quantity'] ?? 1).toString();
        final unitPrice = parseNumericAmount(item['unitPrice']);
        final total = parseNumericAmount(item['total']);
        b.writeln(
            '${i + 1}. $name\n   $qty × TSh ${unitPrice.toStringAsFixed(0)} = *TSh ${total.toStringAsFixed(0)}*');
      }
      b.writeln(line);
    }

    final subtotal = parseNumericAmount(sale['subtotal'] ?? sale['amount']);
    final discount = parseNumericAmount(sale['discountAmount']);
    final vat = parseNumericAmount(sale['vatAmount']);

    if (discount > 0) {
      b.writeln(
          '${_tr("Subtotal", "Jumla Bidhaa")}: TSh ${subtotal.toStringAsFixed(0)}');
      b.writeln(
          '${_tr("Discount", "Punguzo")}: -TSh ${discount.toStringAsFixed(0)}');
    }
    if (vat > 0) {
      b.writeln(
          'VAT (18%): TSh ${vat.toStringAsFixed(0)}');
    }
    b.writeln(
        '*${_tr("TOTAL", "JUMLA KUU")}: TSh ${amount.toStringAsFixed(0)}*');

    if (!isQuotation) {
      b.writeln(
          '*${_tr("Paid", "Imelipwa")}:* TSh ${amountPaid.toStringAsFixed(0)}');
      if (outstanding > 0) {
        b.writeln(
            '*${_tr("Balance Due", "Baki")}:* TSh ${outstanding.toStringAsFixed(0)}');
      }
      if (payMethod.isNotEmpty) {
        final pm = switch (payMethod) {
          'mpesa' => 'M-Pesa',
          'bank_transfer' => _tr('Bank Transfer', 'Uhamisho wa Benki'),
          'card' => _tr('Card', 'Kadi'),
          'credit' => _tr('Credit (Pay Later)', 'Mkopo'),
          _ => _tr('Cash', 'Taslimu'),
        };
        b.writeln('${_tr("Payment", "Malipo")}: $pm');
        final ref = (sale['mpesaRef'] ?? '').toString();
        if (ref.isNotEmpty) b.writeln('Ref: $ref');
      }
    }

    b.writeln(line);
    b.writeln('${_tr("Printed by", "Imechapishwa na")}: $printedBy');
    b.writeln('_Powered by *Mali Up*_ 📊');

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
    final meta =
        await _loadReceiptMeta(uid: user.uid, businessId: ctx.businessId);
    final receipt = _buildReceiptText(
      sale: sale,
      businessName: meta['businessName'] ?? 'Business',
      printedBy: meta['printedBy'] ?? 'User',
    );
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr('Share Receipt', 'Shiriki Risiti'),
                style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                (sale['invoiceNumber'] ?? sale['id'] ?? '').toString(),
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: AppColors.textMuted),
              ),
              const Divider(height: 20, color: AppColors.border),
              _ReceiptAction(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                label: _tr('WhatsApp', 'WhatsApp'),
                onTap: () async {
                  final url =
                      'https://wa.me/?text=${Uri.encodeComponent(receipt)}';
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                },
              ),
              _ReceiptAction(
                icon: Icons.email_outlined,
                iconColor: AppColors.tealAccent,
                label: _tr('Email', 'Barua pepe'),
                onTap: () async {
                  final plain = receipt.replaceAll(RegExp(r'\*|_'), '');
                  final uri = Uri(
                    scheme: 'mailto',
                    queryParameters: {
                      'subject': 'Invoice ${sale['invoiceNumber'] ?? ''}',
                      'body': plain,
                    },
                  );
                  await launchUrl(uri);
                },
              ),
              _ReceiptAction(
                icon: Icons.sms_outlined,
                iconColor: AppColors.warning,
                label: _tr('SMS', 'SMS'),
                onTap: () async {
                  final plain = receipt.replaceAll(RegExp(r'\*|_'), '');
                  await launchUrl(Uri.parse(
                      'sms:?body=${Uri.encodeComponent(plain)}'));
                },
              ),
              _ReceiptAction(
                icon: Icons.copy_rounded,
                iconColor: AppColors.textSecondary,
                label: _tr('Copy Text', 'Nakili Maandishi'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: receipt));
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_tr('Copied.', 'Imenakiliwa.')),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats Card ─────────────────────────────────────────────────────────────────

class _SalesStatsCard extends StatelessWidget {
  final double todayRevenue;
  final double pendingTotal;
  final int overdueCount;

  const _SalesStatsCard({
    required this.todayRevenue,
    required this.pendingTotal,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyPrimary, AppColors.navySecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            label: _tr('Today', 'Leo'),
            value: _fmtAmt(todayRevenue),
            color: AppColors.primary,
          ),
          _vDivider(),
          _StatItem(
            label: _tr('Pending', 'Inasubiri'),
            value: _fmtAmt(pendingTotal),
            color: const Color(0xFF7DD3FC),
          ),
          _vDivider(),
          _StatItem(
            label: _tr('Overdue', 'Imechelewa'),
            value: overdueCount.toString(),
            color: overdueCount > 0
                ? const Color(0xFFFCA5A5)
                : Colors.white54,
            suffix: _tr(' inv.', ' ank.'),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.12),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String suffix;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: color.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Pills ───────────────────────────────────────────────────────────────

class _FilterPills extends StatelessWidget {
  final _SalesFilter selected;
  final Map<_SalesFilter, int> counts;
  final ValueChanged<_SalesFilter> onSelect;

  const _FilterPills({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: _SalesFilter.values.map((f) {
          final isSelected = f == selected;
          final count = counts[f] ?? 0;
          final color = f.activeColor;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.6)
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? color : AppColors.textMuted,
                      ),
                    ),
                    if (count > 0 && f != _SalesFilter.all) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : AppColors.textDisabled,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Invoice Card ───────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onReceiptAction;

  const _InvoiceCard({
    required this.item,
    required this.onTap,
    required this.onReceiptAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = _normalizeStatus(item);
    final overdue = _isOverdue(item);
    final sColor = _statusColor(item);

    final customer =
        (item['customerName'] ?? _tr('Walk-in', 'Mteja wa Kawaida'))
            .toString();
    final invoiceNo =
        (item['invoiceNumber'] ?? item['id'] ?? '').toString();
    final amount = parseNumericAmount(item['amount']);
    final amountPaid = parseNumericAmount(item['amountPaid']);
    final outstanding = (amount - amountPaid).clamp(0.0, amount);
    final date = readTimestamp(item['createdAt'] ?? item['date']);
    final dueDate = readTimestamp(item['dueDate']);
    final items = (item['items'] as List?) ?? const [];
    final itemCount = items.length;
    final isQuotation =
        (item['type'] ?? '').toString().toLowerCase() == 'quotation';

    // Status chip data
    final ({Color bg, Color text, String label, IconData icon}) chipData;
    if (overdue) {
      chipData = (
        bg: AppColors.errorBg,
        text: AppColors.error,
        label: _tr('Overdue', 'Imechelewa'),
        icon: Icons.warning_amber_rounded,
      );
    } else {
      chipData = switch (status) {
        'paid' => (
          bg: AppColors.successBg,
          text: AppColors.success,
          label: _tr('Paid', 'Imelipwa'),
          icon: Icons.check_circle_rounded,
        ),
        'partial' => (
          bg: AppColors.warningBg,
          text: AppColors.warning,
          label: _tr('Partial', 'Nusu'),
          icon: Icons.timelapse_rounded,
        ),
        'draft' => (
          bg: AppColors.surfaceVariant,
          text: AppColors.textMuted,
          label: _tr('Draft', 'Rasimu'),
          icon: Icons.edit_rounded,
        ),
        'cancelled' => (
          bg: AppColors.surfaceVariant,
          text: AppColors.textDisabled,
          label: _tr('Cancelled', 'Imefutwa'),
          icon: Icons.cancel_rounded,
        ),
        _ => (
          bg: AppColors.infoBg,
          text: AppColors.tealAccent,
          label: isQuotation ? _tr('Quotation', 'Nukuu') : _tr('Sent', 'Imetumwa'),
          icon: isQuotation
              ? Icons.description_outlined
              : Icons.send_rounded,
        ),
      };
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: sColor, width: 3.5),
              top: const BorderSide(color: AppColors.border),
              right: const BorderSide(color: AppColors.border),
              bottom: const BorderSide(color: AppColors.border),
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: invoice number + date + status chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (invoiceNo.isNotEmpty)
                                Text(
                                  invoiceNo,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (isQuotation) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _tr('QUO', 'NUK'),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMuted,
                                        letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            customer,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: chipData.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(chipData.icon,
                                  size: 10, color: chipData.text),
                              const SizedBox(width: 3),
                              Text(
                                chipData.label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: chipData.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmtDate(date),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 2: amount + item count + action button
                Row(
                  children: [
                    Text(
                      _fmtAmt(amount),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (itemCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· $itemCount ${_tr(itemCount == 1 ? "item" : "items", itemCount == 1 ? "kitu" : "vitu")}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Receipt action button
                    GestureDetector(
                      onTap: onReceiptAction,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.ios_share_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _tr('Share', 'Shiriki'),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Row 3: overdue / balance warning
                if (overdue && dueDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        '${_tr("Due was", "Malipo ilikuwa")} ${_fmtDate(dueDate)} ${dueDate.year}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'partial' && outstanding > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${_tr("Balance due", "Baki")}: ${_fmtAmt(outstanding)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptySalesState extends StatelessWidget {
  final _SalesFilter filter;

  const _EmptySalesState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, String title, String subtitle}) content =
        switch (filter) {
      _SalesFilter.paid => (
        icon: Icons.check_circle_outline_rounded,
        title: _tr('No paid invoices', 'Hakuna ankara zilizolipwa'),
        subtitle: _tr('Paid invoices will appear here.',
            'Ankara zilizolipwa zitaonekana hapa.'),
      ),
      _SalesFilter.overdue => (
        icon: Icons.schedule_rounded,
        title: _tr('No overdue invoices', 'Hakuna ankara zilizochelewa'),
        subtitle:
            _tr('Great — nothing overdue!', 'Vizuri — hakuna iliyochelewa!'),
      ),
      _SalesFilter.draft => (
        icon: Icons.edit_note_rounded,
        title: _tr('No drafts', 'Hakuna rasimu'),
        subtitle: _tr('Saved drafts will appear here.',
            'Rasimu zilizohifadhiwa zitaonekana hapa.'),
      ),
      _ => (
        icon: Icons.receipt_long_outlined,
        title: _tr('No sales yet', 'Bado hakuna mauzo'),
        subtitle:
            _tr('Tap New Sale to get started.', 'Bonyeza Mauzo Mapya kuanza.'),
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(content.icon,
                  size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              content.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAB option tile ────────────────────────────────────────────────────────────

class _NewSaleOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NewSaleOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
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
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Receipt action row ─────────────────────────────────────────────────────────

class _ReceiptAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ReceiptAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyPrimary),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// QUICK SALE SHEET — preserved from original
// ══════════════════════════════════════════════════════════════════════════════

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
      final invoicesRef = repo.scopeCollection(
          uid: user.uid, context: ctx, childCollection: 'sales_invoices');

      final now = DateTime.now();
      final invoiceNumber = 'INV-${now.millisecondsSinceEpoch.toString().substring(6)}';

      final statusStr = _payStatus == _PayStatus.paid
          ? 'paid'
          : _payStatus == _PayStatus.partial
              ? 'partial'
              : 'unpaid';

      final customerName = _selectedCustomer?.name ??
          (_customerCtrl.text.trim().isNotEmpty
              ? _customerCtrl.text.trim()
              : null);

      await invoicesRef.add({
        'invoiceNumber': invoiceNumber,
        'type': 'invoice',
        'invoiceStatus': statusStr,
        if (customerName != null) 'customerName': customerName,
        if (_selectedCustomer != null) ...{
          'customerId': _selectedCustomer!.id,
          'customerPhone': _selectedCustomer!.phone,
          'isOrganisation': _selectedCustomer!.isOrganisation,
          if (_selectedCustomer!.tinNumber.isNotEmpty)
            'customerTin': _selectedCustomer!.tinNumber,
        },
        'amount': _total,
        'subtotal': _total,
        'amountPaid': amountPaid,
        'status': statusStr,
        'paymentMethod': 'cash',
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

      if (_selectedItem != null) {
        final itemId = ((_selectedItem!['id'] as String?) ?? '').trim();
        if (itemId.isNotEmpty) {
          try {
            await repo
                .scopeCollection(
                    uid: user.uid,
                    context: ctx,
                    childCollection: 'inventory_items')
                .doc(itemId)
                .update({
              'currentStock': FieldValue.increment(-_qty),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }
      }

      if (_selectedCustomer != null) {
        final outstanding = _total - amountPaid;
        try {
          await repo
              .scopeCollection(
                  uid: user.uid,
                  context: ctx,
                  childCollection: 'customers')
              .doc(_selectedCustomer!.id)
              .update({
            'lastTransactionDate': FieldValue.serverTimestamp(),
            'balance': FieldValue.increment(outstanding),
          });
        } catch (_) {}
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
        content: Text(
            _tr('Failed to save. Try again.', 'Imeshindikana. Jaribu tena.')),
      ));
    }
  }

  Future<void> _scanBarcode() async {
    final scanned = await BarcodeScannerScreen.show(context,
        title: _tr('Scan Product', 'Skani Bidhaa'));
    if (scanned == null || scanned.isEmpty || !mounted) return;

    final inventory = ref.read(inventoryItemListProvider).value ?? [];
    final matched = inventory.firstWhere(
      (item) =>
          (item['sku'] ?? '').toString().toLowerCase() ==
          scanned.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    if (matched.isNotEmpty) {
      _selectItem(matched);
    } else {
      _snack(_tr('No product found for barcode: $scanned',
          'Hakuna bidhaa kwa nambari: $scanned'));
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        return SizedBox(
          height: size.height * 0.93,
          width: c.hasBoundedWidth ? c.maxWidth : size.width,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dragHandle(),
                  _header(),
                  const SizedBox(height: 20),
                  _productField(),
                  if (_showProductSuggs) _productSuggestions(),
                  if (_productCtrl.text.isNotEmpty && _selectedItem == null)
                    _addProductHint(),
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
      },
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 20),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99)),
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
            _tr('Quick Sale', 'Mauzo ya Haraka'),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: sc.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(sl,
              style: TextStyle(
                  color: sc, fontSize: 12, fontWeight: FontWeight.w700)),
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
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20)
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
                : IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded,
                        size: 22, color: AppColors.tealAccent),
                    tooltip: _tr('Scan barcode', 'Skani nambari'),
                    onPressed: _scanBarcode,
                  )),
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
          final price =
              parseUnitPrice(item['unitPrice'] ?? item['price'] ?? 0);
          final stock =
              parseStock(item['currentStock'] ?? item['stock'] ?? 0);
          final oos = stock <= 0;
          return Column(
            children: [
              InkWell(
                onTap: oos ? null : () => _selectItem(item),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              (oos ? AppColors.error : AppColors.primary)
                                  .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.inventory_2_rounded,
                            size: 18,
                            color: oos
                                ? AppColors.error
                                : AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: oos
                                        ? AppColors.textMuted
                                        : AppColors.secondary)),
                            Text(
                              oos
                                  ? _tr('Out of Stock',
                                      'Haipatikani Stokuni')
                                  : 'TSh ${price.toStringAsFixed(0)} · $stock ${_tr("in stock", "stokuni")}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: oos
                                      ? AppColors.error
                                      : AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (oos)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color:
                                  AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
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
                const Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: AppColors.border),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tr('Add "${_productCtrl.text}" to inventory',
                      'Ongeza "${_productCtrl.text}" kwa hisa'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
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
                  isUp
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: deltaColor),
              const SizedBox(width: 4),
              Text(deltaLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: deltaColor,
                      fontWeight: FontWeight.w600)),
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
      label = _tr(
          'Out of Stock — cannot sell', 'Imekwisha — haiwezekani kuuza');
    } else if (_maxStock <= 5) {
      color = AppColors.warning;
      label = _tr(
          'Low stock: $_maxStock left', 'Stoku ndogo: $_maxStock zilizobaki');
    } else {
      color = AppColors.success;
      label =
          '$_maxStock ${_tr("available in stock", "zinapatikana stokuni")}';
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
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
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
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20)
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.secondary
                                .withValues(alpha: 0.08),
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
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        if (c.isOrganisation)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary
                                  .withValues(alpha: 0.08),
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
                const Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: AppColors.border),
              ],
            );
          }),
          InkWell(
            onTap: _openAddCustomerSheet,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _tr('Add new customer', 'Ongeza mteja mpya'),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
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
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600),
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
                onTap: () =>
                    setState(() => _payStatus = _PayStatus.partial),
              ),
              const SizedBox(width: 4),
              _PayBtn(
                label: _tr('Not Paid', 'Haijaliwa'),
                icon: Icons.cancel_outlined,
                active: _payStatus == _PayStatus.unpaid,
                activeColor: AppColors.error,
                onTap: () =>
                    setState(() => _payStatus = _PayStatus.unpaid),
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
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
      ],
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
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
              Text(
                display,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                    letterSpacing: -0.5,
                    height: 1.1),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 150,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.secondary))
                : Text(
                    _isOutOfStock
                        ? _tr('Out of Stock', 'Imekwisha')
                        : _tr('Save Sale', 'Hifadhi'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
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
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

// ── Qty widget ─────────────────────────────────────────────────────────────────

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
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500)),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary),
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
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
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
          child: Icon(icon,
              size: 18,
              color: onTap != null ? AppColors.secondary : AppColors.border),
        ),
      ),
    );
  }
}

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
              Icon(icon,
                  size: 16,
                  color: active ? Colors.white : AppColors.textMuted),
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

// ── Add Product Sheet ──────────────────────────────────────────────────────────

class _AddProductSheet extends ConsumerStatefulWidget {
  final String initialName;
  final void Function(Map<String, dynamic>) onAdded;

  const _AddProductSheet(
      {required this.initialName, required this.onAdded});

  @override
  ConsumerState<_AddProductSheet> createState() =>
      _AddProductSheetState();
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
    'pcs','kg','liters','boxes','bottles','bags','meters','sets',
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
    final price =
        double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 1;
    final category = _categoryCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _tr('Enter product name', 'Ingiza jina la bidhaa'))));
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(_tr('Enter a valid price', 'Ingiza bei sahihi'))));
      return;
    }

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final inventoryRef = repo.scopeCollection(
          uid: user.uid,
          context: ctx,
          childCollection: 'inventory_items');

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
          content: Text(_tr(
              'Failed to add product', 'Imeshindikana kuongeza bidhaa'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Material(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Text(
                _tr('Add New Product', 'Ongeza Bidhaa Mpya'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary),
              ),
              const SizedBox(height: 20),
              _field(
                  ctrl: _nameCtrl,
                  label: _tr('Product Name *', 'Jina la Bidhaa *'),
                  icon: Icons.inventory_2_outlined,
                  caps: TextCapitalization.words),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _field(
                      ctrl: _priceCtrl,
                      label: _tr('Unit Price (TSh) *', 'Bei ya Kitengo *'),
                      icon: Icons.sell_outlined,
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true),
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
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
                        prefixIcon:
                            const Icon(Icons.scale_outlined, size: 20),
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
                      items: _units
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _field(
                  ctrl: _skuCtrl,
                  label: _tr('SKU (Optional)', 'SKU (Hiari)'),
                  icon: Icons.tag_outlined,
                  caps: TextCapitalization.characters),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.secondary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.secondary))
                      : Text(
                          _tr('Add to Inventory', 'Ongeza kwa Hisa'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
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
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

// ── Quick Add Customer Sheet ───────────────────────────────────────────────────

class _QuickAddCustomerSheet extends ConsumerStatefulWidget {
  final String initialName;
  final void Function(Customer) onAdded;

  const _QuickAddCustomerSheet(
      {required this.initialName, required this.onAdded});

  @override
  ConsumerState<_QuickAddCustomerSheet> createState() =>
      _QuickAddCustomerSheetState();
}

class _QuickAddCustomerSheetState
    extends ConsumerState<_QuickAddCustomerSheet> {
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
      final customersRef = repo.scopeCollection(
          uid: user.uid, context: ctx, childCollection: 'customers');

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
          content: Text(_tr(
              'Failed to add customer', 'Imeshindikana kuongeza mteja'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Text(
                _tr('New Customer', 'Mteja Mpya'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
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
                      _isOrg
                          ? Icons.business_outlined
                          : Icons.person_outline_rounded,
                      size: 20),
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
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _tr('Phone Number', 'Namba ya Simu'),
                  prefixIcon:
                      const Icon(Icons.phone_outlined, size: 20),
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
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              if (_isOrg) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _tinCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText:
                        _tr('TIN Number (Optional)', 'Namba ya TIN (Hiari)'),
                    hintText: 'e.g. 100-123-456',
                    prefixIcon:
                        const Icon(Icons.numbers_outlined, size: 20),
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
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.secondary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(_tr('Add Customer', 'Ongeza Mteja'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              Icon(icon,
                  size: 15,
                  color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color:
                          active ? Colors.white : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
