import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/online_guard.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/validation_banner.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../debt/data/customer_debt_sync_service.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/domain/models/debt.dart';
import '../../../finance/data/payment_account_service.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../data/sales_providers.dart';

enum _ResolutionType { refundCash, exchangeProduct }

/// Preset return reasons. The three damage reasons ([damagedInTransit],
/// [damagedInStorage], [defective]) mark goods that can't go back into
/// sellable stock — picking one auto-clears "Return to inventory" and makes
/// the proof photo mandatory.
enum _ReturnReason {
  damagedInTransit,
  damagedInStorage,
  defective,
  wrongItem,
  changedMind,
  other,
}

extension _ReturnReasonX on _ReturnReason {
  bool get isDamage =>
      this == _ReturnReason.damagedInTransit ||
      this == _ReturnReason.damagedInStorage ||
      this == _ReturnReason.defective;

  String get label {
    switch (this) {
      case _ReturnReason.damagedInTransit:
        return _tr('Damaged in transit', 'Iliharibika njiani');
      case _ReturnReason.damagedInStorage:
        return _tr('Damaged — poor storage', 'Iliharibika kwa kuhifadhi vibaya');
      case _ReturnReason.defective:
        return _tr('Defective / faulty', 'Ina hitilafu');
      case _ReturnReason.wrongItem:
        return _tr('Wrong item delivered', 'Bidhaa isiyo sahihi ilipelekwa');
      case _ReturnReason.changedMind:
        return _tr('Customer changed mind', 'Mteja alibadili mawazo');
      case _ReturnReason.other:
        return _tr('Other', 'Nyingine');
    }
  }

  IconData get icon {
    switch (this) {
      case _ReturnReason.damagedInTransit:
        return Icons.local_shipping_outlined;
      case _ReturnReason.damagedInStorage:
        return Icons.inventory_2_outlined;
      case _ReturnReason.defective:
        return Icons.build_outlined;
      case _ReturnReason.wrongItem:
        return Icons.swap_horiz_rounded;
      case _ReturnReason.changedMind:
        return Icons.person_outline_rounded;
      case _ReturnReason.other:
        return Icons.more_horiz_rounded;
    }
  }
}

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
  _ReturnReason? _reasonType;
  String _reasonNote = '';
  bool _restockAll = true;
  bool _saving = false;
  String? _errorMsg;
  _ResolutionType _resolution = _ResolutionType.refundCash;
  // Exchange: product picked from inventory search
  String _exchangeProductId   = '';
  String _exchangeProductName = '';
  // Proof-of-return photo (required when a damage reason is picked).
  File? _proofFile;

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

  /// The reason string persisted on the credit note: preset label, with the
  /// optional free-text note appended when the seller added one.
  String get _composedReason {
    final base = _reasonType?.label ?? '';
    final note = _reasonNote.trim();
    if (base.isEmpty) return note;
    if (note.isEmpty) return base;
    return '$base — $note';
  }

  /// Product ids of the currently synced inventory that are services —
  /// services are never returned to stock.
  Set<String> _serviceIds() {
    final items = ref.read(inventoryProvider).valueOrNull ?? const <InventoryItem>[];
    return {for (final i in items) if (i.isService) i.id};
  }

  /// Damage reasons destroy the goods — they can't re-enter sellable stock,
  /// so clear the restock toggle the moment one is picked (the seller can
  /// still switch it back on manually).
  void _onReasonPicked(_ReturnReason reason) {
    setState(() {
      _reasonType = reason;
      if (reason.isDamage) _restockAll = false;
    });
  }

  // ── Proof photo ───────────────────────────────────────────────────────────────

  Future<void> _pickProof(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (file == null) return;
      setState(() => _proofFile = File(file.path));
    } catch (_) {
      _showSnack(_tr(
        'Could not open ${source == ImageSource.camera ? 'the camera' : 'your photos'}. Check app permissions and try again.',
        'Imeshindwa kufungua ${source == ImageSource.camera ? 'kamera' : 'picha zako'}. Angalia ruhusa za programu kisha ujaribu tena.',
      ));
    }
  }

  Future<void> _showProofOptions() async {
    final source = await showAppSheet<ImageSource>(
      context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.navyPrimary),
              title: Text(_tr('Take photo', 'Piga picha'),
                  style: GoogleFonts.dmSans()),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.navyPrimary),
              title: Text(_tr('Choose from gallery', 'Chagua kutoka maktaba'),
                  style: GoogleFonts.dmSans()),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            if (_proofFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: Text(_tr('Remove photo', 'Ondoa picha'),
                    style: GoogleFonts.dmSans(color: AppColors.error)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _proofFile = null);
                },
              ),
          ],
        ),
      ),
    );
    if (source != null && mounted) await _pickProof(source);
  }

  /// Uploads the proof photo and returns its download URL, or null when there
  /// is no photo. Throws on a genuine upload failure so [_save] can abort.
  Future<String?> _uploadProof(String uid, String creditNoteNumber) async {
    if (_proofFile == null) return null;
    final storageRef = FirebaseStorage.instance.ref(
      'returns/$uid/$creditNoteNumber-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await storageRef.putFile(_proofFile!);
    return storageRef.getDownloadURL();
  }

  // ── Save ──────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_hasSelection) {
      _showSnack(_tr(
          'Select at least one item to return',
          'Chagua bidhaaa angalau moja ya kurudisha'));
      return;
    }
    if (_reasonType == null) {
      _showSnack(_tr(
          'Choose a reason for the return',
          'Chagua sababu ya kurudisha'));
      return;
    }
    if (_reasonType!.isDamage && _proofFile == null) {
      _showSnack(_tr(
          'Attach a proof photo for a damaged-goods return',
          'Ambatanisha picha ya ushahidi kwa marejesho ya bidhaa iliyoharibika'));
      return;
    }
    if (_resolution == _ResolutionType.exchangeProduct && _exchangeProductId.isEmpty) {
      _showSnack(_tr(
          'Select a replacement product for the exchange',
          'Chagua bidhaa ya kubadilishana'));
      return;
    }
    // Returns commit an atomic Firestore batch (stock restore + credit note
    // + balances) — online-only for now.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;
    setState(() {
      _saving = true;
      _errorMsg = null;
    });

    try {
      final scope = await resolveSalesScope(ref);
      if (scope == null) throw Exception('Not authenticated');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final role = ref.read(currentUserRoleProvider);

      final selectedLines = _lines.where((l) => l.selected && l.returnQty > 0);

      // Restock only lines still linked to a product that exists locally and
      // isn't a service — free-text sale lines carry a generated row id (a
      // merge-set on that id would create a phantom inventory document), and
      // a service has no stock to credit back.
      final db = ref.read(appDatabaseProvider);
      final serviceIds = _serviceIds();
      final restockableIds = <String>{};
      if (_restockAll) {
        for (final line in selectedLines) {
          if (line.productId.isEmpty) continue;
          if (serviceIds.contains(line.productId)) continue;
          if (await db.inventoryDao.getById(line.productId) != null) {
            restockableIds.add(line.productId);
          }
        }
      }

      // Credit note number
      final now = DateTime.now();
      final rand =
          (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
      final creditNoteNumber =
          'CN-${now.year}${now.month.toString().padLeft(2, '0')}-$rand';

      // Upload the proof photo before committing anything — a failure here
      // must abort the whole return (mandatory for damaged-goods returns).
      String? proofPhotoUrl;
      try {
        proofPhotoUrl = await _uploadProof(scope.userUid, creditNoteNumber);
      } catch (_) {
        _showSnack(_tr(
            'Proof photo upload failed. Check your connection and try again.',
            'Kupakia picha ya ushahidi kumeshindikana. Angalia mtandao kisha ujaribu tena.'));
        setState(() => _saving = false);
        return;
      }

      final returnItemsData = selectedLines
          .map((l) => {
                'productId': l.productId,
                'productName': l.productName,
                'unitPrice': l.unitPrice,
                'returnQty': l.returnQty,
                'lineTotal': l.returnTotal,
                'restock': restockableIds.contains(l.productId),
                'isService': serviceIds.contains(l.productId),
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
        'reason': _composedReason,
        'reasonCategory': _reasonType!.name,
        'restockItems': restockableIds.isNotEmpty,
        'proofPhotoUrl': ?proofPhotoUrl,
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
          if (restockableIds.contains(line.productId)) {
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

      // Flag the original invoice and net the credited amount out of what it
      // reads as worth everywhere else (sales list, dashboard revenue,
      // outstanding-balance calc) — see readInvoiceTotal.
      final salesCol = repo.scopeCollection(
          uid: scope.ownerUid,
          context: scope.context,
          childCollection: 'sales_invoices');
      batch.update(salesCol.doc(invoiceId), {
        'hasReturn': true,
        'creditNoteNumber': creditNoteNumber,
        'returnedAmount': FieldValue.increment(_creditAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Resolve what the return actually settles: refunding cash first pays
      // down any outstanding debt on this invoice (the customer no longer
      // owes for goods they gave back), and only the leftover — money that
      // was actually collected — comes out of the till as a cash refund. An
      // exchange is a same-value swap: nothing owed changes, so no debt or
      // money adjustment happens for it.
      Debt? debt;
      double debtReduction = 0;
      double cashRefund = 0;
      if (_resolution == _ResolutionType.refundCash) {
        debt = await ref.read(debtRepositoryProvider).getByInvoiceRef(invoiceNumber);
        if (debt != null && !debt.isFullyPaid) {
          debtReduction = _creditAmount < debt.remainingAmount
              ? _creditAmount
              : debt.remainingAmount;
        }
        cashRefund = _creditAmount - debtReduction;
      }

      await batch.commit();

      // Mirror the stock changes into Drift immediately — the UI reads stock
      // from Drift, and the incremental sync pull can miss these writes when
      // the device clock runs ahead of the Firestore server clock.
      try {
        if (_restockAll) {
          for (final line in selectedLines) {
            if (!restockableIds.contains(line.productId)) continue;
            await db.inventoryDao
                .applyCommittedDelta(line.productId, line.returnQty.toDouble());
          }
        }
        if (_resolution == _ResolutionType.exchangeProduct &&
            _exchangeProductId.isNotEmpty) {
          await db.inventoryDao.applyCommittedDelta(_exchangeProductId, -1);
        }
        // Mirror the invoice's returnedAmount the same way — the sales list,
        // dashboard revenue and outstanding-balance calc all read this
        // invoice from Drift, not from the Firestore doc just updated above.
        await db.invoiceDao.applyCommittedReturn(
          invoiceId,
          returnedAmountDelta: _creditAmount,
          creditNoteNumber: creditNoteNumber,
        );
      } catch (_) {}

      // Debt/balance settlement — real writes (Drift + queued Firestore push
      // via the normal repositories), since nothing above touched debts or
      // customer balances. Follows the same paidAmount + payment-record +
      // adjustCustomerBalanceForDebtChange idiom as the manual repayment
      // flow in debt_detail_screen, so the debt's payment history stays
      // reconcilable with paidAmount instead of silently drifting apart.
      if (debtReduction > 0 && debt != null) {
        final debtRepo = ref.read(debtRepositoryProvider);
        await debtRepo.addPayment(
          debt.id,
          DebtPayment(
            id: '',
            amount: debtReduction,
            date: now.toIso8601String().split('T').first,
            method: 'return',
            note: creditNoteNumber,
            recordedBy: scope.userUid,
          ),
        );
        final newPaid = debt.paidAmount + debtReduction;
        final updatedDebt = debt.copyWith(
          paidAmount: newPaid,
          status: newPaid >= debt.totalOwedWithInterest ? 'paid' : debt.status,
        );
        await debtRepo.save(updatedDebt);
        await adjustCustomerBalanceForDebtChange(
          ref,
          before: debt,
          after: updatedDebt,
        );
      }
      if (cashRefund > 0) {
        final paymentAccountId =
            (widget.originalInvoice['paymentAccountId'] ?? '').toString();
        if (paymentAccountId.isNotEmpty) {
          await moveMoneyForAccount(
            ref,
            accountId: paymentAccountId,
            amount: cashRefund,
            isDeposit: false,
            description: _tr(
                'Return $invoiceNumber', 'Marejesho $invoiceNumber'),
            reference: creditNoteNumber,
            createdBy: scope.userUid,
          );
        }
      }

      unawaited(AuditLogService().logSaleAction(
        ownerUid: scope.ownerUid,
        businessId: scope.businessId,
        performedByUid: scope.userUid,
        performedByRole: role,
        action: AuditLogService.returnProcessed,
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        amount: _creditAmount,
        details: _composedReason,
      ));
      unawaited(ref.read(syncServiceProvider).syncNow());

      if (mounted) {
        Navigator.of(context).pop({
          'saved': true,
          'creditNoteNumber': creditNoteNumber,
          'returnedAmount': _creditAmount,
        });
      }
    } catch (e) {
      _showSnack(_tr('Failed to save: $e', 'Imeshindwa kuhifadhi: $e'));
      setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    setState(() => _errorMsg = msg);
  }

  // ── UI ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final invoiceNumber =
        (widget.originalInvoice['invoiceNumber'] ??
                widget.originalInvoice['id'] ??
                '')
            .toString();

    // Cross-reference invoice lines against inventory to flag services —
    // invoice line items don't carry the product type themselves.
    final inventory =
        ref.watch(inventoryProvider).valueOrNull ?? const <InventoryItem>[];
    final serviceIds = {
      for (final i in inventory)
        if (i.isService) i.id
    };
    final selectedLines =
        _lines.where((l) => l.selected && l.returnQty > 0).toList();
    final selectedStockLines = selectedLines
        .where((l) => l.productId.isNotEmpty && !serviceIds.contains(l.productId));
    final anySelectedService =
        selectedLines.any((l) => serviceIds.contains(l.productId));
    final restockApplies = selectedStockLines.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Return products', 'Rudisha bidhaa'),
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        if (invoiceNumber.isNotEmpty)
                          Text(
                            invoiceNumber,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textMuted,
                    visualDensity: VisualDensity.compact,
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                children: [
                  _SectionHeader(
                    _tr('Products', 'Bidhaa'),
                  ),
                  const SizedBox(height: 6),
                  if (_lines.isEmpty)
                    _EmptyItems()
                  else
                    ..._lines.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ReturnItemCard(
                          line: e.value,
                          isService: serviceIds.contains(e.value.productId),
                          onToggle: (v) =>
                              setState(() => _lines[e.key].selected = v),
                          onQtyChange: (v) =>
                              setState(() => _lines[e.key].returnQty = v),
                        ),
                      );
                    }),
                  const SizedBox(height: 6),
                  if (restockApplies)
                    _RestockToggle(
                      value: _restockAll,
                      subtitle: anySelectedService
                          ? _tr(
                              'Services on this return are never added to stock',
                              'Huduma kwenye marejesho haya haziwekwi kwenye stoo')
                          : null,
                      onChanged: (v) => setState(() => _restockAll = v),
                    )
                  else if (anySelectedService)
                    const _ServiceNoRestockNote(),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  _ReasonSection(
                    selected: _reasonType,
                    onSelected: _onReasonPicked,
                    noteController: _reasonCtrl,
                    onNoteChanged: (v) => _reasonNote = v,
                  ),
                  const SizedBox(height: 14),
                  _ProofPhotoSection(
                    file: _proofFile,
                    isRequired: _reasonType?.isDamage ?? false,
                    onTap: _saving ? null : _showProofOptions,
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 8),
                    ValidationBanner(
                      message: _errorMsg,
                      onDismiss: () => setState(() => _errorMsg = null),
                    ),
                  ],
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
  final bool isService;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQtyChange;

  const _ReturnItemCard({
    required this.line,
    required this.isService,
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
                    horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line.productName,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
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
            if (isService)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(38, 0, 10, 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _tr('Service — not returned to stock',
                            'Huduma — hairudishwi kwenye stoo'),
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            if (line.selected) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tr('Quantity', 'Idadi'),
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
                    const SizedBox(width: 10),
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
  final String? subtitle;
  final ValueChanged<bool> onChanged;

  const _RestockToggle(
      {required this.value, this.subtitle, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 18, color: AppColors.tealAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Return to inventory', 'Rudisha kwenye stoo'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
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

/// Shown in place of the restock toggle when every selected line is a service
/// (or a free-text sale line) — there is nothing that can go back to stock.
class _ServiceNoRestockNote extends StatelessWidget {
  const _ServiceNoRestockNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _tr('Services can\'t be returned to stock',
                  'Huduma haziwezi kurudishwa kwenye stoo'),
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonSection extends StatelessWidget {
  final _ReturnReason? selected;
  final ValueChanged<_ReturnReason> onSelected;
  final TextEditingController noteController;
  final ValueChanged<String> onNoteChanged;

  const _ReasonSection({
    required this.selected,
    required this.onSelected,
    required this.noteController,
    required this.onNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Reason for Return *', 'Sababu ya Kurudisha *'),
          style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ReturnReason.values.map((r) {
            final isSelected = r == selected;
            return GestureDetector(
              onTap: () => onSelected(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.navyPrimary
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(r.icon,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      r.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.navyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: noteController,
            onChanged: onNoteChanged,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: _tr(
                  'Add a note (optional) — batch number, where it was damaged…',
                  'Ongeza maelezo (si lazima) — namba ya kundi, mahali ilipoharibika…'),
              hintStyle: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(10),
            ),
            style: GoogleFonts.dmSans(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _ProofPhotoSection extends StatelessWidget {
  final File? file;
  final bool isRequired;
  final VoidCallback? onTap;

  const _ProofPhotoSection({
    required this.file,
    required this.isRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isRequired
                  ? _tr('Proof Photo *', 'Picha ya Ushahidi *')
                  : _tr('Proof Photo', 'Picha ya Ushahidi'),
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5),
            ),
            if (isRequired) ...[
              const SizedBox(width: 6),
              Text(
                _tr('required for damaged goods',
                    'lazima kwa bidhaa iliyoharibika'),
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.warning),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (file != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tealAccent),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file!, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _tr('Change', 'Badilisha'),
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRequired ? AppColors.warning : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.tealAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_a_photo_rounded,
                        size: 18, color: AppColors.tealAccent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tr('Attach proof photo', 'Ambatanisha picha ya ushahidi'),
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tealAccent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tr('Take a photo or choose from gallery',
                        'Piga picha au chagua kutoka maktaba'),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
      ],
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
          16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
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
                    _tr('Return Amount', 'Kiasi cha Kurudisha'),
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
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: (saving || !hasSelection) ? null : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.undo_rounded, size: 16),
            label: Text(
              saving
                  ? _tr('Saving…', 'Inahifadhi…')
                  : _tr('Confirm Return', 'Thibitisha Kurudisha'),
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
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
        const SizedBox(height: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.tealAccent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
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
        const SizedBox(height: 6),
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
                        const SizedBox(width: 8),
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
