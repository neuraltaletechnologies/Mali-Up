import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/validation_banner.dart';
import '../../../finance/data/payment_account_service.dart';
import '../../../finance/domain/models/cash_account.dart';
import '../../../finance/domain/payment_method_accounts.dart';
import '../../../finance/presentation/widgets/activate_account_sheet.dart';
import '../../../finance/presentation/widgets/payment_account_chips.dart';
import '../../../invoice/data/mappers/invoice_mapper.dart';
import '../../../sales/data/sales_providers.dart' show normalizeWhatsAppPhone;
import '../../../sales/domain/debt_reminder_text.dart';
import '../../../sales/services/receipt_pdf_service.dart';
import '../../../team/data/creator_providers.dart';
import '../../../team/presentation/widgets/issued_by.dart';
import '../../data/customer_debt_sync_service.dart';
import '../../data/debt_providers.dart';
import '../../domain/models/debt.dart';
import 'add_debt_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ── Formatting ────────────────────────────────────────────────────────────────

String _fmtAmt(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'TZS $buf';
}

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
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
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _fmtDateShort(DateTime d) {
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

String _isoToday() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _periodSuffix(String period) => switch (period) {
      'daily' => _tr('/ day', '/ siku'),
      'weekly' => _tr('/ week', '/ wiki'),
      _ => _tr('/ month', '/ mwezi'),
    };

String _typeSuffix(String type) =>
    type == 'compound' ? _tr('compound', 'mchanganyiko') : _tr('simple', 'rahisi');

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class DebtDetailScreen extends ConsumerStatefulWidget {
  final Debt debt;
  const DebtDetailScreen({super.key, required this.debt});

  @override
  ConsumerState<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends ConsumerState<DebtDetailScreen>
    with TickerProviderStateMixin {
  late Debt _debt;
  bool _busy = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get _isReceivable => _debt.type == 'receivable';
  Color get _typeColor => _isReceivable ? AppColors.success : AppColors.error;

  Future<void> _refreshDebt() async {
    try {
      final repo = ref.read(debtRepositoryProvider);
      final updated = await repo.getById(_debt.id);
      if (updated != null && mounted) {
        setState(() => _debt = updated);
      }
    } catch (_) {}
  }

  // ── Record partial payment ────────────────────────────────────────────────

  Future<void> _recordPayment() async {
    final result = await showAppSheet<bool>(
      context,
      builder: (ctx) => _RecordPaymentSheet(debt: _debt, onSaved: _refreshDebt),
    );
    if (result == true) _refreshDebt();
  }

  // ── Reminders ────────────────────────────────────────────────────────────

  /// The sale that created this receivable, as an Invoice.toFirestore()-shaped
  /// map (for its line items) — empty when the debt has no linked invoice
  /// (e.g. a manually added debt) or the invoice hasn't synced to this
  /// device yet. Read-only lookup against Drift, same pattern as the
  /// recurring-service arrears lookup in InvoiceDao.
  Future<Map<String, dynamic>> _loadLinkedInvoice() async {
    if (_debt.invoiceRef.isEmpty) return const {};
    try {
      final bizId = ref.read(currentBusinessIdProvider).valueOrNull ?? '';
      if (bizId.isEmpty) return const {};
      final db = ref.read(appDatabaseProvider);
      final row = await db.invoiceDao.getByInvoiceNumber(
        bizId,
        _debt.invoiceRef,
      );
      if (row == null) return const {};
      final items = await db.invoiceDao.getItemsForInvoice(row.id);
      return InvoiceMapper.fromRow(row, items).toFirestore();
    } catch (_) {
      return const {};
    }
  }

  /// Persists reminder metadata through the offline-first write path — a
  /// resave that just records the debt was touched, matching what the old
  /// SMS reminder did.
  Future<void> _markReminderSent() async {
    try {
      final repo = ref.read(debtRepositoryProvider);
      await repo.save(_debt.copyWith(note: _debt.note));
    } catch (_) {}
  }

  Future<void> _sendWhatsAppReminder() async {
    if (_debt.partyPhone.isEmpty) {
      AppNotification.warning(
        context,
        _tr('No phone number on file.', 'Hakuna namba ya simu iliyohifadhiwa.'),
      );
      return;
    }
    final phone = normalizeWhatsAppPhone(_debt.partyPhone);
    if (phone.isEmpty) {
      AppNotification.error(
        context,
        _tr('Invalid phone number.', 'Namba ya simu si sahihi.'),
      );
      return;
    }

    final invoice = await _loadLinkedInvoice();
    final message = DebtReminderText.build(
      debt: _debt,
      invoice: invoice,
      isSwahili: LocalizationService.isSwahili,
    );
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('No WhatsApp handler');
      await _markReminderSent();
    } catch (_) {
      if (mounted) {
        AppNotification.error(
          context,
          _tr('Could not open WhatsApp.', 'Imeshindwa kufungua WhatsApp.'),
        );
      }
    }
  }

  Future<void> _sendSmsReminder() async {
    if (_debt.partyPhone.isEmpty) {
      AppNotification.warning(
        context,
        _tr('No phone number on file.', 'Hakuna namba ya simu iliyohifadhiwa.'),
      );
      return;
    }

    final invoice = await _loadLinkedInvoice();
    // SMS is plain text — strip the WhatsApp-style markdown (*bold*, _italic_)
    // from the shared reminder copy.
    final message = DebtReminderText.build(
      debt: _debt,
      invoice: invoice,
      isSwahili: LocalizationService.isSwahili,
    ).replaceAll(RegExp(r'\*|_'), '');
    final uri = Uri.parse(
      'sms:${_debt.partyPhone}?body=${Uri.encodeComponent(message)}',
    );
    try {
      final opened = await launchUrl(uri);
      if (!opened) throw Exception('No SMS handler');
      await _markReminderSent();
    } catch (_) {
      if (mounted) {
        AppNotification.error(
          context,
          _tr('Could not open the SMS app.', 'Imeshindwa kufungua programu ya SMS.'),
        );
      }
    }
  }

  Future<void> _sendPdfReminder() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final bizId = ref.read(currentBusinessIdProvider).valueOrNull;
      final invoice = await _loadLinkedInvoice();
      final sale = {
        ...invoice,
        // The debt is the authoritative money figure — a payment recorded
        // straight on this page never updates the invoice's own amountPaid,
        // so the invoice's figures alone could show a stale balance.
        'invoiceNumber': invoice['invoiceNumber'] ?? _debt.invoiceRef,
        'customerName': _debt.partyName,
        'customerPhone': _debt.partyPhone,
        'totalAmount': _debt.totalOwedWithInterest,
        'amount': _debt.totalOwedWithInterest,
        'amountPaid': _debt.paidAmount,
        'dueDate': _debt.dueDate,
        'notes': _debt.note,
      };
      final meta = await ReceiptPdfService.loadMeta(
        uid: uid,
        businessId: bizId,
        createdByUid: _debt.createdBy,
      );
      await ReceiptPdfService.open(
        sale: sale,
        businessName: meta['businessName'] ?? 'Business',
        printedBy: meta['printedBy'] ?? 'User',
        isSwahili: LocalizationService.isSwahili,
        businessPhone: meta['businessPhone'] ?? '',
        businessEmail: meta['businessEmail'] ?? '',
        businessAddress: meta['businessAddress'] ?? '',
        businessLogoUrl: meta['businessLogoUrl'] ?? '',
      );
      await _markReminderSent();
    } catch (_) {
      if (mounted) {
        AppNotification.error(
          context,
          _tr(
            'Could not create the reminder PDF. Please try again.',
            'Imeshindwa kutengeneza PDF ya ukumbusho. Jaribu tena.',
          ),
        );
      }
    }
  }

  // ── Write-off ─────────────────────────────────────────────────────────────

  Future<void> _showWriteOffDialog() async {
    String? selectedReason;
    final noteCtrl = TextEditingController();
    bool confirmed = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _tr('Write Off Debt', 'Andika Deni'),
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _tr(
                            'This marks the debt as uncollectable. The action is permanent.',
                            'Hii itaashiria deni kama haliwezi kulipwa. Hatua hii haitabadilishwa.',
                          ),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _tr('Reason', 'Sababu'),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    _reasonItem('Customer dispute', 'Mgogoro wa mteja'),
                    _reasonItem(
                      'Customer insolvent',
                      'Mteja hana uwezo wa kulipa',
                    ),
                    _reasonItem(
                      'Small amount — not worth pursuing',
                      'Kiasi kidogo — haifai kufuatilia',
                    ),
                    _reasonItem('Agreed settlement', 'Makubaliano ya malipo'),
                    _reasonItem('Other', 'Nyingine'),
                  ],
                  onChanged: (v) => setDlg(() => selectedReason = v),
                  hint: Text(
                    _tr('Select reason…', 'Chagua sababu…'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: _tr(
                      'Additional note (optional)',
                      'Maelezo zaidi (hiari)',
                    ),
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textDisabled,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                _tr('Cancel', 'Ghairi'),
                style: GoogleFonts.dmSans(color: AppColors.textMuted),
              ),
            ),
            FilledButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      confirmed = true;
                      Navigator.of(ctx).pop();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _tr('Write Off', 'Andika'),
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!confirmed || selectedReason == null) return;

    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(debtRepositoryProvider);
      final reason = noteCtrl.text.trim().isNotEmpty
          ? '$selectedReason — ${noteCtrl.text.trim()}'
          : selectedReason!;
      final writtenOff = _debt.copyWith(
        status: 'written_off',
        isWrittenOff: true,
        writeOffReason: reason,
        writtenOffBy: user.uid,
        writtenOffAt: _isoToday(),
      );
      await repo.save(writtenOff);
      // A written-off receivable is no longer owed — release it from the
      // linked customer's balance.
      await adjustCustomerBalanceForDebtChange(
        ref,
        before: _debt,
        after: writtenOff,
      );
      if (mounted) {
        Navigator.of(context).pop({'writtenOff': true});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        AppNotification.error(
          context,
          _tr('Write-off failed. Try again.', 'Imeshindwa. Jaribu tena.'),
        );
      }
    }
  }

  DropdownMenuItem<String> _reasonItem(String en, String sw) =>
      DropdownMenuItem(
        value: _tr(en, sw),
        child: Text(_tr(en, sw), style: GoogleFonts.dmSans(fontSize: 13)),
      );

  // ── Edit / Delete ─────────────────────────────────────────────────────────

  Future<void> _edit() async {
    await showAppSheet<void>(
      context,
      builder: (_) => AddDebtScreen(debtToEdit: _debt),
    );
    _refreshDebt();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _tr('Delete Entry', 'Futa Rekodi'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _tr(
            'This cannot be undone. All payment records will also be deleted.',
            'Hii haiwezi kubadilishwa. Rekodi zote za malipo pia zitafutwa.',
          ),
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _tr('Delete', 'Futa'),
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(debtRepositoryProvider);
      await repo.delete(_debt.id);
      // Deleting an open receivable removes the claim — release it from
      // the linked customer's balance.
      await adjustCustomerBalanceForDebtChange(ref, before: _debt);
      if (mounted) Navigator.of(context).pop({'deleted': true});
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        AppNotification.error(context, _tr('Delete failed.', 'Imeshindwa kufuta.'));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildSheetHeader(),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  _HeroAmountCard(debt: _debt),
                  const SizedBox(height: 14),
                  _DetailInfoCard(
                    debt: _debt,
                    issuedBy: issuedByLabel(ref, _debt.createdBy),
                  ),
                  const SizedBox(height: 14),
                  _PaymentHistoryCard(debt: _debt),
                  const SizedBox(height: 14),
                  _ActionsCard(
                    debt: _debt,
                    busy: _busy,
                    onRecordPayment: _recordPayment,
                    onSendWhatsApp: _sendWhatsAppReminder,
                    onSendSms: _sendSmsReminder,
                    onSendPdf: _sendPdfReminder,
                    onWriteOff: _showWriteOffDialog,
                    onEdit: _edit,
                    onDelete: _delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _debt.partyName.isNotEmpty
                  ? _debt.partyName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _typeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _debt.partyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isReceivable
                      ? _tr('Receivable', 'Dai')
                      : _tr('Payable', 'Deni'),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _typeColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _tr('Edit', 'Hariri'),
            onPressed: _busy ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.navyPrimary,
          ),
          IconButton(
            tooltip: _tr('Close', 'Funga'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Hero Amount Card ──────────────────────────────────────────────────────────

class _HeroAmountCard extends StatelessWidget {
  final Debt debt;
  const _HeroAmountCard({required this.debt});

  Color get _ageColor => switch (debt.agingBucket) {
    'current' => AppColors.success,
    '0-30' => AppColors.warning,
    '31-60' => const Color(0xFFE07010),
    '61-90' => const Color(0xFFDC4A26),
    '90+' => AppColors.error,
    _ => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final pct = (debt.paidPercent * 100).toStringAsFixed(0);
    final isOverdue = debt.daysOverdue > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AmountPill(
                label: _tr('Original', 'Asili'),
                value: _fmtAmt(debt.originalAmount),
                color: AppColors.textSecondary,
              ),
              if (debt.hasInterest)
                _AmountPill(
                  label: _tr('Interest', 'Riba'),
                  value: _fmtAmt(debt.accruedInterest),
                  color: AppColors.navyPrimary,
                ),
              _AmountPill(
                label: _tr('Paid', 'Kilicholipwa'),
                value: _fmtAmt(debt.paidAmount),
                color: AppColors.success,
              ),
              _AmountPill(
                label: _tr('Remaining', 'Kilichobaki'),
                value: _fmtAmt(debt.remainingAmount),
                color: debt.isFullyPaid ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          if (debt.hasInterest) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 14, color: AppColors.navyPrimary),
                  const SizedBox(width: 6),
                  Text(
                    '${debt.interestRatePercent.toStringAsFixed(debt.interestRatePercent == debt.interestRatePercent.roundToDouble() ? 0 : 1)}% '
                    '${_periodSuffix(debt.interestPeriod)} · ${_typeSuffix(debt.interestType)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: debt.paidPercent,
              backgroundColor: AppColors.border,
              color: debt.isFullyPaid ? AppColors.success : _ageColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$pct% ${_tr('paid', 'kimelipwa')}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (debt.isFullyPaid)
                const PaymentStatusChip(status: 'paid')
              else if (isOverdue)
                PaymentStatusChip(
                  status: debt.paidAmount > 0 ? 'partial' : 'overdue',
                )
              else
                const PaymentStatusChip(status: 'pending'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Info Card ──────────────────────────────────────────────────────────

class _DetailInfoCard extends StatelessWidget {
  final Debt debt;

  /// Resolved "Issued by" label — null hides the row (solo business).
  final String? issuedBy;

  const _DetailInfoCard({required this.debt, this.issuedBy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (debt.partyPhone.isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: _tr('Phone', 'Simu'),
              value: debt.partyPhone,
            ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: _tr('Due Date', 'Tarehe ya Mwisho'),
            value: _fmtDate(debt.dueDate),
          ),
          if (debt.hasInterest) ...[
            _InfoRow(
              icon: Icons.percent_rounded,
              label: _tr('Interest Rate', 'Kiwango cha Riba'),
              value:
                  '${debt.interestRatePercent.toStringAsFixed(debt.interestRatePercent == debt.interestRatePercent.roundToDouble() ? 0 : 1)}% ${_periodSuffix(debt.interestPeriod)}',
            ),
            _InfoRow(
              icon: Icons.functions_rounded,
              label: _tr('Interest Type', 'Aina ya Riba'),
              value: _typeSuffix(debt.interestType)[0].toUpperCase() +
                  _typeSuffix(debt.interestType).substring(1),
            ),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              label: _tr('Interest Since', 'Riba Tangu'),
              value: _fmtDate(
                  debt.loanDate.isNotEmpty ? debt.loanDate : debt.createdAt),
            ),
          ],
          if (debt.invoiceRef.isNotEmpty)
            _InfoRow(
              icon: Icons.receipt_long_outlined,
              label: _tr('Invoice Ref', 'Kumbukumbu ya Ankara'),
              value: debt.invoiceRef,
            ),
          if (debt.note.isNotEmpty)
            _InfoRow(
              icon: Icons.notes_outlined,
              label: _tr('Note', 'Maelezo'),
              value: debt.note,
              isLast: issuedBy == null,
            ),
          if (issuedBy != null)
            _InfoRow(
              icon: Icons.badge_outlined,
              label: _tr('Issued by', 'Imetolewa na'),
              value: issuedBy!,
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.border),
          ),
      ],
    );
  }
}

// ── Payment History Card ──────────────────────────────────────────────────────

class _PaymentHistoryCard extends ConsumerWidget {
  final Debt debt;
  const _PaymentHistoryCard({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(debtPaymentsProvider(debt.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  _tr('Payment History', 'Historia ya Malipo'),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  paymentsAsync.maybeWhen(
                    data: (p) => '${p.length} ${_tr('payments', 'malipo')}',
                    orElse: () => '',
                  ),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          paymentsAsync.when(
            loading: () => const FlatRowsSkeleton(itemCount: 3, shrinkWrap: true),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _tr('Could not load payments.', 'Imeshindwa kupakia malipo.'),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            data: (payments) => payments.isEmpty
                ? EmptyState(
                    icon: Icons.payments_outlined,
                    title: _tr(
                      'No payments recorded yet',
                      'Hakuna malipo yaliyorekodiwa bado',
                    ),
                    subtitle: _tr(
                      'Add a payment to start tracking repayments.',
                      'Ongeza malipo ili uanze kufuatilia marejesho.',
                    ),
                  )
                : Column(
                    children: payments
                        .asMap()
                        .entries
                        .map(
                          (e) => _PaymentTile(
                            payment: e.value,
                            isLast: e.key == payments.length - 1,
                            recordedBy:
                                issuedByLabel(ref, e.value.recordedBy),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final DebtPayment payment;
  final bool isLast;

  /// Resolved "recorded by" label — null hides it (solo business).
  final String? recordedBy;

  const _PaymentTile({
    required this.payment,
    required this.isLast,
    this.recordedBy,
  });

  static const _methodIcons = {
    'cash': Icons.payments_outlined,
    'mpesa': Icons.phone_android_outlined,
    'bank': Icons.account_balance_outlined,
    'card': Icons.credit_card_outlined,
  };

  static const _methodColors = {
    'cash': AppColors.success,
    'mpesa': Color(0xFF4CAF50),
    'bank': AppColors.tealAccent,
    'card': AppColors.navySecondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _methodColors[payment.method] ?? AppColors.textMuted;
    final icon = _methodIcons[payment.method] ?? Icons.payments_outlined;
    final date = DateTime.tryParse(payment.date);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.method.toUpperCase(),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (payment.note.isNotEmpty)
                      Text(
                        payment.note,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (recordedBy != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: IssuedByInline(value: recordedBy!),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtAmt(payment.amount),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  if (date != null)
                    Text(
                      _fmtDateShort(date),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.border),
          ),
      ],
    );
  }
}

// ── Actions Card ──────────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  final Debt debt;
  final bool busy;
  final VoidCallback onRecordPayment;
  final VoidCallback onSendWhatsApp;
  final VoidCallback onSendSms;
  final VoidCallback onSendPdf;
  final VoidCallback onWriteOff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionsCard({
    required this.debt,
    required this.busy,
    required this.onRecordPayment,
    required this.onSendWhatsApp,
    required this.onSendSms,
    required this.onSendPdf,
    required this.onWriteOff,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final showWriteOff = !debt.isWrittenOff && !debt.isFullyPaid;
    // Reminding a supplier that the shop owes them (a payable) doesn't fit
    // this customer-addressed reminder template — receivables only.
    final showReminders = debt.type == 'receivable';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (!debt.isFullyPaid && !debt.isWrittenOff) ...[
            _ActionRow(
              icon: Icons.payments_outlined,
              label: _tr('Record Payment', 'Rekodi Malipo'),
              color: AppColors.success,
              onTap: busy ? null : onRecordPayment,
            ),
            const _Divider(),
          ],
          if (showReminders) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: _ReminderShareRow(
                onWhatsApp: busy ? null : onSendWhatsApp,
                onSms: busy ? null : onSendSms,
                onPdf: busy ? null : onSendPdf,
              ),
            ),
            const _Divider(),
          ],
          if (showWriteOff) ...[
            const _Divider(),
            _ActionRow(
              icon: Icons.delete_sweep_outlined,
              label: _tr('Write Off Debt', 'Andika Deni'),
              color: AppColors.warning,
              onTap: busy ? null : onWriteOff,
            ),
          ],
          const _Divider(),
          _ActionRow(
            icon: Icons.edit_outlined,
            label: _tr('Edit', 'Hariri'),
            color: AppColors.navyPrimary,
            onTap: busy ? null : onEdit,
          ),
          const _Divider(),
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: _tr('Delete', 'Futa'),
            color: AppColors.error,
            isDestructive: true,
            onTap: busy ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

/// Three buttons — WhatsApp, SMS, and PDF reminders, all showing the full
/// itemized bill — matching the share-button style already used on the
/// Invoice detail screen (see _ShareRow there). SMS exists alongside
/// WhatsApp/PDF rather than being assumed away, since not every customer's
/// phone has WhatsApp installed.
class _ReminderShareRow extends StatelessWidget {
  final VoidCallback? onWhatsApp;
  final VoidCallback? onSms;
  final VoidCallback? onPdf;

  const _ReminderShareRow({
    required this.onWhatsApp,
    required this.onSms,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReminderShareBtn(
            label: _tr('WhatsApp Reminder', 'Ukumbusho wa WhatsApp'),
            icon: Icons.chat_outlined,
            color: AppColors.success,
            onTap: onWhatsApp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ReminderShareBtn(
            label: _tr('SMS Reminder', 'Ukumbusho wa SMS'),
            icon: Icons.sms_outlined,
            color: AppColors.warning,
            onTap: onSms,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ReminderShareBtn(
            label: _tr('PDF Reminder', 'Ukumbusho wa PDF'),
            icon: Icons.picture_as_pdf_outlined,
            color: AppColors.tealAccent,
            onTap: onPdf,
          ),
        ),
      ],
    );
  }
}

class _ReminderShareBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ReminderShareBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: AppColors.border),
  );
}

// ── Record Payment Bottom Sheet ───────────────────────────────────────────────

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final Debt debt;
  final VoidCallback onSaved;

  const _RecordPaymentSheet({required this.debt, required this.onSaved});

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CashAccount? _selectedAccount;
  late DateTime _date;
  bool _saving = false;
  String? _paymentError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // Double-tapping a locked payment chip above opens this — activation
  // itself is Drift-based (SyncCashRepository) so it works fully offline;
  // the sheet shows its own confirmation once saved.
  Future<void> _showActivateAccountSheet(PaymentMethodSpec spec) async {
    await showAppSheet<bool>(
      context,
      builder: (_) => ActivateAccountSheet(spec: spec),
    );
  }

  Future<void> _save() async {
    if (_paymentError != null || _generalError != null) {
      setState(() {
        _paymentError = null;
        _generalError = null;
      });
    }
    if (!_formKey.currentState!.validate()) return;
    final account = _selectedAccount;
    if (account == null) {
      setState(
        () => _paymentError = _tr(
          'Select a payment account',
          'Chagua akaunti ya malipo',
        ),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(debtRepositoryProvider);

      final amount =
          double.tryParse(
            _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      final dateStr =
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      final method = switch (account.id) {
        PaymentMethodAccounts.cashId => 'cash',
        PaymentMethodAccounts.mpesaId => 'mpesa',
        PaymentMethodAccounts.bankId => 'bank',
        PaymentMethodAccounts.cardId => 'card',
        _ => account.name,
      };

      final payment = DebtPayment(
        id: '',
        amount: amount,
        date: dateStr,
        method: method,
        note: _noteCtrl.text.trim(),
        recordedBy: user.uid,
        accountId: account.id,
      );

      // Records payment locally and queues sync; also updates paidAmount.
      await repo.addPayment(widget.debt.id, payment);

      // Denormalize paidAmount on the debt so reports stay accurate offline.
      final newPaid = widget.debt.paidAmount + amount;
      final isNowPaid = newPaid >= widget.debt.totalOwedWithInterest;
      final updatedDebt = widget.debt.copyWith(
        paidAmount: newPaid,
        status: isNowPaid ? 'paid' : widget.debt.status,
      );
      await repo.save(updatedDebt);

      // Mirror the repayment into the linked customer's balance so the
      // customer page shows the same outstanding amount.
      await adjustCustomerBalanceForDebtChange(
        ref,
        before: widget.debt,
        after: updatedDebt,
      );

      // A receivable being collected is money coming in; a payable being
      // paid off is money going out — either way it moves through the
      // chosen account so Cash Flow reflects debt collection/settlement.
      await moveMoneyForAccount(
        ref,
        accountId: account.id,
        amount: amount,
        isDeposit: widget.debt.type == 'receivable',
        description: widget.debt.partyName,
        reference: widget.debt.id,
        createdBy: user.uid,
      );

      widget.onSaved();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _generalError = _tr(
            'Failed to save payment. Try again.',
            'Imeshindwa kuhifadhi malipo. Jaribu tena.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.debt.remainingAmount;
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
            const SheetHandle(),
            const SizedBox(height: 4),
            Text(
              _tr('Record Payment', 'Rekodi Malipo'),
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_tr('Remaining balance', 'Salio linalobaki')}: ${_fmtAmt(remaining)}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: 'TZS  ',
                prefixStyle: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                hintText: '0',
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  color: AppColors.textDisabled,
                  fontWeight: FontWeight.w700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return _tr('Enter amount', 'Ingiza kiasi');
                }
                final amt = double.tryParse(v) ?? 0;
                if (amt <= 0) return _tr('Invalid amount', 'Kiasi si halali');
                if (amt > remaining) {
                  return _tr(
                    'Exceeds remaining balance',
                    'Inazidi salio linalobaki',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Method chips
            Text(
              _tr('Payment Method', 'Njia ya Malipo'),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            PaymentAccountChips(
              selectedAccountId: _selectedAccount?.id,
              onSelectAccount: (a) => setState(() {
                _selectedAccount = a;
                _paymentError = null;
              }),
              onActivationRequired: (message) =>
                  setState(() => _paymentError = message),
              onActivateMethod: (spec) => _showActivateAccountSheet(spec),
            ),
            ValidationBanner(
              message: _paymentError,
              onDismiss: () => setState(() => _paymentError = null),
            ),
            const SizedBox(height: 14),

            // Note
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: _tr('Note (optional)', 'Maelezo (hiari)'),
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textDisabled,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.navyPrimary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 18),

            ValidationBanner(
              message: _generalError,
              onDismiss: () => setState(() => _generalError = null),
              margin: EdgeInsets.zero,
            ),
            if (_generalError != null) const SizedBox(height: 10),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _saving
                      ? AppColors.border
                      : AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _tr('Record Payment', 'Rekodi Malipo'),
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
