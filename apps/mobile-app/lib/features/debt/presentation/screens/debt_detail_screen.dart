import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _fmtDateShort(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]}';
}

String _isoToday() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

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
        vsync: this, duration: const Duration(milliseconds: 300));
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
      builder: (ctx) =>
          _RecordPaymentSheet(debt: _debt, onSaved: _refreshDebt),
    );
    if (result == true) _refreshDebt();
  }

  // ── SMS Reminder ─────────────────────────────────────────────────────────

  Future<void> _sendSmsReminder() async {
    if (_debt.partyPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _tr('No phone number on file.', 'Hakuna namba ya simu iliyohifadhiwa.')),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final daysOver = _debt.daysOverdue;
    final message = daysOver > 0
        ? Uri.encodeComponent(
            '${_tr("Dear", "Mpendwa")} ${_debt.partyName}, '
            '${_tr("your account has", "akaunti yako ina")} ${_fmtAmt(_debt.remainingAmount)} '
            '${_tr("overdue by", "iliyochelewa kwa")} $daysOver ${_tr("days", "siku")}. '
            '${_tr("Please settle promptly.", "Tafadhali lipa haraka.")}',
          )
        : Uri.encodeComponent(
            '${_tr("Dear", "Mpendwa")} ${_debt.partyName}, '
            '${_tr("a balance of", "salio la")} ${_fmtAmt(_debt.remainingAmount)} '
            '${_tr("is due on", "linastahiwa tarehe")} ${_fmtDate(_debt.dueDate)}. '
            '${_tr("Please arrange payment. Thank you.", "Tafadhali fanya malipo. Asante.")}',
          );

    final uri =
        Uri.parse('sms:${_debt.partyPhone}?body=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      // Persist reminder metadata through the offline-first write path.
      try {
        final repo = ref.read(debtRepositoryProvider);
        final updated = _debt.copyWith(note: _debt.note);
        await repo.save(updated);
      } catch (_) {}
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr(
                'Could not open SMS app.',
                'Imeshindwa kufungua programu ya SMS.')),
            backgroundColor: AppColors.error,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _tr('Write Off Debt', 'Andika Deni'),
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _tr(
                              'This marks the debt as uncollectable. The action is permanent.',
                              'Hii itaashiria deni kama haliwezi kulipwa. Hatua hii haitabadilishwa.'),
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.warning),
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
                      color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: [
                    _reasonItem('Customer dispute',
                        'Mgogoro wa mteja'),
                    _reasonItem('Customer insolvent',
                        'Mteja hana uwezo wa kulipa'),
                    _reasonItem('Small amount — not worth pursuing',
                        'Kiasi kidogo — haifai kufuatilia'),
                    _reasonItem('Agreed settlement',
                        'Makubaliano ya malipo'),
                    _reasonItem('Other', 'Nyingine'),
                  ],
                  onChanged: (v) => setDlg(() => selectedReason = v),
                  hint: Text(
                    _tr('Select reason…', 'Chagua sababu…'),
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.textDisabled),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: _tr('Additional note (optional)',
                        'Maelezo zaidi (hiari)'),
                    hintStyle: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.textDisabled),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
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
              child: Text(_tr('Cancel', 'Ghairi'),
                  style: GoogleFonts.dmSans(color: AppColors.textMuted)),
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
                      borderRadius: BorderRadius.circular(10))),
              child: Text(
                _tr('Write Off', 'Andika'),
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, color: Colors.white),
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
      final writtenOff = Debt(
        id: _debt.id,
        partyName: _debt.partyName,
        partyPhone: _debt.partyPhone,
        partyId: _debt.partyId,
        type: _debt.type,
        originalAmount: _debt.originalAmount,
        paidAmount: _debt.paidAmount,
        dueDate: _debt.dueDate,
        status: 'written_off',
        invoiceRef: _debt.invoiceRef,
        note: _debt.note,
        createdBy: _debt.createdBy,
        createdAt: _debt.createdAt,
        isWrittenOff: true,
        writeOffReason: reason,
        writtenOffBy: user.uid,
        writtenOffAt: _isoToday(),
      );
      await repo.save(writtenOff);
      if (mounted) {
        Navigator.of(context).pop({'writtenOff': true});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('Write-off failed. Try again.',
                'Imeshindwa. Jaribu tena.')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  DropdownMenuItem<String> _reasonItem(String en, String sw) =>
      DropdownMenuItem(
        value: _tr(en, sw),
        child: Text(_tr(en, sw),
            style: GoogleFonts.dmSans(fontSize: 13)),
      );

  // ── Edit / Delete ─────────────────────────────────────────────────────────

  Future<void> _edit() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDebtScreen(debtToEdit: _debt),
    );
    _refreshDebt();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_tr('Delete Entry', 'Futa Rekodi'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          _tr(
              'This cannot be undone. All payment records will also be deleted.',
              'Hii haiwezi kubadilishwa. Rekodi zote za malipo pia zitafutwa.'),
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
                    borderRadius: BorderRadius.circular(10))),
            child: Text(_tr('Delete', 'Futa'),
                style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(debtRepositoryProvider);
      await repo.delete(_debt.id);
      if (mounted) Navigator.of(context).pop({'deleted': true});
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _tr('Delete failed.', 'Imeshindwa kufuta.')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  children: [
                    _HeroAmountCard(debt: _debt),
                    const SizedBox(height: 14),
                    _DetailInfoCard(debt: _debt),
                    const SizedBox(height: 14),
                    _PaymentHistoryCard(debt: _debt),
                    const SizedBox(height: 14),
                    _ActionsCard(
                      debt: _debt,
                      busy: _busy,
                      onRecordPayment: _recordPayment,
                      onSendSms: _sendSmsReminder,
                      onWriteOff: _showWriteOffDialog,
                      onEdit: _edit,
                      onDelete: _delete,
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

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: AppColors.navyPrimary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: _busy ? null : _edit,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 14),
        title: Text(
          _debt.partyName,
          style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navyPrimary, Color(0xFF003153)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 36),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _typeColor.withValues(alpha: 0.5), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _debt.partyName.isNotEmpty
                        ? _debt.partyName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.dmSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _typeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _isReceivable
                        ? _tr('RECEIVABLE', 'DAI')
                        : _tr('PAYABLE', 'DENI'),
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _typeColor,
                        letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              color: AppColors.shadowCard, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AmountColumn(
                top: _tr('Original', 'Asili'),
                value: _fmtAmt(debt.originalAmount),
                color: AppColors.textMuted,
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.border),
              _AmountColumn(
                top: _tr('Paid', 'Kilicholipwa'),
                value: _fmtAmt(debt.paidAmount),
                color: AppColors.success,
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.border),
              _AmountColumn(
                top: _tr('Remaining', 'Kilichobaki'),
                value: _fmtAmt(debt.remainingAmount),
                color: debt.isFullyPaid ? AppColors.success : AppColors.error,
                large: true,
              ),
            ],
          ),
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
                    color: AppColors.textMuted),
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

class _AmountColumn extends StatelessWidget {
  final String top;
  final String value;
  final Color color;
  final bool large;

  const _AmountColumn({
    required this.top,
    required this.value,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            top,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Detail Info Card ──────────────────────────────────────────────────────────

class _DetailInfoCard extends StatelessWidget {
  final Debt debt;
  const _DetailInfoCard({required this.debt});

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
                    fontSize: 13, color: AppColors.textMuted),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
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
                const Icon(Icons.history_rounded,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  _tr('Payment History', 'Historia ya Malipo'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  paymentsAsync.maybeWhen(
                    data: (p) =>
                        '${p.length} ${_tr('payments', 'malipo')}',
                    orElse: () => '',
                  ),
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          paymentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.navyPrimary)),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _tr('Could not load payments.', 'Imeshindwa kupakia malipo.'),
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            data: (payments) => payments.isEmpty
                ? EmptyState(
                    icon: Icons.payments_outlined,
                    title: _tr('No payments recorded yet',
                        'Hakuna malipo yaliyorekodiwa bado'),
                    subtitle: _tr(
                      'Add a payment to start tracking repayments.',
                      'Ongeza malipo ili uanze kufuatilia marejesho.',
                    ),
                  )
                : Column(
                    children: payments
                        .asMap()
                        .entries
                        .map((e) => _PaymentTile(
                              payment: e.value,
                              isLast: e.key == payments.length - 1,
                            ))
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

  const _PaymentTile({required this.payment, required this.isLast});

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
    final color =
        _methodColors[payment.method] ?? AppColors.textMuted;
    final icon = _methodIcons[payment.method] ?? Icons.payments_outlined;
    final date = DateTime.tryParse(payment.date);

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          color: color),
                    ),
                    if (payment.note.isNotEmpty)
                      Text(
                        payment.note,
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        color: AppColors.success),
                  ),
                  if (date != null)
                    Text(
                      _fmtDateShort(date),
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted),
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
  final VoidCallback onSendSms;
  final VoidCallback onWriteOff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionsCard({
    required this.debt,
    required this.busy,
    required this.onRecordPayment,
    required this.onSendSms,
    required this.onWriteOff,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final showWriteOff = !debt.isWrittenOff && !debt.isFullyPaid;

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
          _ActionRow(
            icon: Icons.sms_outlined,
            label: _tr('Send SMS Reminder', 'Tuma Ukumbusho wa SMS'),
            color: AppColors.tealAccent,
            onTap: busy ? null : onSendSms,
          ),
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
                  color: isDestructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textDisabled),
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
  String _method = 'cash';
  late DateTime _date;
  bool _saving = false;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(debtRepositoryProvider);

      final amount = double.tryParse(
              _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      final dateStr =
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

      final payment = DebtPayment(
        id: '',
        amount: amount,
        date: dateStr,
        method: _method,
        note: _noteCtrl.text.trim(),
        recordedBy: user.uid,
      );

      // Records payment locally and queues sync; also updates paidAmount.
      await repo.addPayment(widget.debt.id, payment);

      // Denormalize paidAmount on the debt so reports stay accurate offline.
      final newPaid = widget.debt.paidAmount + amount;
      final isNowPaid = newPaid >= widget.debt.originalAmount;
      final updatedDebt = Debt(
        id: widget.debt.id,
        partyName: widget.debt.partyName,
        partyPhone: widget.debt.partyPhone,
        partyId: widget.debt.partyId,
        type: widget.debt.type,
        originalAmount: widget.debt.originalAmount,
        paidAmount: newPaid,
        dueDate: widget.debt.dueDate,
        status: isNowPaid ? 'paid' : widget.debt.status,
        invoiceRef: widget.debt.invoiceRef,
        note: widget.debt.note,
        createdBy: widget.debt.createdBy,
        createdAt: widget.debt.createdAt,
        isWrittenOff: widget.debt.isWrittenOff,
        writeOffReason: widget.debt.writeOffReason,
        writtenOffBy: widget.debt.writtenOffBy,
        writtenOffAt: widget.debt.writtenOffAt,
      );
      await repo.save(updatedDebt);

      widget.onSaved();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('Failed to save payment.', 'Imeshindwa kuhifadhi malipo.')),
            backgroundColor: AppColors.error,
          ),
        );
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
                  color: AppColors.textPrimary),
            ),
            Text(
              '${_tr('Remaining balance', 'Salio linalobaki')}: ${_fmtAmt(remaining)}',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted),
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
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.navyPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return _tr('Enter amount', 'Ingiza kiasi');
                }
                final amt = double.tryParse(v) ?? 0;
                if (amt <= 0) return _tr('Invalid amount', 'Kiasi si halali');
                if (amt > remaining) {
                  return _tr('Exceeds remaining balance',
                      'Inazidi salio linalobaki');
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
                  color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MethodChip(
                    method: 'cash',
                    label: _tr('Cash', 'Taslimu'),
                    selected: _method,
                    onSelect: (v) => setState(() => _method = v)),
                const SizedBox(width: 8),
                _MethodChip(
                    method: 'mpesa',
                    label: 'M-Pesa',
                    selected: _method,
                    onSelect: (v) => setState(() => _method = v)),
                const SizedBox(width: 8),
                _MethodChip(
                    method: 'bank',
                    label: _tr('Bank', 'Benki'),
                    selected: _method,
                    onSelect: (v) => setState(() => _method = v)),
                const SizedBox(width: 8),
                _MethodChip(
                    method: 'card',
                    label: _tr('Card', 'Kadi'),
                    selected: _method,
                    onSelect: (v) => setState(() => _method = v)),
              ],
            ),
            const SizedBox(height: 14),

            // Note
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: _tr('Note (optional)', 'Maelezo (hiari)'),
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textDisabled),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.navyPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 18),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _saving ? AppColors.border : AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _tr('Record Payment', 'Rekodi Malipo'),
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

class _MethodChip extends StatelessWidget {
  final String method;
  final String label;
  final String selected;
  final ValueChanged<String> onSelect;

  const _MethodChip({
    required this.method,
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == method;
    return GestureDetector(
      onTap: () => onSelect(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.navyPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                active ? AppColors.navyPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

