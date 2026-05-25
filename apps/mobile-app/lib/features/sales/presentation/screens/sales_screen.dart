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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const _NewSaleSheet(),
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
                          return _InvoiceCard(
                            item: item,
                            onTap: () => Navigator.of(ctx).push(
                              MaterialPageRoute(
                                builder: (_) => InvoiceDetailScreen(
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
          '${_tr("Subtotal", "Jumla Bidhaaa")}: TSh ${subtotal.toStringAsFixed(0)}');
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
      useRootNavigator: true,
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
                    const EdgeInsets.symmetric(horizontal: 14),
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
// NEW SALE SHEET — unified full-invoice slide-up
// ══════════════════════════════════════════════════════════════════════════════

class _ItemEntry {
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  int qty;
  Map<String, dynamic>? selectedItem;
  double? basePrice;
  List<Map<String, dynamic>> suggs = [];
  bool showSuggs = false;

  _ItemEntry({String name = '', String price = ''})
      : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price),
        qty = 1;

  double get unitPrice {
    final t = priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(t) ?? 0;
  }

  double get lineTotal => unitPrice * qty;

  int get maxStock {
    if (selectedItem == null) return 9999;
    return parseStock(
        selectedItem!['currentStock'] ?? selectedItem!['stock'] ?? 9999);
  }

  bool get isOutOfStock => selectedItem != null && maxStock <= 0;

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _NewSaleSheet extends ConsumerStatefulWidget {
  const _NewSaleSheet();

  @override
  ConsumerState<_NewSaleSheet> createState() => _NewSaleSheetState();
}

class _NewSaleSheetState extends ConsumerState<_NewSaleSheet> {
  final _items = <_ItemEntry>[];
  final _customerCtrl = TextEditingController();
  final _amtPaidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _customerFocus = FocusNode();

  Customer? _selectedCustomer;
  List<Customer> _customerSuggs = [];
  bool _showCustomerSuggs = false;
  _PayStatus _payStatus = _PayStatus.paid;
  DateTime? _dueDate;
  bool _vatEnabled = false;
  bool _isSaving = false;

  double get _subtotal => _items.fold(0.0, (s, e) => s + e.lineTotal);
  double get _discountAmt =>
      double.tryParse(_discountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
      0.0;
  double get _vatAmt => _vatEnabled ? (_subtotal - _discountAmt) * 0.18 : 0.0;
  double get _grandTotal =>
      (_subtotal - _discountAmt + _vatAmt).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _addItem();
    _customerCtrl.addListener(_onCustomerChanged);
  }

  @override
  void dispose() {
    _customerCtrl
      ..removeListener(_onCustomerChanged)
      ..dispose();
    _amtPaidCtrl.dispose();
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    _customerFocus.dispose();
    for (final e in _items) {
      e.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    final entry = _ItemEntry();
    entry.nameCtrl.addListener(() => _onItemNameChanged(entry));
    setState(() => _items.add(entry));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    final e = _items[index];
    e.dispose();
    setState(() => _items.removeAt(index));
  }

  void _onItemNameChanged(_ItemEntry entry) {
    final query = entry.nameCtrl.text.trim();
    final inventory = ref.read(inventoryItemListProvider).value ?? [];

    if (entry.selectedItem != null) {
      final name = (entry.selectedItem!['name'] ?? '') as String;
      if (query.toLowerCase() != name.toLowerCase()) {
        entry.selectedItem = null;
        entry.basePrice = null;
      }
    }

    if (query.isEmpty || entry.selectedItem != null) {
      if (entry.showSuggs || entry.suggs.isNotEmpty) {
        setState(() {
          entry.suggs = [];
          entry.showSuggs = false;
        });
      }
      return;
    }

    final matched = inventory
        .where((i) => (i['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .take(5)
        .toList();

    setState(() {
      entry.suggs = matched;
      entry.showSuggs = matched.isNotEmpty;
    });
  }

  void _selectProduct(_ItemEntry entry, Map<String, dynamic> item) {
    final name = (item['name'] ?? '') as String;
    final price = parseUnitPrice(item['unitPrice'] ?? item['price'] ?? 0);
    setState(() {
      entry.selectedItem = item;
      entry.basePrice = price;
      entry.nameCtrl.text = name;
      entry.priceCtrl.text = price > 0 ? price.toStringAsFixed(0) : '';
      entry.suggs = [];
      entry.showSuggs = false;
      entry.qty = 1;
    });
  }

  void _onCustomerChanged() {
    final query = _customerCtrl.text.trim();
    final customers = ref.read(customerListProvider).value ?? [];

    if (_selectedCustomer != null) {
      if (query.toLowerCase() != _selectedCustomer!.name.toLowerCase()) {
        setState(() => _selectedCustomer = null);
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

  void _selectCustomer(Customer c) {
    _customerFocus.unfocus();
    setState(() {
      _selectedCustomer = c;
      _customerCtrl.text = c.name;
      _customerSuggs = [];
      _showCustomerSuggs = false;
    });
  }

  Future<void> _scanBarcode(int index) async {
    final entry = _items[index];
    final scanned = await BarcodeScannerScreen.show(context,
        title: _tr('Scan Product', 'Skani Bidhaaa'));
    if (scanned == null || scanned.isEmpty || !mounted) return;

    final inventory = ref.read(inventoryItemListProvider).value ?? [];
    final matched = inventory.firstWhere(
      (item) =>
          (item['sku'] ?? '').toString().toLowerCase() ==
          scanned.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    if (matched.isNotEmpty) {
      _selectProduct(entry, matched);
    } else {
      _snack(_tr('No product found for barcode: $scanned',
          'Hakuna bidhaaa kwa nambari: $scanned'));
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    for (var i = 0; i < _items.length; i++) {
      final e = _items[i];
      if (e.nameCtrl.text.trim().isEmpty) {
        _snack(_tr(
            'Enter name for item ${i + 1}', 'Ingiza jina la bidhaaa ${i + 1}'));
        return;
      }
      if (e.unitPrice <= 0) {
        _snack(_tr(
            'Enter price for item ${i + 1}', 'Ingiza bei ya bidhaaa ${i + 1}'));
        return;
      }
      if (e.isOutOfStock) {
        _snack(_tr('${e.nameCtrl.text.trim()} is out of stock.',
            '${e.nameCtrl.text.trim()} imekwisha stokuni.'));
        return;
      }
    }

    double amountPaid;
    if (_payStatus == _PayStatus.paid) {
      amountPaid = _grandTotal;
    } else if (_payStatus == _PayStatus.partial) {
      final t = _amtPaidCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      amountPaid = double.tryParse(t) ?? 0;
      if (amountPaid <= 0) {
        _snack(_tr('Enter amount paid.', 'Ingiza kiasi kilicholipwa.'));
        return;
      }
      if (amountPaid >= _grandTotal) amountPaid = _grandTotal;
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
      final invoiceNumber =
          'INV-${now.millisecondsSinceEpoch.toString().substring(6)}';
      final statusStr = _payStatus == _PayStatus.paid
          ? 'paid'
          : _payStatus == _PayStatus.partial
              ? 'partial'
              : 'unpaid';

      final customerName = _selectedCustomer?.name ??
          (_customerCtrl.text.trim().isNotEmpty
              ? _customerCtrl.text.trim()
              : null);

      final itemsData = _items
          .map((e) => {
                'name': e.nameCtrl.text.trim(),
                'qty': e.qty,
                'unitPrice': e.unitPrice,
                'basePrice': e.basePrice ?? e.unitPrice,
                'total': e.lineTotal,
                if (e.selectedItem != null)
                  'inventoryItemId': (e.selectedItem!['id'] as String?) ?? '',
              })
          .toList();

      final notes = _notesCtrl.text.trim();

      await invoicesRef.add({
        'invoiceNumber': invoiceNumber,
        'type': 'invoice',
        'invoiceStatus': statusStr,
        'status': statusStr,
        'customerName': ?customerName,
        if (_selectedCustomer != null) ...{
          'customerId': _selectedCustomer!.id,
          'customerPhone': _selectedCustomer!.phone,
          'isOrganisation': _selectedCustomer!.isOrganisation,
          if (_selectedCustomer!.tinNumber.isNotEmpty)
            'customerTin': _selectedCustomer!.tinNumber,
        },
        'items': itemsData,
        'subtotal': _subtotal,
        'discountAmount': _discountAmt,
        'vatAmount': _vatAmt,
        'amount': _grandTotal,
        'amountPaid': amountPaid,
        if (_dueDate != null) 'dueDate': Timestamp.fromDate(_dueDate!),
        if (notes.isNotEmpty) 'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final e in _items) {
        if (e.selectedItem != null) {
          final itemId = ((e.selectedItem!['id'] as String?) ?? '').trim();
          if (itemId.isNotEmpty) {
            try {
              await repo
                  .scopeCollection(
                      uid: user.uid,
                      context: ctx,
                      childCollection: 'inventory_items')
                  .doc(itemId)
                  .update({
                'currentStock': FieldValue.increment(-e.qty),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } catch (_) {}
          }
        }
      }

      if (_selectedCustomer != null) {
        final outstanding = _grandTotal - amountPaid;
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
              'Failed to save. Try again.', 'Imeshindikana. Jaribu tena.'))));
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.95),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCustomerSection(),
                    const SizedBox(height: 16),
                    _buildItemsSection(),
                    const SizedBox(height: 16),
                    _buildTotalsSection(),
                    const SizedBox(height: 16),
                    _buildPaymentSection(),
                    if (_payStatus != _PayStatus.paid) ...[
                      const SizedBox(height: 12),
                      _buildDueDateRow(),
                    ],
                    const SizedBox(height: 16),
                    _buildNotesField(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99)),
        ),
      );

  Widget _buildHeader() {
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _tr('New Sale', 'Mauzo Mapya'),
              style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary),
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
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr('Customer', 'Mteja'),
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _customerCtrl,
          focusNode: _customerFocus,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: _fieldDec(
            label: _tr('Search customer (optional)', 'Tafuta mteja (hiari)'),
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
        ),
        if (_showCustomerSuggs) _buildCustomerSuggestions(),
      ],
    );
  }

  Widget _buildCustomerSuggestions() {
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
          ..._customerSuggs.map((c) => Column(
                children: [
                  InkWell(
                    onTap: () => _selectCustomer(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                              c.isOrganisation
                                  ? Icons.business_outlined
                                  : Icons.person_outline_rounded,
                              size: 18,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(c.name,
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navyPrimary)),
                          ),
                          if (c.phone.isNotEmpty)
                            Text(c.phone,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: AppColors.textMuted)),
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
              )),
          InkWell(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useSafeArea: true,
              builder: (_) => _QuickAddCustomerSheet(
                initialName: _customerCtrl.text.trim(),
                onAdded: _selectCustomer,
              ),
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.person_add_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(_tr('Add new customer', 'Ongeza mteja mpya'),
                      style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_tr('Items', 'Bidhaaa'),
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
            const Spacer(),
            Text(
                '${_items.length} ${_tr("item", "bidhaaa")}${_items.length != 1 ? "s" : ""}',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _items.length; i++) ...[
          _buildItemRow(i),
          const SizedBox(height: 10),
        ],
        InkWell(
          onTap: _addItem,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(_tr('Add Item', 'Ongeza Bidhaaa'),
                    style: GoogleFonts.dmSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(int index) {
    final entry = _items[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: entry.isOutOfStock
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_tr("Item", "Bidhaaa")} ${index + 1}',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted),
              ),
              const Spacer(),
              if (_items.length > 1)
                GestureDetector(
                  onTap: () => _removeItem(index),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.nameCtrl,
            autofocus: index == 0 && _items.length == 1,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: _fieldDec(
              label: _tr('Product name', 'Jina la bidhaaa'),
              prefix: Icons.inventory_2_outlined,
              suffix: entry.selectedItem != null
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20)
                  : (entry.nameCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            entry.nameCtrl.clear();
                            setState(() {
                              entry.selectedItem = null;
                              entry.basePrice = null;
                              entry.suggs = [];
                              entry.showSuggs = false;
                            });
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded,
                              size: 22, color: AppColors.tealAccent),
                          tooltip: _tr('Scan barcode', 'Skani nambari'),
                          onPressed: () => _scanBarcode(index),
                        )),
            ),
          ),
          if (entry.showSuggs) _buildProductSuggestions(index),
          if (entry.nameCtrl.text.isNotEmpty &&
              entry.selectedItem == null &&
              !entry.showSuggs)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InkWell(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  useSafeArea: true,
                  builder: (_) => _AddProductSheet(
                    initialName: entry.nameCtrl.text.trim(),
                    onAdded: (item) => _selectProduct(entry, item),
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _tr(
                              'Add "${entry.nameCtrl.text}" to inventory',
                              'Ongeza "${entry.nameCtrl.text}" kwa bidhaa'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: entry.priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDec(
                    label: _tr('Price (TSh)', 'Bei (TSh)'),
                    prefix: Icons.payments_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _QtyWidget(
                qty: entry.qty,
                maxQty: entry.maxStock,
                onDecrement:
                    entry.qty > 1 ? () => setState(() => entry.qty--) : null,
                onIncrement:
                    (entry.selectedItem == null || entry.qty < entry.maxStock)
                        ? () => setState(() => entry.qty++)
                        : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (entry.selectedItem != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (entry.isOutOfStock
                            ? AppColors.error
                            : entry.maxStock <= 5
                                ? AppColors.warning
                                : AppColors.success)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.isOutOfStock
                        ? _tr('Out of stock', 'Imekwisha')
                        : '${entry.maxStock} ${_tr("in stock", "stokuni")}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: entry.isOutOfStock
                            ? AppColors.error
                            : entry.maxStock <= 5
                                ? AppColors.warning
                                : AppColors.success),
                  ),
                ),
              const Spacer(),
              if (entry.lineTotal > 0)
                Text(
                  'TSh ${entry.lineTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSuggestions(int index) {
    final entry = _items[index];
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: entry.suggs.asMap().entries.map((e) {
          final isLast = e.key == entry.suggs.length - 1;
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
                onTap: oos ? null : () => _selectProduct(entry, item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_rounded,
                          size: 16,
                          color: oos ? AppColors.error : AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: oos
                                        ? AppColors.textMuted
                                        : AppColors.navyPrimary)),
                            Text(
                              oos
                                  ? _tr('Out of Stock', 'Haipatikani')
                                  : 'TSh ${price.toStringAsFixed(0)} · $stock ${_tr("in stock", "stokuni")}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11,
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
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(_tr('Out', 'Imekwisha'),
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700)),
                        )
                      else
                        const Icon(Icons.north_west_rounded,
                            size: 13, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                    color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _TotalRow(
              label: _tr('Subtotal', 'Jumla Bidhaaa'),
              value: 'TSh ${_subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          TextField(
            controller: _discountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            onChanged: (_) => setState(() {}),
            decoration: _fieldDec(
              label: _tr('Discount (TSh, optional)', 'Punguzo (TSh, hiari)'),
              prefix: Icons.discount_outlined,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                    _tr('VAT (18%)', 'Kodi ya Ongezeko (18%)'),
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),
              Switch.adaptive(
                value: _vatEnabled,
                onChanged: (v) => setState(() => _vatEnabled = v),
                activeThumbColor: AppColors.tealAccent,
                activeTrackColor:
                    AppColors.tealAccent.withValues(alpha: 0.4),
              ),
            ],
          ),
          if (_vatEnabled)
            _TotalRow(
                label: 'VAT (18%)',
                value: 'TSh ${_vatAmt.toStringAsFixed(0)}'),
          const Divider(color: AppColors.border, height: 16),
          Row(
            children: [
              Text(_tr('TOTAL', 'JUMLA KUU'),
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyPrimary)),
              const Spacer(),
              Text(
                'TSh ${_grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                    letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr('Payment Status', 'Hali ya Malipo'),
            style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
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
                label: _tr('Partial', 'Nusu'),
                icon: Icons.timelapse_rounded,
                active: _payStatus == _PayStatus.partial,
                activeColor: AppColors.warning,
                onTap: () =>
                    setState(() => _payStatus = _PayStatus.partial),
              ),
              const SizedBox(width: 4),
              _PayBtn(
                label: _tr('Unpaid', 'Haijaliwa'),
                icon: Icons.cancel_outlined,
                active: _payStatus == _PayStatus.unpaid,
                activeColor: AppColors.error,
                onTap: () =>
                    setState(() => _payStatus = _PayStatus.unpaid),
              ),
            ],
          ),
        ),
        if (_payStatus == _PayStatus.partial) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _amtPaidCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            onChanged: (_) => setState(() {}),
            decoration: _fieldDec(
              label: _tr('Amount Paid (TSh)', 'Kiasi Kilicholipwa (TSh)'),
              prefix: Icons.payments_outlined,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDueDateRow() {
    return GestureDetector(
      onTap: _pickDueDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dueDate != null
                    ? '${_tr("Due", "Malipo")} ${_fmtDate(_dueDate!)}'
                    : _tr(
                        'Set due date (optional)',
                        'Weka tarehe ya malipo (hiari)'),
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: _dueDate != null
                        ? AppColors.navyPrimary
                        : AppColors.textMuted,
                    fontWeight: _dueDate != null
                        ? FontWeight.w600
                        : FontWeight.w400),
              ),
            ),
            if (_dueDate != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesCtrl,
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      decoration: _fieldDec(
        label: _tr('Notes (optional)', 'Maelezo (hiari)'),
        prefix: Icons.notes_outlined,
      ),
    );
  }

  Widget _buildSaveButton() {
    final hasOutOfStock = _items.any((e) => e.isOutOfStock);
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: (_isSaving || hasOutOfStock) ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.navyPrimary,
          disabledBackgroundColor: hasOutOfStock
              ? AppColors.error.withValues(alpha: 0.6)
              : AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.navyPrimary))
            : Text(
                hasOutOfStock
                    ? _tr('Item out of stock', 'Bidhaaa imekwisha')
                    : _tr('Save Sale', 'Hifadhi Mauzo'),
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  InputDecoration _fieldDec({
    required String label,
    required IconData prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefix, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
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

// ── Totals row ─────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TotalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
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
              _tr('Enter product name', 'Ingiza jina la bidhaaa'))));
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
              'Failed to add product', 'Imeshindikana kuongeza bidhaaa'))));
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
                _tr('Add New Product', 'Ongeza Bidhaaa Mpya'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary),
              ),
              const SizedBox(height: 20),
              _field(
                  ctrl: _nameCtrl,
                  label: _tr('Product Name *', 'Jina la Bidhaaa *'),
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
                      value: _selectedUnit,
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
                          _tr('Add to Inventory', 'Ongeza kwa Bidhaa'),
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
