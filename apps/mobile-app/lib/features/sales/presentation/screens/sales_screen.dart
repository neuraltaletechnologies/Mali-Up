import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/sentry_metrics_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/online_guard.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/barcode_scanner_screen.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/nav_aware_fab.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
import '../../../../shared/widgets/validation_banner.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../customer/domain/models/customer.dart';
import '../../../customer/presentation/widgets/add_customer_dialog.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/domain/models/debt.dart';
import '../../../finance/data/payment_account_service.dart';
import '../../../finance/domain/models/cash_account.dart';
import '../../../finance/domain/payment_method_accounts.dart';
import '../../../finance/presentation/widgets/payment_account_chips.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../invoice/domain/models/invoice.dart';
import '../../../invoice/presentation/providers/invoice_providers.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../../rbac/data/rbac_providers.dart';
import '../../data/invoice_local_mirror.dart';
import '../../data/invoice_payment_service.dart';
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

String _fmtAmt(double v) {
  if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
  return 'TSh ${v.toStringAsFixed(0)}';
}

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
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
  bool _searchExpanded = false;
  String _query = '';

  int get _activeFilters => _filter != _SalesFilter.all ? 1 : 0;

  @override
  void dispose() {
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> items) {
    var list = items.where((i) => _matchesFilter(i, _filter)).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((i) {
        final cn = (i['customerName'] ?? '').toString().toLowerCase();
        final inv = (i['invoiceNumber'] ?? i['id'] ?? '')
            .toString()
            .toLowerCase();
        return cn.contains(q) || inv.contains(q);
      }).toList();
    }
    return list;
  }

  Map<_SalesFilter, int> _buildCounts(List<Map<String, dynamic>> items) {
    return {
      _SalesFilter.all: items.length,
      _SalesFilter.paid: items
          .where((i) => _normalizeStatus(i) == 'paid')
          .length,
      _SalesFilter.sent: items
          .where((i) => _matchesFilter(i, _SalesFilter.sent))
          .length,
      _SalesFilter.overdue: items.where(_isOverdue).length,
      _SalesFilter.draft: items
          .where((i) => _normalizeStatus(i) == 'draft')
          .length,
      _SalesFilter.cancelled: items
          .where((i) => _normalizeStatus(i) == 'cancelled')
          .length,
    };
  }

  Future<void> _deleteSale(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> sale,
  ) async {
    final id = (sale['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) return;
    final saleNo = (sale['invoiceNumber'] ?? sale['id'] ?? '').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _tr('Delete Invoice?', 'Futa Ankara?'),
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: AppColors.navyPrimary,
          ),
        ),
        content: Text(
          _tr(
            'Delete $saleNo? This cannot be undone.',
            'Futa $saleNo? Haiwezi kurejeshwa.',
          ),
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              _tr('Delete', 'Futa'),
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final scope = await resolveSalesScope(ref);
      if (scope == null) return;
      // Offline-first: soft-delete locally + queue the remote delete. A direct
      // Firestore delete would leave a stale row in the local database.
      await ref.read(invoiceRepositoryProvider).delete(id);
      unawaited(
        AuditLogService().logSaleAction(
          ownerUid: scope.ownerUid,
          businessId: scope.businessId,
          performedByUid: scope.userUid,
          performedByRole: ref.read(currentUserRoleProvider),
          action: AuditLogService.invoiceDeleted,
          invoiceId: id,
          invoiceNumber: saleNo,
        ),
      );
      unawaited(ref.read(syncServiceProvider).syncNow());
    } catch (e, st) {
      unawaited(Sentry.captureException(e, stackTrace: st));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              _tr(
                'Could not delete invoice. Please try again.',
                'Imeshindwa kufuta ankara. Jaribu tena.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showNewSaleSheet(BuildContext ctx) async {
    final plan = await ref.read(planStatusProvider.future);
    if (!ctx.mounted) return;
    if (!plan.canCreateInvoice) {
      await showUpgradeSheet(
        ctx,
        currentStatus: plan,
        triggerReason: _tr(
          'You\'ve reached the ${plan.limits.monthlyInvoices}-invoice monthly limit.',
          'Umefika kikomo cha ankara ${plan.limits.monthlyInvoices} kwa mwezi.',
        ),
      );
      return;
    }
    if (!ctx.mounted) return;
    final saleReceipt = await showAppSheet<Map<String, dynamic>>(
      ctx,
      maxHeightFactor: 0.92,
      builder: (_) => const _NewSaleSheet(),
    );
    if (saleReceipt == null || !ctx.mounted) return;

    unawaited(HapticFeedback.heavyImpact());
    await showGeneralDialog<void>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: _tr('Close receipt', 'Funga risiti'),
      barrierColor: AppColors.navyPrimary.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) =>
          _PaperSaleReceiptNotice(saleData: saleReceipt, ref: ref),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesInvoiceListProvider);
    final ps = ref.watch(permissionServiceProvider);

    return Scaffold(
      floatingActionButton: !ps.canCreateSale
          ? null
          : NavAwareFab(
              child: Builder(
                builder: (ctx) => FloatingActionButton.extended(
                  onPressed: () => _showNewSaleSheet(ctx),
                  backgroundColor: AppColors.yellowBrand,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 3,
                  icon: Icon(Icons.add_rounded, size: 22),
                  label: Text(
                    _tr('New Sale', 'Mauzo Mapya'),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ),
              ),
            ),
      body: salesAsync.when(
        loading: () => const SalesPageSkeleton(),
        error: (_, _) => Center(
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: _tr('Could not load sales', 'Imeshindikana kupakia mauzo'),
            subtitle: _tr(
              'Check your connection and try again.',
              'Angalia muunganiko wako na ujaribu tena.',
            ),
          ),
        ),
        data: (items) {
          final counts = _buildCounts(items);
          final filtered = _applyFilters(items);

          final today = DateTime.now();
          final todayRevenue = items
              .where((i) {
                final d = readTimestamp(i['createdAt'] ?? i['date']);
                return d != null &&
                    d.year == today.year &&
                    d.month == today.month &&
                    d.day == today.day;
              })
              .fold<double>(0, (s, i) => s + readInvoiceTotal(i));

          final pendingTotal = items
              .where((i) => _matchesFilter(i, _SalesFilter.sent))
              .fold<double>(
                0,
                (s, i) =>
                    s +
                    (readInvoiceTotal(i) - parseNumericAmount(i['amountPaid']))
                        .clamp(0, double.infinity),
              );

          final overdueCount = counts[_SalesFilter.overdue] ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SalesDarkHeader(
                todayRevenue: todayRevenue,
                pendingTotal: pendingTotal,
                overdueCount: overdueCount,
                searchExpanded: _searchExpanded,
                activeFilters: _activeFilters,
                onSearchToggle: () => setState(() {
                  _searchExpanded = !_searchExpanded;
                  if (!_searchExpanded) _query = '';
                }),
                onSearchChanged: (v) => setState(() => _query = v.trim()),
                onFilterTap: () => showAppSheet<void>(
                  context,
                  builder: (_) => _SalesFilterSheet(
                    selected: _filter,
                    onApply: (f) => setState(() => _filter = f),
                  ),
                ),
              ),
              const SizedBox(height: _SalesDarkHeader._pillHalf + 8),
              if (_filter != _SalesFilter.all)
                _ActiveSalesFilterChip(
                  filter: _filter,
                  onRemove: () => setState(() => _filter = _SalesFilter.all),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptySalesState(filter: _filter)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 104),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          return ListSwipeCard(
                            itemKey: ValueKey(item['id'] ?? i),
                            onEdit: () => Navigator.of(ctx).push(
                              MaterialPageRoute(
                                builder: (_) => InvoiceDetailScreen(
                                  invoice: Map<String, dynamic>.from(item),
                                ),
                              ),
                            ),
                            onDelete: ps.canDeleteSale
                                ? () => _deleteSale(ctx, ref, item)
                                : null,
                            child: _InvoiceCard(
                              item: item,
                              isLast: i == filtered.length - 1,
                              onTap: () => showAppSheet<void>(
                                ctx,
                                builder: (_) => _SaleInfoSheet(
                                  item: Map<String, dynamic>.from(item),
                                ),
                              ),
                              onReceiptAction: () => _openReceiptActions(
                                context: ctx,
                                sale: item,
                                ref: ref,
                              ),
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
    required String ownerUid,
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
        final doc = await fs.collection('businesses').doc(businessId).get();
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
    final invoiceNo = (sale['invoiceNumber'] ?? sale['id'] ?? '-').toString();
    final rawCustomer = (sale['customerName'] ?? '').toString().trim();
    final customer = rawCustomer.isNotEmpty
        ? rawCustomer
        : _tr('Walk-in', 'Mteja wa kawaida');
    final createdAt = readTimestamp(sale['createdAt'] ?? sale['date']);
    final dueDate = readTimestamp(sale['dueDate']);
    final amount = readInvoiceTotal(sale);
    final amountPaid = parseNumericAmount(sale['amountPaid']);
    final outstanding = (amount - amountPaid).clamp(0, amount);
    final items =
        (sale['items'] as List?)?.whereType<Map>().toList() ?? const [];
    final isQuotation =
        (sale['type'] ?? '').toString().toLowerCase() == 'quotation';
    final docType = isQuotation
        ? _tr('QUOTATION', 'NUKUU')
        : _tr('INVOICE', 'ANKARA');
    final payMethod = (sale['paymentMethod'] ?? '').toString().toLowerCase();

    const line = '────────────────────────────';
    const dline = '════════════════════════════';

    final b = StringBuffer();
    b.writeln('*$docType*');
    b.writeln(dline);
    b.writeln('*${businessName.toUpperCase()}*');
    b.writeln(dline);

    if (createdAt != null) {
      b.writeln(
        '*${_tr("Date", "Tarehe")}:* ${_fmtDate(createdAt)} ${createdAt.year}',
      );
    }
    if (dueDate != null && !isQuotation) {
      b.writeln(
        '*${_tr("Due", "Malipo")}:* ${_fmtDate(dueDate)} ${dueDate.year}',
      );
    }
    b.writeln('*${_tr("No", "Na")}.:* $invoiceNo');
    b.writeln('*${_tr("Customer", "Mteja")}:* $customer');
    b.writeln(line);

    // Items sold below their catalog price print at the catalog price with
    // the difference folded into the discount line — the total is unchanged.
    // Prices raised above the catalog price stay business-side: the receipt
    // simply shows the price as charged.
    var itemDiscount = 0.0;
    if (items.isNotEmpty) {
      b.writeln('*${_tr("ITEMS", "BIDHAA")}:*');
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        var name = (item['name'] ?? item['productName'] ?? '')
            .toString()
            .trim();
        if (name.isEmpty) name = '-';
        final qty = (item['qty'] ?? item['quantity'] ?? 1).toString();
        final qtyNum = parseNumericAmount(item['qty'] ?? item['quantity'] ?? 1);
        var unitPrice = parseNumericAmount(item['unitPrice']);
        var total = parseNumericAmount(item['total']);
        final basePrice = parseNumericAmount(item['basePrice']);
        if (unitPrice > 0 && basePrice > unitPrice) {
          itemDiscount += (basePrice - unitPrice) * qtyNum;
          unitPrice = basePrice;
          total = basePrice * qtyNum;
        }
        b.writeln(
          '${i + 1}. $name\n   $qty × TSh ${unitPrice.toStringAsFixed(0)} = *TSh ${total.toStringAsFixed(0)}*',
        );
      }
      b.writeln(line);
    }

    final subtotal =
        (parseNumericAmount(sale['subtotal']) > 0
            ? parseNumericAmount(sale['subtotal'])
            : amount) +
        itemDiscount;
    final discount = parseNumericAmount(sale['discountAmount']) + itemDiscount;
    final vat = parseNumericAmount(sale['vatAmount']);

    if (discount > 0) {
      b.writeln(
        '${_tr("Subtotal", "Jumla Bidhaaa")}: TSh ${subtotal.toStringAsFixed(0)}',
      );
      b.writeln(
        '${_tr("Discount", "Punguzo")}: -TSh ${discount.toStringAsFixed(0)}',
      );
    }
    if (vat > 0) {
      b.writeln('VAT (18%): TSh ${vat.toStringAsFixed(0)}');
    }
    b.writeln(
      '*${_tr("TOTAL", "JUMLA KUU")}: TSh ${amount.toStringAsFixed(0)}*',
    );

    if (!isQuotation) {
      b.writeln(
        '*${_tr("Paid", "Imelipwa")}:* TSh ${amountPaid.toStringAsFixed(0)}',
      );
      if (outstanding > 0) {
        b.writeln(
          '*${_tr("Balance Due", "Baki")}:* TSh ${outstanding.toStringAsFixed(0)}',
        );
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
    final scope = await resolveSalesScope(ref);
    if (scope == null) return;
    final meta = await _loadReceiptMeta(
      uid: scope.userUid,
      ownerUid: scope.ownerUid,
      businessId: scope.businessId,
    );
    final receipt = _buildReceiptText(
      sale: sale,
      businessName: meta['businessName'] ?? 'Business',
      printedBy: meta['printedBy'] ?? 'User',
    );
    SentryMetricsService.invoicePrinted(surface: 'receipt_sheet');
    if (!context.mounted) return;

    await showAppSheet<void>(
      context,
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
                  color: AppColors.navyPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                (sale['invoiceNumber'] ?? sale['id'] ?? '').toString(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const Divider(height: 20, color: AppColors.border),
              _ReceiptAction(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                label: _tr('WhatsApp', 'WhatsApp'),
                onTap: () async {
                  final phone = normalizeWhatsAppPhone(
                    (sale['customerPhone'] ?? '').toString(),
                  );
                  final url = phone.isEmpty
                      ? 'https://wa.me/?text=${Uri.encodeComponent(receipt)}'
                      : 'https://wa.me/$phone?text=${Uri.encodeComponent(receipt)}';
                  await _launchShare(ctx, Uri.parse(url), external: true);
                },
              ),
              _ReceiptAction(
                icon: Icons.email_outlined,
                iconColor: AppColors.tealAccent,
                label: _tr('Email', 'Barua pepe'),
                onTap: () async {
                  final plain = receipt.replaceAll(RegExp(r'\*|_'), '');
                  // Built by hand: Uri(queryParameters:) form-encodes spaces
                  // as '+', which email clients render literally in the body.
                  final subject = Uri.encodeComponent(
                    'Invoice ${sale['invoiceNumber'] ?? ''}',
                  );
                  final body = Uri.encodeComponent(plain);
                  await _launchShare(
                    ctx,
                    Uri.parse('mailto:?subject=$subject&body=$body'),
                  );
                },
              ),
              _ReceiptAction(
                icon: Icons.sms_outlined,
                iconColor: AppColors.warning,
                label: _tr('SMS', 'SMS'),
                onTap: () async {
                  final plain = receipt.replaceAll(RegExp(r'\*|_'), '');
                  await _launchShare(
                    ctx,
                    Uri.parse('sms:?body=${Uri.encodeComponent(plain)}'),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_tr('Copied.', 'Imenakiliwa.')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Launches a share/compose URL, surfacing a snackbar instead of an
  /// unhandled exception when no app on the device can handle it.
  static Future<void> _launchShare(
    BuildContext context,
    Uri uri, {
    bool external = false,
  }) async {
    try {
      final ok = await launchUrl(
        uri,
        mode: external
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
      if (!ok) throw Exception('no handler');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'No app available to open this share option.',
              'Hakuna programu ya kufungua chaguo hili la kushiriki.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Stats Card ─────────────────────────────────────────────────────────────────

// ── Dark Header ────────────────────────────────────────────────────────────────

class _SalesDarkHeader extends StatefulWidget {
  static const double _pillHalf = 22.0;

  final double todayRevenue;
  final double pendingTotal;
  final int overdueCount;
  final bool searchExpanded;
  final int activeFilters;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;

  const _SalesDarkHeader({
    required this.todayRevenue,
    required this.pendingTotal,
    required this.overdueCount,
    required this.searchExpanded,
    required this.activeFilters,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  State<_SalesDarkHeader> createState() => _SalesDarkHeaderState();
}

class _SalesDarkHeaderState extends State<_SalesDarkHeader> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_SalesDarkHeader old) {
    super.didUpdateWidget(old);
    if (!widget.searchExpanded && old.searchExpanded) {
      _ctrl.clear();
      _focus.unfocus();
    } else if (widget.searchExpanded && !old.searchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Color get _alertDotColor {
    if (widget.overdueCount > 0) return AppColors.error;
    if (widget.activeFilters > 0) return AppColors.yellowBrand;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            top + AppTheme.headerTopPadding,
            20,
            _SalesDarkHeader._pillHalf + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('Sales', 'Mauzo'),
                      style: GoogleFonts.dmSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Search icon
                  GestureDetector(
                    onTap: widget.onSearchToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.searchExpanded
                            ? AppColors.yellowBrand.withValues(alpha: 0.18)
                            : Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.searchExpanded
                              ? AppColors.yellowBrand
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        widget.searchExpanded
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: widget.searchExpanded
                            ? AppColors.yellowBrand
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter icon
                  GestureDetector(
                    onTap: widget.onFilterTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.activeFilters > 0
                                ? AppColors.yellowBrand.withValues(alpha: 0.18)
                                : Colors.white12,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.activeFilters > 0
                                  ? AppColors.yellowBrand
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: widget.activeFilters > 0
                                ? AppColors.yellowBrand
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                        if (_alertDotColor != Colors.transparent)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _alertDotColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.navyPrimary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: widget.searchExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          onChanged: widget.onSearchChanged,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: _tr(
                              'Customer name or invoice #…',
                              'Jina la mteja au namba ya ankara…',
                            ),
                            hintStyle: GoogleFonts.dmSans(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        // Stats pill
        Positioned(
          bottom: -_SalesDarkHeader._pillHalf,
          left: 24,
          right: 24,
          child: Container(
            height: _SalesDarkHeader._pillHalf * 2,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(_SalesDarkHeader._pillHalf),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyPrimary.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PillStat(
                  value: _fmtAmt(widget.todayRevenue),
                  label: _tr('Today', 'Leo'),
                  valueColor: AppColors.tealAccent,
                ),
                const _PillDivider(),
                _PillStat(
                  value: _fmtAmt(widget.pendingTotal),
                  label: _tr('Pending', 'Inasubiri'),
                  valueColor: widget.pendingTotal > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
                const _PillDivider(),
                _PillStat(
                  value: widget.overdueCount.toString(),
                  label: _tr('Overdue', 'Imechelewa'),
                  valueColor: widget.overdueCount > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PillStat extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const _PillStat({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppColors.border);
  }
}

// ── Filter Sheet ───────────────────────────────────────────────────────────────

class _SalesFilterSheet extends StatefulWidget {
  final _SalesFilter selected;
  final ValueChanged<_SalesFilter> onApply;

  const _SalesFilterSheet({required this.selected, required this.onApply});

  @override
  State<_SalesFilterSheet> createState() => _SalesFilterSheetState();
}

class _SalesFilterSheetState extends State<_SalesFilterSheet> {
  late _SalesFilter _pick;

  @override
  void initState() {
    super.initState();
    _pick = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 16),
            _SheetSectionLabel(_tr('Status', 'Hali')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _SalesFilter.values
                  .map(
                    (f) => _SortChip(
                      label: f.label,
                      selected: _pick == f,
                      onTap: () => setState(() => _pick = f),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_pick);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _tr('Apply', 'Tumia'),
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
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navyPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Active filter chip ─────────────────────────────────────────────────────────

class _ActiveSalesFilterChip extends StatelessWidget {
  final _SalesFilter filter;
  final VoidCallback onRemove;
  const _ActiveSalesFilterChip({required this.filter, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.navyPrimary.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.navyPrimary,
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

// ── Invoice Card ───────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onReceiptAction;

  const _InvoiceCard({
    required this.item,
    required this.isLast,
    required this.onTap,
    required this.onReceiptAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = _normalizeStatus(item);
    final overdue = _isOverdue(item);

    // Drift-backed maps always carry the key with '' (never null), so an
    // empty check — not a null check — decides the walk-in fallback.
    final rawCustomer = (item['customerName'] ?? '').toString().trim();
    final customer = rawCustomer.isNotEmpty
        ? rawCustomer
        : _tr('Walk-in', 'Mteja wa Kawaida');
    final amount = readInvoiceTotal(item);
    final amountPaid = parseNumericAmount(item['amountPaid']);
    final outstanding = (amount - amountPaid).clamp(0.0, amount);
    final date = readTimestamp(item['createdAt'] ?? item['date']);
    final dueDate = readTimestamp(item['dueDate']);
    // Quick sales store 'items' (name); the full editor stores
    // 'lineItems' (productName) — accept both shapes.
    final items = ((item['items'] as List?)?.isNotEmpty ?? false)
        ? item['items'] as List
        : (item['lineItems'] as List?) ?? const [];
    final itemCount = items.length;

    // Main heading: customer name if set, otherwise first product name
    final String cardTitle;
    if (rawCustomer.isNotEmpty) {
      cardTitle = customer;
    } else if (items.isNotEmpty) {
      final first = items.first;
      final firstName = first is Map
          ? (first['name'] ?? first['productName'] ?? '').toString().trim()
          : '';
      cardTitle = firstName.isNotEmpty
          ? (itemCount > 1
                ? '$firstName & ${itemCount - 1} ${_tr('more', 'zaidi')}'
                : firstName)
          : customer;
    } else {
      cardTitle = customer;
    }

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
        _ =>
          isQuotation
              ? (
                  bg: AppColors.infoBg,
                  text: AppColors.tealAccent,
                  label: _tr('Quotation', 'Nukuu'),
                  icon: Icons.description_outlined,
                )
              : (
                  bg: AppColors.errorBg,
                  text: AppColors.error,
                  label: _tr('Unpaid', 'Haijalipwa'),
                  icon: Icons.hourglass_empty_rounded,
                ),
      };
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: [customer] left | [amount] right
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          cardTitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isQuotation) ...[
                        SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _tr('QUO', 'NUK'),
                            style: GoogleFonts.dmSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmtAmt(amount),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Row 2: date + item count | status pill + share button
            Row(
              children: [
                Text(
                  _fmtDate(date),
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
                if (itemCount > 0) ...[
                  SizedBox(width: 5),
                  Text(
                    '· $itemCount ${_tr(itemCount == 1 ? "item" : "items", itemCount == 1 ? "kitu" : "vitu")}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: chipData.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chipData.icon, size: 9, color: chipData.text),
                      SizedBox(width: 3),
                      Text(
                        chipData.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: chipData.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onReceiptAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.ios_share_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          _tr('Share', 'Shiriki'),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
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
              SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 11,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${_tr("Due was", "Malipo ilikuwa")} ${_fmtDate(dueDate)} ${dueDate.year}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else if (status == 'partial' && outstanding > 0) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 11,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${_tr("Balance due", "Baki")}: ${_fmtAmt(outstanding)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            if (!isLast)
              const Padding(
                padding: EdgeInsets.only(top: 9),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              ),
          ],
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
    final (IconData icon, String title, String subtitle)
    content = switch (filter) {
      _SalesFilter.paid => (
        Icons.check_circle_outline_rounded,
        _tr('All paid up', 'Yote yalilipwa'),
        _tr(
          'Paid invoices will show up here once customers settle.',
          'Ankara zilizolipwa zitaonekana hapa.',
        ),
      ),
      _SalesFilter.overdue => (
        Icons.hourglass_empty_rounded,
        _tr('Nothing overdue — nice!', 'Hakuna zilizochelewa — vizuri!'),
        _tr('All your invoices are on track.', 'Ankara zako zote ziko sawa.'),
      ),
      _SalesFilter.draft => (
        Icons.edit_note_rounded,
        _tr('No drafts saved', 'Hakuna rasimu zilizohifadhiwa'),
        _tr(
          'Unfinished sales will be saved here as drafts.',
          'Mauzo ambayo hayajakamilika yatahifadhiwa hapa kama rasimu.',
        ),
      ),
      _ => (
        Icons.receipt_long_outlined,
        _tr('Your first sale is waiting!', 'Mauzo yako ya kwanza yanangoja!'),
        _tr(
          'Tap New Sale to record a payment.',
          'Bonyeza Mauzo Mapya kurekodi malipo.',
        ),
      ),
    };

    return EmptyState(
      icon: content.$1,
      title: content.$2,
      subtitle: content.$3,
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
            SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.navyPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NEW SALE SHEET — unified full-invoice slide-up
// ══════════════════════════════════════════════════════════════════════════════

/// "12%" / "8.5%" — one decimal below 10% so small edits stay visible.
String _pctText(double pct) {
  final a = pct.abs();
  final s = a >= 10
      ? a.toStringAsFixed(0)
      : a.toStringAsFixed(1).replaceAll('.0', '');
  return '$s%';
}

class _ItemEntry {
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController qtyCtrl;
  int _qty;
  Map<String, dynamic>? selectedItem;
  double? basePrice;
  List<Map<String, dynamic>> suggs = [];
  bool showSuggs = false;

  _ItemEntry({String name = '', String price = ''})
    : nameCtrl = TextEditingController(text: name),
      priceCtrl = TextEditingController(text: price),
      qtyCtrl = TextEditingController(text: '1'),
      _qty = 1;

  int get qty => _qty;
  set qty(int v) {
    _qty = v;
    final s = '$v';
    if (qtyCtrl.text != s) qtyCtrl.text = s;
  }

  double get unitPrice {
    final t = priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(t) ?? 0;
  }

  double get lineTotal => unitPrice * qty;

  /// % change of the entered price vs the catalog price. Negative = sold
  /// below list (an automatic discount, surfaced on the receipt); positive =
  /// a markup that stays business-side only. Null when there is no catalog
  /// price to compare against or the price is untouched.
  double? get priceChangePct {
    final base = basePrice;
    if (base == null || base <= 0 || unitPrice <= 0) return null;
    final pct = ((unitPrice - base) / base) * 100;
    return pct.abs() < 0.05 ? null : pct;
  }

  double get lineDiscount {
    final base = basePrice;
    if (base == null || unitPrice <= 0 || unitPrice >= base) return 0;
    return (base - unitPrice) * qty;
  }

  double get lineMarkup {
    final base = basePrice;
    if (base == null || base <= 0 || unitPrice <= base) return 0;
    return (unitPrice - base) * qty;
  }

  bool get _isService => (selectedItem?['productType'] as String?) == 'service';

  int get maxStock {
    if (selectedItem == null) return 9999;
    if (_isService) return 9999;
    return parseStock(
      selectedItem!['currentStock'] ?? selectedItem!['stock'] ?? 9999,
    );
  }

  bool get isOutOfStock => selectedItem != null && !_isService && maxStock <= 0;

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
  }
}

/// Where a validation error from [_NewSaleSheetState._save] belongs, so it
/// can render right next to the field it's actually about instead of a
/// single message far away from what needs fixing.
enum _ErrorField { items, customer, payment, general }

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
  CashAccount? _selectedAccount;
  final _mpesaRefCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _vatEnabled = false;
  bool _adjustmentsExpanded = false;
  bool _detailsExpanded = false;
  bool _isSaving = false;
  // Surfaced as an inline banner next to the field it's about, rather than
  // a SnackBar: this sheet is pushed on the root Navigator and covers
  // ~80-95% of the screen height, so a SnackBar from the underlying
  // Scaffold renders behind it and is never seen by the user.
  String? _errorMsg;
  _ErrorField _errorField = _ErrorField.general;

  /// Value written to the invoice's `paymentMethod` field. Built-in channels
  /// keep the exact strings quick sale has always written ('bank_transfer'
  /// for Bank, matching the historical firestoreKey); a custom account's
  /// name is used instead so reports group by it meaningfully.
  String get _paymentMethodValue {
    final acc = _selectedAccount;
    if (acc == null) return '';
    return switch (acc.id) {
      PaymentMethodAccounts.cashId => 'cash',
      PaymentMethodAccounts.mpesaId => 'mpesa',
      PaymentMethodAccounts.bankId => 'bank_transfer',
      PaymentMethodAccounts.cardId => 'card',
      _ => acc.name,
    };
  }

  double get _subtotal => _items.fold(0.0, (s, e) => s + e.lineTotal);
  // Discount can never exceed the subtotal — otherwise VAT (computed on the
  // discounted base) and the grand total would go negative.
  double get _discountAmt {
    final raw =
        double.tryParse(
          _discountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    return raw.clamp(0.0, _subtotal);
  }

  double get _vatAmt => _vatEnabled ? (_subtotal - _discountAmt) * 0.18 : 0.0;
  double get _grandTotal =>
      (_subtotal - _discountAmt + _vatAmt).clamp(0.0, double.infinity);

  // Manual price edits vs the catalog price. Both are already baked into the
  // unit prices (so they never adjust the totals above) — they are recorded
  // so the receipt can surface below-list sales as a discount and reports can
  // see markups, which stay business-side only.
  double get _itemPriceDiscount =>
      _items.fold(0.0, (s, e) => s + e.lineDiscount);
  double get _itemPriceMarkup => _items.fold(0.0, (s, e) => s + e.lineMarkup);

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
    _mpesaRefCtrl.dispose();
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

    final q = query.toLowerCase();
    bool fieldMatches(Map<String, dynamic> i, String key) =>
        (i[key] ?? '').toString().toLowerCase().contains(q);

    // Search across name, SKU, barcode and category — name matches first.
    final byName = <Map<String, dynamic>>[];
    final byOther = <Map<String, dynamic>>[];
    for (final i in inventory) {
      if (fieldMatches(i, 'name')) {
        byName.add(i);
      } else if (fieldMatches(i, 'sku') ||
          fieldMatches(i, 'barcode') ||
          fieldMatches(i, 'category')) {
        byOther.add(i);
      }
      if (byName.length >= 5) break;
    }
    final matched = [...byName, ...byOther].take(5).toList();

    setState(() {
      entry.suggs = matched;
      entry.showSuggs = matched.isNotEmpty;
    });
  }

  List<Map<String, dynamic>> _recentlySoldProducts() {
    final inventory = ref.read(inventoryItemListProvider).value ?? [];
    if (inventory.isEmpty) return const [];
    final sales = ref.read(salesInvoiceListProvider).value ?? [];
    final inventoryByName = <String, Map<String, dynamic>>{
      for (final item in inventory)
        (item['name'] ?? '').toString().toLowerCase(): item,
    };
    final recent = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final sale in sales.take(30)) {
      final items = (sale['items'] as List?) ?? const [];
      for (final soldItem in items.whereType<Map>()) {
        final name = (soldItem['name'] ?? '').toString().toLowerCase();
        final inventoryItem = inventoryByName[name];
        if (name.isEmpty || inventoryItem == null || !seen.add(name)) continue;
        recent.add(inventoryItem);
        if (recent.length == 3) return recent;
      }
    }
    return recent;
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
        .where(
          (c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.phone.contains(query),
        )
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
      if (_errorField == _ErrorField.customer) _errorMsg = null;
    });
  }

  /// Opens the continuous POS scanner. Each successful scan auto-adds an
  /// item row (or increments qty if the product is already in the list).
  /// True when the scanned code matches the product's barcode or SKU.
  static bool _codeMatches(Map<String, dynamic> item, String code) {
    final c = code.toLowerCase();
    return (item['barcode'] ?? '').toString().toLowerCase() == c ||
        (item['sku'] ?? '').toString().toLowerCase() == c;
  }

  Future<void> _openPosScanner() async {
    final inventory = ref.read(inventoryItemListProvider).value ?? [];

    final results = await PosScannerScreen.show(
      context,
      title: _tr('Scan Items', 'Skani Bidhaa'),
      onScanned: (barcode) async {
        final matched = inventory.firstWhere(
          (item) => _codeMatches(item, barcode),
          orElse: () => <String, dynamic>{},
        );
        if (matched.isEmpty) return null;
        final name = (matched['name'] ?? '').toString();
        final price = parseUnitPrice(
          matched['unitPrice'] ?? matched['price'] ?? 0,
        );
        return PosCartEntry(barcode: barcode, name: name, price: price);
      },
    );

    if (!mounted || results.isEmpty) return;

    // Remove any blank placeholder items first.
    final toRemove = _items
        .where((e) => e.nameCtrl.text.trim().isEmpty && e.selectedItem == null)
        .toList();
    for (final e in toRemove) {
      e.dispose();
      _items.remove(e);
    }

    // Merge scanner results into the items list, never exceeding stock.
    for (final scanned in results) {
      final matchIdx = _items.indexWhere(
        (e) =>
            e.selectedItem != null &&
            _codeMatches(e.selectedItem!, scanned.barcode),
      );

      if (matchIdx >= 0) {
        final entry = _items[matchIdx];
        final cap = entry.maxStock > 0 ? entry.maxStock : 1;
        entry.qty = (entry.qty + scanned.qty).clamp(1, cap);
      } else {
        final inv = inventory.firstWhere(
          (item) => _codeMatches(item, scanned.barcode),
          orElse: () => <String, dynamic>{},
        );
        if (inv.isNotEmpty) {
          final newEntry = _ItemEntry();
          newEntry.nameCtrl.addListener(() => _onItemNameChanged(newEntry));
          _selectProduct(newEntry, inv);
          final cap = newEntry.maxStock > 0 ? newEntry.maxStock : 1;
          newEntry.qty = scanned.qty.clamp(1, cap);
          _items.add(newEntry);
        }
      }
    }

    if (_items.isEmpty) _addItem();
    setState(() {});
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
    if (_errorMsg != null) setState(() => _errorMsg = null);
    for (var i = 0; i < _items.length; i++) {
      final e = _items[i];
      final name = e.nameCtrl.text.trim();
      if (name.isEmpty) {
        _snack(
          _tr(
            'Enter name for item ${i + 1}',
            'Ingiza jina la bidhaaa ${i + 1}',
          ),
        );
        return;
      }
      if (e.unitPrice <= 0) {
        _snack(
          _tr(
            'Enter price for item ${i + 1}',
            'Ingiza bei ya bidhaaa ${i + 1}',
          ),
        );
        return;
      }
      if (e.isOutOfStock) {
        _snack(_tr('$name is out of stock.', '$name imekwisha stokuni.'));
        return;
      }
      if (e.selectedItem != null && e.qty > e.maxStock) {
        _snack(
          _tr(
            'Only ${e.maxStock} of $name in stock.',
            'Kuna ${e.maxStock} tu za $name stokuni.',
          ),
        );
        return;
      }
    }

    // Require a customer when payment is not fully settled
    if (_payStatus != _PayStatus.paid && _selectedCustomer == null) {
      _snack(
        _tr(
          'Please select a customer before recording a credit sale.',
          'Tafadhali chagua mteja kabla ya kurekodi mauzo ya mkopo.',
        ),
        field: _ErrorField.customer,
      );
      return;
    }

    double amountPaid;
    var payStatus = _payStatus;
    if (payStatus == _PayStatus.paid) {
      amountPaid = _grandTotal;
    } else if (payStatus == _PayStatus.partial) {
      final t = _amtPaidCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      amountPaid = double.tryParse(t) ?? 0;
      if (amountPaid <= 0) {
        _snack(
          _tr('Enter amount paid.', 'Ingiza kiasi kilicholipwa.'),
          field: _ErrorField.payment,
        );
        return;
      }
      // A "partial" payment covering the full total is simply a paid sale.
      if (amountPaid >= _grandTotal) {
        amountPaid = _grandTotal;
        payStatus = _PayStatus.paid;
      }
    } else {
      amountPaid = 0;
    }

    // Money received now must land in a chosen, activated payment account —
    // PaymentAccountChips only lets an activated built-in or custom account
    // become selected, so a null selection here just means nothing was picked.
    if (payStatus != _PayStatus.unpaid &&
        amountPaid > 0 &&
        _selectedAccount == null) {
      _snack(
        _tr('Select a payment account', 'Chagua akaunti ya malipo'),
        field: _ErrorField.payment,
      );
      return;
    }

    // Enforce credit limit: block the sale if the projected balance after
    // this outstanding amount would exceed the customer's set credit limit.
    if (payStatus != _PayStatus.paid &&
        _selectedCustomer != null &&
        _selectedCustomer!.creditLimit > 0) {
      final outstanding = _grandTotal - amountPaid;
      final projectedBalance = _selectedCustomer!.balanceAmount + outstanding;
      if (projectedBalance > _selectedCustomer!.creditLimit) {
        final available = _selectedCustomer!.availableCredit;
        _snack(
          _tr(
            'Credit limit exceeded. ${_selectedCustomer!.name} can only borrow TZS ${available.toStringAsFixed(0)} more.',
            'Kikomo cha mkopo kimezidiwa. ${_selectedCustomer!.name} anaweza kukopa TZS ${available.toStringAsFixed(0)} tu zaidi.',
          ),
          field: _ErrorField.customer,
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final invoiceId = const Uuid().v4();
      final invoiceNumber =
          'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
      final statusStr = payStatus == _PayStatus.paid
          ? 'paid'
          : payStatus == _PayStatus.partial
          ? 'partial'
          : 'unpaid';

      final customerName =
          _selectedCustomer?.name ??
          (_customerCtrl.text.trim().isNotEmpty
              ? _customerCtrl.text.trim()
              : null);

      final itemsData = _items
          .map(
            (e) => {
              'name': e.nameCtrl.text.trim(),
              'qty': e.qty,
              'unitPrice': e.unitPrice,
              'basePrice': e.basePrice ?? e.unitPrice,
              'total': e.lineTotal,
              if (e.selectedItem != null)
                'inventoryItemId': (e.selectedItem!['id'] as String?) ?? '',
            },
          )
          .toList();

      final notes = _notesCtrl.text.trim();
      final mpesaRef = _mpesaRefCtrl.text.trim();
      final outstanding = _grandTotal - amountPaid;

      final invoiceItems = _items
          .map(
            (e) => InvoiceItem(
              // Keep the product link — returns restock by this id, and
              // offline sales sync this payload to Firestore verbatim.
              id: ((e.selectedItem?['id'] as String?) ?? '').trim(),
              name: e.nameCtrl.text.trim(),
              quantity: e.qty.toDouble(),
              unitPrice: e.unitPrice,
              total: e.lineTotal,
              basePrice: e.basePrice ?? e.unitPrice,
            ),
          )
          .toList();
      final invoiceObj = Invoice(
        id: invoiceId,
        customerId: _selectedCustomer?.id ?? '',
        customerName: customerName ?? '',
        customerPhone: _selectedCustomer?.phone ?? '',
        invoiceNumber: invoiceNumber,
        date: now.toIso8601String(),
        dueDate: _dueDate?.toIso8601String() ?? '',
        status: statusStr,
        subtotal: _subtotal,
        discountAmount: _discountAmt,
        tax: _vatAmt,
        total: _grandTotal,
        amountPaid: amountPaid,
        paymentMethod: payStatus != _PayStatus.unpaid
            ? _paymentMethodValue
            : '',
        paymentAccountId: payStatus != _PayStatus.unpaid
            ? (_selectedAccount?.id ?? '')
            : '',
        items: invoiceItems,
        note: notes,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      // Offline: commit the sale to Drift + the sync queue instead of the
      // Firestore batch (whose commit() would never resolve without a
      // connection). SyncService pushes everything when connectivity returns.
      if (!await OnlineGuard.isDeviceOnline()) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Not logged in');

        await ref.read(invoiceRepositoryProvider).save(invoiceObj);

        // Stock deductions as deltas so concurrent sessions compose on push.
        for (final e in _items) {
          if (e.selectedItem == null) continue;
          final itemId = ((e.selectedItem!['id'] as String?) ?? '').trim();
          if (itemId.isEmpty) continue;
          await ref
              .read(inventoryRepositoryProvider)
              .adjustQuantity(itemId, -e.qty.toDouble());
        }

        // Credit sale: queued balance increment + receivable record.
        if (_selectedCustomer != null && outstanding > 0) {
          await ref
              .read(customerRepositoryProvider)
              .adjustBalance(_selectedCustomer!.id, outstanding);
          await ref
              .read(debtRepositoryProvider)
              .save(
                Debt(
                  id: '',
                  partyName: _selectedCustomer!.name,
                  partyPhone: _selectedCustomer!.phone,
                  partyId: _selectedCustomer!.id,
                  type: 'receivable',
                  originalAmount: _grandTotal,
                  paidAmount: amountPaid,
                  dueDate: _dueDate?.toIso8601String().split('T').first ?? '',
                  invoiceRef: invoiceNumber,
                  note: notes,
                  createdBy: user.uid,
                  createdAt: now.toIso8601String(),
                ),
              );
        }

        // Money received lands in the chosen account — Drift balance moves
        // instantly, the queued op replays on Firestore later.
        if (payStatus != _PayStatus.unpaid && _selectedAccount != null) {
          await moveMoneyForAccount(
            ref,
            accountId: _selectedAccount!.id,
            amount: amountPaid,
            isDeposit: true,
            description: LocalizationService.tr(
              en: 'Sale $invoiceNumber',
              sw: 'Mauzo $invoiceNumber',
            ),
            reference: invoiceNumber,
            createdBy: user.uid,
          );
        }

        await _showQuickSaleReceipt(
          invoiceNumber: invoiceNumber,
          customerName: customerName,
          itemsData: itemsData,
          amountPaid: amountPaid,
          payStatus: payStatus,
          mpesaRef: mpesaRef,
          statusStr: statusStr,
          now: now,
        );
        return;
      }

      final scope = await resolveSalesScope(ref);
      if (scope == null) throw Exception('Not logged in');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final role = ref.read(currentUserRoleProvider);

      final invoicesRef = repo.scopeCollection(
        uid: scope.ownerUid,
        context: scope.context,
        childCollection: 'sales_invoices',
      );

      // One atomic batch: invoice + stock deduction + customer balance +
      // debt record all commit together, so a crash or permission failure
      // can never leave half-written financial records.
      final batch = FirebaseFirestore.instance.batch();
      final invoiceDoc = invoicesRef.doc(invoiceId);

      batch.set(invoiceDoc, {
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
        'lineItems': itemsData,
        'subtotal': _subtotal,
        'discountAmount': _discountAmt,
        // Manual price edits vs catalog price — already baked into the item
        // unit prices, stored for reporting. The markup never appears on
        // customer receipts.
        if (_itemPriceDiscount > 0) 'itemPriceDiscount': _itemPriceDiscount,
        if (_itemPriceMarkup > 0) 'itemPriceMarkup': _itemPriceMarkup,
        'vatAmount': _vatAmt,
        'amount': _grandTotal,
        'totalAmount': _grandTotal,
        'amountPaid': amountPaid,
        if (payStatus != _PayStatus.unpaid) ...{
          'paymentMethod': _paymentMethodValue,
          'paymentAccountId': _selectedAccount?.id ?? '',
        },
        if (payStatus != _PayStatus.unpaid &&
            _selectedAccount?.id == PaymentMethodAccounts.mpesaId &&
            mpesaRef.isNotEmpty)
          'mpesaRef': mpesaRef,
        if (_dueDate != null) 'dueDate': Timestamp.fromDate(_dueDate!),
        if (notes.isNotEmpty) 'notes': notes,
        'createdBy': scope.userUid,
        'createdByRole': role,
        'createdAt': FieldValue.serverTimestamp(),
        // updatedAt drives the incremental sync pull — without it the sale
        // would never reach the local database (and the sales list).
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final inventoryRef = repo.scopeCollection(
        uid: scope.ownerUid,
        context: scope.context,
        childCollection: 'inventory_items',
      );
      for (final e in _items) {
        if (e.selectedItem == null) continue;
        final itemId = ((e.selectedItem!['id'] as String?) ?? '').trim();
        if (itemId.isEmpty) continue;
        batch.set(inventoryRef.doc(itemId), {
          'currentStock': FieldValue.increment(-e.qty),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (_selectedCustomer != null) {
        final customersRef = repo.scopeCollection(
          uid: scope.ownerUid,
          context: scope.context,
          childCollection: 'customers',
        );
        batch.set(customersRef.doc(_selectedCustomer!.id), {
          'lastTransactionDate': FieldValue.serverTimestamp(),
          if (outstanding > 0) ...{
            'balance': FieldValue.increment(outstanding),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));

        // Receivable record for any sale that is not fully paid, linked to
        // the customer, invoice and business.
        if (outstanding > 0) {
          final debtsRef = repo.scopeCollection(
            uid: scope.ownerUid,
            context: scope.context,
            childCollection: 'debts',
          );
          batch.set(debtsRef.doc(), {
            'partyId': _selectedCustomer!.id,
            'partyName': _selectedCustomer!.name,
            'partyPhone': _selectedCustomer!.phone,
            'invoiceRef': invoiceNumber,
            'businessId': scope.businessId,
            'originalAmount': _grandTotal,
            'paidAmount': amountPaid,
            'status': payStatus == _PayStatus.partial ? 'partial' : 'unpaid',
            'type': 'receivable',
            if (_dueDate != null) 'dueDate': Timestamp.fromDate(_dueDate!),
            'createdBy': scope.userUid,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      // Mirror the stock deduction into Drift immediately — the UI reads stock
      // from Drift, and the incremental sync pull can miss this write whenever
      // the device clock runs ahead of the Firestore server clock.
      try {
        final db = ref.read(appDatabaseProvider);
        for (final e in _items) {
          if (e.selectedItem == null) continue;
          final itemId = ((e.selectedItem!['id'] as String?) ?? '').trim();
          if (itemId.isEmpty) continue;
          await db.inventoryDao.applyCommittedDelta(itemId, -e.qty.toDouble());
        }
      } catch (e, st) {
        unawaited(Sentry.captureException(e, stackTrace: st));
      }

      // Update the Drift customer balance immediately so the credit-limit check
      // on the *next* sale in this session uses the correct outstanding amount,
      // without having to wait for the background sync to pull Firestore.
      if (_selectedCustomer != null && outstanding > 0) {
        try {
          final db = ref.read(appDatabaseProvider);
          await db.customerDao.updateBalance(
            _selectedCustomer!.id,
            _selectedCustomer!.balanceAmount + outstanding,
          );
        } catch (e, st) {
          unawaited(Sentry.captureException(e, stackTrace: st));
        }
      }

      // Write to Drift immediately so the sale appears in the list right away
      // without waiting for the next Firestore sync pull.
      await mirrorInvoiceToDrift(ref, invoiceObj);

      // Money received lands in the chosen account — Drift balance moves
      // instantly, the queued op replays on Firestore later.
      if (payStatus != _PayStatus.unpaid && _selectedAccount != null) {
        await moveMoneyForAccount(
          ref,
          accountId: _selectedAccount!.id,
          amount: amountPaid,
          isDeposit: true,
          description: LocalizationService.tr(
            en: 'Sale $invoiceNumber',
            sw: 'Mauzo $invoiceNumber',
          ),
          reference: invoiceNumber,
          createdBy: scope.userUid,
        );
      }

      unawaited(
        AuditLogService().logSaleAction(
          ownerUid: scope.ownerUid,
          businessId: scope.businessId,
          performedByUid: scope.userUid,
          performedByRole: role,
          action: AuditLogService.saleCreated,
          invoiceId: invoiceDoc.id,
          invoiceNumber: invoiceNumber,
          amount: _grandTotal,
          details: statusStr,
        ),
      );
      // Pull the new sale into the local database right away so it appears
      // in the sales list without waiting for the next connectivity event.
      unawaited(ref.read(syncServiceProvider).syncNow());

      await _showQuickSaleReceipt(
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        itemsData: itemsData,
        amountPaid: amountPaid,
        payStatus: payStatus,
        mpesaRef: mpesaRef,
        statusStr: statusStr,
        now: now,
      );
    } catch (e, st) {
      unawaited(Sentry.captureException(e, stackTrace: st));
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMsg = _tr(
          'Failed to save. Try again.',
          'Imeshindikana. Jaribu tena.',
        );
        _errorField = _ErrorField.general;
      });
    }
  }

  /// Shared success tail for the online and offline quick-sale paths:
  /// records the metric and closes the sale sheet with the receipt data. The
  /// sales screen presents the compact success notice after the sheet is gone.
  Future<void> _showQuickSaleReceipt({
    required String invoiceNumber,
    required String? customerName,
    required List<Map<String, dynamic>> itemsData,
    required double amountPaid,
    required _PayStatus payStatus,
    required String mpesaRef,
    required String statusStr,
    required DateTime now,
  }) async {
    SentryMetricsService.salesCreated(amount: _grandTotal, status: statusStr);

    // Build a plain data map for the receipt popup — no server timestamps,
    // just the values we already have in memory.
    final saleReceipt = <String, dynamic>{
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'items': itemsData,
      'subtotal': _subtotal,
      'discountAmount': _discountAmt,
      if (_itemPriceDiscount > 0) 'itemPriceDiscount': _itemPriceDiscount,
      if (_itemPriceMarkup > 0) 'itemPriceMarkup': _itemPriceMarkup,
      'vatAmount': _vatAmt,
      'amount': _grandTotal,
      'amountPaid': amountPaid,
      if (payStatus != _PayStatus.unpaid) 'paymentMethod': _paymentMethodValue,
      if (mpesaRef.isNotEmpty) 'mpesaRef': mpesaRef,
      'status': statusStr,
      'createdAt': now,
    };

    if (!mounted) return;
    Navigator.of(context).pop(saleReceipt);
  }

  void _snack(String msg, {_ErrorField field = _ErrorField.items}) =>
      setState(() {
        _errorMsg = msg;
        _errorField = field;
      });

  @override
  Widget build(BuildContext context) {
    return Material(
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
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildItemsSection(),
                  _buildFieldError(_ErrorField.items),
                  const SizedBox(height: 8),
                  _buildTotalsSection(),
                  const SizedBox(height: 16),
                  Text(
                    _tr('Payment', 'Malipo'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentSection(),
                  _buildFieldError(_ErrorField.payment),
                  const SizedBox(height: 8),
                  _buildDetailsSection(),
                  _buildFieldError(_ErrorField.customer),
                  _buildFieldError(_ErrorField.general),
                ],
              ),
            ),
          ),
          _buildStickyFooter(),
        ],
      ),
    );
  }

  Widget _buildHandle() => const SheetHandle();

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _tr('New Sale', 'Mauzo Mapya'),
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            tooltip: _tr('Close', 'Funga'),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Renders the current [_errorMsg] right where it belongs — directly under
  /// the section it's about — or nothing if the error is for a different
  /// field (or there is none). Keeps validation messages next to the data
  /// that needs fixing instead of a single message far away from it.
  Widget _buildFieldError(_ErrorField field) {
    if (_errorField != field) return const SizedBox.shrink();
    return ValidationBanner(
      message: _errorMsg,
      onDismiss: () => setState(() => _errorMsg = null),
    );
  }

  Widget _buildCustomerSection() {
    final needsCustomer =
        _payStatus != _PayStatus.paid && _selectedCustomer == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _tr('Customer', 'Mteja'),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: needsCustomer ? AppColors.warning : AppColors.textMuted,
              ),
            ),
            if (needsCustomer) ...[
              SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _tr('Required for debt', 'Inahitajika kwa deni'),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ],
        ),
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
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  )
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

  Widget _buildDetailsSection() {
    final needsCustomer =
        _payStatus != _PayStatus.paid && _selectedCustomer == null;
    final showDetails = _detailsExpanded || needsCustomer;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: needsCustomer
              ? AppColors.warning.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _detailsExpanded = !showDetails),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 19,
                    color: needsCustomer
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _tr('Customer & details', 'Mteja na maelezo'),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          needsCustomer
                              ? _tr('Required', 'Lazima')
                              : _tr('Optional', 'Hiari'),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: needsCustomer
                                ? AppColors.warning
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    showDetails
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  _buildCustomerSection(),
                  if (_payStatus != _PayStatus.paid) ...[
                    const SizedBox(height: 12),
                    _buildDueDateRow(),
                  ],
                  const SizedBox(height: 12),
                  _buildNotesField(),
                ],
              ),
            ),
            crossFadeState: showDetails
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x120D1B3E),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Total', 'Jumla'),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'TSh ${_grandTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          SizedBox(width: 176, child: _buildSaveButton()),
        ],
      ),
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ..._customerSuggs.map(
            (c) => Column(
              children: [
                InkWell(
                  onTap: () => _selectCustomer(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          c.isOrganisation
                              ? Icons.business_outlined
                              : Icons.person_outline_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ),
                        if (c.phone.isNotEmpty)
                          Text(
                            c.phone,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: AppColors.border,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => showAppSheet<void>(
              context,
              builder: (_) => AddCustomerDialog(
                initialName: _customerCtrl.text.trim(),
                onAdded: _selectCustomer,
              ),
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_add_outlined,
                    size: 18,
                    color: AppColors.navyPrimary,
                  ),
                  SizedBox(width: 10),
                  Text(
                    _tr('Add new customer', 'Ongeza mteja mpya'),
                    style: GoogleFonts.dmSans(
                      color: AppColors.navyPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _tr('Products', 'Bidhaa'),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
            const Spacer(),
            // POS continuous scan button
            GestureDetector(
              onTap: _openPosScanner,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tealAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.tealAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 14,
                      color: AppColors.tealAccent,
                    ),
                    SizedBox(width: 5),
                    Text(
                      _tr('Scan Mode', 'Skani'),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${_items.length} ${_tr("item", "bidhaa")}${_items.length != 1 ? "s" : ""}',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < _items.length; i++) ...[
          _buildItemRow(i),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: _addItem,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.navyPrimary.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 18,
                  color: AppColors.navyPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  _tr('Add Item', 'Ongeza Bidhaa'),
                  style: GoogleFonts.dmSans(
                    color: AppColors.navyPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isOutOfStock
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_tr("Item", "Bidhaa")} ${index + 1}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (_items.length > 1)
                GestureDetector(
                  onTap: () => _removeItem(index),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: entry.nameCtrl,
            autofocus: index == 0 && _items.length == 1,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: _fieldDec(
              label: _tr('Product name', 'Jina la bidhaa'),
              prefix: Icons.inventory_2_outlined,
              suffix: entry.selectedItem != null
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    )
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
                            icon: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 22,
                              color: AppColors.tealAccent,
                            ),
                            tooltip: _tr('Scan mode', 'Hali ya skani'),
                            onPressed: _openPosScanner,
                          )),
            ),
          ),
          if (entry.showSuggs) _buildProductSuggestions(index),
          if (entry.nameCtrl.text.isEmpty && entry.selectedItem == null)
            Builder(
              builder: (_) {
                final recent = _recentlySoldProducts();
                if (recent.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Text(
                        _tr('Recent', 'Hivi karibuni'),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: recent.map((item) {
                              final name = (item['name'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  backgroundColor: AppColors.surface,
                                  label: Text(
                                    name,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  onPressed: () => _selectProduct(entry, item),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (entry.nameCtrl.text.isNotEmpty &&
              entry.selectedItem == null &&
              !entry.showSuggs)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InkWell(
                onTap: () => showAppSheet<void>(
                  context,
                  builder: (_) => _AddProductSheet(
                    initialName: entry.nameCtrl.text.trim(),
                    onAdded: (item) => _selectProduct(entry, item),
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.06),
                    border: Border.all(
                      color: AppColors.navyPrimary.withValues(alpha: 0.25),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 15,
                        color: AppColors.navyPrimary,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _tr(
                            'Add "${entry.nameCtrl.text}" to inventory',
                            'Ongeza "${entry.nameCtrl.text}" kwa bidhaa',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: AppColors.navyPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDec(
                    label: _tr('Price (TSh)', 'Bei (TSh)'),
                    prefix: Icons.payments_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: entry.qtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: (v) {
                    final parsed = int.tryParse(v) ?? 1;
                    final clamped = parsed.clamp(1, entry.maxStock);
                    setState(() => entry._qty = clamped);
                    if (clamped != parsed) {
                      entry.qtyCtrl.text = '$clamped';
                      entry.qtyCtrl.selection = TextSelection.collapsed(
                        offset: '$clamped'.length,
                      );
                    }
                  },
                  decoration:
                      _fieldDec(
                        label: _tr('Qty', 'Idadi'),
                        prefix: Icons.remove_rounded,
                      ).copyWith(
                        prefixIcon: GestureDetector(
                          onTap: entry.qty > 1
                              ? () => setState(() => entry.qty--)
                              : null,
                          child: Icon(
                            Icons.remove_rounded,
                            size: 18,
                            color: entry.qty > 1
                                ? AppColors.navyPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap:
                              (entry.selectedItem == null ||
                                  entry.qty < entry.maxStock)
                              ? () => setState(() => entry.qty++)
                              : null,
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color:
                                (entry.selectedItem == null ||
                                    entry.qty < entry.maxStock)
                                ? AppColors.navyPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        helperText:
                            entry.selectedItem != null &&
                                !entry._isService &&
                                entry.maxStock < 9999
                            ? '/ ${entry.maxStock}'
                            : null,
                        helperStyle: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (entry.selectedItem != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (entry._isService
                                      ? AppColors.tealAccent
                                      : entry.isOutOfStock
                                      ? AppColors.error
                                      : entry.maxStock <= 5
                                      ? AppColors.warning
                                      : AppColors.success)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry._isService
                              ? _tr('Service', 'Huduma')
                              : entry.isOutOfStock
                              ? _tr('Out of stock', 'Imekwisha')
                              : '${entry.maxStock} ${_tr("in stock", "stokuni")}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: entry._isService
                                ? AppColors.tealAccent
                                : entry.isOutOfStock
                                ? AppColors.error
                                : entry.maxStock <= 5
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ),
                    // Manual price edit vs catalog price: below list reads as
                    // a discount (goes on the receipt), above list is flagged
                    // for the cashier but stays off the receipt.
                    if (entry.priceChangePct != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (entry.priceChangePct! < 0
                                      ? AppColors.success
                                      : AppColors.warning)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              entry.priceChangePct! < 0
                                  ? Icons.south_rounded
                                  : Icons.north_rounded,
                              size: 11,
                              color: entry.priceChangePct! < 0
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              entry.priceChangePct! < 0
                                  ? '${_pctText(entry.priceChangePct!)} ${_tr("discount", "punguzo")}'
                                  : '${_pctText(entry.priceChangePct!)} ${_tr("above price", "juu ya bei")}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: entry.priceChangePct! < 0
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (entry.lineTotal > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'TSh ${entry.lineTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
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
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: entry.suggs.asMap().entries.map((e) {
            final isLast = e.key == entry.suggs.length - 1;
            final item = e.value;
            final name = (item['name'] ?? '') as String;
            final category = (item['category'] ?? '') as String;
            final price = parseUnitPrice(
              item['unitPrice'] ?? item['price'] ?? 0,
            );
            final stock = parseStock(
              item['currentStock'] ?? item['stock'] ?? 0,
            );
            final isService = (item['productType'] as String?) == 'service';
            final oos = !isService && stock <= 0;
            final isLow =
                !isService &&
                !oos &&
                stock <= parseStock(item['reorderPoint'] ?? 5);
            final stockColor = oos
                ? AppColors.error
                : isLow
                ? AppColors.warning
                : AppColors.success;
            final iconData = isService
                ? Icons.design_services_rounded
                : Icons.inventory_2_outlined;

            return Column(
              children: [
                InkWell(
                  onTap: oos ? null : () => _selectProduct(entry, item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Inventory-style tinted icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(iconData, size: 18, color: stockColor),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: oos
                                      ? AppColors.textMuted
                                      : AppColors.navyPrimary,
                                ),
                              ),
                              if (category.isNotEmpty)
                                Text(
                                  category,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TZS ${price.toStringAsFixed(0)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (!isService)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: stockColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: stockColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  oos
                                      ? _tr('Out', 'Imekwisha')
                                      : '$stock ${_tr("left", "zimebaki")}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: stockColor,
                                  ),
                                ),
                              ),
                          ],
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
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                _TotalRow(
                  label: _tr('Subtotal', 'Jumla ya bidhaa'),
                  value: 'TSh ${_subtotal.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => setState(
                    () => _adjustmentsExpanded = !_adjustmentsExpanded,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 17,
                          color: _adjustmentsExpanded
                              ? AppColors.tealAccent
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _tr('Discount & VAT', 'Punguzo na kodi'),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          _tr('Optional', 'Hiari'),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _adjustmentsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_adjustmentsExpanded) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDec(
                      label: _tr(
                        'Discount (TSh, optional)',
                        'Punguzo (TSh, hiari)',
                      ),
                      prefix: Icons.discount_outlined,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: AppColors.tealAccent,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _tr('VAT (18%)', 'Kodi ya Ongezeko (18%)'),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _vatEnabled,
                        onChanged: (v) => setState(() => _vatEnabled = v),
                        activeThumbColor: AppColors.tealAccent,
                        activeTrackColor: AppColors.tealAccent.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),
                  if (_vatEnabled) ...[
                    const SizedBox(height: 4),
                    _TotalRow(
                      label: 'VAT (18%)',
                      value: 'TSh ${_vatAmt.toStringAsFixed(0)}',
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setPayStatus(_PayStatus status) {
    setState(() {
      _payStatus = status;
      if (status != _PayStatus.paid) _detailsExpanded = true;
    });
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
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
                onTap: () => _setPayStatus(_PayStatus.paid),
              ),
              const SizedBox(width: 4),
              _PayBtn(
                label: _tr('Partial', 'Nusu'),
                icon: Icons.timelapse_rounded,
                active: _payStatus == _PayStatus.partial,
                activeColor: AppColors.warning,
                onTap: () => _setPayStatus(_PayStatus.partial),
              ),
              const SizedBox(width: 4),
              _PayBtn(
                label: _tr('Unpaid', 'Haijalipwa'),
                icon: Icons.cancel_outlined,
                active: _payStatus == _PayStatus.unpaid,
                activeColor: AppColors.error,
                onTap: () => _setPayStatus(_PayStatus.unpaid),
              ),
            ],
          ),
        ),
        if (_payStatus != _PayStatus.unpaid) ...[
          SizedBox(height: 8),
          Text(
            _tr('Payment Method', 'Njia ya Malipo'),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          PaymentAccountChips(
            selectedAccountId: _selectedAccount?.id,
            onSelectAccount: (account) => setState(() {
              _selectedAccount = account;
              if (_errorField == _ErrorField.payment) _errorMsg = null;
            }),
            onActivationRequired: (message) =>
                _snack(message, field: _ErrorField.payment),
          ),
          if (_selectedAccount?.id == PaymentMethodAccounts.mpesaId) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _mpesaRefCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: _fieldDec(
                label: _tr(
                  'M-Pesa Reference (optional)',
                  'Nambari ya M-Pesa (hiari)',
                ),
                prefix: Icons.tag_rounded,
              ),
            ),
          ],
        ],
        if (_payStatus == _PayStatus.partial) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _amtPaidCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _dueDate != null
                    ? '${_tr("Due", "Malipo")} ${_fmtDate(_dueDate!)}'
                    : _tr(
                        'Set due date (optional)',
                        'Weka tarehe ya malipo (hiari)',
                      ),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: _dueDate != null
                      ? AppColors.navyPrimary
                      : AppColors.textMuted,
                  fontWeight: _dueDate != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (_dueDate != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
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
    final needsCustomer =
        _payStatus != _PayStatus.paid && _selectedCustomer == null;
    final isDisabled = _isSaving || hasOutOfStock || needsCustomer;

    String buttonLabel;
    if (hasOutOfStock) {
      buttonLabel = _tr('Item out of stock', 'Bidhaaa imekwisha');
    } else if (needsCustomer) {
      buttonLabel = _tr('Select a customer first', 'Chagua mteja kwanza');
    } else {
      buttonLabel = _tr('Save Sale', 'Hifadhi Mauzo');
    }

    Color disabledBg;
    if (hasOutOfStock) {
      disabledBg = AppColors.error.withValues(alpha: 0.6);
    } else if (needsCustomer) {
      disabledBg = AppColors.warning.withValues(alpha: 0.5);
    } else {
      disabledBg = AppColors.primary.withValues(alpha: 0.5);
    }

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.navyPrimary,
          disabledBackgroundColor: disabledBg,
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
                buttonLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  InputDecoration _fieldDec({
    required String label,
    required IconData prefix,
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(prefix, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
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
      borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : AppColors.textMuted,
              ),
              SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
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

// ── Add Product Sheet ──────────────────────────────────────────────────────────

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
  String? _errorMsg;

  final List<String> _units = [
    'pcs',
    'kg',
    'liters',
    'boxes',
    'bottles',
    'bags',
    'meters',
    'sets',
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
      setState(
        () => _errorMsg = _tr('Enter product name', 'Ingiza jina la bidhaaa'),
      );
      return;
    }
    if (price <= 0) {
      setState(
        () => _errorMsg = _tr('Enter a valid price', 'Ingiza bei sahihi'),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });
    final navigator = Navigator.of(context);

    try {
      // Offline-first: Drift + sync queue, same as the inventory screen —
      // works with no connection and pushes to Firestore on reconnect.
      final id = const Uuid().v4();
      final nowIso = DateTime.now().toIso8601String();
      await ref
          .read(inventoryRepositoryProvider)
          .save(
            InventoryItem(
              id: id,
              name: name,
              category: category.isNotEmpty ? category : 'General',
              sku: _skuCtrl.text.trim(),
              currentStock: stock.toDouble(),
              reorderPoint: 5,
              unitPrice: price,
              unit: _selectedUnit,
              createdAt: nowIso,
              updatedAt: nowIso,
            ),
          );

      navigator.pop();
      widget.onAdded({
        'id': id,
        'name': name,
        'unitPrice': price,
        'category': category.isNotEmpty ? category : 'General',
        'currentStock': stock,
        'unit': _selectedUnit,
      });
    } catch (e, st) {
      unawaited(Sentry.captureException(e, stackTrace: st));
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMsg = _tr(
          'Failed to add product',
          'Imeshindikana kuongeza bidhaaa',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHandle(),
              Text(
                _tr('Add New Product', 'Ongeza Bidhaaa Mpya'),
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              _field(
                ctrl: _nameCtrl,
                label: _tr('Product Name *', 'Jina la Bidhaaa *'),
                icon: Icons.inventory_2_outlined,
                caps: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _field(
                      ctrl: _priceCtrl,
                      label: _tr('Unit Price (TSh) *', 'Bei ya Kitengo *'),
                      icon: Icons.sell_outlined,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
                          borderSide: const BorderSide(
                            color: AppColors.navyPrimary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
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
                caps: TextCapitalization.characters,
              ),
              ValidationBanner(
                message: _errorMsg,
                onDismiss: () => setState(() => _errorMsg = null),
                margin: const EdgeInsets.only(top: 16),
              ),
              SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.secondary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
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
                          _tr('Add to Inventory', 'Ongeza kwa Bidhaa'),
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
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    TextCapitalization caps = TextCapitalization.none,
  }) => TextField(
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
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SALE INFO SLIDE-UP SHEET — tap-a-card to view details
// ══════════════════════════════════════════════════════════════════════════════

class _SaleInfoSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  const _SaleInfoSheet({required this.item});

  @override
  ConsumerState<_SaleInfoSheet> createState() => _SaleInfoSheetState();
}

class _SaleInfoSheetState extends ConsumerState<_SaleInfoSheet> {
  late Map<String, dynamic> _inv;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _inv = Map.from(widget.item);
  }

  // ── Derived ──────────────────────────────────────────────────────────────────

  String get _status {
    final raw = readInvoiceStatus(_inv).toLowerCase().trim();
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

  bool get _isQuotation =>
      (_inv['type'] ?? '').toString().toLowerCase() == 'quotation';
  double get _total => readInvoiceTotal(_inv);
  double get _subtotal => parseNumericAmount(_inv['subtotal']);
  double get _discount => parseNumericAmount(_inv['discountAmount']);
  double get _vat => parseNumericAmount(_inv['vatAmount']);
  double get _amountPaid => parseNumericAmount(_inv['amountPaid']);
  double get _outstanding => (_total - _amountPaid).clamp(0.0, _total);

  String get _invoiceNumber =>
      _inv['invoiceNumber']?.toString() ?? _inv['id']?.toString() ?? '—';

  String get _customerName {
    // Drift maps store '' (not null) when the sale had no customer.
    final raw = (_inv['customerName'] ?? '').toString().trim();
    return raw.isNotEmpty ? raw : _tr('Walk-in', 'Mteja wa Njiani');
  }

  DateTime? get _invoiceDate =>
      readTimestamp(_inv['createdAt'] ?? _inv['date']);
  DateTime? get _dueDate => readTimestamp(_inv['dueDate']);

  bool get _isOverdueNow {
    final s = _status;
    if (s == 'paid' || s == 'cancelled' || s == 'draft') return false;
    if (s == 'overdue') return true;
    final due = _dueDate;
    return due != null && due.isBefore(DateTime.now());
  }

  List<Map<String, dynamic>> get _lineItems {
    final raw = _inv['lineItems'];
    if (raw is List && raw.isNotEmpty) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    final fallback = _inv['items'];
    if (fallback is List) {
      return fallback
          .whereType<Map<String, dynamic>>()
          .map(
            (it) => {
              'productName': it['productName'] ?? it['name'] ?? '',
              'qty': it['qty'] ?? it['quantity'] ?? 1,
              'unitPrice': it['unitPrice'],
              'lineTotal': it['lineTotal'] ?? it['total'],
              'unit': it['unit'] ?? '',
            },
          )
          .toList();
    }
    return [];
  }

  ({Color bg, Color text, String label, IconData icon}) get _chipData {
    if (_isOverdueNow) {
      return (
        bg: AppColors.errorBg,
        text: AppColors.error,
        label: _tr('Overdue', 'Imechelewa'),
        icon: Icons.warning_amber_rounded,
      );
    }
    return switch (_status) {
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
        label: _isQuotation
            ? _tr('Quotation', 'Nukuu')
            : _tr('Sent', 'Imetumwa'),
        icon: _isQuotation ? Icons.description_outlined : Icons.send_rounded,
      ),
    };
  }

  // ── Permissions ───────────────────────────────────────────────────────────────

  bool get _canTakePayment {
    final ps = ref.read(permissionServiceProvider);
    return ps.canCreateSale || ps.canEditSale;
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> _markPaid() async {
    // Payment settlement moves customer balances via server increments —
    // keep it online-only for now (offline sales themselves still work).
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;
    setState(() => _updating = true);
    try {
      // Full-outstanding payment through the shared settlement path so the
      // payment record, customer balance and receivable/debt ledgers all move
      // together with the invoice status.
      final method = (_inv['paymentMethod'] ?? '').toString();
      final result = await settleInvoicePayment(
        ref,
        invoice: _inv,
        amount: _outstanding,
        method: method.isEmpty || method == 'credit' ? 'cash' : method,
        auditDetails: 'mark_paid',
      );
      if (!mounted) return;
      if (result == null) {
        setState(() => _updating = false);
        return;
      }
      setState(() {
        _inv = {
          ..._inv,
          'status': result.newStatus,
          'amountPaid': result.newAmountPaid,
        };
        _updating = false;
      });
      _showSnack(
        _tr('Invoice marked as paid!', 'Ankara imewekwa kama imelipwa!'),
      );
    } catch (e, st) {
      unawaited(Sentry.captureException(e, stackTrace: st));
      if (!mounted) return;
      setState(() => _updating = false);
      _showSnack(_tr('Update failed. Try again.', 'Imeshindwa. Jaribu tena.'));
    }
  }

  void _openFullDetail() {
    Navigator.of(context).pop();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoice: Map.from(_inv)),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final chip = _chipData;
    final isPaidOrCancelled = _status == 'paid' || _status == 'cancelled';
    final lineItems = _lineItems;
    final hasDiscount = _discount > 0;
    final hasVat = _vat > 0;
    final hasTotalsBreakdown = hasDiscount || hasVat;
    final payMethod = (_inv['paymentMethod'] ?? '').toString();
    final notes = (_inv['notes'] ?? '').toString();
    final invoiceDate = _invoiceDate;
    final dueDate = _dueDate;
    final overdue = _isOverdueNow;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),

            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Invoice header ───────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (_invoiceNumber.isNotEmpty)
                                    Text(
                                      _invoiceNumber,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  if (_isQuotation) ...[
                                    SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
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
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                _customerName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: chip.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(chip.icon, size: 12, color: chip.text),
                              SizedBox(width: 4),
                              Text(
                                chip.label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: chip.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Date row ─────────────────────────────────────────────
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (invoiceDate != null) ...[
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _fmtDate(invoiceDate),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        if (dueDate != null) ...[
                          if (invoiceDate != null) SizedBox(width: 8),
                          Text(
                            '·',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.event_rounded,
                            size: 11,
                            color: overdue
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${_tr("Due", "Mwisho")}: ${_fmtDate(dueDate)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: overdue
                                  ? AppColors.error
                                  : AppColors.textMuted,
                              fontWeight: overdue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // ── Total + outstanding ───────────────────────────────────
                    SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TZS ${_sNum(_total)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (!isPaidOrCancelled && _outstanding > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              '${_tr("Due", "Baki")}: TZS ${_sNum(_outstanding)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Container(height: 1, color: AppColors.border),

                    // ── Line items ────────────────────────────────────────────
                    if (lineItems.isNotEmpty) ...[
                      SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            _tr('ITEMS', 'BIDHAA').toUpperCase(),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            '(${lineItems.length})',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: lineItems.asMap().entries.map((e) {
                            final idx = e.key;
                            final it = e.value;
                            final name =
                                (it['productName'] ?? it['name'] ?? '—')
                                    .toString();
                            final qty = (it['qty'] ?? it['quantity'] ?? 1)
                                .toString();
                            final unitPrice = parseNumericAmount(
                              it['unitPrice'],
                            );
                            final lineTotal = parseNumericAmount(
                              it['lineTotal'] ?? it['total'],
                            );
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (idx > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: AppColors.border,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (unitPrice > 0) ...[
                                              SizedBox(height: 2),
                                              Text(
                                                '×$qty · TZS ${_sNum(unitPrice)} ${_tr("each", "kila")}',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'TZS ${_sNum(lineTotal)}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navyPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: AppColors.border),
                    ],

                    // ── Totals breakdown ──────────────────────────────────────
                    const SizedBox(height: 14),
                    if (hasTotalsBreakdown) ...[
                      _SaleSheetRow(
                        label: _tr('Subtotal', 'Jumla Ndogo'),
                        value:
                            'TZS ${_sNum(_subtotal > 0 ? _subtotal : _total)}',
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(height: 6),
                        _SaleSheetRow(
                          label: _tr('Discount', 'Punguzo'),
                          value: '-TZS ${_sNum(_discount)}',
                          valueColor: AppColors.success,
                        ),
                      ],
                      if (hasVat) ...[
                        const SizedBox(height: 6),
                        _SaleSheetRow(
                          label: _tr('VAT (18%)', 'VAT (18%)'),
                          value: 'TZS ${_sNum(_vat)}',
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(height: 1, color: AppColors.border),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tr('TOTAL', 'JUMLA').toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'TZS ${_sNum(_total)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                      ],
                    ),

                    // ── Payment method ────────────────────────────────────────
                    if (payMethod.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.navyPrimary.withValues(
                                alpha: 0.07,
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            switch (payMethod) {
                              'cash' => _tr('Cash', 'Taslimu'),
                              'mpesa' => 'M-Pesa',
                              'bank_transfer' => _tr(
                                'Bank Transfer',
                                'Uhamisho wa Benki',
                              ),
                              'card' => _tr('Card', 'Kadi'),
                              'credit' => _tr('On Account', 'Mkopo'),
                              _ => payMethod,
                            },
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if ((_inv['mpesaRef'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            SizedBox(width: 8),
                            Text(
                              (_inv['mpesaRef'] ?? '').toString(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // ── Notes ────────────────────────────────────────────────
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(height: 1, color: AppColors.border),
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notes,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 14),

                    // ── Share Receipt ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _SalesScreenState._openReceiptActions(
                          context: context,
                          sale: _inv,
                          ref: ref,
                        ),
                        icon: Icon(Icons.ios_share_rounded, size: 16),
                        label: Text(
                          _tr('Share Receipt', 'Shiriki Risiti'),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // ── Mark as Paid ──────────────────────────────────────────
                    if (_canTakePayment && !isPaidOrCancelled) ...[
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _updating ? null : _markPaid,
                          icon: _updating
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            _tr('Mark as Paid', 'Weka kama Imelipwa'),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],

                    // ── View Full Details ─────────────────────────────────────
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _openFullDetail,
                        icon: Icon(Icons.receipt_long_rounded, size: 18),
                        label: Text(
                          _tr('View Full Details', 'Ona Maelezo Kamili'),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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

class _SaleSheetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SaleSheetRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

String _sNum(double v) {
  if (v == 0) return '0';
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ══════════════════════════════════════════════════════════════════════════════
// SALE SUCCESS RECEIPT SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class _SaleSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> saleData;
  final WidgetRef ref;

  const _SaleSuccessScreen({required this.saleData, required this.ref});

  @override
  State<_SaleSuccessScreen> createState() => _SaleSuccessScreenState();
}

class _SaleSuccessScreenState extends State<_SaleSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _cardCtrl;

  late final Animation<double> _checkScale;
  late final Animation<double> _checkFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _checkFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);

    _checkCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _cardCtrl.forward();
    });
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.saleData;
    final amount = (sale['amount'] as num?)?.toDouble() ?? 0;
    final amountPaid = (sale['amountPaid'] as num?)?.toDouble() ?? 0;
    final invoiceNo = (sale['invoiceNumber'] ?? '').toString();
    final rawCustomer = (sale['customerName'] ?? '').toString().trim();
    final customerName = rawCustomer.isNotEmpty
        ? rawCustomer
        : _tr('Walk-in', 'Mteja wa kawaida');
    final statusStr = (sale['status'] ?? 'paid').toString();
    final items =
        (sale['items'] as List?)?.whereType<Map>().toList() ?? const [];
    final createdAt = sale['createdAt'] as DateTime? ?? DateTime.now();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.statusBarLightIcons,
      child: Scaffold(
        backgroundColor: AppColors.navyPrimary,
        body: Column(
          children: [
            // ── Top hero — navy background ────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _checkScale,
                      child: FadeTransition(
                        opacity: _checkFade,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x4005966A),
                                  blurRadius: 20,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      _tr('Sale Successful!', 'Mauzo Yamefanikiwa!'),
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'TSh ${_sNum(amount)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SuccessStatusBadge(statusStr),
                  ],
                ),
              ),
            ),

            // ── Ticket receipt card — white ───────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _cardFade,
                child: SlideTransition(
                  position: _cardSlide,
                  child: _TicketReceiptCard(
                    invoiceNo: invoiceNo,
                    customerName: customerName,
                    amount: amount,
                    amountPaid: amountPaid,
                    items: items,
                    sale: sale,
                    statusStr: statusStr,
                    createdAt: createdAt,
                    onShare: () async {
                      await _SalesScreenState._openReceiptActions(
                        context: context,
                        sale: widget.saleData,
                        ref: widget.ref,
                      );
                    },
                    onDone: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ticket-style receipt card with perforated edge ────────────────────────────

class _PaperSaleReceiptNotice extends _SaleSuccessNotice {
  const _PaperSaleReceiptNotice({required super.saleData, required super.ref});

  @override
  Widget build(BuildContext context) {
    const paperColor = Color(0xFFFFFEF7);
    final amount = parseNumericAmount(saleData['amount']);
    final amountPaid = parseNumericAmount(saleData['amountPaid']);
    final subtotal = parseNumericAmount(saleData['subtotal']);
    final discount = parseNumericAmount(saleData['discountAmount']);
    final vat = parseNumericAmount(saleData['vatAmount']);
    final outstanding = (amount - amountPaid).clamp(0.0, amount);
    final invoiceNo = (saleData['invoiceNumber'] ?? '').toString();
    final rawCustomer = (saleData['customerName'] ?? '').toString().trim();
    final customer = rawCustomer.isEmpty
        ? _tr('Walk-in customer', 'Mteja wa kawaida')
        : rawCustomer;
    final status = (saleData['status'] ?? 'paid').toString();
    final statusLabel = switch (status) {
      'paid' => _tr('PAID', 'IMELIPWA'),
      'partial' => _tr('PART PAID', 'SEHEMU'),
      'unpaid' => _tr('CREDIT', 'MKOPO'),
      _ => _tr('SAVED', 'IMEHIFADHIWA'),
    };
    final items = (saleData['items'] as List?)?.whereType<Map>().toList() ?? [];
    final createdAt = saleData['createdAt'] as DateTime? ?? DateTime.now();
    final date =
        '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}  '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 370,
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: PhysicalShape(
              clipper: const _ReceiptPaperClipper(),
              color: paperColor,
              elevation: 20,
              shadowColor: AppColors.navyPrimary.withValues(alpha: 0.35),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.navyPrimary,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.navyPrimary,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'MALI UP',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyPrimary,
                                  letterSpacing: 2.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _tr('SALE RECEIPT', 'RISITI YA MAUZO'),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: _tr('Close', 'Funga'),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 21,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    const _PerforatedLine(),
                    const SizedBox(height: 13),
                    _ReceiptMetaRow(
                      label: _tr('RECEIPT', 'RISITI'),
                      value: invoiceNo,
                    ),
                    const SizedBox(height: 5),
                    _ReceiptMetaRow(label: _tr('DATE', 'TAREHE'), value: date),
                    const SizedBox(height: 5),
                    _ReceiptMetaRow(
                      label: _tr('CUSTOMER', 'MTEJA'),
                      value: customer,
                    ),
                    const SizedBox(height: 13),
                    const _PerforatedLine(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tr('ITEM', 'BIDHAA'),
                            style: _receiptLabelStyle(),
                          ),
                        ),
                        Text(
                          _tr('AMOUNT', 'KIASI'),
                          style: _receiptLabelStyle(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    for (final item in items) ...[
                      _ReceiptItemRow(item: item),
                      const SizedBox(height: 9),
                    ],
                    if (items.isEmpty)
                      Text(
                        _tr('Sale item', 'Bidhaa ya mauzo'),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 3),
                    const _PerforatedLine(),
                    const SizedBox(height: 12),
                    if (subtotal > 0)
                      _ReceiptAmountRow(
                        label: _tr('Subtotal', 'Jumla ndogo'),
                        amount: subtotal,
                      ),
                    if (discount > 0) ...[
                      const SizedBox(height: 5),
                      _ReceiptAmountRow(
                        label: _tr('Discount', 'Punguzo'),
                        amount: -discount,
                      ),
                    ],
                    if (vat > 0) ...[
                      const SizedBox(height: 5),
                      _ReceiptAmountRow(label: 'VAT', amount: vat),
                    ],
                    const SizedBox(height: 10),
                    _ReceiptAmountRow(
                      label: _tr('TOTAL', 'JUMLA KUU'),
                      amount: amount,
                      prominent: true,
                    ),
                    const SizedBox(height: 7),
                    _ReceiptAmountRow(
                      label: _tr('Paid', 'Imelipwa'),
                      amount: amountPaid,
                    ),
                    if (outstanding > 0) ...[
                      const SizedBox(height: 5),
                      _ReceiptAmountRow(
                        label: _tr('Balance due', 'Baki'),
                        amount: outstanding,
                        valueColor: AppColors.error,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.navyPrimary),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyPrimary,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _tr(
                        'Thank you for your business!',
                        'Asante kwa kufanya biashara nasi!',
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _PerforatedLine(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _SalesScreenState._openReceiptActions(
                                  context: context,
                                  sale: saleData,
                                  ref: ref,
                                ),
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: Text(_tr('Share', 'Shiriki')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navyPrimary,
                              side: const BorderSide(
                                color: AppColors.navyPrimary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navyPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: Text(_tr('Done', 'Maliza')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _receiptLabelStyle() => GoogleFonts.jetBrainsMono(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );
}

class _ReceiptMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptMetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: _PaperSaleReceiptNotice._receiptLabelStyle(),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  final Map item;

  const _ReceiptItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ?? item['productName'] ?? '-').toString();
    final qty = parseNumericAmount(item['qty'] ?? item['quantity'] ?? 1);
    final unitPrice = parseNumericAmount(item['unitPrice']);
    final storedTotal = parseNumericAmount(item['total'] ?? item['lineTotal']);
    final total = storedTotal > 0 ? storedTotal : unitPrice * qty;
    final qtyText = qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$qtyText × TSh ${_sNum(unitPrice)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'TSh ${_sNum(total)}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ReceiptAmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool prominent;
  final Color? valueColor;

  const _ReceiptAmountRow({
    required this.label,
    required this.amount,
    this.prominent = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = amount < 0 ? '-' : '';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: prominent ? 13 : 10.5,
              fontWeight: prominent ? FontWeight.w800 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '${prefix}TSh ${_sNum(amount.abs())}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: prominent ? 15 : 11,
            fontWeight: prominent ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ReceiptPaperClipper extends CustomClipper<Path> {
  const _ReceiptPaperClipper();

  @override
  Path getClip(Size size) {
    const toothWidth = 12.0;
    const toothDepth = 7.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - toothDepth);
    var x = size.width;
    var down = false;
    while (x > 0) {
      x = (x - toothWidth / 2).clamp(0, size.width);
      path.lineTo(x, down ? size.height - toothDepth : size.height);
      down = !down;
    }
    return path
      ..lineTo(0, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SaleSuccessNotice extends StatelessWidget {
  final Map<String, dynamic> saleData;
  final WidgetRef ref;

  const _SaleSuccessNotice({required this.saleData, required this.ref});

  @override
  Widget build(BuildContext context) {
    final amount = parseNumericAmount(saleData['amount']);
    final amountPaid = parseNumericAmount(saleData['amountPaid']);
    final outstanding = (amount - amountPaid).clamp(0.0, amount);
    final invoiceNo = (saleData['invoiceNumber'] ?? '').toString();
    final rawCustomer = (saleData['customerName'] ?? '').toString().trim();
    final customerName = rawCustomer.isEmpty
        ? _tr('Walk-in', 'Mteja wa kawaida')
        : rawCustomer;
    final status = (saleData['status'] ?? 'paid').toString();
    final items = (saleData['items'] as List?)?.whereType<Map>().toList() ?? [];
    final itemCount = items.fold<int>(
      0,
      (total, item) =>
          total +
          parseNumericAmount(item['qty'] ?? item['quantity'] ?? 1).round(),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Material(
            color: Colors.white,
            elevation: 18,
            shadowColor: AppColors.navyPrimary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 20, 12, 19),
                      color: AppColors.navyPrimary,
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr('Sale successful', 'Mauzo yamefanikiwa'),
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'TSh ${_sNum(amount)}',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: _tr('Close', 'Funga'),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SuccessNoticeDetail(
                                  label: _tr('Invoice', 'Ankara'),
                                  value: invoiceNo,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _SuccessNoticeDetail(
                                  label: _tr('Customer', 'Mteja'),
                                  value: customerName,
                                  alignEnd: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                size: 19,
                                color: AppColors.tealAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _tr(
                                    '$itemCount item${itemCount == 1 ? '' : 's'} sold',
                                    'Bidhaa $itemCount ${itemCount == 1 ? 'imeuzwa' : 'zimeuzwa'}',
                                  ),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              _SuccessStatusBadge(status),
                            ],
                          ),
                          if (outstanding > 0) ...[
                            const SizedBox(height: 12),
                            _SuccessTotalRow(
                              label: _tr('Balance Due', 'Baki'),
                              value: 'TSh ${_sNum(outstanding)}',
                              valueColor: AppColors.error,
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _SalesScreenState._openReceiptActions(
                                        context: context,
                                        sale: saleData,
                                        ref: ref,
                                      ),
                                  icon: const Icon(
                                    Icons.share_rounded,
                                    size: 17,
                                  ),
                                  label: Text(_tr('Receipt', 'Risiti')),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.tealAccent,
                                    side: const BorderSide(
                                      color: AppColors.tealAccent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: AppColors.navyPrimary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                  child: Text(_tr('Done', 'Maliza')),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class _SuccessNoticeDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _SuccessNoticeDetail({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.navyPrimary,
          ),
        ),
      ],
    );
  }
}

class _TicketReceiptCard extends StatelessWidget {
  final String invoiceNo;
  final String customerName;
  final double amount;
  final double amountPaid;
  final List<Map> items;
  final Map<String, dynamic> sale;
  final String statusStr;
  final DateTime createdAt;
  final VoidCallback onShare;
  final VoidCallback onDone;

  const _TicketReceiptCard({
    required this.invoiceNo,
    required this.customerName,
    required this.amount,
    required this.amountPaid,
    required this.items,
    required this.sale,
    required this.statusStr,
    required this.createdAt,
    required this.onShare,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    // Mirror the shared receipt text: items sold below catalog price show at
    // the catalog price, with the difference folded into the discount row.
    var itemDiscount = 0.0;
    final lineTotals = <double>[];
    for (final item in items) {
      final qtyNum = parseNumericAmount(item['qty'] ?? item['quantity'] ?? 1);
      final unitPrice = parseNumericAmount(item['unitPrice']);
      final basePrice = parseNumericAmount(item['basePrice']);
      var total = (item['total'] as num?)?.toDouble() ?? 0;
      if (unitPrice > 0 && basePrice > unitPrice) {
        itemDiscount += (basePrice - unitPrice) * qtyNum;
        total = basePrice * qtyNum;
      }
      lineTotals.add(total);
    }
    final discount =
        ((sale['discountAmount'] as num?)?.toDouble() ?? 0) + itemDiscount;
    final vat = (sale['vatAmount'] as num?)?.toDouble() ?? 0;
    final outstanding = (amount - amountPaid).clamp(0.0, amount);
    final payMethod = (sale['paymentMethod'] ?? '').toString();
    final mpesaRef = (sale['mpesaRef'] ?? '').toString();
    final dateStr =
        '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}  '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Navy semicircle notches — mimic a physical ticket stub
          Positioned(
            top: -1,
            left: -16,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
          Positioned(
            top: -1,
            right: -16,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navyPrimary,
              ),
            ),
          ),

          // Card content
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Perforated dashed line
                  const _PerforatedLine(),
                  const SizedBox(height: 20),

                  // Invoice meta row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr('Invoice', 'Ankara'),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            invoiceNo,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _tr('Customer', 'Mteja'),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            customerName,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),

                  // Line items
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${items[i]['name'] ?? items[i]['productName'] ?? '-'}  ×${items[i]['qty'] ?? items[i]['quantity'] ?? 1}',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            'TSh ${_sNum(lineTotals[i])}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 10),
                  ],

                  if (discount > 0) ...[
                    _SuccessTotalRow(
                      label: _tr('Discount', 'Punguzo'),
                      value: '-TSh ${_sNum(discount)}',
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (vat > 0) ...[
                    _SuccessTotalRow(
                      label: 'VAT (18%)',
                      value: 'TSh ${_sNum(vat)}',
                    ),
                    const SizedBox(height: 6),
                  ],
                  _SuccessTotalRow(
                    label: _tr('TOTAL', 'JUMLA KUU'),
                    value: 'TSh ${_sNum(amount)}',
                    isBold: true,
                  ),
                  const SizedBox(height: 6),
                  _SuccessTotalRow(
                    label: _tr('Paid', 'Imelipwa'),
                    value: 'TSh ${_sNum(amountPaid)}',
                    valueColor: AppColors.success,
                  ),
                  if (outstanding > 0) ...[
                    const SizedBox(height: 6),
                    _SuccessTotalRow(
                      label: _tr('Balance Due', 'Baki'),
                      value: 'TSh ${_sNum(outstanding)}',
                      valueColor: AppColors.error,
                    ),
                  ],

                  if (payMethod.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _pmIcon(payMethod),
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _pmLabel(payMethod),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (mpesaRef.isNotEmpty) ...[
                          Text(
                            ' · ',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            mpesaRef,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onShare,
                          icon: Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            _tr('Share', 'Shiriki'),
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: AppColors.tealAccent,
                            side: const BorderSide(
                              color: AppColors.tealAccent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onDone,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.navyPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _tr('Done', 'Maliza'),
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _pmIcon(String m) => switch (m) {
    'mpesa' => Icons.phone_android_rounded,
    'bank_transfer' => Icons.account_balance_rounded,
    'card' => Icons.credit_card_rounded,
    _ => Icons.payments_rounded,
  };

  String _pmLabel(String m) => switch (m) {
    'mpesa' => 'M-Pesa',
    'bank_transfer' => _tr('Bank Transfer', 'Uhamisho wa Benki'),
    'card' => _tr('Card', 'Kadi'),
    'credit' => _tr('Credit', 'Mkopo'),
    _ => _tr('Cash', 'Taslimu'),
  };
}

// Dashed perforated line (mimics a ticket tear edge)
class _PerforatedLine extends StatelessWidget {
  const _PerforatedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashW = 5.0;
        const gap = 4.0;
        final count = ((constraints.maxWidth) / (dashW + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1.5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuccessTotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SuccessTotalRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppColors.navyPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color:
                valueColor ??
                (isBold ? AppColors.navyPrimary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _SuccessStatusBadge extends StatelessWidget {
  final String status;
  const _SuccessStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, bg) = switch (status) {
      'paid' => (_tr('Paid', 'Imelipwa'), AppColors.success),
      'partial' => (_tr('Partial', 'Sehemu'), AppColors.warning),
      'unpaid' => (_tr('Credit', 'Mkopo'), AppColors.error),
      _ => (_tr('Sent', 'Imetumwa'), AppColors.tealAccent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
