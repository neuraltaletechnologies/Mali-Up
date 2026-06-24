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
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/data/customer_providers.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/recurring_expense_template.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/domain/models/debt.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Category meta (mirrors expense_list_screen)
// ─────────────────────────────────────────────────────────────────────────────

enum _Cat {
  rent,
  utilities,
  salaries,
  transport,
  marketing,
  supplies,
  other,
}

extension _CatX on _Cat {
  String get key => name;

  String get label => switch (this) {
        _Cat.rent => _tr('Rent', 'Kodi'),
        _Cat.utilities => _tr('Utilities', 'Huduma'),
        _Cat.salaries => _tr('Salaries', 'Mishahara'),
        _Cat.transport => _tr('Transport', 'Usafiri'),
        _Cat.marketing => _tr('Marketing', 'Masoko'),
        _Cat.supplies => _tr('Supplies', 'Vifaa'),
        _Cat.other => _tr('Other', 'Nyingine'),
      };

  IconData get icon => switch (this) {
        _Cat.rent => Icons.home_rounded,
        _Cat.utilities => Icons.bolt_rounded,
        _Cat.salaries => Icons.people_rounded,
        _Cat.transport => Icons.local_shipping_rounded,
        _Cat.marketing => Icons.campaign_rounded,
        _Cat.supplies => Icons.inventory_2_rounded,
        _Cat.other => Icons.more_horiz_rounded,
      };

  Color get color => switch (this) {
        _Cat.rent => AppColors.navyPrimary,
        _Cat.utilities => AppColors.tealAccent,
        _Cat.salaries => AppColors.success,
        _Cat.transport => AppColors.warning,
        _Cat.marketing => AppColors.purpleAccent,
        _Cat.supplies => AppColors.warning,
        _Cat.other => AppColors.textMuted,
      };

  static _Cat fromKey(String key) => _Cat.values.firstWhere(
        (c) => c.key == key.toLowerCase(),
        orElse: () => _Cat.other,
      );
}

enum _PayMethod { cash, mpesa, bank, card }

extension _PayMethodX on _PayMethod {
  String get key => name;

  String get label => switch (this) {
        _PayMethod.cash => _tr('Cash', 'Taslimu'),
        _PayMethod.mpesa => 'M-Pesa',
        _PayMethod.bank => _tr('Bank', 'Benki'),
        _PayMethod.card => _tr('Card', 'Kadi'),
      };

  IconData get icon => switch (this) {
        _PayMethod.cash => Icons.payments_rounded,
        _PayMethod.mpesa => Icons.phone_android_rounded,
        _PayMethod.bank => Icons.account_balance_rounded,
        _PayMethod.card => Icons.credit_card_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with TickerProviderStateMixin {
  _Cat _cat = _Cat.other;
  _PayMethod _payMethod = _PayMethod.cash;
  DateTime _date = DateTime.now();
  String _receiptUrl = '';
  File? _receiptFile;
  bool _isRecurring = false;
  String _frequency = 'monthly';
  bool _submitForApproval = false;
  bool _saving = false;
  bool _uploadingReceipt = false;
  bool _isCreditPurchase = false;

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _supplierPhoneCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _cat = _CatX.fromKey(e.category);
      _payMethod = _PayMethod.values.firstWhere(
        (m) => m.key == e.paymentMethod,
        orElse: () => _PayMethod.cash,
      );
      _amountCtrl.text = e.amount;
      _noteCtrl.text = e.note;
      _recipientCtrl.text = e.recipient;
      _date = DateTime.tryParse(e.date) ?? DateTime.now();
      _receiptUrl = e.receiptUrl;
      _isRecurring = e.isRecurring;
      _frequency = e.recurrenceType.isNotEmpty ? e.recurrenceType : 'monthly';
      _submitForApproval = e.status == 'pending';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _recipientCtrl.dispose();
    _supplierPhoneCtrl.dispose();
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Receipt photo ────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1200);
      if (file == null) return;
      setState(() {
        _receiptFile = File(file.path);
        _receiptUrl = '';
      });
    } catch (_) {}
  }

  Future<String?> _uploadReceipt(String uid) async {
    if (_receiptFile == null) return _receiptUrl.isNotEmpty ? _receiptUrl : null;
    setState(() => _uploadingReceipt = true);
    try {
      final ref = FirebaseStorage.instance.ref(
          'receipts/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_receiptFile!);
      final url = await ref.getDownloadURL();
      setState(() => _uploadingReceipt = false);
      return url;
    } catch (_) {
      setState(() => _uploadingReceipt = false);
      return null;
    }
  }

  void _showReceiptOptions() {
    showAppSheet(
      context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.navyPrimary),
              title: Text(_tr('Take photo', 'Piga picha'),
                  style: GoogleFonts.dmSans()),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.navyPrimary),
              title: Text(_tr('Choose from gallery', 'Chagua kutoka maktaba'),
                  style: GoogleFonts.dmSans()),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_receiptFile != null || _receiptUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: Text(_tr('Remove receipt', 'Ondoa risiti'),
                    style: GoogleFonts.dmSans(color: AppColors.error)),
                onTap: () {
                  Navigator.of(context).pop();
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
    final amountStr = _amountCtrl.text.trim();
    if (amountStr.isEmpty || (double.tryParse(amountStr) ?? 0) <= 0) {
      _showSnack(_tr('Enter a valid amount', 'Weka kiasi sahihi'));
      return;
    }
    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final col = repo.scopeCollection(
          uid: user.uid, context: ctx, childCollection: 'expenses');

      // Upload receipt if a new file was selected
      final uploadedUrl = await _uploadReceipt(user.uid);
      final finalReceiptUrl = uploadedUrl ?? '';

      final dateStr =
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

      final status = _submitForApproval ? 'pending' : 'approved';

      final data = <String, dynamic>{
        'category': _cat.key,
        'amount': amountStr,
        'date': dateStr,
        'note': _noteCtrl.text.trim(),
        'recipient': _recipientCtrl.text.trim(),
        'paymentMethod': _payMethod.key,
        'status': status,
        'createdBy': user.uid,
        'isRecurring': _isRecurring,
        if (_isRecurring) 'recurrenceType': _frequency,
        if (finalReceiptUrl.isNotEmpty) 'receiptUrl': finalReceiptUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing) {
        await col.doc(widget.expenseToEdit!.id).update(data);

        // If recurring and this is the first time enabling it, create a template
        if (_isRecurring && !widget.expenseToEdit!.isRecurring) {
          await _createRecurringTemplate(user.uid, ctx, repo, dateStr);
        }
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await col.add(data);

        if (_isRecurring) {
          await _createRecurringTemplate(user.uid, ctx, repo, dateStr);
        }
      }

      // Auto-create payable debt when expense is not fully paid to supplier
      if (!_isEditing && _isCreditPurchase) {
        final amount = double.tryParse(amountStr) ?? 0;
        if (amount > 0) {
          final dueDate = DateTime.now().add(const Duration(days: 30));
          final dueDateStr =
              '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
          await ref.read(debtRepositoryProvider).save(Debt(
            id: '',
            partyName: _recipientCtrl.text.trim(),
            partyPhone: _supplierPhoneCtrl.text.trim(),
            type: 'payable',
            originalAmount: amount,
            dueDate: dueDateStr,
            note: _tr(
                'Expense: ${_cat.label}', 'Matumizi: ${_cat.label}'),
            createdBy: user.uid,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      }

      if (mounted) {
        if (!_isEditing && _isCreditPurchase) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_tr(
              'Expense saved – debt recorded in Payables',
              'Gharama imehifadhiwa – deni limerekodiwa kwenye Madeni',
            )),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ));
        }
        Navigator.of(context).pop({'saved': true});
      }
    } catch (e) {
      _showSnack(_tr('Failed to save: $e', 'Imeshindwa kuhifadhi: $e'));
      setState(() => _saving = false);
    }
  }

  Future<void> _createRecurringTemplate(
    String uid,
    dynamic ctx,
    dynamic repo,
    String dateStr,
  ) async {
    final nextDue = RecurringExpenseTemplate.computeNextDue(
        _frequency, DateTime.tryParse(dateStr) ?? DateTime.now());
    await repo.addRecurringTemplate(
      uid: uid,
      context: ctx,
      templateData: {
        'category': _cat.key,
        'note': _noteCtrl.text.trim(),
        'amount': _amountCtrl.text.trim(),
        'recipient': _recipientCtrl.text.trim(),
        'recurrenceType': _frequency,
        'nextDueDate': nextDue,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing
              ? _tr('Edit Expense', 'Hariri Gharama')
              : _tr('New Expense', 'Gharama Mpya'),
          style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                children: [
                  _AmountSection(controller: _amountCtrl),
                  const SizedBox(height: 20),
                  _SectionLabel(_tr('Category', 'Kundi')),
                  const SizedBox(height: 10),
                  _CategoryGrid(
                    selected: _cat,
                    onSelect: (c) => setState(() => _cat = c),
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
                  _PaymentMethodChips(
                    selected: _payMethod,
                    onSelect: (m) => setState(() => _payMethod = m),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(_tr('Details', 'Maelezo')),
                  const SizedBox(height: 10),
                  _FieldCard(
                    child: Column(
                      children: [
                        _InlineField(
                          controller: _noteCtrl,
                          hint: _tr(
                              'Description (e.g. Office rent - June)',
                              'Maelezo (mfano Kodi ofisi - Juni)'),
                          icon: Icons.notes_rounded,
                        ),
                        const Divider(
                            height: 1, color: AppColors.border),
                        _InlineField(
                          controller: _recipientCtrl,
                          hint: _tr(
                              'Paid to (recipient)',
                              'Imelipwa kwa (mlipwaji)'),
                          icon: Icons.person_outline_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Credit purchase toggle
                  _FieldCard(
                    child: Column(
                      children: [
                        _ToggleRow(
                          icon: Icons.credit_score_rounded,
                          label: _tr('Bought on Credit', 'Umenunua kwa Mkopo'),
                          subtitle: _tr(
                            'Not fully paid – record as payable debt',
                            'Haujalipia kikamilifu – rekodi kama deni',
                          ),
                          value: _isCreditPurchase,
                          color: AppColors.error,
                          onChanged: (v) =>
                              setState(() => _isCreditPurchase = v),
                        ),
                        if (_isCreditPurchase) ...[
                          const Divider(height: 1, color: AppColors.border),
                          _InlineField(
                            controller: _supplierPhoneCtrl,
                            hint: _tr(
                                'Supplier Phone (Optional)',
                                'Simu ya Muuzaji (Hiari)'),
                            icon: Icons.phone_outlined,
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.error, size: 15),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _tr(
                                      'A payable debt will be recorded for this supplier',
                                      'Deni la kulipa litarekodiwa kwa muuzaji huyu',
                                    ),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12, color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
                  // Recurring toggle
                  _FieldCard(
                    child: Column(
                      children: [
                        _ToggleRow(
                          icon: Icons.repeat_rounded,
                          label: _tr('Recurring expense',
                              'Gharama inayojirudia'),
                          subtitle: _tr(
                              'Auto-log this expense on schedule',
                              'Andika gharama hii moja kwa moja kwa ratiba'),
                          value: _isRecurring,
                          color: AppColors.tealAccent,
                          onChanged: (v) =>
                              setState(() => _isRecurring = v),
                        ),
                        if (_isRecurring) ...[
                          const Divider(
                              height: 1, color: AppColors.border),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  _tr('Frequency:', 'Mara ngapi:'),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 12),
                                _FreqPill(
                                  label: _tr('Monthly', 'Kila Mwezi'),
                                  active: _frequency == 'monthly',
                                  onTap: () => setState(
                                      () => _frequency = 'monthly'),
                                ),
                                const SizedBox(width: 8),
                                _FreqPill(
                                  label: _tr('Weekly', 'Kila Wiki'),
                                  active: _frequency == 'weekly',
                                  onTap: () => setState(
                                      () => _frequency = 'weekly'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Approval workflow toggle
                  _FieldCard(
                    child: _ToggleRow(
                      icon: Icons.approval_rounded,
                      label: _tr(
                          'Submit for approval',
                          'Wasilisha kwa idhini'),
                      subtitle: _tr(
                          'Expense will be held pending manager review',
                          'Gharama itashikiliwa hadi meneja akubali'),
                      value: _submitForApproval,
                      color: AppColors.warning,
                      onChanged: (v) =>
                          setState(() => _submitForApproval = v),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // Bottom save bar
            _BottomSaveBar(
              saving: _saving,
              submitForApproval: _submitForApproval,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AmountSection extends StatelessWidget {
  final TextEditingController controller;

  const _AmountSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyPrimary, AppColors.navySecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Amount', 'Kiasi'),
            style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.white54,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'TZS',
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'))
                  ],
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  cursorColor: AppColors.yellowBrand,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white24),
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
  final _Cat selected;
  final ValueChanged<_Cat> onSelect;

  const _CategoryGrid(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: _Cat.values.map((cat) {
        final active = cat == selected;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: active ? cat.color : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? cat.color : AppColors.border,
                width: active ? 0 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: cat.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat.icon,
                  size: 24,
                  color: active ? Colors.white : cat.color,
                ),
                const SizedBox(height: 6),
                Text(
                  cat.label,
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : AppColors.textSecondary),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 15, color: AppColors.navyPrimary),
          const SizedBox(width: 8),
          Text(
            _fmt(date),
            style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down_rounded,
              size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _PaymentMethodChips extends StatelessWidget {
  final _PayMethod selected;
  final ValueChanged<_PayMethod> onSelect;

  const _PaymentMethodChips(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _PayMethod.values.map((m) {
        final active = m == selected;
        return GestureDetector(
          onTap: () => onSelect(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.navyPrimary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: active
                      ? AppColors.navyPrimary
                      : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(m.icon,
                    size: 15,
                    color: active ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  m.label,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

  bool get hasReceipt =>
      receiptFile != null || receiptUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (hasReceipt) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.tealAccent),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (receiptFile != null)
                Image.file(receiptFile!, fit: BoxFit.cover)
              else if (receiptUrl.isNotEmpty)
                Image.network(receiptUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.navyPrimary,
                              strokeWidth: 2));
                    }),
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
              if (uploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.tealAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_photo_alternate_rounded,
                  size: 24, color: AppColors.tealAccent),
            ),
            const SizedBox(height: 10),
            Text(
              _tr('Attach receipt photo',
                  'Ambatanisha picha ya risiti'),
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tealAccent),
            ),
            const SizedBox(height: 4),
            Text(
              _tr('Camera or gallery — Phase 2: auto OCR extraction',
                  'Kamera au maktaba — Awamu 2: utambuzi wa maandishi'),
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.textMuted),
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
      ),
      child: child,
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _InlineField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
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
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textMuted)),
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

  const _FreqPill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.tealAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? AppColors.tealAccent : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMuted),
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
          letterSpacing: 0.6),
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  final bool saving;
  final bool submitForApproval;
  final VoidCallback onSave;

  const _BottomSaveBar({
    required this.saving,
    required this.submitForApproval,
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
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(
                  submitForApproval
                      ? Icons.send_rounded
                      : Icons.check_circle_rounded,
                  size: 18),
          label: Text(
            saving
                ? _tr('Saving…', 'Inahifadhi…')
                : submitForApproval
                    ? _tr('Submit for Approval',
                        'Wasilisha kwa Idhini')
                    : _tr('Save Expense', 'Hifadhi Gharama'),
            style: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: submitForApproval
                ? AppColors.warning
                : AppColors.navyPrimary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
