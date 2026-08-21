import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/validation_banner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../customer/data/customer_providers.dart';
import '../../data/finance_providers.dart';
import '../../data/payment_account_service.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/expense_category.dart';
import '../../domain/models/recurring_expense_template.dart';
import '../../domain/payment_method_accounts.dart';
import '../expense_category_style.dart';
import '../providers/expense_providers.dart';
import '../widgets/activate_account_sheet.dart';
import '../widgets/manage_expense_categories_sheet.dart';
import '../widgets/payment_account_chips.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/domain/models/debt.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

enum _ExpenseErrorField { amount, payment, general }

// ─────────────────────────────────────────────────────────────────────────────
// Category meta (mirrors expense_list_screen)
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  String _categoryKey = 'other';
  String? _selectedAccountId;
  DateTime _date = DateTime.now();
  String _receiptUrl = '';
  File? _receiptFile;
  bool _isRecurring = false;
  String _frequency = 'monthly';
  bool _saving = false;
  bool _uploadingReceipt = false;
  bool _isCreditPurchase = false;
  String? _errorMessage;
  _ExpenseErrorField _errorField = _ExpenseErrorField.general;

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _supplierPhoneCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();

    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _categoryKey = e.category;
      // Prefer the exact account recorded at save time (works for custom
      // accounts too); fall back to resolving a built-in from the legacy
      // method string for older expenses that predate this field.
      _selectedAccountId = e.paymentAccountId.isNotEmpty
          ? e.paymentAccountId
          : PaymentMethodAccounts.accountIdForMethod(e.paymentMethod);
      _amountCtrl.text = e.amount;
      _noteCtrl.text = e.note;
      _recipientCtrl.text = e.recipient;
      _date = DateTime.tryParse(e.date) ?? DateTime.now();
      _receiptUrl = e.receiptUrl;
      _isRecurring = e.isRecurring;
      _frequency = e.recurrenceType.isNotEmpty ? e.recurrenceType : 'monthly';
    }
  }

  ExpenseCategory get _selectedCategory {
    final categories =
        ref.read(expenseCategoryListProvider).valueOrNull ??
        ExpenseCategory.defaults;
    return categories.firstWhere(
      (category) => category.key == _categoryKey,
      orElse: () => ExpenseCategory.fallback(_categoryKey),
    );
  }

  Future<void> _manageCategories() async {
    await showAppSheet<void>(
      context,
      maxHeightFactor: 0.88,
      builder: (_) => const ManageExpenseCategoriesSheet(),
    );
    if (!mounted) return;
    final categories =
        ref.read(expenseCategoryListProvider).valueOrNull ??
        ExpenseCategory.defaults;
    if (!categories.any((category) => category.key == _categoryKey)) {
      setState(() => _categoryKey = categories.first.key);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _recipientCtrl.dispose();
    _supplierPhoneCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Receipt photo ────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (file == null) return;
      setState(() {
        _receiptFile = File(file.path);
        _receiptUrl = '';
      });
    } catch (_) {
      if (!mounted) return;
      AppNotification.error(
        context,
        _tr(
          'Could not open ${source == ImageSource.camera ? 'the camera' : 'your photos'}. Check app permissions and try again.',
          'Imeshindwa kufungua ${source == ImageSource.camera ? 'kamera' : 'picha zako'}. Angalia ruhusa za programu kisha ujaribu tena.',
        ),
      );
    }
  }

  Future<String?> _uploadReceipt(String uid) async {
    if (_receiptFile == null) {
      return _receiptUrl.isNotEmpty ? _receiptUrl : null;
    }
    setState(() => _uploadingReceipt = true);
    try {
      final ref = FirebaseStorage.instance.ref(
        'receipts/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(_receiptFile!);
      final url = await ref.getDownloadURL();
      if (mounted) setState(() => _uploadingReceipt = false);
      return url;
    } catch (_) {
      if (mounted) setState(() => _uploadingReceipt = false);
      return null;
    }
  }

  Future<void> _showReceiptOptions() async {
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
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.navyPrimary,
              ),
              title: Text(
                _tr('Take photo', 'Piga picha'),
                style: GoogleFonts.dmSans(),
              ),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.navyPrimary,
              ),
              title: Text(
                _tr('Choose from gallery', 'Chagua kutoka maktaba'),
                style: GoogleFonts.dmSans(),
              ),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            if (_receiptFile != null || _receiptUrl.isNotEmpty)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  _tr('Remove receipt', 'Ondoa risiti'),
                  style: GoogleFonts.dmSans(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    _receiptFile = null;
                    _receiptUrl = '';
                  });
                },
              ),
          ],
        ),
      ),
    );
    if (source != null && mounted) await _pickPhoto(source);
  }

  // ── Date picker ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    final amountStr = _amountCtrl.text.trim();
    if (amountStr.isEmpty || (double.tryParse(amountStr) ?? 0) <= 0) {
      _showValidation(
        _tr('Enter a valid amount', 'Weka kiasi sahihi'),
        _ExpenseErrorField.amount,
      );
      return;
    }

    // Money paid out must leave a chosen, activated payment account —
    // PaymentAccountChips only lets an activated built-in or custom account
    // become selected, so a null selection here just means nothing was picked.
    if (_selectedAccountId == null) {
      _showValidation(
        _tr('Select a payment account', 'Chagua akaunti ya malipo'),
        _ExpenseErrorField.payment,
      );
      return;
    }
    final account = await ref
        .read(cashRepositoryProvider)
        .getAccountById(_selectedAccountId!);
    if (account == null) {
      _showValidation(
        _tr(
          'That payment account is no longer available. Choose another.',
          'Akaunti hiyo ya malipo haipatikani tena. Chagua nyingine.',
        ),
        _ExpenseErrorField.payment,
      );
      return;
    }
    final paymentMethodValue = switch (account.id) {
      PaymentMethodAccounts.cashId => 'cash',
      PaymentMethodAccounts.mpesaId => 'mpesa',
      PaymentMethodAccounts.bankId => 'bank',
      PaymentMethodAccounts.cardId => 'card',
      _ => account.name,
    };

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Upload receipt if a new file was selected
      final uploadedUrl = await _uploadReceipt(user.uid);
      if (_receiptFile != null && uploadedUrl == null) {
        if (!mounted) return;
        final message = _tr(
          'Receipt upload failed. Check your connection and try again, or remove the receipt.',
          'Imeshindwa kupakia risiti. Angalia intaneti kisha ujaribu tena, au ondoa risiti.',
        );
        setState(() {
          _saving = false;
          _errorMessage = message;
          _errorField = _ExpenseErrorField.general;
        });
        AppNotification.error(context, message);
        return;
      }
      final finalReceiptUrl = uploadedUrl ?? '';

      final dateStr =
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

      // Core expense write goes through the Drift + sync-queue repository —
      // this is what makes it work fully offline (matches every other
      // synced entity: customers, inventory, sales, debts). It used to write
      // straight to Firestore here, which hangs/fails while offline since
      // Firestore's own persistence cache is disabled (see main.dart).
      final wasRecurring = widget.expenseToEdit?.isRecurring ?? false;
      final expense = Expense(
        id: _isEditing ? widget.expenseToEdit!.id : '',
        category: _categoryKey,
        amount: amountStr,
        date: dateStr,
        note: _noteCtrl.text.trim(),
        recipient: _recipientCtrl.text.trim(),
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring ? _frequency : '',
        receiptUrl: finalReceiptUrl,
        paymentMethod: paymentMethodValue,
        paymentAccountId: account.id,
        createdBy: user.uid,
      );

      await ref.read(expenseRepositoryProvider).save(expense);

      // Recurring templates are a best-effort, online-only side feature —
      // fire-and-forget so a stalled connection never blocks the expense
      // save that already landed safely in Drift.
      if (_isRecurring && (!_isEditing || !wasRecurring)) {
        unawaited(_createRecurringTemplate(user.uid, dateStr));
      }

      // Money paid out leaves the chosen account — Drift balance moves
      // instantly, the queued op replays on Firestore later. Credit
      // purchases move no money now (a payable debt is recorded instead),
      // and edits never re-withdraw for money already paid the first time.
      if (!_isEditing && !_isCreditPurchase) {
        await moveMoneyForAccount(
          ref,
          accountId: account.id,
          amount: double.tryParse(amountStr) ?? 0,
          isDeposit: false,
          description: _recipientCtrl.text.trim().isNotEmpty
              ? _recipientCtrl.text.trim()
              : _selectedCategory.label,
          createdBy: user.uid,
        );
      }

      // Auto-create payable debt when expense is not fully paid to supplier
      if (!_isEditing && _isCreditPurchase) {
        final amount = double.tryParse(amountStr) ?? 0;
        if (amount > 0) {
          final dueDate = DateTime.now().add(const Duration(days: 30));
          final dueDateStr =
              '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
          await ref
              .read(debtRepositoryProvider)
              .save(
                Debt(
                  id: '',
                  partyName: _recipientCtrl.text.trim(),
                  partyPhone: _supplierPhoneCtrl.text.trim(),
                  type: 'payable',
                  originalAmount: amount,
                  dueDate: dueDateStr,
                  note: _tr(
                    'Expense: ${_selectedCategory.label}',
                    'Matumizi: ${_selectedCategory.label}',
                  ),
                  createdBy: user.uid,
                  createdAt: DateTime.now().toIso8601String(),
                ),
              );
        }
      }

      if (mounted) {
        if (!_isEditing && _isCreditPurchase) {
          AppNotification.warning(
            context,
            _tr(
              'Expense saved – debt recorded in Payables',
              'Gharama imehifadhiwa – deni limerekodiwa kwenye Madeni',
            ),
          );
        }
        Navigator.of(context).pop({'saved': true});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = _tr(
          'Failed to save. Try again.',
          'Imeshindwa kuhifadhi. Jaribu tena.',
        );
        _errorField = _ExpenseErrorField.general;
      });
    }
  }

  /// Best-effort, online-only side write — resolves its own context and
  /// swallows failures so a stalled connection never surfaces as a save
  /// error for the expense itself (already safely saved via Drift by then).
  Future<void> _createRecurringTemplate(String uid, String dateStr) async {
    try {
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(uid);
      final nextDue = RecurringExpenseTemplate.computeNextDue(
        _frequency,
        DateTime.tryParse(dateStr) ?? DateTime.now(),
      );
      await repo.addRecurringTemplate(
        uid: uid,
        context: ctx,
        templateData: {
          'category': _categoryKey,
          'note': _noteCtrl.text.trim(),
          'amount': _amountCtrl.text.trim(),
          'recipient': _recipientCtrl.text.trim(),
          'recurrenceType': _frequency,
          'nextDueDate': nextDue,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (_) {
      // Best-effort: the expense itself already saved successfully.
    }
  }

  Future<void> _showActivateAccountSheet(PaymentMethodSpec spec) async {
    final result = await showAppSheet<bool>(
      context,
      builder: (_) => ActivateAccountSheet(spec: spec),
    );
    if (result == true && mounted) {
      _showValidation(
        _tr(
          '${spec.nameFor(LocalizationService.isSwahili ? 'sw' : 'en')} activated',
          '${spec.nameFor(LocalizationService.isSwahili ? 'sw' : 'en')} imewashwa',
        ),
        _ExpenseErrorField.payment,
      );
    }
  }

  void _showValidation(String message, _ExpenseErrorField field) =>
      setState(() {
        _errorMessage = message;
        _errorField = field;
      });

  Widget _buildValidation(_ExpenseErrorField field) => ValidationBanner(
    message: _errorField == field ? _errorMessage : null,
    onDismiss: () => setState(() => _errorMessage = null),
  );

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.sizeOf(context);
    final categories =
        ref.watch(expenseCategoryListProvider).valueOrNull ??
        ExpenseCategory.defaults;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? _tr('Edit Expense', 'Hariri Gharama')
                            : _tr('New Expense', 'Gharama Mpya'),
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      tooltip: _tr('Close', 'Funga'),
                      visualDensity: VisualDensity.compact,
                      color: AppColors.textMuted,
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
                  children: [
                    _AmountSection(
                      controller: _amountCtrl,
                      onChanged: (_) {
                        setState(() {
                          if (_errorField == _ExpenseErrorField.amount &&
                              _errorMessage != null) {
                            _errorMessage = null;
                          }
                        });
                      },
                    ),
                    _buildValidation(_ExpenseErrorField.amount),
                    const SizedBox(height: 20),
                    _SectionLabel(_tr('Category', 'Kundi')),
                    const SizedBox(height: 10),
                    _CategoryGrid(
                      categories: categories,
                      selectedKey: _categoryKey,
                      onSelect: (key) => setState(() => _categoryKey = key),
                      onManage: _manageCategories,
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(_tr('Date & Payment', 'Tarehe na Malipo')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _pickDate,
                          child: _DateChip(date: _date),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PaymentAccountChips(
                      selectedAccountId: _selectedAccountId,
                      onSelectAccount: (a) => setState(() {
                        _selectedAccountId = a.id;
                        if (_errorField == _ExpenseErrorField.payment) {
                          _errorMessage = null;
                        }
                      }),
                      onActivationRequired: (message) =>
                          _showValidation(message, _ExpenseErrorField.payment),
                      onActivateMethod: (spec) => _showActivateAccountSheet(spec),
                    ),
                    _buildValidation(_ExpenseErrorField.payment),
                    const SizedBox(height: 20),
                    _SectionLabel(_tr('Details', 'Maelezo')),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _noteCtrl,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _fieldDec(
                        label: _tr('Description', 'Maelezo'),
                        prefix: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _recipientCtrl,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _fieldDec(
                        label: _tr('Paid To (recipient)', 'Imelipwa Kwa'),
                        prefix: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldCard(
                      child: _ToggleRow(
                        icon: Icons.credit_score_rounded,
                        label: _tr('Bought on Credit', 'Umenunua kwa Mkopo'),
                        subtitle: _tr(
                          'Not fully paid – record as payable debt',
                          'Haujalipia kikamilifu – rekodi kama deni',
                        ),
                        value: _isCreditPurchase,
                        color: AppColors.error,
                        onChanged: (v) => setState(() => _isCreditPurchase = v),
                      ),
                    ),
                    if (_isCreditPurchase) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _supplierPhoneCtrl,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _fieldDec(
                          label: _tr(
                            'Supplier Phone (optional)',
                            'Simu ya Muuzaji (hiari)',
                          ),
                          prefix: Icons.phone_outlined,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _tr(
                                  'A payable debt will be recorded for this supplier',
                                  'Deni la kulipa litarekodiwa kwa muuzaji huyu',
                                ),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SectionLabel(_tr('Receipt', 'Risiti')),
                    const SizedBox(height: 10),
                    _ReceiptSection(
                      receiptFile: _receiptFile,
                      receiptUrl: _receiptUrl,
                      uploading: _uploadingReceipt,
                      onTap: _showReceiptOptions,
                    ),
                    const SizedBox(height: 20),
                    _FieldCard(
                      child: Column(
                        children: [
                          _ToggleRow(
                            icon: Icons.repeat_rounded,
                            label: _tr(
                              'Recurring expense',
                              'Gharama inayojirudia',
                            ),
                            subtitle: _tr(
                              'Auto-log this expense on schedule',
                              'Andika gharama hii moja kwa moja kwa ratiba',
                            ),
                            value: _isRecurring,
                            color: AppColors.tealAccent,
                            onChanged: (v) => setState(() => _isRecurring = v),
                          ),
                          if (_isRecurring) ...[
                            const Divider(height: 1, color: AppColors.border),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _tr('Frequency:', 'Mara ngapi:'),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _FreqPill(
                                    label: _tr('Monthly', 'Kila Mwezi'),
                                    active: _frequency == 'monthly',
                                    onTap: () =>
                                        setState(() => _frequency = 'monthly'),
                                  ),
                                  const SizedBox(width: 8),
                                  _FreqPill(
                                    label: _tr('Weekly', 'Kila Wiki'),
                                    active: _frequency == 'weekly',
                                    onTap: () =>
                                        setState(() => _frequency = 'weekly'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildValidation(_ExpenseErrorField.general),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _BottomSaveBar(
                saving: _saving,
                amount: _amountCtrl.text,
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDec({
  required String label,
  required IconData prefix,
  String? hint,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDisabled),
  labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
  floatingLabelStyle: GoogleFonts.dmSans(
    fontSize: 12,
    color: AppColors.navyPrimary,
  ),
  prefixIcon: Icon(prefix, size: 20, color: AppColors.textSecondary),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.5),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AmountSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AmountSection({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.yellowBrand.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('AMOUNT', 'KIASI'),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'TZS',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                    letterSpacing: -0.5,
                  ),
                  cursorColor: AppColors.navyPrimary,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDisabled,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final String selectedKey;
  final ValueChanged<String> onSelect;
  final VoidCallback onManage;

  const _CategoryGrid({
    required this.categories,
    required this.selectedKey,
    required this.onSelect,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 50,
      ),
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return InkWell(
            onTap: onManage,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.tealAccent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: AppColors.tealAccent,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tr('Manage', 'Simamia'),
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealAccent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final cat = categories[index];
        final active = cat.key == selectedKey;
        final activeForeground =
            ThemeData.estimateBrightnessForColor(cat.color) == Brightness.light
            ? AppColors.navyPrimary
            : Colors.white;
        return InkWell(
          onTap: () => onSelect(cat.key),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: active ? cat.color : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? cat.color : AppColors.border,
                width: active ? 0 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat.icon,
                  size: 15,
                  color: active ? activeForeground : cat.color,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    cat.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? activeForeground
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;

  const _DateChip({required this.date});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 15,
            color: AppColors.navyPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            _fmt(date),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_drop_down_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  final File? receiptFile;
  final String receiptUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _ReceiptSection({
    required this.receiptFile,
    required this.receiptUrl,
    required this.uploading,
    required this.onTap,
  });

  bool get hasReceipt => receiptFile != null || receiptUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (hasReceipt) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.tealAccent),
            boxShadow: AppTheme.cardShadow,
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (receiptFile != null)
                Image.file(receiptFile!, fit: BoxFit.cover)
              else if (receiptUrl.isNotEmpty)
                Image.network(
                  receiptUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.error,
                    ),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.navyPrimary,
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _tr('Change', 'Badilisha'),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (uploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.cardShadow,
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
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 20,
                color: AppColors.tealAccent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tr('Attach receipt photo', 'Ambatanisha picha ya risiti'),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.tealAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _tr(
                'Take a photo or choose from gallery',
                'Piga picha au chagua kutoka maktaba',
              ),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final Widget child;

  const _FieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _FreqPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FreqPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.tealAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.tealAccent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  final bool saving;
  final String amount;
  final VoidCallback onSave;

  const _BottomSaveBar({
    required this.saving,
    required this.amount,
    required this.onSave,
  });

  String get _formattedAmount {
    final value = double.tryParse(amount.trim()) ?? 0;
    final digits = value.toStringAsFixed(0);
    final result = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) result.write(',');
      result.write(digits[i]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Total expense', 'Jumla ya gharama'),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'TZS $_formattedAmount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 184,
            height: 48,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                saving
                    ? _tr('Saving…', 'Inahifadhi…')
                    : _tr('Save Expense', 'Hifadhi Gharama'),
                maxLines: 1,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.navyPrimary.withValues(
                  alpha: 0.65,
                ),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
