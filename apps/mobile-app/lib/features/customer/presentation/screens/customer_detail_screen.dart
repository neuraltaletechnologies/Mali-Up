import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/data/repositories/context_firestore_repository.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/nav_aware_fab.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';
import '../../../../shared/widgets/smart_skeleton.dart';
import '../../../debt/data/customer_debt_sync_service.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../../rbac/data/rbac_providers.dart';
import '../../../sales/data/sales_providers.dart';
import '../../../sales/presentation/screens/invoice_detail_screen.dart';
import '../../data/customer_providers.dart';
import '../../domain/models/customer.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kTagVip = 'VIP';
const _kTagWholesale = 'Jumla';
const _kTagRetail = 'Reja reja';
const _kTagBlacklisted = 'Orodha Nyeusi';
const _kStandardTags = [_kTagVip, _kTagWholesale, _kTagRetail, _kTagBlacklisted];

// ─────────────────────────────────────────────────────────────────────────────
// Note types
// ─────────────────────────────────────────────────────────────────────────────

enum _NoteType { note, call, email, meeting, reminder }

extension _NoteTypeX on _NoteType {
  String get label => switch (this) {
        _NoteType.note => _tr('Note', 'Kumbukumbu'),
        _NoteType.call => _tr('Call', 'Simu'),
        _NoteType.email => _tr('Email', 'Barua pepe'),
        _NoteType.meeting => _tr('Meeting', 'Mkutano'),
        _NoteType.reminder => _tr('Reminder', 'Kumbusho'),
      };

  IconData get icon => switch (this) {
        _NoteType.note => Icons.sticky_note_2_rounded,
        _NoteType.call => Icons.phone_rounded,
        _NoteType.email => Icons.email_rounded,
        _NoteType.meeting => Icons.handshake_rounded,
        _NoteType.reminder => Icons.alarm_rounded,
      };

  Color get color => switch (this) {
        _NoteType.note => AppColors.navyPrimary,
        _NoteType.call => AppColors.success,
        _NoteType.email => AppColors.tealAccent,
        _NoteType.meeting => const Color(0xFFB45309),
        _NoteType.reminder => AppColors.warning,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Insight computation helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Insights {
  final double totalSpent;
  final double totalPending;
  final int totalInvoices;
  final int overdueCount;
  final DateTime? lastPurchase;
  final double avgOrderValue;
  final int avgDaysBetweenOrders; // -1 = insufficient data
  final int daysSinceLastPurchase; // -1 = no data

  const _Insights({
    required this.totalSpent,
    required this.totalPending,
    required this.totalInvoices,
    required this.overdueCount,
    required this.lastPurchase,
    required this.avgOrderValue,
    required this.avgDaysBetweenOrders,
    required this.daysSinceLastPurchase,
  });

  factory _Insights.fromInvoices(List<Map<String, dynamic>> invoices) {
    if (invoices.isEmpty) {
      return const _Insights(
        totalSpent: 0,
        totalPending: 0,
        totalInvoices: 0,
        overdueCount: 0,
        lastPurchase: null,
        avgOrderValue: 0,
        avgDaysBetweenOrders: -1,
        daysSinceLastPurchase: -1,
      );
    }

    double totalSpent = 0;
    double totalPending = 0;
    int overdueCount = 0;
    final dates = <DateTime>[];

    for (final inv in invoices) {
      final status = (inv['status'] ?? '').toString().toLowerCase();
      final amount = readInvoiceTotal(inv);
      final date = readTimestamp(inv['createdAt'] ?? inv['invoiceDate']);

      if (status == 'paid') {
        totalSpent += amount;
      } else if (status != 'cancelled' && status != 'draft') {
        totalPending += amount;
        if (status == 'overdue') overdueCount++;
      }

      if (date != null) dates.add(date);
    }

    dates.sort();
    final DateTime? lastPurchase = dates.isNotEmpty ? dates.last : null;

    final int daysSinceLast = lastPurchase != null
        ? DateTime.now().difference(lastPurchase).inDays
        : -1;

    int avgDays = -1;
    if (dates.length >= 2) {
      final gaps = <int>[];
      for (int i = 1; i < dates.length; i++) {
        gaps.add(dates[i].difference(dates[i - 1]).inDays);
      }
      final sum = gaps.fold(0, (a, b) => a + b);
      avgDays = (sum / gaps.length).round();
    }

    final paidCount =
        invoices.where((i) => (i['status'] ?? '') == 'paid').length;
    final avgOrder = paidCount > 0 ? totalSpent / paidCount : 0.0;

    return _Insights(
      totalSpent: totalSpent,
      totalPending: totalPending,
      totalInvoices: invoices.length,
      overdueCount: overdueCount,
      lastPurchase: lastPurchase,
      avgOrderValue: avgOrder,
      avgDaysBetweenOrders: avgDays,
      daysSinceLastPurchase: daysSinceLast,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the complete customer profile as a slide-up sheet.
///
/// [showAppSheet] enforces the app-wide maximum height of 80% of the screen.
Future<void> showCustomerDetailSheet(
  BuildContext context, {
  required Customer customer,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) => _CustomerDetailSheet(customer: customer),
  );
}

class _CustomerDetailSheet extends ConsumerStatefulWidget {
  final Customer customer;

  const _CustomerDetailSheet({required this.customer});

  @override
  ConsumerState<_CustomerDetailSheet> createState() =>
      _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends ConsumerState<_CustomerDetailSheet>
    with TickerProviderStateMixin {
  late Customer _customer;
  late TabController _tabCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _tabCtrl = TabController(length: 2, vsync: this);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _callCustomer() async {
    if (_customer.phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: _customer.phone);
    await launchUrl(uri);
  }

  void _whatsappCustomer() async {
    if (_customer.phone.isEmpty) return;
    final phone = _customer.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse('https://wa.me/$phone'),
        mode: LaunchMode.externalApplication);
  }

  void _smsCustomer() async {
    if (_customer.phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'sms', path: _customer.phone));
  }

  void _sendReminder() async {
    final balance = _customer.balanceAmount;
    if (balance <= 0) {
      _showSnack(_tr('No outstanding balance', 'Hakuna deni linalodaiwa'));
      return;
    }

    final invoices = ref
        .read(customerInvoicesProvider(_customer.id))
        .maybeWhen(data: (d) => d, orElse: () => <Map<String, dynamic>>[]);
    final overdue = invoices.where((inv) {
      final s = (inv['status'] ?? '').toString().toLowerCase();
      return s != 'paid' && s != 'cancelled' && s != 'draft';
    }).toList();

    final phone = _customer.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = _buildReminderText(_customer, balance, overdue);
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

    await _saveNote(
      type: _NoteType.reminder,
      text: _tr('Payment reminder sent via WhatsApp',
          'Kumbusho la malipo kilitumwa kupitia WhatsApp'),
    );
    await ref.read(customerAuditLoggerProvider).log(
          AuditLogService.reminderSent,
          customerId: _customer.id,
          customerName: _customer.name,
          newValue: 'whatsapp',
        );
  }

  String _buildReminderText(
      Customer c, double balance, List<Map<String, dynamic>> overdue) {
    final buf = StringBuffer();
    buf.writeln(_tr('Dear *${c.name}*,', 'Ndugu *${c.name}*,'));
    buf.writeln();
    buf.writeln(_tr(
        'This is a friendly reminder of your outstanding balance with us.',
        'Hii ni ukumbusho wa kirafiki wa salio lako linalodaiwa kwetu.'));
    buf.writeln();
    if (overdue.isNotEmpty) {
      buf.writeln(_tr('Unpaid invoices:', 'Ankara ambazo hazijalipwa:'));
      for (final inv in overdue.take(5)) {
        final invNum =
            inv['invoiceNumber']?.toString() ?? inv['id']?.toString() ?? '';
        final amt = readInvoiceTotal(inv);
        final date = readTimestamp(inv['invoiceDate'] ?? inv['createdAt']);
        final datePart = date != null ? ' (${_fmtDate(date)})' : '';
        buf.writeln('• ${_tr('Invoice', 'Ankara')} $invNum$datePart — TZS ${_fmtNum(amt)}');

        // List the purchased items so the customer knows which purchase created this debt.
        final rawItems = inv['lineItems'] ?? inv['items'];
        if (rawItems is List && rawItems.isNotEmpty) {
          for (final item in rawItems.take(3)) {
            final name = (item['name'] ?? item['productName'] ?? '').toString();
            if (name.isEmpty) continue;
            final rawQty = item['quantity'] ?? item['qty'] ?? 1;
            final qtyVal = rawQty is num ? rawQty.toDouble() : 1.0;
            final qtyStr = qtyVal % 1 == 0
                ? qtyVal.toInt().toString()
                : qtyVal.toStringAsFixed(1);
            buf.writeln('   › $name × $qtyStr');
          }
          if (rawItems.length > 3) {
            final extra = rawItems.length - 3;
            buf.writeln('   ${_tr('+ $extra more item${extra == 1 ? '' : 's'}', '+ vitu $extra zaidi')}');
          }
          buf.writeln();
        }
      }
      buf.writeln();
    }
    buf.writeln(
        '*${_tr('Total Outstanding: TZS ${_fmtNum(balance)}', 'Jumla Inayodaiwa: TZS ${_fmtNum(balance)}')}*');
    buf.writeln();
    buf.writeln(_tr('Please arrange payment at your earliest convenience.',
        'Tafadhali panga malipo haraka iwezekanavyo.'));
    buf.writeln(_tr('Thank you!', 'Asante!'));
    return buf.toString();
  }

  Future<void> _saveNote({
    required _NoteType type,
    required String text,
    DateTime? scheduledFor,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      // Notes live under the tenant owner's business — the same path the
      // notes stream reads from. Team members must not write to their own
      // (empty) tenant.
      final ownerUid = ref.read(tenantOwnerUidProvider) ?? user.uid;
      final bizId = ref.read(currentBusinessIdProvider).valueOrNull ?? '';
      if (bizId.isEmpty) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final customersCol = repo.scopeCollection(
          uid: ownerUid,
          context: ResolvedFinanceContext.business(bizId),
          childCollection: 'customers');
      await customersCol.doc(_customer.id).collection('notes').add({
        'type': type.name,
        'text': text,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': user.uid,
        if (scheduledFor != null)
          'scheduledFor': Timestamp.fromDate(scheduledFor),
        if (type == _NoteType.reminder) 'reminderSent': false,
      });
    } catch (_) {}
  }

  Future<void> _updateTags(List<String> newTags) async {
    final previous = _customer.tags;
    try {
      // Offline-first: Drift + sync queue in one transaction.
      await ref
          .read(customerRepositoryProvider)
          .save(_customer.copyWith(tags: newTags));
      setState(() => _customer = _customer.copyWith(tags: newTags));

      final logger = ref.read(customerAuditLoggerProvider);
      for (final tag in newTags.where((t) => !previous.contains(t))) {
        await logger.log(AuditLogService.tagAdded,
            customerId: _customer.id,
            customerName: _customer.name,
            newValue: tag);
      }
      for (final tag in previous.where((t) => !newTags.contains(t))) {
        await logger.log(AuditLogService.tagRemoved,
            customerId: _customer.id,
            customerName: _customer.name,
            previousValue: tag);
      }
    } catch (_) {
      _showSnack(_tr('Update failed', 'Imeshindwa kusasisha'));
    }
  }

  Future<void> _updateCreditLimit(double limit) async {
    final previous = _customer.creditLimit;
    try {
      await ref
          .read(customerRepositoryProvider)
          .save(_customer.copyWith(creditLimit: limit));
      setState(() => _customer = _customer.copyWith(creditLimit: limit));
      await ref.read(customerAuditLoggerProvider).log(
            AuditLogService.creditLimitChanged,
            customerId: _customer.id,
            customerName: _customer.name,
            previousValue: previous,
            newValue: limit,
          );
      _showSnack(_tr('Credit limit updated', 'Kikomo cha mkopo kimesasishwa'));
    } catch (_) {
      _showSnack(_tr('Update failed', 'Imeshindwa kusasisha'));
    }
  }

  void _openEdit() {
    showAppSheet(
      context,
      builder: (_) => _EditCustomerFullSheet(
        customer: _customer,
        onSaved: (updated) => setState(() => _customer = updated),
      ),
    );
  }

  void _showSnack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(permissionServiceProvider);
    final showFinancials = ps.canViewDebt || ps.isOwner;
    final canManage = ps.canManageCustomers || ps.isOwner;
    final canEditCredit = ps.canGrantCredit || ps.isOwner;

    // Live record from Drift — balance changes from sales, sync pulls, and
    // edits made elsewhere reflect here without re-opening the screen.
    final live = ref
        .watch(customerListProvider)
        .valueOrNull
        ?.where((c) => c.id == widget.customer.id)
        .firstOrNull;
    if (live != null) _customer = live;

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.navyPrimary,
              child: SheetHandle(),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: NestedScrollView(
                  headerSliverBuilder: (_, _) => [
                    _buildSliverAppBar(
                      canManage: canManage,
                      showFinancials: showFinancials,
                    ),
                    SliverToBoxAdapter(child: _buildTabBar()),
                  ],
                  body: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _OverviewTab(
                        customer: _customer,
                        showFinancials: showFinancials,
                        canEditCredit: canEditCredit,
                        onTagsChanged: _updateTags,
                        onCreditLimitSave: _updateCreditLimit,
                        onCall: _callCustomer,
                        onWhatsApp: _whatsappCustomer,
                        onSms: _smsCustomer,
                        onReminder: _sendReminder,
                        onPayDebt:
                            showFinancials ? _showPayDebtSheet : null,
                      ),
                      _ActivityTab(
                        customerId: _customer.id,
                        showFinancials: showFinancials,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar({
    required bool canManage,
    required bool showFinancials,
  }) {
    final balance = _customer.balanceAmount;
    final hasBalance = balance > 0;
    final initials = _customer.name.isNotEmpty
        ? _customer.name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return SliverAppBar(
      expandedHeight: 112,
      pinned: true,
      primary: false,
      backgroundColor: AppColors.navyPrimary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, size: 22),
        tooltip: _tr('Close', 'Funga'),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (canManage)
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            tooltip: _tr('Edit', 'Hariri'),
            onPressed: _openEdit,
          ),
        if (_customer.phone.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.phone_rounded, size: 20),
            tooltip: _tr('Call', 'Piga Simu'),
            onPressed: _callCustomer,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  // ── Avatar ────────────────────────────────────────────────
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 11),
                  // ── Name + phone ──────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _customer.name,
                                style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_customer.isOrganisation)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _tr('ORG', 'SHIRIKA'),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                        if (_customer.phone.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(_customer.phone,
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: Colors.white60)),
                        ],
                      ],
                    ),
                  ),
                  // ── Balance pill ──────────────────────────────────────────
                  if (showFinancials) ...[
                    SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          hasBalance
                              ? 'TZS ${_fmtNum(balance)}'
                              : _tr('All clear', 'Hakuna deni'),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: hasBalance
                                ? const Color(0xFFFC8181)
                                : const Color(0xFF86EFAC),
                          ),
                        ),
                        if (_customer.isOverCreditLimit)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _tr('OVER LIMIT', 'IMEZIDI'),
                              style: GoogleFonts.dmSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFC8181)),
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
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            labelStyle:
                GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: AppColors.navyPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.navyPrimary,
            indicatorWeight: 2.5,
            tabs: [
              Tab(text: _tr('Overview', 'Muhtasari')),
              Tab(text: _tr('Activity', 'Shughuli')),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  void _showPayDebtSheet() {
    final balance = _customer.balanceAmount;
    if (balance <= 0) return;
    showAppSheet(
      context,
      builder: (_) => CustomerPayDebtSheet(
        customerName: _customer.name,
        balance: balance,
        onSave: (amount, method, note) async {
          final newBalance = balance - amount;
          final user = FirebaseAuth.instance.currentUser;
          try {
            // Move the balance as a delta (Drift + queued
            // FieldValue.increment) — Customer.toFirestore() excludes
            // balance, so a full save would never reach the server.
            await ref
                .read(customerRepositoryProvider)
                .adjustBalance(_customer.id, -amount);
            // Pay down the customer's open receivables so the Debts screen
            // reflects this payment too.
            await applyCustomerPaymentToDebts(
              ref,
              customerId: _customer.id,
              amount: amount,
              method: method,
              note: note,
              recordedBy: user?.uid ?? '',
            );
            // Record the payment event in Firestore subcollection
            if (user != null) {
              final ownerUid = ref.read(tenantOwnerUidProvider) ?? user.uid;
              final bizId =
                  ref.read(currentBusinessIdProvider).valueOrNull ?? '';
              if (bizId.isNotEmpty) {
                final fsRepo = ref.read(contextFirestoreRepositoryProvider);
                final col = fsRepo.scopeCollection(
                  uid: ownerUid,
                  context: ResolvedFinanceContext.business(bizId),
                  childCollection: 'customers',
                );
                await col.doc(_customer.id).collection('payments').add({
                  'amount': amount,
                  'method': method,
                  'note': note,
                  'paidAt': FieldValue.serverTimestamp(),
                  'recordedBy': user.uid,
                });
              }
            }
            await ref.read(customerAuditLoggerProvider).log(
              AuditLogService.customerUpdated,
              customerId: _customer.id,
              customerName: _customer.name,
              previousValue: 'balance:$balance',
              newValue: 'balance:$newBalance',
            );
            if (mounted) {
              _showSnack(
                _tr('Payment recorded successfully',
                    'Malipo yamerekodiwa kikamilifu'),
                color: AppColors.success,
              );
            }
          } catch (_) {
            if (mounted) {
              _showSnack(_tr(
                  'Failed to record payment', 'Imeshindwa kurekodi malipo'));
            }
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerStatefulWidget {
  final Customer customer;
  final bool showFinancials;
  final bool canEditCredit;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<double> onCreditLimitSave;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onSms;
  final VoidCallback onReminder;
  final VoidCallback? onPayDebt;

  const _OverviewTab({
    required this.customer,
    required this.showFinancials,
    required this.canEditCredit,
    required this.onTagsChanged,
    required this.onCreditLimitSave,
    required this.onCall,
    required this.onWhatsApp,
    required this.onSms,
    required this.onReminder,
    this.onPayDebt,
  });

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  late List<String> _tags;
  final _limitCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.customer.tags);
    _limitCtrl.text = widget.customer.creditLimit > 0
        ? widget.customer.creditLimit.toStringAsFixed(0)
        : '';
  }

  @override
  void didUpdateWidget(covariant _OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resync local edit state when the live customer record changes.
    if (!listEquals(oldWidget.customer.tags, widget.customer.tags)) {
      _tags = List.from(widget.customer.tags);
    }
    if (oldWidget.customer.creditLimit != widget.customer.creditLimit) {
      _limitCtrl.text = widget.customer.creditLimit > 0
          ? widget.customer.creditLimit.toStringAsFixed(0)
          : '';
    }
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final updated = List<String>.from(_tags);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    setState(() => _tags = updated);
    widget.onTagsChanged(updated);
  }

  void _addCustomTag(String tag) {
    if (tag.isEmpty || _tags.contains(tag)) return;
    final updated = List<String>.from(_tags)..add(tag);
    setState(() => _tags = updated);
    widget.onTagsChanged(updated);
  }

  void _removeCustomTag(String tag) {
    final updated = List<String>.from(_tags)..remove(tag);
    setState(() => _tags = updated);
    widget.onTagsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.customer.balanceAmount;
    final limit = widget.customer.creditLimit;
    final c = widget.customer;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ── Quick actions ─────────────────────────────────────────────────
        _QuickActions(
          onCall: widget.onCall,
          onWhatsApp: widget.onWhatsApp,
          onSms: widget.onSms,
          onReminder: widget.onReminder,
          showReminder: widget.showFinancials,
        ),
        const SizedBox(height: 16),

        // ── Smart Insights ────────────────────────────────────────────────
        if (widget.showFinancials)
          _InsightsCard(customerId: c.id),
        if (widget.showFinancials) const SizedBox(height: 16),

        // ── Balance + credit limit ────────────────────────────────────────
        if (widget.showFinancials) ...[
          _BalanceCard(
            balance: balance,
            limit: limit,
            limitCtrl: _limitCtrl,
            canEditCredit: widget.canEditCredit,
            onSaveLimit: (v) => widget.onCreditLimitSave(v),
            onPayDebt: widget.onPayDebt,
          ),
          const SizedBox(height: 16),
        ],

        // ── Contact info ──────────────────────────────────────────────────
        _ContactCard(customer: c),
        const SizedBox(height: 16),

        // ── Segmentation tags ─────────────────────────────────────────────
        _TagsCard(
          tags: _tags,
          standardTags: _kStandardTags,
          onToggle: _toggleTag,
          onAddCustom: _addCustomTag,
          onRemoveCustom: _removeCustomTag,
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onSms;
  final VoidCallback onReminder;
  final bool showReminder;

  const _QuickActions({
    required this.onCall,
    required this.onWhatsApp,
    required this.onSms,
    required this.onReminder,
    required this.showReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: Icons.phone_rounded,
            label: _tr('Call', 'Simu'),
            color: AppColors.success,
            onTap: onCall,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: onWhatsApp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.sms_rounded,
            label: _tr('Message', 'Ujumbe'),
            color: AppColors.tealAccent,
            onTap: onSms,
          ),
        ),
        if (showReminder) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _ActionBtn(
              icon: Icons.alarm_rounded,
              label: _tr('Remind', 'Kumbushia'),
              color: AppColors.warning,
              onTap: onReminder,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowCard, blurRadius: 4, offset: Offset(0, 1))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance card
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  final double balance;
  final double limit;
  final TextEditingController limitCtrl;
  final bool canEditCredit;
  final ValueChanged<double> onSaveLimit;
  final VoidCallback? onPayDebt;

  const _BalanceCard({
    required this.balance,
    required this.limit,
    required this.limitCtrl,
    required this.canEditCredit,
    required this.onSaveLimit,
    this.onPayDebt,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _editingLimit = false;

  @override
  Widget build(BuildContext context) {
    final hasLimit = widget.limit > 0;
    final progress = hasLimit
        ? (widget.balance / widget.limit).clamp(0.0, 1.0)
        : 0.0;
    final overLimit = hasLimit && widget.balance > widget.limit;
    final availableCredit =
        hasLimit ? (widget.limit - widget.balance).clamp(0.0, widget.limit) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overLimit
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowCard, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.balance > 0
                      ? AppColors.errorBg
                      : AppColors.successBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  widget.balance > 0
                      ? Icons.account_balance_wallet_rounded
                      : widget.balance < 0
                          ? Icons.savings_rounded
                          : Icons.check_circle_rounded,
                  size: 16,
                  color: widget.balance > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.balance < 0
                          ? _tr('Reserve Credit', 'Akiba ya Mteja')
                          : _tr('Outstanding Balance', 'Deni Linalodaiwa'),
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          letterSpacing: 0.4),
                    ),
                    Text(
                      widget.balance > 0
                          ? 'TZS ${_fmtNum(widget.balance)}'
                          : widget.balance < 0
                              ? '+TZS ${_fmtNum(widget.balance.abs())}'
                              : _tr('All clear', 'Hakuna deni'),
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22,
                          color: widget.balance > 0
                              ? AppColors.error
                              : AppColors.success),
                    ),
                  ],
                ),
              ),
              if (overLimit)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _tr('OVER LIMIT', 'IMEZIDI'),
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error),
                  ),
                ),
            ],
          ),

          // ── Credit utilization ────────────────────────────────────────
          if (hasLimit) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                    overLimit ? AppColors.error : AppColors.warning),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _CreditStat(
                    label: _tr('Used', 'Imetumika'),
                    value: 'TZS ${_fmtShort(widget.balance)}',
                    color: overLimit ? AppColors.error : AppColors.warning,
                  ),
                ),
                Expanded(
                  child: _CreditStat(
                    label: _tr('Available', 'Inabaki'),
                    value: overLimit
                        ? _tr('Exceeded', 'Imezidi')
                        : 'TZS ${_fmtShort(availableCredit)}',
                    color:
                        overLimit ? AppColors.error : AppColors.success,
                  ),
                ),
                Expanded(
                  child: _CreditStat(
                    label: _tr('Limit', 'Kikomo'),
                    value: 'TZS ${_fmtShort(widget.limit)}',
                    color: AppColors.navyPrimary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // ── Credit limit editor ───────────────────────────────────────
          if (widget.canEditCredit)
            _editingLimit
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.limitCtrl,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: GoogleFonts.jetBrainsMono(fontSize: 14),
                          decoration: InputDecoration(
                            prefixText: 'TZS ',
                            prefixStyle: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textMuted),
                            hintText: _tr('0 = no limit', '0 = bila kikomo'),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final v =
                              double.tryParse(widget.limitCtrl.text) ?? 0;
                          widget.onSaveLimit(v);
                          setState(() => _editingLimit = false);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(_tr('Save', 'Hifadhi'),
                            style: GoogleFonts.dmSans(fontSize: 13)),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _editingLimit = false),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textMuted),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => setState(() => _editingLimit = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.tealAccent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppColors.tealAccent.withValues(alpha: 0.30)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.credit_score_rounded,
                              size: 16, color: AppColors.tealAccent),
                          SizedBox(width: 8),
                          Text(
                            hasLimit
                                ? _tr('Edit credit limit',
                                    'Badilisha kikomo cha mkopo')
                                : _tr('Set credit limit',
                                    'Weka kikomo cha mkopo'),
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.tealAccent,
                                fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded,
                              size: 16,
                              color:
                                  AppColors.tealAccent.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  )
          else
            Row(
              children: [
                const Icon(Icons.credit_score_rounded,
                    size: 16, color: AppColors.textDisabled),
                SizedBox(width: 6),
                Text(
                  hasLimit
                      ? _tr('Credit limit: TZS ${_fmtNum(widget.limit)}',
                          'Kikomo cha mkopo: TZS ${_fmtNum(widget.limit)}')
                      : _tr('No credit limit set', 'Hakuna kikomo cha mkopo'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),

          // ── Pay Debt button ───────────────────────────────────────
          if (widget.balance > 0 && widget.onPayDebt != null) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onPayDebt,
                icon: Icon(Icons.payments_rounded, size: 16),
                label: Text(
                  _tr('Pay Debt', 'Lipa Deni'),
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreditStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CreditStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart Insights card
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsCard extends ConsumerWidget {
  final String customerId;
  const _InsightsCard({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));

    return invoicesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (invoices) {
        if (invoices.isEmpty) return const SizedBox.shrink();
        final ins = _Insights.fromInvoices(invoices);
        final items = _buildInsightItems(ins);
        if (items.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadowCard,
                  blurRadius: 6,
                  offset: Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.insights_rounded,
                        size: 15, color: AppColors.navyPrimary),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _tr('Customer Insights', 'Uchambuzi wa Mteja'),
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => _InsightRow(
                    icon: item.icon,
                    text: item.text,
                    color: item.color,
                  )),
            ],
          ),
        );
      },
    );
  }

  List<_InsightItem> _buildInsightItems(_Insights ins) {
    final items = <_InsightItem>[];

    // Total spent
    if (ins.totalSpent > 0) {
      items.add(_InsightItem(
        icon: Icons.payments_rounded,
        text: _tr(
          'Spent TZS ${_fmtNum(ins.totalSpent)} in total',
          'Ametumia TZS ${_fmtNum(ins.totalSpent)} jumla',
        ),
        color: AppColors.navyPrimary,
      ));
    }

    // Invoice count
    if (ins.totalInvoices > 0) {
      items.add(_InsightItem(
        icon: Icons.receipt_long_rounded,
        text: _tr(
          '${ins.totalInvoices} invoice${ins.totalInvoices == 1 ? '' : 's'} recorded',
          'Ankara ${ins.totalInvoices} zimerekodiwa',
        ),
        color: AppColors.tealAccent,
      ));
    }

    // Average order value
    if (ins.avgOrderValue > 0) {
      items.add(_InsightItem(
        icon: Icons.bar_chart_rounded,
        text: _tr(
          'Avg. order: TZS ${_fmtNum(ins.avgOrderValue)}',
          'Wastani wa agizo: TZS ${_fmtNum(ins.avgOrderValue)}',
        ),
        color: AppColors.navySecondary,
      ));
    }

    // Purchase frequency
    if (ins.avgDaysBetweenOrders > 0) {
      items.add(_InsightItem(
        icon: Icons.autorenew_rounded,
        text: _tr(
          'Purchases every ~${ins.avgDaysBetweenOrders} days on average',
          'Ananunua kila ~${ins.avgDaysBetweenOrders} siku kwa wastani',
        ),
        color: AppColors.success,
      ));
    }

    // Days since last purchase
    if (ins.daysSinceLastPurchase >= 0) {
      if (ins.daysSinceLastPurchase == 0) {
        items.add(_InsightItem(
          icon: Icons.today_rounded,
          text: _tr('Last purchase: Today', 'Ununuzi wa mwisho: Leo'),
          color: AppColors.success,
        ));
      } else if (ins.daysSinceLastPurchase <= 30) {
        items.add(_InsightItem(
          icon: Icons.history_rounded,
          text: _tr(
            'Last purchase: ${ins.daysSinceLastPurchase} days ago',
            'Ununuzi wa mwisho: siku ${ins.daysSinceLastPurchase} zilizopita',
          ),
          color: AppColors.success,
        ));
      } else if (ins.daysSinceLastPurchase <= 60) {
        items.add(_InsightItem(
          icon: Icons.history_rounded,
          text: _tr(
            'No purchases in ${ins.daysSinceLastPurchase} days',
            'Hakuna ununuzi kwa siku ${ins.daysSinceLastPurchase}',
          ),
          color: AppColors.warning,
        ));
      } else {
        items.add(_InsightItem(
          icon: Icons.history_rounded,
          text: _tr(
            'Inactive for ${ins.daysSinceLastPurchase} days — follow up!',
            'Hamna shughuli kwa siku ${ins.daysSinceLastPurchase} — wasiliana!',
          ),
          color: AppColors.error,
        ));
      }
    }

    // Pending amount
    if (ins.totalPending > 0) {
      items.add(_InsightItem(
        icon: Icons.pending_actions_rounded,
        text: _tr(
          'TZS ${_fmtNum(ins.totalPending)} pending payment',
          'TZS ${_fmtNum(ins.totalPending)} inasubiri malipo',
        ),
        color: AppColors.warning,
      ));
    }

    // Overdue warning
    if (ins.overdueCount > 0) {
      items.add(_InsightItem(
        icon: Icons.warning_amber_rounded,
        text: _tr(
          '${ins.overdueCount} overdue invoice${ins.overdueCount == 1 ? '' : 's'} — action needed',
          'Ankara ${ins.overdueCount} zimekwisha muda — hatua inahitajika',
        ),
        color: AppColors.error,
      ));
    }

    return items;
  }
}

class _InsightItem {
  final IconData icon;
  final String text;
  final Color color;
  const _InsightItem({required this.icon, required this.text, required this.color});
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InsightRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact card
// ─────────────────────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final Customer customer;
  const _ContactCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    if (customer.phone.isEmpty &&
        customer.email.isEmpty &&
        customer.address.isEmpty &&
        customer.tinNumber.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowCard, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.contact_page_rounded,
                      size: 15, color: AppColors.tealAccent),
                ),
                SizedBox(width: 10),
                Text(
                  _tr('Contact Info', 'Mawasiliano'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          if (customer.phone.isNotEmpty)
            _ContactRow(
              icon: Icons.phone_rounded,
              iconColor: AppColors.success,
              label: _tr('Phone', 'Simu'),
              value: customer.phone,
              copyValue: customer.phone,
              onCopied: (ctx) => _toast(ctx,
                  _tr('Phone number copied', 'Namba ya simu imenakiliwa')),
            ),
          if (customer.email.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _ContactRow(
              icon: Icons.email_rounded,
              iconColor: AppColors.tealAccent,
              label: _tr('Email', 'Barua pepe'),
              value: customer.email,
              copyValue: customer.email,
              onCopied: (ctx) =>
                  _toast(ctx, _tr('Email copied', 'Barua pepe imenakiliwa')),
            ),
          ],
          if (customer.address.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _ContactRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.navyPrimary,
              label: _tr('Address', 'Anwani'),
              value: customer.address,
              copyValue: customer.address,
              onCopied: (ctx) =>
                  _toast(ctx, _tr('Address copied', 'Anwani imenakiliwa')),
            ),
          ],
          if (customer.tinNumber.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _ContactRow(
              icon: Icons.numbers_rounded,
              iconColor: AppColors.warning,
              label: 'TIN',
              value: customer.tinNumber,
              copyValue: customer.tinNumber,
              onCopied: (ctx) =>
                  _toast(ctx, _tr('TIN copied', 'TIN imenakiliwa')),
            ),
          ],
        ],
      ),
    );
  }

  void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? copyValue;
  final void Function(BuildContext ctx)? onCopied;

  const _ContactRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.copyValue,
    this.onCopied,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: copyValue != null
          ? () async {
              await Clipboard.setData(ClipboardData(text: copyValue!));
              if (context.mounted) onCopied?.call(context);
            }
          : null,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 10, color: AppColors.textMuted)),
                  Text(value,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            if (copyValue != null)
              const Icon(Icons.copy_rounded,
                  size: 14, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tags card (standard + custom creation)
// ─────────────────────────────────────────────────────────────────────────────

class _TagsCard extends StatefulWidget {
  final List<String> tags;
  final List<String> standardTags;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onAddCustom;
  final ValueChanged<String> onRemoveCustom;

  const _TagsCard({
    required this.tags,
    required this.standardTags,
    required this.onToggle,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  @override
  State<_TagsCard> createState() => _TagsCardState();
}

class _TagsCardState extends State<_TagsCard> {
  bool _addingCustom = false;
  final _customTagCtrl = TextEditingController();

  @override
  void dispose() {
    _customTagCtrl.dispose();
    super.dispose();
  }

  Color _color(String tag) {
    final t = tag.toLowerCase();
    if (t == 'vip') return const Color(0xFFB45309);
    if (t.contains('nyeusi') || t.contains('black')) return AppColors.error;
    if (t.contains('jumla') || t.contains('wholesale')) {
      return AppColors.tealAccent;
    }
    return AppColors.navySecondary;
  }

  @override
  Widget build(BuildContext context) {
    final customTags =
        widget.tags.where((t) => !widget.standardTags.contains(t)).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowCard, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _tr('Segment Tags', 'Lebo za Kundi'),
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _addingCustom = !_addingCustom;
                  if (!_addingCustom) _customTagCtrl.clear();
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _addingCustom
                            ? Icons.close_rounded
                            : Icons.add_rounded,
                        size: 14,
                        color: AppColors.navyPrimary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _addingCustom
                            ? _tr('Cancel', 'Ghairi')
                            : _tr('Custom tag', 'Lebo maalum'),
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Standard tags ─────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.standardTags.map((tag) {
              final active = widget.tags.contains(tag);
              final color = _color(tag);
              return GestureDetector(
                onTap: () => widget.onToggle(tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: active ? color : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(Icons.check_rounded,
                              size: 13, color: Colors.white),
                        ),
                      Text(
                        tag,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // ── Custom tag input ──────────────────────────────────────────
          if (_addingCustom) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTagCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.dmSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _tr(
                          'e.g. Frequent Buyer, Corporate…',
                          'mfano: Mnunuzi wa kawaida, Kampuni…'),
                      hintStyle: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textMuted),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (v) {
                      final tag = v.trim();
                      if (tag.isNotEmpty) {
                        widget.onAddCustom(tag);
                        _customTagCtrl.clear();
                        setState(() => _addingCustom = false);
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final tag = _customTagCtrl.text.trim();
                    if (tag.isNotEmpty) {
                      widget.onAddCustom(tag);
                      _customTagCtrl.clear();
                      setState(() => _addingCustom = false);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_tr('Add', 'Ongeza'),
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: Colors.white)),
                ),
              ],
            ),
          ],

          // ── Custom tags list ──────────────────────────────────────────
          if (customTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            SizedBox(height: 10),
            Text(
              _tr('Custom Tags', 'Lebo za Mtumiaji'),
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: customTags
                  .map((tag) => _CustomTagPill(
                        tag: tag,
                        onRemove: () => widget.onRemoveCustom(tag),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomTagPill extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;
  const _CustomTagPill({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.navyPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navyPrimary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Invoices (kept for potential future re-use; no longer in tab bar)
// ─────────────────────────────────────────────────────────────────────────────

// ignore: unused_element
class _InvoicesTab extends ConsumerWidget {
  final String customerId;
  final bool showFinancials;

  const _InvoicesTab({required this.customerId, required this.showFinancials});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));

    return invoicesAsync.smartWhen(
      skeleton: () => const Column(
        children: [
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      ),
      onError: (e, _) => Center(child: Text('$e')),
      data: (invoices) {
        if (invoices.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: _tr(
                'No invoices yet', 'Bado hakuna ankara'),
            subtitle: _tr(
                'Record a sale to see invoices here.',
                'Rekodi uuzaji ili kuona ankara hapa.'),
          );
        }

        // ── Compute stats ───────────────────────────────────────────────
        final ins = _Insights.fromInvoices(invoices);
        final totalCount = invoices.length;
        final paidCount =
            invoices.where((i) => (i['status'] ?? '') == 'paid').length;

        return Column(
          children: [
            if (showFinancials) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: _tr('Total Spent', 'Jumla Iliyolipwa'),
                        value: 'TZS ${_fmtShort(ins.totalSpent)}',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: _tr('Pending', 'Inasubiri'),
                        value: 'TZS ${_fmtShort(ins.totalPending)}',
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: _tr('Invoices', 'Ankara'),
                        value: '$paidCount / $totalCount',
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (ins.avgOrderValue > 0)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.navyPrimary
                              .withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded,
                            size: 14, color: AppColors.navyPrimary),
                        SizedBox(width: 8),
                        Text(
                          _tr(
                            'Avg. order value: TZS ${_fmtNum(ins.avgOrderValue)}',
                            'Wastani wa agizo: TZS ${_fmtNum(ins.avgOrderValue)}',
                          ),
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.navyPrimary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                itemCount: invoices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _InvoiceTile(invoice: invoices[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final status = (invoice['status'] ?? 'pending').toString().toLowerCase();
    final total = readInvoiceTotal(invoice);
    final number = invoice['invoiceNumber']?.toString() ??
        invoice['id']?.toString() ??
        '—';
    final createdAt =
        readTimestamp(invoice['createdAt'] ?? invoice['invoiceDate']);
    final dueDate = readTimestamp(invoice['dueDate']);
    final isQuotation =
        (invoice['type'] ?? '').toString().toLowerCase() == 'quotation';

    final rawItems = invoice['lineItems'] ?? invoice['items'];
    final itemCount = rawItems is List ? rawItems.length : 0;

    final isOverdue = status != 'paid' &&
        status != 'cancelled' &&
        dueDate != null &&
        dueDate.isBefore(DateTime.now());

    final statusColor = switch (status) {
      'paid' => AppColors.success,
      'sent' => AppColors.tealAccent,
      'overdue' => AppColors.error,
      'draft' => AppColors.textMuted,
      'cancelled' => AppColors.textDisabled,
      _ => AppColors.warning,
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoice: invoice),
        )),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
              right: const BorderSide(color: AppColors.border),
              top: const BorderSide(color: AppColors.border),
              bottom: const BorderSide(color: AppColors.border),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          number,
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        if (isQuotation) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.tealAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _tr('QUOTE', 'NUKUU'),
                              style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tealAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        if (createdAt != null) ...[
                          const Icon(Icons.calendar_today_rounded,
                              size: 10, color: AppColors.textDisabled),
                          SizedBox(width: 3),
                          Text(
                            _fmtDate(createdAt),
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                        if (createdAt != null && itemCount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                  color: AppColors.textDisabled,
                                  shape: BoxShape.circle),
                            ),
                          ),
                        if (itemCount > 0)
                          Text(
                            _tr('$itemCount item${itemCount == 1 ? '' : 's'}',
                                'vitu $itemCount'),
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                    if (dueDate != null) ...[
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 10,
                            color: isOverdue
                                ? AppColors.error
                                : AppColors.textDisabled,
                          ),
                          SizedBox(width: 3),
                          Text(
                            '${_tr('Due', 'Mwisho')}: ${_fmtDate(dueDate)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: isOverdue
                                  ? AppColors.error
                                  : AppColors.textMuted,
                              fontWeight: isOverdue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TZS ${_fmtNum(total)}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  PaymentStatusChip(status: status),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes / Communication Log (kept for potential future re-use; no longer in tab bar)
// ─────────────────────────────────────────────────────────────────────────────

// ignore: unused_element
class _NotesTab extends ConsumerWidget {
  final String customerId;
  final String customerName;
  final VoidCallback onAddNote;

  const _NotesTab({
    required this.customerId,
    required this.customerName,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(customerNotesProvider(customerId));

    return notesAsync.smartWhen(
      skeleton: () => const Column(
        children: [
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      ),
      onError: (e, _) => Center(child: Text('$e')),
      data: (notes) => Stack(
        children: [
          notes.isEmpty
              ? EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: _tr('No notes yet', 'Bado hakuna maelezo'),
                  subtitle: _tr(
                    'Log a call, meeting, or reminder for this customer.',
                    'Rekodi simu, mkutano, au kumbusho kwa mteja huyu.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NoteTile(note: notes[i]),
                ),
          Positioned(
            bottom: 20,
            right: 16,
            child: NavAwareFab(
              child: FloatingActionButton.extended(
                heroTag: 'add-note-fab',
                onPressed: onAddNote,
                backgroundColor: AppColors.navyPrimary,
                icon: Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  _tr('Add Note', 'Ongeza Logi'),
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Map<String, dynamic> note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final typeStr = (note['type'] ?? 'note').toString();
    final type = _NoteType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => _NoteType.note,
    );
    final text = note['text']?.toString() ?? '';
    final addedAt = readTimestamp(note['addedAt']);
    final scheduledFor = readTimestamp(note['scheduledFor']);
    final isReminder = type == _NoteType.reminder;
    final reminderSent = note['reminderSent'] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: type.color, width: 3),
          right: const BorderSide(color: AppColors.border),
          top: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(type.icon, size: 15, color: type.color),
              ),
              SizedBox(width: 8),
              Text(
                type.label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: type.color),
              ),
              const Spacer(),
              if (addedAt != null)
                Text(
                  _fmtDate(addedAt),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
          if (text.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textPrimary)),
          ],
          if (isReminder && scheduledFor != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: reminderSent ? AppColors.success : AppColors.warning,
                ),
                SizedBox(width: 4),
                Text(
                  '${_tr("Scheduled:", "Imepangwa:")} ${_fmtDate(scheduledFor)}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: reminderSent
                          ? AppColors.success
                          : AppColors.warning),
                ),
                if (reminderSent) ...[
                  SizedBox(width: 6),
                  Text(
                    _tr('Sent', 'Imetumwa'),
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.success),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Note Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddNoteSheet extends StatefulWidget {
  final Future<void> Function(
      _NoteType type, String text, DateTime? scheduledFor) onSave;

  const _AddNoteSheet({required this.onSave});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  _NoteType _type = _NoteType.note;
  final _textCtrl = TextEditingController();
  DateTime? _scheduledFor;
  bool _saving = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _scheduledFor = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _tr('Log Activity', 'Rekodi Shughuli'),
              style: GoogleFonts.dmSans(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            // Type selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _NoteType.values.map((t) {
                  final active = t == _type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? t.color : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: active ? t.color : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon,
                                size: 13,
                                color: active ? Colors.white : t.color),
                            SizedBox(width: 5),
                            Text(t.label,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? Colors.white
                                        : AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _textCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _type == _NoteType.call
                      ? _tr('What was discussed?', 'Nini kilijadiliwa?')
                      : _type == _NoteType.reminder
                          ? _tr('Reminder details…', 'Maelezo ya kumbusho…')
                          : _type == _NoteType.meeting
                              ? _tr('Meeting outcome…', 'Matokeo ya mkutano…')
                              : _tr('Add notes…', 'Ongeza maelezo…'),
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: GoogleFonts.dmSans(fontSize: 14),
              ),
            ),
            if (_type == _NoteType.reminder) ...[
              SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_rounded,
                          size: 16, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text(
                        _scheduledFor != null
                            ? _fmtDate(_scheduledFor!)
                            : _tr(
                                'Set reminder date', 'Weka tarehe ya kumbusho'),
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: AppColors.warning),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (_textCtrl.text.trim().isEmpty) return;
                        setState(() => _saving = true);
                        await widget.onSave(
                          _type,
                          _textCtrl.text.trim(),
                          _scheduledFor,
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _tr('Save Note', 'Hifadhi Maelezo'),
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Customer Full Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditCustomerFullSheet extends ConsumerStatefulWidget {
  final Customer customer;
  final ValueChanged<Customer> onSaved;

  const _EditCustomerFullSheet(
      {required this.customer, required this.onSaved});

  @override
  ConsumerState<_EditCustomerFullSheet> createState() =>
      _EditCustomerFullSheetState();
}

class _EditCustomerFullSheetState
    extends ConsumerState<_EditCustomerFullSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _tinCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _limitCtrl;
  late bool _isOrg;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c.name);
    _phoneCtrl = TextEditingController(text: c.phone);
    _emailCtrl = TextEditingController(text: c.email);
    _tinCtrl = TextEditingController(text: c.tinNumber);
    _addressCtrl = TextEditingController(text: c.address);
    _limitCtrl = TextEditingController(
        text: c.creditLimit > 0 ? c.creditLimit.toStringAsFixed(0) : '');
    _isOrg = c.isOrganisation;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _tinCtrl.dispose();
    _addressCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final limit = double.tryParse(_limitCtrl.text) ?? 0;
      final updated = widget.customer.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        isOrganisation: _isOrg,
        address: _addressCtrl.text.trim(),
        tinNumber: _tinCtrl.text.trim(),
        creditLimit: limit,
      );

      // Offline-first: Drift + sync queue in one transaction.
      await ref.read(customerRepositoryProvider).save(updated);
      await ref.read(customerAuditLoggerProvider).log(
            AuditLogService.customerUpdated,
            customerId: updated.id,
            customerName: updated.name,
          );

      widget.onSaved(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        content: Text(_tr(
          'Could not save changes. Please try again.',
          'Imeshindwa kuhifadhi mabadiliko. Jaribu tena.',
        )),
      ));
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 2),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _tr('Edit Profile', 'Hariri Wasifu'),
                    style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary),
                  ),
                  const SizedBox(height: 16),
                  _TypeToggleRow(
                    isOrg: _isOrg,
                    onChanged: (v) => setState(() => _isOrg = v),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec(
                      _isOrg
                          ? _tr('Organisation Name *', 'Jina la Shirika *')
                          : _tr('Customer Name *', 'Jina la Mteja *'),
                      _isOrg
                          ? Icons.business_outlined
                          : Icons.person_outline_rounded,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tr('Required', 'Inahitajika')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        _dec(_tr('Phone *', 'Simu *'), Icons.phone_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tr('Required', 'Inahitajika')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec(
                        _tr('Email', 'Barua pepe'), Icons.email_outlined),
                  ),
                  if (_isOrg) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tinCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _dec(
                          _tr('TIN Number', 'Namba ya TIN'),
                          Icons.numbers_outlined),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(
                        _tr('Address', 'Anwani'), Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _limitCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _dec(
                      _tr('Credit Limit (TZS)', 'Kikomo cha Mkopo (TZS)'),
                      Icons.credit_score_rounded,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _saving ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_tr('Cancel', 'Ghairi'),
                              style: GoogleFonts.dmSans()),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navyPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text(
                                  _tr('Save Changes', 'Hifadhi Mabadiliko'),
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared detail-screen sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggleRow extends StatelessWidget {
  final bool isOrg;
  final ValueChanged<bool> onChanged;

  const _TypeToggleRow({required this.isOrg, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleTab(
            label: _tr('Individual', 'Mtu Binafsi'),
            icon: Icons.person_outline_rounded,
            active: !isOrg,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _ToggleTab(
            label: _tr('Organisation', 'Shirika'),
            icon: Icons.business_outlined,
            active: isOrg,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleTab(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.navyPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? Colors.white : AppColors.textMuted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: active ? Colors.white : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pay Debt Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class CustomerPayDebtSheet extends StatefulWidget {
  final String customerName;
  final double balance;
  final Future<void> Function(double amount, String method, String note) onSave;

  const CustomerPayDebtSheet({
    super.key,
    required this.customerName,
    required this.balance,
    required this.onSave,
  });

  @override
  State<CustomerPayDebtSheet> createState() => _CustomerPayDebtSheetState();
}

class _CustomerPayDebtSheetState extends State<CustomerPayDebtSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _method = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
    try {
      await widget.onSave(amount, _method, _noteCtrl.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr(
              'Failed to record payment', 'Imeshindwa kurekodi malipo')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _tr('Record Debt Payment', 'Rekodi Malipo ya Deni'),
              style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            SizedBox(height: 2),
            Text(
              '${_tr('Outstanding balance', 'Deni linalobaki')}: TZS ${_fmtNum(widget.balance)}',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),

            // Amount field
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixText: 'TZS  ',
                prefixStyle: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500),
                hintText: '0',
                hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 22,
                    color: AppColors.textDisabled,
                    fontWeight: FontWeight.w700),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.tealAccent, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return _tr('Enter amount', 'Ingiza kiasi');
                }
                final amt = double.tryParse(v) ?? 0;
                if (amt <= 0) return _tr('Invalid amount', 'Kiasi si halali');
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Payment method chips
            Text(
              _tr('Payment Method', 'Njia ya Malipo'),
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _PayMethodChip(
                    method: 'cash',
                    label: _tr('Cash', 'Taslimu'),
                    selected: _method,
                    onSelect: (v) => setState(() => _method = v)),
                const SizedBox(width: 8),
                _PayMethodChip(
                    method: 'mpesa',
                    label: 'M-Pesa',
                    selected: _method,
                    onSelect: (v) => setState(() => _method = v)),
                const SizedBox(width: 8),
                _PayMethodChip(
                    method: 'bank',
                    label: _tr('Bank', 'Benki'),
                    selected: _method,
                    onSelect: (v) => setState(() => _method = v)),
                const SizedBox(width: 8),
                _PayMethodChip(
                    method: 'card',
                    label: _tr('Card', 'Kadi'),
                    selected: _method,
                    onSelect: (v) => setState(() => _method = v)),
              ],
            ),
            const SizedBox(height: 14),

            // Note field
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: _tr('Note (optional)', 'Maelezo (hiari)'),
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textDisabled),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.tealAccent, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _saving ? AppColors.border : AppColors.tealAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _tr('Confirm Payment', 'Thibitisha Malipo'),
                        style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethodChip extends StatelessWidget {
  final String method;
  final String label;
  final String selected;
  final ValueChanged<String> onSelect;

  const _PayMethodChip({
    required this.method,
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final active = method == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.tealAccent
                : AppColors.tealAccent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? AppColors.tealAccent
                  : AppColors.tealAccent.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.tealAccent),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Activity (combined purchases + debt payments timeline)
// ─────────────────────────────────────────────────────────────────────────────

enum _ActivityType { purchase, payment }

class _ActivityEntry {
  final _ActivityType type;
  final DateTime date;
  final double amount;
  final String title;
  final String? subtitle;
  final String? status;

  const _ActivityEntry({
    required this.type,
    required this.date,
    required this.amount,
    required this.title,
    this.subtitle,
    this.status,
  });
}

String _payMethodLabel(String method) => switch (method) {
      'cash' => _tr('Cash', 'Taslimu'),
      'mpesa' => 'M-Pesa',
      'bank' => _tr('Bank', 'Benki'),
      'card' => _tr('Card', 'Kadi'),
      _ => method,
    };

class _ActivityTab extends ConsumerWidget {
  final String customerId;
  final bool showFinancials;

  const _ActivityTab({
    required this.customerId,
    required this.showFinancials,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));
    final paymentsAsync = ref.watch(customerPaymentsProvider(customerId));

    // Only block on Drift-backed invoices loading. The Firestore-backed payments
    // stream has no local cache (persistence is disabled), so it may never emit
    // when offline — treat it as empty until it resolves.
    if (invoicesAsync.isLoading) {
      return const CustomScrollView(slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
                color: AppColors.navyPrimary, strokeWidth: 2),
          ),
        ),
      ]);
    }

    final invoices = invoicesAsync.valueOrNull ?? [];
    final payments = paymentsAsync.valueOrNull ?? [];

    final items = <_ActivityEntry>[
      ...invoices.map((inv) {
        final date =
            readTimestamp(inv['createdAt'] ?? inv['invoiceDate']) ??
                DateTime(2000);
        final amount = readInvoiceTotal(inv);
        final status =
            (inv['status'] ?? 'pending').toString().toLowerCase();
        final number = inv['invoiceNumber']?.toString() ??
            inv['id']?.toString() ??
            '—';
        final rawItems = inv['lineItems'] ?? inv['items'];
        final itemCount = rawItems is List ? rawItems.length : 0;
        return _ActivityEntry(
          type: _ActivityType.purchase,
          date: date,
          amount: amount,
          title: '${_tr('Invoice', 'Ankara')} $number',
          subtitle: itemCount > 0
              ? _tr('$itemCount item${itemCount == 1 ? '' : 's'}',
                  'vitu $itemCount')
              : null,
          status: status,
        );
      }),
      ...payments.map((pay) {
        final date =
            readTimestamp(pay['paidAt'] ?? pay['date']) ?? DateTime(2000);
        final amount = (pay['amount'] as num?)?.toDouble() ?? 0;
        final method = pay['method']?.toString() ?? 'cash';
        final note = pay['note']?.toString() ?? '';
        return _ActivityEntry(
          type: _ActivityType.payment,
          date: date,
          amount: amount,
          title: _tr('Debt Payment', 'Malipo ya Deni'),
          subtitle: note.isNotEmpty
              ? '${_payMethodLabel(method)} · $note'
              : _payMethodLabel(method),
        );
      }),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return CustomScrollView(slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.timeline_rounded,
            title: _tr('No activity yet', 'Bado hakuna shughuli'),
            subtitle: _tr(
              'Sales and debt payments will appear here.',
              'Uuzaji na malipo ya deni vitaonekana hapa.',
            ),
          ),
        ),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 60),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(left: 58, right: 16),
        child: Divider(height: 1, color: AppColors.border, thickness: 0.8),
      ),
      itemBuilder: (_, i) => _ActivityTile(
        entry: items[i],
        showFinancials: showFinancials,
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityEntry entry;
  final bool showFinancials;

  const _ActivityTile(
      {required this.entry, required this.showFinancials});

  @override
  Widget build(BuildContext context) {
    final isPurchase = entry.type == _ActivityType.purchase;
    final isPayment = entry.type == _ActivityType.payment;

    final statusColor = isPurchase
        ? switch (entry.status ?? 'pending') {
            'paid' => AppColors.success,
            'overdue' => AppColors.error,
            'cancelled' => AppColors.textDisabled,
            'draft' => AppColors.textMuted,
            _ => AppColors.warning,
          }
        : AppColors.tealAccent;

    final iconBg = isPayment
        ? AppColors.tealAccent.withValues(alpha: 0.1)
        : statusColor.withValues(alpha: 0.1);
    final icon = isPayment
        ? Icons.payments_rounded
        : Icons.shopping_bag_rounded;

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle != null
                        ? '${entry.subtitle!} · ${_fmtDate(entry.date)}'
                        : _fmtDate(entry.date),
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showFinancials)
                  Text(
                    'TZS ${_fmtNum(entry.amount)}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isPayment
                            ? AppColors.tealAccent
                            : AppColors.textPrimary),
                  ),
                if (isPurchase && entry.status != null) ...[
                  const SizedBox(height: 4),
                  PaymentStatusChip(status: entry.status!),
                ],
                if (isPayment) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.tealAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _tr('Paid', 'Imelipwa'),
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealAccent),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtNum(double v) {
  if (v == 0) return '0';
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtShort(double v) {
  if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
  if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
