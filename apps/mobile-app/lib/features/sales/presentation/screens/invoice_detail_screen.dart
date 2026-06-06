import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../data/sales_providers.dart';
import 'create_invoice_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen>
    with TickerProviderStateMixin {
  late Map<String, dynamic> _inv;
  bool _updating = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _inv = Map.from(widget.invoice);
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

  // ── Derived ─────────────────────────────────────────────────────────────────

  String get _status {
    final raw =
        (_inv['status'] ?? _inv['paymentStatus'] ?? '').toString().trim();
    if (raw.isEmpty) return 'pending';
    return raw.toLowerCase();
  }

  bool get _isQuotation =>
      (_inv['type'] ?? '').toString().toLowerCase() == 'quotation';
  double get _total => parseNumericAmount(_inv['totalAmount']);
  double get _subtotal => parseNumericAmount(_inv['subtotal']);
  double get _discount => parseNumericAmount(_inv['discountAmount']);
  double get _vat => parseNumericAmount(_inv['vatAmount']);
  double get _amountPaid => parseNumericAmount(_inv['amountPaid']);
  double get _outstanding => (_total - _amountPaid).clamp(0.0, _total);

  String get _invoiceNumber =>
      _inv['invoiceNumber']?.toString() ?? _inv['id']?.toString() ?? '—';

  String get _customerName =>
      _inv['customerName']?.toString() ?? _tr('Walk-in', 'Mteja wa Njiani');
  String get _customerPhone => _inv['customerPhone']?.toString() ?? '';

  DateTime? get _invoiceDate =>
      readTimestamp(_inv['invoiceDate'] ?? _inv['createdAt']);
  DateTime? get _dueDate => readTimestamp(_inv['dueDate']);

  List<Map<String, dynamic>> get _lineItems {
    final raw = _inv['lineItems'];
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    final fallback = _inv['items'];
    if (fallback is List) return fallback.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final col = repo.scopeCollection(
          uid: user.uid, context: ctx, childCollection: 'sales_invoices');
      await col.doc(_inv['id'] as String).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'paid') 'paidAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _inv = {..._inv, 'status': newStatus};
        _updating = false;
      });
    } catch (e) {
      _showSnack(_tr('Update failed: $e', 'Imeshindwa kusasisha: $e'));
      setState(() => _updating = false);
    }
  }

  Future<void> _convertToInvoice() async {
    await _updateStatus('sent');
    setState(() => _inv = {..._inv, 'type': 'invoice'});
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final repo = ref.read(contextFirestoreRepositoryProvider);
    final ctx = await repo.resolveContextForUser(user.uid);
    final col = repo.scopeCollection(
        uid: user.uid, context: ctx, childCollection: 'sales_invoices');
    await col.doc(_inv['id'] as String).update({'type': 'invoice'});
    _showSnack(_tr('Converted to invoice', 'Imebadilishwa kuwa ankara'));
  }

  void _openEdit() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CreateInvoiceScreen(
        isQuotation: _isQuotation,
        invoiceToEdit: _inv,
      ),
    ));
  }

  void _openReturn() {
    Navigator.of(context).pushNamed('/sales-return', arguments: _inv);
  }

  Future<void> _recordPayment() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RecordPaymentSheet(
        outstanding: _total,
        invoiceId: _inv['id'] as String,
      ),
    );

    if (result != null && result['paid'] == true) {
      await _updateStatus('paid');
    }
  }

  void _shareWhatsApp() async {
    final text = _buildShareText();
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    if (_customerPhone.isNotEmpty) {
      final phone = _customerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
      final directUrl =
          'https://wa.me/$phone?text=${Uri.encodeComponent(text)}';
      await launchUrl(Uri.parse(directUrl),
          mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    }
  }

  void _shareEmail() async {
    final text = _buildShareText();
    final subject = Uri.encodeComponent(
        _tr('Invoice $_invoiceNumber', 'Ankara $_invoiceNumber'));
    final body = Uri.encodeComponent(text);
    final customerEmail = (_inv['customerEmail'] ?? '').toString();
    final to = customerEmail.isNotEmpty ? Uri.encodeComponent(customerEmail) : '';
    await launchUrl(Uri.parse('mailto:$to?subject=$subject&body=$body'));
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _buildShareText()));
    _showSnack(_tr('Copied to clipboard', 'Imenakiliwa'));
  }

  String _buildShareText() {
    final type = _isQuotation ? _tr('QUOTATION', 'NUKUU') : _tr('INVOICE', 'ANKARA');
    final lines = StringBuffer();
    lines.writeln('*$type — $_invoiceNumber*');
    lines.writeln('━━━━━━━━━━━━━━━━━━━━━');
    lines.writeln('${_tr('Customer:', 'Mteja:')} *$_customerName*');
    if (_invoiceDate != null) {
      lines.writeln('${_tr('Date:', 'Tarehe:')} ${_fmt(_invoiceDate!)}');
    }
    if (_dueDate != null) {
      lines.writeln('${_tr('Due:', 'Mwisho:')} ${_fmt(_dueDate!)}');
    }
    lines.writeln();
    for (final item in _lineItems) {
      final name = item['productName']?.toString() ?? item['name']?.toString() ?? '';
      final qty = item['qty']?.toString() ?? item['quantity']?.toString() ?? '1';
      final price = _fmtNum(parseNumericAmount(item['unitPrice']));
      final total = _fmtNum(parseNumericAmount(item['lineTotal'] ?? item['total']));
      lines.writeln('• $name × $qty @ TZS $price = *TZS $total*');
    }
    lines.writeln('━━━━━━━━━━━━━━━━━━━━━');
    if (_discount > 0) {
      lines.writeln('${_tr('Discount:', 'Punguzo:')} -TZS ${_fmtNum(_discount)}');
    }
    if (_vat > 0) {
      lines.writeln('${_tr('VAT (18%):', 'VAT (18%):')} TZS ${_fmtNum(_vat)}');
    }
    lines.writeln('*${_tr('TOTAL:', 'JUMLA:')} TZS ${_fmtNum(_total)}*');
    if ((_inv['notes'] ?? '').toString().isNotEmpty) {
      lines.writeln();
      lines.writeln('_${_inv['notes']}_');
    }
    return lines.toString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _InvoiceSummaryCard(
              invoiceNumber: _invoiceNumber,
              total: _total,
              status: _status,
              isQuotation: _isQuotation,
              customerName: _customerName,
              invoiceDate: _invoiceDate,
              dueDate: _dueDate,
              itemCount: _lineItems.length,
              outstanding: _outstanding,
            ),
            const SizedBox(height: 16),
            _ShareRow(
              onWhatsApp: _shareWhatsApp,
              onEmail: _shareEmail,
              onCopy: _copyText,
            ),
            const SizedBox(height: 16),
            _LineItemsCard(items: _lineItems),
            const SizedBox(height: 16),
            _SummaryCard(
              subtotal: _subtotal,
              discount: _discount,
              vatAmount: _vat,
              total: _total,
              applyVat: _inv['vatApplied'] as bool? ?? _vat > 0,
            ),
            if (_inv['paymentMethod'] != null) ...[
              const SizedBox(height: 16),
              _PaymentInfoCard(invoice: _inv),
            ],
            if ((_inv['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _NotesCard(notes: _inv['notes'].toString()),
            ],
            const SizedBox(height: 16),
            _ActionsCard(
              status: _status,
              isQuotation: _isQuotation,
              updating: _updating,
              onMarkPaid: () => _updateStatus('paid'),
              onMarkSent: () => _updateStatus('sent'),
              onCancel: () => _confirmCancel(),
              onConvert: _convertToInvoice,
              onEdit: _openEdit,
              onReturn: _openReturn,
              onRecordPayment: _recordPayment,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.navyPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        _isQuotation ? _tr('Quotation', 'Nukuu') : _tr('Invoice', 'Ankara'),
        style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, size: 20),
          tooltip: _tr('Edit', 'Hariri'),
          onPressed: _openEdit,
        ),
      ],
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_tr('Cancel Invoice?', 'Futa Ankara?'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
            _tr('This action cannot be undone.', 'Hatua hii haiwezi kutenduliwa.'),
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_tr('Back', 'Rudi'),
                  style: GoogleFonts.dmSans())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(context).pop();
              _updateStatus('cancelled');
            },
            child: Text(_tr('Cancel Invoice', 'Futa Ankara'),
                style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final String invoiceNumber;
  final double total;
  final String status;
  final bool isQuotation;
  final String customerName;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final int itemCount;
  final double outstanding;

  const _InvoiceSummaryCard({
    required this.invoiceNumber,
    required this.total,
    required this.status,
    required this.isQuotation,
    required this.customerName,
    required this.invoiceDate,
    required this.dueDate,
    required this.itemCount,
    required this.outstanding,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = dueDate != null &&
        dueDate!.isBefore(DateTime.now()) &&
        status != 'paid' &&
        status != 'cancelled';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (invoiceNumber.isNotEmpty)
                          Text(
                            invoiceNumber,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
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
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PaymentStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMeta(
                  label: _tr('Date', 'Tarehe'),
                  value: invoiceDate == null ? '-' : _fmt(invoiceDate!),
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              Expanded(
                child: _SummaryMeta(
                  label: _tr('Due', 'Mwisho'),
                  value: dueDate == null ? '-' : _fmt(dueDate!),
                  icon: Icons.event_rounded,
                  warn: overdue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'TZS ${_fmtNum(total)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (itemCount > 0)
                Text(
                  '· $itemCount ${_tr(itemCount == 1 ? 'item' : 'items', itemCount == 1 ? 'kitu' : 'vitu')}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              const Spacer(),
              if (outstanding > 0 && status != 'paid' && status != 'cancelled')
                Text(
                  '${_tr('Due', 'Baki')}: TZS ${_fmtNum(outstanding)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          if (overdue) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 12, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  '${_tr('Due was', 'Malipo ilikuwa')} ${_fmt(dueDate!)} ${dueDate!.year}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMeta extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool warn;

  const _SummaryMeta({
    required this.label,
    required this.value,
    required this.icon,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warn ? AppColors.error : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Share Row ─────────────────────────────────────────────────────────────────

class _ShareRow extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onEmail;
  final VoidCallback onCopy;

  const _ShareRow(
      {required this.onWhatsApp,
      required this.onEmail,
      required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShareBtn(
            label: 'WhatsApp',
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            onTap: onWhatsApp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ShareBtn(
            label: _tr('Email', 'Barua pepe'),
            icon: Icons.email_rounded,
            color: AppColors.tealAccent,
            onTap: onEmail,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ShareBtn(
            label: _tr('Copy', 'Nakili'),
            icon: Icons.copy_rounded,
            color: AppColors.textSecondary,
            onTap: onCopy,
          ),
        ),
      ],
    );
  }
}

class _ShareBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShareBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line Items ────────────────────────────────────────────────────────────────

class _LineItemsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _LineItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
          child: Text(
            _tr('Items', 'Bidhaaa'),
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3),
          ),
        ),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final isLast = i == items.length - 1;
          final productName = item['productName']?.toString() ?? '—';
          final unit = (item['unit'] ?? '').toString();
          final unitPrice = parseNumericAmount(item['unitPrice']);
          final lineTotal = parseNumericAmount(item['lineTotal']);
          final qty = item['qty']?.toString() ?? '1';
          final isService = (item['productType'] as String?) == 'service';

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadowCard,
                      blurRadius: 6,
                      offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  // Icon with tinted background — inventory card style
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isService
                          ? Icons.design_services_rounded
                          : Icons.inventory_2_outlined,
                      size: 20,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name + unit · price per unit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary),
                        ),
                        if (unit.isNotEmpty || unitPrice > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (unit.isNotEmpty) unit,
                              if (unitPrice > 0)
                                'TZS ${_fmtNum(unitPrice)} ${_tr("each", "kila")}',
                            ].join(' · '),
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Qty × total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TZS ${_fmtNum(lineTotal)}',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyPrimary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.navyPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.navyPrimary.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          '×$qty',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double vatAmount;
  final double total;
  final bool applyVat;

  const _SummaryCard({
    required this.subtotal,
    required this.discount,
    required this.vatAmount,
    required this.total,
    required this.applyVat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SRow(
              label: _tr('Subtotal', 'Jumla Ndogo'),
              value: 'TZS ${_fmtNum(subtotal)}'),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _SRow(
                label: _tr('Discount', 'Punguzo'),
                value: '-TZS ${_fmtNum(discount)}',
                valueColor: AppColors.success),
          ],
          if (applyVat && vatAmount > 0) ...[
            const SizedBox(height: 8),
            _SRow(
                label: _tr('VAT (18%)', 'VAT (18%)'),
                value: 'TZS ${_fmtNum(vatAmount)}'),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tr('TOTAL', 'JUMLA'),
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary),
              ),
              Text(
                'TZS ${_fmtNum(total)}',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22, color: AppColors.navyPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}

// ── Payment Info ─────────────────────────────────────────────────────────────

class _PaymentInfoCard extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const _PaymentInfoCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final method = invoice['paymentMethod']?.toString() ?? '';
    final ref = invoice['mpesaReference']?.toString() ?? '';
    final methodLabel = switch (method) {
      'cash' => _tr('Cash', 'Taslimu'),
      'mpesa' => 'M-Pesa',
      'bank' => _tr('Bank Transfer', 'Benki'),
      'card' => _tr('Card', 'Kadi'),
      'credit' => _tr('On Account', 'Mkopo'),
      _ => method,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_rounded,
                size: 20, color: AppColors.navyPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Payment Method', 'Njia ya Malipo'),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                Text(
                  methodLabel,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (ref.isNotEmpty)
                  Text(
                    '${_tr('Ref:', 'Kumb:')} $ref',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notes Card ────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final String notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Notes', 'Maelezo'),
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(notes,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Actions Card ──────────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  final String status;
  final bool isQuotation;
  final bool updating;
  final VoidCallback onMarkPaid;
  final VoidCallback onMarkSent;
  final VoidCallback onCancel;
  final VoidCallback onConvert;
  final VoidCallback onEdit;
  final VoidCallback onReturn;
  final VoidCallback onRecordPayment;

  const _ActionsCard({
    required this.status,
    required this.isQuotation,
    required this.updating,
    required this.onMarkPaid,
    required this.onMarkSent,
    required this.onCancel,
    required this.onConvert,
    required this.onEdit,
    required this.onReturn,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isDraft = status == 'draft';
    final isPaid = status == 'paid';
    final isCancelled = status == 'cancelled';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Actions', 'Hatua'),
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (isQuotation && !isCancelled) ...[
            _ActionTile(
              icon: Icons.swap_horiz_rounded,
              label: _tr('Convert to Invoice', 'Badilisha kuwa Ankara'),
              color: AppColors.tealAccent,
              onTap: updating ? null : onConvert,
            ),
            const SizedBox(height: 8),
          ],
          if (!isPaid && !isCancelled && !isQuotation) ...[
            _ActionTile(
              icon: Icons.check_circle_rounded,
              label: _tr('Mark as Paid', 'Weka kama Imelipwa'),
              color: AppColors.success,
              onTap: updating ? null : onMarkPaid,
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.account_balance_wallet_rounded,
              label: _tr('Record Payment', 'Rekodi Malipo'),
              color: AppColors.navyPrimary,
              onTap: updating ? null : onRecordPayment,
            ),
            const SizedBox(height: 8),
          ],
          if (isDraft && !isQuotation) ...[
            _ActionTile(
              icon: Icons.send_rounded,
              label: _tr('Mark as Sent', 'Weka kama Imetumwa'),
              color: AppColors.tealAccent,
              onTap: updating ? null : onMarkSent,
            ),
            const SizedBox(height: 8),
          ],
          if (isPaid && !isQuotation) ...[
            _ActionTile(
              icon: Icons.undo_rounded,
              label: _tr('Issue Credit Note / Return',
                  'Toa Nota ya Mkopo / Rudisha'),
              color: AppColors.warning,
              onTap: onReturn,
            ),
            const SizedBox(height: 8),
          ],
          if (!isCancelled) ...[
            _ActionTile(
              icon: Icons.edit_rounded,
              label: _tr('Edit Invoice', 'Hariri Ankara'),
              color: AppColors.textSecondary,
              onTap: onEdit,
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.cancel_rounded,
              label: _tr('Cancel Invoice', 'Futa Ankara'),
              color: AppColors.error,
              onTap: updating ? null : onCancel,
              destructive: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool destructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: destructive
                ? AppColors.error.withOpacity(0.05)
                : color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: destructive
                    ? AppColors.error.withOpacity(0.2)
                    : color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: destructive
                          ? AppColors.error
                          : AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Record Payment Sheet ──────────────────────────────────────────────────────

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final double outstanding;
  final String invoiceId;

  const _RecordPaymentSheet(
      {required this.outstanding, required this.invoiceId});

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState
    extends ConsumerState<_RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text =
        widget.outstanding.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final paymentsCol = repo.scopeCollection(
          uid: user.uid,
          context: ctx,
          childCollection: 'invoice_payments');

      await paymentsCol.add({
        'invoiceId': widget.invoiceId,
        'amount': amount,
        'method': _method,
        if (_refCtrl.text.isNotEmpty) 'reference': _refCtrl.text,
        'recordedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.of(context).pop({'paid': true});
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
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
            const SizedBox(height: 16),
            Text(
              _tr('Record Payment', 'Rekodi Malipo'),
              style: GoogleFonts.dmSans(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _tr('Outstanding: TZS ${_fmtNum(widget.outstanding)}',
                  'Inayodaiwa: TZS ${_fmtNum(widget.outstanding)}'),
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(_tr('Amount Received', 'Kiasi Kilichopokelewa'),
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: 'TZS ',
                prefixStyle: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['cash', 'mpesa', 'bank', 'card'].map((m) {
                final labels = {
                  'cash': _tr('Cash', 'Taslimu'),
                  'mpesa': 'M-Pesa',
                  'bank': _tr('Bank', 'Benki'),
                  'card': _tr('Card', 'Kadi'),
                };
                final active = m == _method;
                return GestureDetector(
                  onTap: () => setState(() => _method = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.navyPrimary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labels[m]!,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              active ? Colors.white : AppColors.textSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_method == 'mpesa') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _refCtrl,
                decoration: InputDecoration(
                  hintText:
                      _tr('M-Pesa reference', 'Nambari ya M-Pesa'),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
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
                        _tr('Confirm Payment', 'Thibitisha Malipo'),
                        style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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

