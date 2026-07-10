import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/online_guard.dart';
import '../../../../shared/widgets/customer_picker_field.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../customer/domain/models/customer.dart';
import '../../../finance/data/finance_providers.dart';
import '../../../finance/data/payment_account_service.dart';
import '../../../finance/domain/models/cash_account.dart';
import '../../../finance/domain/payment_method_accounts.dart';
import '../../../finance/presentation/widgets/payment_account_chips.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/domain/models/debt.dart';
import '../../../invoice/domain/models/invoice.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../data/invoice_local_mirror.dart';
import '../../data/sales_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _LineItem {
  String productId;
  String productName;
  double unitPrice;
  int qty;
  double discount; // per-line flat discount
  String unit;

  _LineItem({
    this.productId = '',
    this.productName = '',
    this.unitPrice = 0,
    this.qty = 1,
    this.discount = 0,
    this.unit = '',
  });

  double get lineTotal => (unitPrice * qty) - discount;

  _LineItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? qty,
    double? discount,
    String? unit,
  }) =>
      _LineItem(
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        unitPrice: unitPrice ?? this.unitPrice,
        qty: qty ?? this.qty,
        discount: discount ?? this.discount,
        unit: unit ?? this.unit,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final bool isQuotation;
  final Map<String, dynamic>? invoiceToEdit;

  const CreateInvoiceScreen({
    super.key,
    this.isQuotation = false,
    this.invoiceToEdit,
  });

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen>
    with TickerProviderStateMixin {
  late bool _isQuotation;
  final List<_LineItem> _items = [_LineItem()];

  Customer? _customer;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String? _selectedAccountId;
  bool _isCredit = false;
  String _mpesaRef = '';
  double _globalDiscount = 0;
  bool _applyVat = false;
  String _notes = '';
  bool _saving = false;

  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _mpesaCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _isQuotation = widget.isQuotation;
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    if (widget.invoiceToEdit != null) {
      _populateFromExisting(widget.invoiceToEdit!);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    _mpesaCtrl.dispose();
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _populateFromExisting(Map<String, dynamic> data) {
    _isQuotation = (data['type'] ?? '').toString() == 'quotation';
    _applyVat = data['vatApplied'] as bool? ?? false;
    _globalDiscount = parseNumericAmount(data['discountAmount']);
    _notes = data['notes']?.toString() ?? '';
    _notesCtrl.text = _notes;
    _discountCtrl.text =
        _globalDiscount > 0 ? _globalDiscount.toStringAsFixed(0) : '';

    // Restore customer + dates — otherwise saving an edit silently wipes them.
    final customerId = (data['customerId'] ?? '').toString();
    final customerName = (data['customerName'] ?? '').toString();
    if (customerId.isNotEmpty || customerName.isNotEmpty) {
      _customer = Customer(
        id: customerId,
        name: customerName,
        phone: (data['customerPhone'] ?? '').toString(),
      );
    }
    _invoiceDate =
        readTimestamp(data['invoiceDate'] ?? data['createdAt'] ?? data['date']) ??
            _invoiceDate;
    _dueDate = readTimestamp(data['dueDate']);

    final pmRaw = (data['paymentMethod'] ?? '').toString().toLowerCase();
    final storedAccountId = (data['paymentAccountId'] ?? '').toString();
    if (pmRaw == 'credit') {
      _isCredit = true;
      _selectedAccountId = null;
    } else {
      _isCredit = false;
      // Prefer the exact account recorded at save time (works for custom
      // accounts too); fall back to resolving a built-in from the legacy
      // method string for older documents that predate this field.
      _selectedAccountId = storedAccountId.isNotEmpty
          ? storedAccountId
          : PaymentMethodAccounts.accountIdForMethod(pmRaw);
    }

    // Quick sales store 'items'; the full editor stores 'lineItems'.
    final lineItems = (data['lineItems'] is List &&
            (data['lineItems'] as List).isNotEmpty)
        ? data['lineItems'] as List
        : data['items'];
    if (lineItems is List && lineItems.isNotEmpty) {
      _items.clear();
      for (final raw in lineItems) {
        if (raw is Map) {
          _items.add(_LineItem(
            productId: (raw['productId'] ?? raw['inventoryItemId'] ?? '')
                .toString(),
            productName:
                (raw['productName'] ?? raw['name'] ?? '').toString(),
            unitPrice: parseNumericAmount(raw['unitPrice']),
            qty: ((raw['qty'] ?? raw['quantity']) is num)
                ? ((raw['qty'] ?? raw['quantity']) as num).toInt()
                : 1,
            discount: parseNumericAmount(raw['lineDiscount']),
            unit: raw['unit']?.toString() ?? '',
          ));
        }
      }
    }
  }

  // ── Computed ────────────────────────────────────────────────────────────────

  double get _subtotal => _items.fold(0, (s, i) => s + i.lineTotal);
  // Discount is capped at the subtotal so VAT and totals can't go negative.
  double get _effectiveDiscount => _globalDiscount.clamp(0.0, _subtotal);
  double get _vatAmount =>
      _applyVat ? (_subtotal - _effectiveDiscount) * 0.18 : 0;
  double get _grandTotal =>
      (_subtotal - _effectiveDiscount + _vatAmount).clamp(0.0, double.infinity);

  String _invoiceNumber() {
    final now = DateTime.now();
    final prefix = _isQuotation ? 'QUO' : 'INV';
    final rand = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return '$prefix-${now.year}${now.month.toString().padLeft(2, '0')}-$rand';
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save({required bool asDraft}) async {
    // The full editor (drafts, quotations, edits) commits an atomic Firestore
    // batch — online-only for now. Offline sales go through Quick Sale.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;
    if (_items.every((i) => i.productName.trim().isEmpty)) {
      _showSnack(_tr('Add at least one item', 'Ongeza bidhaaa angalau moja'));
      return;
    }
    // Credit (on-account) sales must always be tied to a customer —
    // otherwise the receivable has no one to collect from.
    if (!asDraft &&
        !_isQuotation &&
        _isCredit &&
        (_customer == null || _customer!.id.isEmpty)) {
      _showSnack(_tr(
        'Please select a customer before recording a credit sale.',
        'Tafadhali chagua mteja kabla ya kurekodi mauzo ya mkopo.',
      ));
      return;
    }
    // Enforce credit limit: block the sale if the customer's outstanding
    // balance after this sale would exceed their set limit.
    if (!asDraft &&
        !_isQuotation &&
        _isCredit &&
        _customer != null &&
        _customer!.creditLimit > 0) {
      final projectedBalance = _customer!.balanceAmount + _grandTotal;
      if (projectedBalance > _customer!.creditLimit) {
        final available = _customer!.availableCredit;
        _showSnack(_tr(
          'Credit limit exceeded. ${_customer!.name} can only borrow TZS ${available.toStringAsFixed(0)} more.',
          'Kikomo cha mkopo kimezidiwa. ${_customer!.name} anaweza kukopa TZS ${available.toStringAsFixed(0)} tu zaidi.',
        ));
        return;
      }
    }

    // Stock + receivable side effects must run exactly once — on the first
    // confirmation. Re-saving an already-confirmed invoice must NOT deduct
    // stock again or duplicate the receivable.
    final isEdit = widget.invoiceToEdit != null;
    final previousStatus =
        (widget.invoiceToEdit?['status'] ?? '').toString().toLowerCase();
    final wasConfirmed =
        isEdit && previousStatus.isNotEmpty && previousStatus != 'draft';
    final confirmingNow = !asDraft && !_isQuotation && !wasConfirmed;

    // A confirmed sale must never oversell stock — a line's product may have
    // sold out (elsewhere, or via another draft) since it was added here.
    if (confirmingNow) {
      final inventory = ref.read(inventoryItemListProvider).value ?? const [];
      for (final item in _items) {
        if (item.productId.isEmpty || item.productName.trim().isEmpty) {
          continue;
        }
        final inv = inventory.firstWhere(
          (i) => (i['id'] ?? '').toString() == item.productId,
          orElse: () => const <String, dynamic>{},
        );
        if (inv.isEmpty || (inv['productType'] as String?) == 'service') {
          continue;
        }
        final stock = parseStock(inv['currentStock'] ?? inv['stock'] ?? 0);
        if (item.qty > stock) {
          _showSnack(
            stock <= 0
                ? _tr(
                    '${item.productName} is out of stock.',
                    '${item.productName} imekwisha stokuni.',
                  )
                : _tr(
                    'Only $stock of ${item.productName} in stock.',
                    'Kuna $stock tu za ${item.productName} stokuni.',
                  ),
          );
          return;
        }
      }
    }

    setState(() => _saving = true);

    try {
      final scope = await resolveSalesScope(ref);
      if (scope == null) throw Exception('Not authenticated');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final role = ref.read(currentUserRoleProvider);
      final col = repo.scopeCollection(
          uid: scope.ownerUid,
          context: scope.context,
          childCollection: 'sales_invoices');

      final invNumber = widget.invoiceToEdit?['invoiceNumber'] as String? ??
          _invoiceNumber();

      final status = asDraft
          ? 'draft'
          : (_isQuotation ? 'sent' : (_isCredit ? 'sent' : 'paid'));

      // Resolve the chosen account once — built-in channels keep the exact
      // strings this screen has always written ('bank' unlike quick sale's
      // 'bank_transfer'); a custom account's current name is used instead so
      // reports group by it meaningfully.
      CashAccount? selectedAccount;
      String paymentMethodValue = _isCredit ? 'credit' : '';
      if (!_isCredit && _selectedAccountId != null) {
        selectedAccount =
            await ref.read(cashRepositoryProvider).getAccountById(_selectedAccountId!);
        if (selectedAccount != null) {
          paymentMethodValue = switch (selectedAccount.id) {
            PaymentMethodAccounts.cashId => 'cash',
            PaymentMethodAccounts.mpesaId => 'mpesa',
            PaymentMethodAccounts.bankId => 'bank',
            PaymentMethodAccounts.cardId => 'card',
            _ => selectedAccount.name,
          };
        }
      }

      // Money received now must land in a chosen, activated payment account —
      // an unactivated Taslimu/M-Pesa/Benki/Kadi cannot take sale money.
      // Credit moves no money at confirmation, so it needs no account.
      if (confirmingNow && !_isCredit && selectedAccount == null) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_tr(
              'Select an activated payment account',
              'Chagua akaunti ya malipo iliyowashwa',
            )),
            backgroundColor: AppColors.error,
          ));
        }
        return;
      }

      final lineItemsData = _items
          .where((i) => i.productName.trim().isNotEmpty)
          .map((i) => {
                'productId': i.productId,
                'productName': i.productName,
                'unitPrice': i.unitPrice,
                'qty': i.qty,
                'lineDiscount': i.discount,
                'unit': i.unit,
                'lineTotal': i.lineTotal,
              })
          .toList();

      final payload = <String, dynamic>{
        'invoiceNumber': invNumber,
        'type': _isQuotation ? 'quotation' : 'invoice',
        'status': status,
        'customerId': _customer?.id ?? '',
        'customerName': _customer?.name ?? '',
        'customerPhone': _customer?.phone ?? '',
        'lineItems': lineItemsData,
        'items': lineItemsData,
        'subtotal': _subtotal,
        'discountAmount': _effectiveDiscount,
        'vatApplied': _applyVat,
        'vatAmount': _vatAmount,
        'totalAmount': _grandTotal,
        'amount': _grandTotal,
        'paymentMethod': paymentMethodValue,
        'paymentAccountId': selectedAccount?.id ?? '',
        // Settled methods are fully paid on confirmation; credit starts at 0.
        if (confirmingNow)
          'amountPaid': _isCredit ? 0 : _grandTotal,
        if (selectedAccount?.id == PaymentMethodAccounts.mpesaId &&
            _mpesaRef.isNotEmpty)
          'mpesaReference': _mpesaRef,
        'invoiceDate': Timestamp.fromDate(_invoiceDate),
        if (_dueDate != null) 'dueDate': Timestamp.fromDate(_dueDate!),
        'notes': _notes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Deduct stock only for lines whose product exists locally — draft
      // lines restored from the local mirror carry a generated row id for
      // free-text entries, and deducting against that id would create a
      // phantom inventory document.
      final stockLines = <_LineItem>[];
      if (confirmingNow) {
        final db = ref.read(appDatabaseProvider);
        for (final item in _items.where((i) => i.productId.isNotEmpty)) {
          if (await db.inventoryDao.getById(item.productId) != null) {
            stockLines.add(item);
          }
        }
      }

      // One atomic batch: invoice + stock deduction + receivable.
      final batch = FirebaseFirestore.instance.batch();
      final DocumentReference<Map<String, dynamic>> docRef;
      if (isEdit) {
        docRef = col.doc(widget.invoiceToEdit!['id'] as String);
        batch.update(docRef, payload);
      } else {
        docRef = col.doc();
        batch.set(docRef, {
          ...payload,
          'createdBy': scope.userUid,
          'createdByRole': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (confirmingNow) {
        final invCol = repo.scopeCollection(
            uid: scope.ownerUid,
            context: scope.context,
            childCollection: 'inventory_items');
        for (final item in stockLines) {
          batch.set(
              invCol.doc(item.productId),
              {
                'currentStock': FieldValue.increment(-item.qty),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        }

        if (_isCredit && _customer != null) {
          final recCol = repo.scopeCollection(
              uid: scope.ownerUid,
              context: scope.context,
              childCollection: 'receivables');
          batch.set(recCol.doc(), {
            'invoiceId': docRef.id,
            'saleId': docRef.id,
            'businessId': scope.businessId,
            'invoiceNumber': invNumber,
            'customerId': _customer!.id,
            'customerName': _customer!.name,
            'amount': _grandTotal,
            'outstanding': _grandTotal,
            'status': 'open',
            'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
            'createdBy': scope.userUid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Increment the customer's outstanding balance so the credit-limit
          // check on future sales uses the correct value.
          final customersRef = repo.scopeCollection(
              uid: scope.ownerUid,
              context: scope.context,
              childCollection: 'customers');
          batch.set(
              customersRef.doc(_customer!.id),
              {
                'balance': FieldValue.increment(_grandTotal),
                'lastTransactionDate': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        }
      }

      await batch.commit();

      // Mirror the stock deduction into Drift immediately so product numbers
      // update on screen without waiting for a sync pull (which can miss the
      // write when the device clock runs ahead of the server).
      if (confirmingNow) {
        try {
          final db = ref.read(appDatabaseProvider);
          for (final item in stockLines) {
            await db.inventoryDao
                .applyCommittedDelta(item.productId, -item.qty.toDouble());
          }
        } catch (_) {}
      }

      // Update Drift customer balance immediately so the credit-limit check on
      // the next sale in this session uses the correct outstanding amount.
      if (confirmingNow && _isCredit && _customer != null) {
        try {
          final db = ref.read(appDatabaseProvider);
          await db.customerDao.updateBalance(
            _customer!.id,
            _customer!.balanceAmount + _grandTotal,
          );
        } catch (_) {}
      }

      // Auto-create receivable debt in the offline-first ledger for credit sales
      if (confirmingNow && _isCredit && _customer != null) {
        final dueStr = _dueDate != null
            ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
            : DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String()
                .split('T')
                .first;
        await ref.read(debtRepositoryProvider).save(Debt(
          id: '',
          partyName: _customer!.name,
          partyPhone: _customer!.phone,
          partyId: _customer!.id,
          type: 'receivable',
          originalAmount: _grandTotal,
          dueDate: dueStr,
          invoiceRef: invNumber,
          note: _notes,
          createdBy: scope.userUid,
          createdAt: DateTime.now().toIso8601String(),
        ));
      }

      // Mirror the invoice into Drift immediately so the sales list and the
      // dashboard revenue/profit update without waiting for a sync pull.
      final nowIso = DateTime.now().toIso8601String();
      final amountPaidNow = confirmingNow
          ? (_isCredit ? 0.0 : _grandTotal)
          : parseNumericAmount(widget.invoiceToEdit?['amountPaid']);
      await mirrorInvoiceToDrift(
        ref,
        Invoice(
          id: docRef.id,
          customerId: _customer?.id ?? '',
          customerName: _customer?.name ?? '',
          customerPhone: _customer?.phone ?? '',
          invoiceNumber: invNumber,
          date: _invoiceDate.toIso8601String(),
          dueDate: _dueDate?.toIso8601String() ?? '',
          status: status,
          type: _isQuotation ? 'quotation' : 'invoice',
          subtotal: _subtotal,
          discountAmount: _effectiveDiscount,
          tax: _vatAmount,
          total: _grandTotal,
          amountPaid: amountPaidNow,
          paymentMethod: paymentMethodValue,
          paymentAccountId: selectedAccount?.id ?? '',
          items: [
            for (final i in _items)
              if (i.productName.trim().isNotEmpty)
                InvoiceItem(
                  id: i.productId,
                  name: i.productName,
                  quantity: i.qty.toDouble(),
                  unitPrice: i.unitPrice,
                  total: i.lineTotal,
                ),
          ],
          note: _notes,
          createdAt: isEdit
              ? (readTimestamp(widget.invoiceToEdit?['createdAt'])
                      ?.toIso8601String() ??
                  nowIso)
              : nowIso,
          updatedAt: nowIso,
        ),
      );

      // Money received on confirmation lands in the chosen account — Drift
      // balance moves instantly, the queued op replays the increment on
      // Firestore idempotently.
      if (confirmingNow && !_isCredit && selectedAccount != null) {
        await moveMoneyForAccount(
          ref,
          accountId: selectedAccount.id,
          amount: _grandTotal,
          isDeposit: true,
          description:
              LocalizationService.tr(en: 'Sale $invNumber', sw: 'Mauzo $invNumber'),
          reference: invNumber,
          createdBy: scope.userUid,
        );
      }

      unawaited(AuditLogService().logSaleAction(
        ownerUid: scope.ownerUid,
        businessId: scope.businessId,
        performedByUid: scope.userUid,
        performedByRole: role,
        action: isEdit
            ? AuditLogService.invoiceEdited
            : AuditLogService.saleCreated,
        invoiceId: docRef.id,
        invoiceNumber: invNumber,
        amount: _grandTotal,
        details: status,
      ));
      unawaited(ref.read(syncServiceProvider).syncNow());

      if (mounted) {
        if (confirmingNow && _isCredit && _customer != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_tr(
              'Receivable added for ${_customer!.name} – check Debts',
              'Dai limeongezwa kwa ${_customer!.name} – angalia Madeni',
            )),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        }
        Navigator.of(context).pop({'saved': true, 'id': docRef.id});
      }
    } catch (e) {
      _showSnack(_tr('Save failed: $e', 'Imeshindwa kuhifadhi: $e'));
      setState(() => _saving = false);
    }
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

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _TypeToggle(
                    isQuotation: _isQuotation,
                    onChanged: (v) => setState(() => _isQuotation = v),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    children: [
                      CustomerPickerField(
                        selected: _customer,
                        onSelected: (c) => setState(() => _customer = c),
                      ),
                      const _Divider(),
                      _DateRow(
                        invoiceDate: _invoiceDate,
                        dueDate: _dueDate,
                        onInvoiceDate: (d) =>
                            setState(() => _invoiceDate = d),
                        onDueDate: (d) => setState(() => _dueDate = d),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ItemsSection(
                    items: _items,
                    onAdd: () =>
                        setState(() => _items.add(_LineItem())),
                    onRemove: (i) =>
                        setState(() => _items.removeAt(i)),
                    onUpdate: (i, item) =>
                        setState(() => _items[i] = item),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    children: [
                      _DiscountRow(
                        controller: _discountCtrl,
                        onChanged: (v) => setState(
                            () => _globalDiscount =
                                double.tryParse(v) ?? 0),
                      ),
                      const _Divider(),
                      _VatToggle(
                        value: _applyVat,
                        onChanged: (v) => setState(() => _applyVat = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TotalsCard(
                    subtotal: _subtotal,
                    discount: _effectiveDiscount,
                    vatAmount: _vatAmount,
                    grandTotal: _grandTotal,
                    applyVat: _applyVat,
                  ),
                  const SizedBox(height: 16),
                  _PaymentSection(
                    selectedAccountId: _selectedAccountId,
                    isCredit: _isCredit,
                    mpesaRef: _mpesaRef,
                    mpesaCtrl: _mpesaCtrl,
                    onAccount: (a) => setState(() {
                      _selectedAccountId = a.id;
                      _isCredit = false;
                    }),
                    onCredit: () => setState(() {
                      _selectedAccountId = null;
                      _isCredit = true;
                    }),
                    onMpesaRef: (v) => _mpesaRef = v,
                    lockUnactivated: !_isQuotation,
                  ),
                  const SizedBox(height: 16),
                  _NotesField(
                    controller: _notesCtrl,
                    onChanged: (v) => _notes = v,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _BottomActions(
              saving: _saving,
              isQuotation: _isQuotation,
              onDraft: () => _save(asDraft: true),
              onFinalize: () => _save(asDraft: false),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final title = widget.invoiceToEdit != null
        ? _tr('Edit Invoice', 'Hariri Ankara')
        : _isQuotation
            ? _tr('New Quotation', 'Nukuu Mpya')
            : _tr('New Invoice', 'Ankara Mpya');

    return AppBar(
      backgroundColor: AppColors.navyPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final bool isQuotation;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({required this.isQuotation, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _Tab(
            label: _tr('Invoice', 'Ankara'),
            icon: Icons.receipt_long_rounded,
            active: !isQuotation,
            onTap: () => onChanged(false),
          ),
          _Tab(
            label: _tr('Quotation', 'Nukuu'),
            icon: Icons.request_quote_rounded,
            active: isQuotation,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Tab(
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
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(vertical: 10),
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
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.border);
}



// ── Date Row ─────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final ValueChanged<DateTime> onInvoiceDate;
  final ValueChanged<DateTime?> onDueDate;

  const _DateRow({
    required this.invoiceDate,
    required this.dueDate,
    required this.onInvoiceDate,
    required this.onDueDate,
  });

  Future<void> _pick(BuildContext context, DateTime initial,
      ValueChanged<DateTime> cb) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) cb(picked);
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _DateChip(
              label: _tr('Invoice Date', 'Tarehe'),
              value: _fmt(invoiceDate),
              onTap: () => _pick(context, invoiceDate, onInvoiceDate),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DateChip(
              label: _tr('Due Date', 'Mwisho'),
              value: dueDate != null
                  ? _fmt(dueDate!)
                  : _tr('No due date', 'Bila mwisho'),
              onTap: () => _pick(
                context,
                dueDate ?? DateTime.now().add(const Duration(days: 30)),
                (d) => onDueDate(d),
              ),
              optional: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool optional;

  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
            SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12,
                    color: optional
                        ? AppColors.textMuted
                        : AppColors.navyPrimary),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: optional
                            ? AppColors.textSecondary
                            : AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Items Section ─────────────────────────────────────────────────────────────

class _ItemsSection extends ConsumerWidget {
  final List<_LineItem> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int, _LineItem) onUpdate;

  const _ItemsSection({
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref
        .watch(inventoryItemListProvider)
        .maybeWhen(data: (d) => d, orElse: () => <Map<String, dynamic>>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _tr('Items', 'Bidhaaa'),
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add_circle_rounded, size: 16),
              label: Text(_tr('Add Item', 'Ongeza'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...List.generate(items.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LineItemCard(
              index: i,
              item: items[i],
              inventory: inventory,
              canRemove: items.length > 1,
              onRemove: () => onRemove(i),
              onUpdate: (updated) => onUpdate(i, updated),
            ),
          );
        }),
      ],
    );
  }
}

class _LineItemCard extends StatefulWidget {
  final int index;
  final _LineItem item;
  final List<Map<String, dynamic>> inventory;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<_LineItem> onUpdate;

  const _LineItemCard({
    required this.index,
    required this.item,
    required this.inventory,
    required this.canRemove,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends State<_LineItemCard> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _lineDiscCtrl;
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.productName);
    _priceCtrl = TextEditingController(
        text: widget.item.unitPrice > 0
            ? widget.item.unitPrice.toStringAsFixed(0)
            : '');
    _qtyCtrl =
        TextEditingController(text: widget.item.qty.toString());
    _lineDiscCtrl = TextEditingController(
        text: widget.item.discount > 0
            ? widget.item.discount.toStringAsFixed(0)
            : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _lineDiscCtrl.dispose();
    super.dispose();
  }

  void _filterInventory(String q) {
    if (q.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _filtered = [];
      });
      return;
    }
    setState(() {
      _filtered = widget.inventory
          .where((inv) =>
              (inv['name'] ?? '').toString().toLowerCase().contains(
                  q.toLowerCase()) ||
              (inv['sku'] ?? '').toString().toLowerCase().contains(
                  q.toLowerCase()))
          .take(6)
          .toList();
      _showSuggestions = _filtered.isNotEmpty;
    });
  }

  void _selectInventory(Map<String, dynamic> inv) {
    final price = parseNumericAmount(inv['sellingPrice'] ?? inv['unitPrice']);
    final updated = widget.item.copyWith(
      productId: inv['id']?.toString() ?? '',
      productName: inv['name']?.toString() ?? '',
      unitPrice: price,
      unit: inv['unit']?.toString() ?? '',
    );
    _nameCtrl.text = updated.productName;
    _priceCtrl.text =
        price > 0 ? price.toStringAsFixed(0) : '';
    setState(() => _showSuggestions = false);
    widget.onUpdate(updated);
  }

  void _emit() {
    final updated = widget.item.copyWith(
      productName: _nameCtrl.text,
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
      qty: int.tryParse(_qtyCtrl.text) ?? 1,
      discount: double.tryParse(_lineDiscCtrl.text) ?? 0,
    );
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.productName.isEmpty
                        ? _tr('New Item', 'Bidhaaa Mpya')
                        : widget.item.productName,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.canRemove)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Product name field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(_tr('Product / Service', 'Bidhaaa / Huduma')),
                const SizedBox(height: 4),
                _OutlineField(
                  controller: _nameCtrl,
                  hint: _tr('Type to search…', 'Andika kutafuta…'),
                  onChanged: (v) {
                    _filterInventory(v);
                    _emit();
                  },
                ),
                if (_showSuggestions)
                  _SuggestionList(
                    items: _filtered,
                    onTap: _selectInventory,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(_tr('Unit Price', 'Bei ya Moja')),
                      const SizedBox(height: 4),
                      _OutlineField(
                        controller: _priceCtrl,
                        hint: '0',
                        numeric: true,
                        prefix: 'TZS',
                        onChanged: (_) => _emit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(_tr('Qty', 'Idadi')),
                      const SizedBox(height: 4),
                      _QtyField(
                        controller: _qtyCtrl,
                        onChanged: (_) => _emit(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Line total
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tr('Line Total', 'Jumla ya Mstari'),
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  'TZS ${_fmtNum(widget.item.lineTotal)}',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onTap;

  const _SuggestionList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          final inv = e.value;
          final price = parseNumericAmount(
              inv['sellingPrice'] ?? inv['unitPrice']);
          final stock = parseStock(inv['currentStock'] ?? inv['stock']);
          final isOut  = stock <= 0;
          final isLow  = !isOut && stock <= parseStock(inv['reorderPoint'] ?? 5);
          final productType = (inv['productType'] as String?) ?? '';
          final isService    = productType == 'service';
          final category = (inv['category'] as String?) ?? '';
          final stockColor = isService
              ? AppColors.tealAccent
              : isOut
                  ? AppColors.error
                  : isLow
                      ? AppColors.warning
                      : AppColors.success;

          return Column(children: [
          InkWell(
            onTap: isOut ? null : () => onTap(inv),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Inventory-style tinted icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isService
                          ? Icons.design_services_rounded
                          : Icons.inventory_2_outlined,
                      size: 18,
                      color: stockColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv['name']?.toString() ?? '',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary),
                        ),
                        if (category.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(category,
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TZS ${_fmtNum(price)}',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary),
                      ),
                      if (!isService) ...[
                        SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: stockColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isOut
                                ? _tr('Out', 'Imekwisha')
                                : '$stock ${_tr("left", "zimebaki")}',
                            style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: stockColor),
                          ),
                        ),
                      ],
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
                color: AppColors.border),
          ]);
        }).toList(),
        ),
      ),
    );
  }
}

// ── Discount & VAT ───────────────────────────────────────────────────────────

class _DiscountRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DiscountRow(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded,
              size: 18, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _tr('Invoice Discount', 'Punguzo la Ankara'),
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*'))
              ],
              textAlign: TextAlign.right,
              onChanged: onChanged,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: 'TZS ',
                prefixStyle: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textMuted),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VatToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _VatToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.receipt_rounded,
              size: 18, color: AppColors.tealAccent),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Add VAT (18%)', 'Ongeza VAT (18%)'),
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  _tr('Tanzanian statutory rate',
                      'Kiwango cha kisheria Tanzania'),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.tealAccent,
            activeTrackColor: AppColors.tealAccent.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

// ── Totals Card ───────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double vatAmount;
  final double grandTotal;
  final bool applyVat;

  const _TotalsCard({
    required this.subtotal,
    required this.discount,
    required this.vatAmount,
    required this.grandTotal,
    required this.applyVat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navyPrimary,
            AppColors.navyPrimary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _TotalRow(
            label: _tr('Subtotal', 'Jumla Ndogo'),
            amount: subtotal,
            light: true,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _TotalRow(
              label: _tr('Discount', 'Punguzo'),
              amount: -discount,
              light: true,
              isDiscount: true,
            ),
          ],
          if (applyVat) ...[
            const SizedBox(height: 8),
            _TotalRow(
              label: _tr('VAT (18%)', 'VAT (18%)'),
              amount: vatAmount,
              light: true,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tr('TOTAL', 'JUMLA'),
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 1),
              ),
              Text(
                'TZS ${_fmtNum(grandTotal)}',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool light;
  final bool isDiscount;

  const _TotalRow({
    required this.label,
    required this.amount,
    this.light = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                color: light ? Colors.white60 : AppColors.textSecondary)),
        Text(
          '${isDiscount ? '-' : ''}TZS ${_fmtNum(amount.abs())}',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDiscount
                  ? const Color(0xFF86EFAC)
                  : light
                      ? Colors.white70
                      : AppColors.textPrimary),
        ),
      ],
    );
  }
}

// ── Payment Section ───────────────────────────────────────────────────────────

class _PaymentSection extends ConsumerWidget {
  final String? selectedAccountId;
  final bool isCredit;
  final String mpesaRef;
  final TextEditingController mpesaCtrl;
  final ValueChanged<CashAccount> onAccount;
  final VoidCallback onCredit;
  final ValueChanged<String> onMpesaRef;

  /// True when picking an unactivated channel would move money right now
  /// (a real invoice). Quotations only note the intended method, so they
  /// may pick anything — the block happens if/when money actually arrives.
  final bool lockUnactivated;

  const _PaymentSection({
    required this.selectedAccountId,
    required this.isCredit,
    required this.mpesaRef,
    required this.mpesaCtrl,
    required this.onAccount,
    required this.onCredit,
    required this.onMpesaRef,
    required this.lockUnactivated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Payment Method', 'Njia ya Malipo'),
          style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        PaymentAccountChips(
          selectedAccountId: selectedAccountId,
          selectedIsCredit: isCredit,
          allowCredit: true,
          lockUnactivated: lockUnactivated,
          onSelectAccount: onAccount,
          onSelectCredit: onCredit,
        ),
        if (!isCredit && selectedAccountId == PaymentMethodAccounts.mpesaId) ...[
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: TextField(
              controller: mpesaCtrl,
              onChanged: onMpesaRef,
              decoration: InputDecoration.collapsed(
                hintText: _tr(
                    'M-Pesa reference (e.g. SBF5XXXXXX)',
                    'Nambari ya M-Pesa (mfano SBF5XXXXXX)'),
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textMuted),
              ),
              style:
                  GoogleFonts.jetBrainsMono(fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Notes Field ───────────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NotesField(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Notes', 'Maelezo'),
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
                  'Terms, delivery notes, or thank-you message…',
                  'Masharti, maelezo ya utoaji, au ujumbe wa shukrani…'),
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

// ── Bottom Actions ─────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final bool saving;
  final bool isQuotation;
  final VoidCallback onDraft;
  final VoidCallback onFinalize;

  const _BottomActions({
    required this.saving,
    required this.isQuotation,
    required this.onDraft,
    required this.onFinalize,
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: saving ? null : onDraft,
              icon: Icon(Icons.save_outlined, size: 16),
              label: Text(_tr('Save Draft', 'Hifadhi Rasimu'),
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navyPrimary,
                side: const BorderSide(color: AppColors.navyPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: saving ? null : onFinalize,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(
                      isQuotation
                          ? Icons.send_rounded
                          : Icons.check_circle_rounded,
                      size: 16),
              label: Text(
                saving
                    ? _tr('Saving…', 'Inahifadhi…')
                    : isQuotation
                        ? _tr('Send Quotation', 'Tuma Nukuu')
                        : _tr('Finalize Invoice', 'Kamilisha Ankara'),
                style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.3),
    );
  }
}

class _OutlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final String? prefix;
  final ValueChanged<String>? onChanged;

  const _OutlineField({
    required this.controller,
    required this.hint,
    this.numeric = false,
    this.prefix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      style: numeric
          ? GoogleFonts.jetBrainsMono(fontSize: 14)
          : GoogleFonts.dmSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle:
            GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: AppColors.navyPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _QtyField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _QtyField({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyBtn(
          icon: Icons.remove_rounded,
          onTap: () {
            final v = int.tryParse(controller.text) ?? 1;
            if (v > 1) {
              controller.text = (v - 1).toString();
              onChanged?.call(controller.text);
            }
          },
        ),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        _QtyBtn(
          icon: Icons.add_rounded,
          onTap: () {
            final v = int.tryParse(controller.text) ?? 1;
            controller.text = (v + 1).toString();
            onChanged?.call(controller.text);
          },
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child:
            Icon(icon, size: 16, color: AppColors.navyPrimary),
      ),
    );
  }
}

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

