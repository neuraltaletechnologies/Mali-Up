import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../data/sales_providers.dart';

enum _ResolutionType { refundCash, exchangeProduct }

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SalesReturnScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> originalInvoice;

  const SalesReturnScreen({super.key, required this.originalInvoice});

  @override
  ConsumerState<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends ConsumerState<SalesReturnScreen>
    with SingleTickerProviderStateMixin {
  late List<_ReturnLine> _lines;
  String _reason = '';
  bool _restockAll = true;
  bool _saving = false;
  _ResolutionType _resolution = _ResolutionType.refundCash;
  // Exchange: product picked from inventory search
  String _exchangeProductId   = '';
  String _exchangeProductName = '';

  final _reasonCtrl   = TextEditingController();
  final _exchangeCtrl = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Full invoices store 'lineItems'; quick sales (and locally synced rows)
    // store 'items' — accept either so every sale can be returned.
    final rawLineItems = widget.originalInvoice['lineItems'];
    final raw = (rawLineItems is List && rawLineItems.isNotEmpty)
        ? rawLineItems
        : widget.originalInvoice['items'];
    if (raw is List) {
      _lines = raw
          .whereType<Map>()
          .map((item) => _ReturnLine.fromInvoiceItem(
              Map<String, dynamic>.from(item)))
          .toList();
    } else {
      _lines = [];
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _exchangeCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Computed ─────────────────────────────────────────────────────────────────

  double get _creditAmount => _lines
      .where((l) => l.selected)
      .fold(0.0, (s, l) => s + l.returnTotal);

  bool get _hasSelection => _lines.any((l) => l.selected && l.returnQty > 0);

  // ── Save ──────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_hasSelection) {
      _showSnack(_tr(
          'Select at least one item to return',
          'Chagua bidhaaa angalau moja ya kurudisha'));
      return;
    }
    if (_resolution == _ResolutionType.exchangeProduct && _exchangeProductId.isEmpty) {
      _showSnack(_tr(
          'Select a replacement product for the exchange',
          'Chagua bidhaa ya kubadilishana'));
      return;
    }
    setState(() => _saving = true);

    try {
      final scope = await resolveSalesScope(ref);
      if (scope == null) throw Exception('Not authenticated');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final role = ref.read(currentUserRoleProvider);

      final selectedLines = _lines.where((l) => l.selected && l.returnQty > 0);

      // Credit note number
      final now = DateTime.now();
      final rand =
          (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
      final creditNoteNumber =
          'CN-${now.year}${now.month.toString().padLeft(2, '0')}-$rand';

      final returnItemsData = selectedLines
          .map((l) => {
                'productId': l.productId,
                'productName': l.productName,
                'unitPrice': l.unitPrice,
                'returnQty': l.returnQty,
                'lineTotal': l.returnTotal,
                'restock': _restockAll,
              })
          .toList();

      final invoiceId = widget.originalInvoice['id'] as String;
      final invoiceNumber = (widget.originalInvoice['invoiceNumber'] ??
              widget.originalInvoice['id'])
          .toString();

      // One atomic batch: credit note + stock reversal + invoice flag.
      final batch = FirebaseFirestore.instance.batch();

      final cnCol = repo.scopeCollection(
          uid: scope.ownerUid,
          context: scope.context,
          childCollection: 'credit_notes');
      batch.set(cnCol.doc(), {
        'creditNoteNumber': creditNoteNumber,
        'originalInvoiceId': invoiceId,
        'originalInvoiceNumber': invoiceNumber,
        'businessId': scope.businessId,
        'customerId': widget.originalInvoice['customerId'] ?? '',
        'customerName': widget.originalInvoice['customerName'] ?? '',
        'returnItems': returnItemsData,
        'creditAmount': _creditAmount,
        'reason': _reason,
        'restockItems': _restockAll,
        'resolutionType': _resolution.name,
        if (_resolution == _ResolutionType.exchangeProduct) ...{
          'exchangeProductId': _exchangeProductId,
          'exchangeProductName': _exchangeProductName,
        },
        'status': 'issued',
        'processedBy': scope.userUid,
        'processedByRole': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Stock reversal — the sale deducted 'currentStock', so the return
      // must credit the same field.
      if (_restockAll) {
        final invCol = repo.scopeCollection(
            uid: scope.ownerUid,
            context: scope.context,
            childCollection: 'inventory_items');
        for (final line in selectedLines) {
          if (line.productId.isNotEmpty) {
            batch.set(
                invCol.doc(line.productId),
                {
                  'currentStock': FieldValue.increment(line.returnQty),
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true));
          }
        }
      }

      // Exchange: deduct one unit of the replacement product
      if (_resolution == _ResolutionType.exchangeProduct &&
          _exchangeProductId.isNotEmpty) {
        final invCol = repo.scopeCollection(
            uid: scope.ownerUid,
            context: scope.context,
            childCollection: 'inventory_items');
        batch.set(
            invCol.doc(_exchangeProductId),
            {
              'currentStock': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      // Flag the original invoice
      final salesCol = repo.scopeCollection(
          uid: scope.ownerUid,
          context: scope.context,
          childCollection: 'sales_invoices');
      batch.update(salesCol.doc(invoiceId), {
        'hasReturn': true,
        'creditNoteNumber': creditNoteNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      unawaited(AuditLogService().logSaleAction(
        ownerUid: scope.ownerUid,
        businessId: scope.businessId,
        performedByUid: scope.userUid,
        performedByRole: role,
        action: AuditLogService.returnProcessed,
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        amount: _creditAmount,
        details: _reason,
      ));
      unawaited(ref.read(syncServiceProvider).syncNow());

      if (mounted) {
        Navigator.of(context).pop({'saved': true, 'creditNoteNumber': creditNoteNumber});
      }
    } catch (e) {
      _showSnack(_tr('Failed to save: $e', 'Imeshindwa kuhifadhi: $e'));
      setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _tr('Sales Return', 'Kurudisha Bidhaaa'),
          style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                children: [
                    _InvoiceSummaryCard(
                      invoice: widget.originalInvoice),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    _tr('Select Items to Return',
                        'Chagua Bidhaaa za Kurudisha')),
                  const SizedBox(height: 8),
                  if (_lines.isEmpty)
                    _EmptyItems()
                  else
                    ..._lines.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ReturnItemCard(
                          line: e.value,
                          onToggle: (v) =>
                              setState(() => _lines[e.key].selected = v),
                          onQtyChange: (v) =>
                              setState(() => _lines[e.key].returnQty = v),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  _RestockToggle(
                    value: _restockAll,
                    onChanged: (v) => setState(() => _restockAll = v),
                  ),
                  const SizedBox(height: 16),
                  _ResolutionPicker(
                    value: _resolution,
                    onChanged: (v) => setState(() => _resolution = v),
                  ),
                  if (_resolution == _ResolutionType.exchangeProduct) ...[
                    const SizedBox(height: 10),
                    _ExchangeProductPicker(
                      controller: _exchangeCtrl,
                      selectedId: _exchangeProductId,
                      selectedName: _exchangeProductName,
                      onSelected: (id, name) => setState(() {
                        _exchangeProductId   = id;
                        _exchangeProductName = name;
                        _exchangeCtrl.text   = name;
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ReasonField(
                    controller: _reasonCtrl,
                    onChanged: (v) => _reason = v,
                  ),
                  const SizedBox(height: 16),
                  if (_hasSelection) _CreditSummary(amount: _creditAmount),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            _BottomBar(
              saving: _saving,
              hasSelection: _hasSelection,
              creditAmount: _creditAmount,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _ReturnLine {
  final String productId;
  final String productName;
  final double unitPrice;
  final int originalQty;
  bool selected = true;
  int returnQty;

  _ReturnLine({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.originalQty,
    required this.returnQty,
  });

  factory _ReturnLine.fromInvoiceItem(Map<String, dynamic> item) {
    final rawQty = item['qty'] ?? item['quantity'];
    final qty = (rawQty is num) ? rawQty.toInt() : 1;
    return _ReturnLine(
      productId: (item['productId'] ?? item['inventoryItemId'] ?? '')
          .toString(),
      productName:
          (item['productName'] ?? item['name'] ?? '').toString(),
      unitPrice: parseNumericAmount(item['unitPrice']),
      originalQty: qty,
      returnQty: qty,
    );
  }

  double get returnTotal => unitPrice * returnQty;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceSummaryCard extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const _InvoiceSummaryCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final number = invoice['invoiceNumber']?.toString() ??
        invoice['id']?.toString() ?? '—';
    final customer =
        invoice['customerName']?.toString() ?? _tr('Walk-in', 'Mteja wa Njiani');
    final total = parseNumericAmount(invoice['totalAmount']);
    final status = invoice['status']?.toString().toLowerCase() ?? 'posted';
    final itemCount = invoice['lineItems'] is List
        ? (invoice['lineItems'] as List).length
        : 0;
    final invoiceDate = _readInvoiceDate(invoice['invoiceDate']) ??
        _readInvoiceDate(invoice['createdAt']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                        Text(
                          number,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _tr('ORIG', 'ASILI'),
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3),
                    Text(
                      customer,
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
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMeta(
                  label: _tr('Date', 'Tarehe'),
                  value: invoiceDate == null ? '-' : _fmt(invoiceDate),
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              Expanded(
                child: _SummaryMeta(
                  label: _tr('Items', 'Bidhaa'),
                  value: '$itemCount',
                  icon: Icons.inventory_2_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(height: 12),
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
              Spacer(),
              Text(
                _tr('Source invoice', 'Ankara chanzo'),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isPaid = normalized == 'paid';
    final isCancelled = normalized == 'cancelled';
    final isDraft = normalized == 'draft';
    final color = isPaid
        ? AppColors.success
        : isCancelled
            ? AppColors.error
            : isDraft
                ? AppColors.warning
                : AppColors.tealAccent;
    final label = isPaid
        ? _tr('Paid', 'Imelipwa')
        : isCancelled
            ? _tr('Cancelled', 'Imefutwa')
            : isDraft
                ? _tr('Draft', 'Rasimu')
                : _tr('Posted', 'Imechapishwa');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SummaryMeta extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMeta({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: AppColors.textMuted),
            SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.receipt_long_outlined,
        title: _tr('No items on this invoice',
            'Hakuna bidhaa kwenye ankara hii'),
        subtitle: _tr(
          'This invoice has no line items to return.',
          'Ankara hii haina bidhaa za kurudisha.',
        ),
      );
}

class _ReturnItemCard extends StatelessWidget {
  final _ReturnLine line;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQtyChange;

  const _ReturnItemCard({
    required this.line,
    required this.onToggle,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: line.selected ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: line.selected
                ? AppColors.navyPrimary.withValues(alpha: 0.3)
                : AppColors.border,
            width: line.selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Top: product name + checkbox
            InkWell(
              onTap: () => onToggle(!line.selected),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: line.selected
                            ? AppColors.navyPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: line.selected
                              ? AppColors.navyPrimary
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: line.selected
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        line.productName,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      'TZS ${_fmtNum(line.unitPrice)} × ${line.originalQty}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            if (line.selected) ...[
              Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tr('Return quantity:', 'Idadi ya kurudisha:'),
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ),
                    _QtyPicker(
                      value: line.returnQty,
                      max: line.originalQty,
                      onChanged: onQtyChange,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'TZS ${_fmtNum(line.returnTotal)}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QtyPicker extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _QtyPicker(
      {required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Container(
          width: 36,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value.toString(),
            style: GoogleFonts.jetBrainsMono(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        _Btn(
          icon: Icons.add_rounded,
          onTap: value < max ? () => onChanged(value + 1) : null,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.35 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 28,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 14, color: AppColors.navyPrimary),
        ),
      ),
    );
  }
}

class _RestockToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RestockToggle(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.inventory_rounded,
                size: 18, color: AppColors.tealAccent),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Add back to inventory', 'Ongeza tena kwenye hifadhi'),
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  _tr('Restores stock for returned items',
                      'Inarudisha bidhaa kwa bidhaaa zilizorudishwa'),
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.tealAccent,
            activeTrackColor: AppColors.tealAccent.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _ReasonField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _ReasonField(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Reason for Return', 'Sababu ya Kurudisha'),
          style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _tr(
                  'e.g. Damaged goods, wrong item delivered, customer changed mind…',
                  'mfano: Bidhaaa ziliharibiwa, bidhaaa mbaya kuletewa, mteja alibadilisha mawazo…'),
              hintStyle: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
            style: GoogleFonts.dmSans(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CreditSummary extends StatelessWidget {
  final double amount;

  const _CreditSummary({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withValues(alpha: 0.08),
            AppColors.error.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.credit_score_rounded,
              color: AppColors.error, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Credit Note Value', 'Thamani ya Nota ya Mkopo'),
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.error),
                ),
                Text(
                  _tr('Customer will be credited this amount',
                      'Mteja atapewa mkopo wa kiasi hiki'),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            'TZS ${_fmtNum(amount)}',
            style: GoogleFonts.dmSerifDisplay(
                fontSize: 20, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool saving;
  final bool hasSelection;
  final double creditAmount;
  final VoidCallback onSave;

  const _BottomBar({
    required this.saving,
    required this.hasSelection,
    required this.creditAmount,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (hasSelection)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tr('Credit Amount', 'Kiasi cha Mkopo'),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    'TZS ${_fmtNum(creditAmount)}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error),
                  ),
                ],
              ),
            ),
          if (!hasSelection)
            Expanded(
              child: Text(
                _tr('Select items to return',
                    'Chagua bidhaaa za kurudisha'),
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          SizedBox(width: 12),
          FilledButton.icon(
            onPressed: (saving || !hasSelection) ? null : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(Icons.undo_rounded, size: 16),
            label: Text(
              saving
                  ? _tr('Saving…', 'Inahifadhi…')
                  : _tr('Issue Credit Note', 'Toa Nota ya Mkopo'),
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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

DateTime? _readInvoiceDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _fmt(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}

// ─────────────────────────────────────────────────────────────────────────────
// Resolution type picker (Refund Cash | Exchange Product)
// ─────────────────────────────────────────────────────────────────────────────

class _ResolutionPicker extends StatelessWidget {
  final _ResolutionType value;
  final ValueChanged<_ResolutionType> onChanged;

  const _ResolutionPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Resolution', 'Suluhisho'),
          style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ResolutionOption(
              icon: Icons.payments_outlined,
              label: _tr('Refund Cash', 'Rejesha Pesa'),
              selected: value == _ResolutionType.refundCash,
              onTap: () => onChanged(_ResolutionType.refundCash),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ResolutionOption(
              icon: Icons.swap_horiz_rounded,
              label: _tr('Exchange Product', 'Badilisha Bidhaa'),
              selected: value == _ResolutionType.exchangeProduct,
              onTap: () => onChanged(_ResolutionType.exchangeProduct),
            )),
          ],
        ),
      ],
    );
  }
}

class _ResolutionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ResolutionOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.tealAccent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? Colors.white : AppColors.textMuted),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.navyPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exchange product picker — live search from inventory
// ─────────────────────────────────────────────────────────────────────────────

class _ExchangeProductPicker extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String selectedId;
  final String selectedName;
  final void Function(String id, String name) onSelected;

  const _ExchangeProductPicker({
    required this.controller,
    required this.selectedId,
    required this.selectedName,
    required this.onSelected,
  });

  @override
  ConsumerState<_ExchangeProductPicker> createState() =>
      _ExchangeProductPickerState();
}

class _ExchangeProductPickerState
    extends ConsumerState<_ExchangeProductPicker> {
  final _focus = FocusNode();
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _showList = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.controller.text.trim().toLowerCase();
    final allItems = ref.watch(inventoryProvider).valueOrNull ?? [];
    final suggestions = (_showList && q.isNotEmpty)
        ? allItems
            .where((i) => i.name.toLowerCase().contains(q) && !i.isService)
            .take(5)
            .toList()
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Replacement Product *', 'Bidhaa ya Kubadilisha *'),
          style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.navyPrimary, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: _tr('Search product to give instead…', 'Tafuta bidhaa ya kutoa badala yake…'),
            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDisabled),
            prefixIcon: widget.selectedId.isNotEmpty
                ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
                : const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.tealAccent, width: 1.5)),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: suggestions.asMap().entries.map((e) {
                final idx  = e.key;
                final item = e.value;
                return InkWell(
                  onTap: () {
                    widget.onSelected(item.id, item.name);
                    _focus.unfocus();
                  },
                  borderRadius: BorderRadius.vertical(
                    top: idx == 0 ? const Radius.circular(10) : Radius.zero,
                    bottom: idx == suggestions.length - 1 ? const Radius.circular(10) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textMuted),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyPrimary),
                          ),
                        ),
                        Text(
                          '${item.currentStock.toStringAsFixed(0)} ${item.unit}',
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
