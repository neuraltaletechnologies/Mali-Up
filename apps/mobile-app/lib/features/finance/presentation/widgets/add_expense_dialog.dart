import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/recurring_expense_template.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/domain/models/debt.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _recipientController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedCategory = 'Rent';
  bool _isLoading = false;
  bool _isRecurring = false;
  String _recurrenceType = 'monthly';
  bool _isCreditPurchase = false;
  final _supplierPhoneCtrl = TextEditingController();

  /// Standard expense categories for Tanzanian SMEs.
  /// Keys are the stored English values; values are Swahili display labels.
  static const _categoryEntries = <(String en, String sw)>[
    ('Rent',        'Kodi ya Nyumba'),
    ('Salary',      'Mshahara'),
    ('Fuel',        'Mafuta'),
    ('Electricity', 'Umeme'),
    ('Water',       'Maji'),
    ('Transport',   'Usafirishaji'),
    ('Internet',    'Intaneti'),
    ('Inventory',   'Stoo / Bidhaa'),
    ('Marketing',   'Masoko'),
    ('Tax',         'Kodi / Ushuru'),
    ('Maintenance', 'Matengenezo'),
    ('Supplies',    'Vifaa'),
    ('Insurance',   'Bima'),
    ('Equipment',   'Vifaa vya Kazi'),
    ('Office',      'Ofisi'),
    ('Other',       'Nyingine'),
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = _today();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _recipientController.dispose();
    _dateController.dispose();
    _supplierPhoneCtrl.dispose();
    super.dispose();
  }

  String _today() =>
      DateTime.now().toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
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
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('Add New Expense', 'Ongeza Matumizi Mapya'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),

                  // Category
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: _t('Category', 'Kundi'),
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                    items: _categoryEntries.map((entry) {
                      final label = LocalizationService.isSwahili
                          ? entry.$2
                          : entry.$1;
                      return DropdownMenuItem(
                        value: entry.$1,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: _t('Amount', 'Kiasi'),
                      border: const OutlineInputBorder(),
                      prefixText: 'TZS ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return _t('Please enter amount', 'Tafadhali weka kiasi');
                      }
                      if (double.tryParse(v) == null) {
                        return _t('Enter a valid amount', 'Weka kiasi halali');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date
                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: _t('Date', 'Tarehe'),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectDate,
                      ),
                    ),
                    readOnly: true,
                    validator: (v) => (v == null || v.isEmpty)
                        ? _t('Please select date', 'Chagua tarehe')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Recipient / Supplier name
                  TextFormField(
                    controller: _recipientController,
                    decoration: InputDecoration(
                      labelText: _isCreditPurchase
                          ? _t('Supplier Name', 'Jina la Muuzaji')
                          : _t('Recipient (Optional)', 'Mpokeaji (Hiari)'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Credit purchase toggle
                  Container(
                    decoration: BoxDecoration(
                      color: _isCreditPurchase
                          ? AppColors.error.withValues(alpha: 0.05)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isCreditPurchase
                            ? AppColors.error.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _isCreditPurchase,
                          onChanged: (v) =>
                              setState(() => _isCreditPurchase = v),
                          activeThumbColor: AppColors.error,
                          title: Text(
                            _t('Bought on Credit', 'Umenunua kwa Mkopo'),
                            style: GoogleFonts.dmSans(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _t(
                              'Not fully paid – record as payable debt',
                              'Haujalipia kikamilifu – rekodi kama deni',
                            ),
                            style: GoogleFonts.dmSans(fontSize: 12),
                          ),
                        ),
                        if (_isCreditPurchase) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: TextFormField(
                              controller: _supplierPhoneCtrl,
                              decoration: InputDecoration(
                                labelText:
                                    _t('Supplier Phone (Optional)', 'Simu ya Muuzaji (Hiari)'),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: _t('Note', 'Maoni'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Recurring toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _isRecurring,
                          onChanged: (v) => setState(() => _isRecurring = v),
                          activeThumbColor: AppColors.tealAccent,
                          title: Text(
                            _t('Recurring expense', 'Matumizi ya mara kwa mara'),
                            style: GoogleFonts.dmSans(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _t(
                              'Auto-record this expense on schedule',
                              'Rekodi matumizi haya kiotomatiki',
                            ),
                            style: GoogleFonts.dmSans(fontSize: 12),
                          ),
                        ),
                        if (_isRecurring) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Text(
                                  _t('Frequency', 'Muda'),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SegmentedButton<String>(
                                    segments: [
                                      ButtonSegment(
                                        value: 'weekly',
                                        label: Text(_t('Weekly', 'Kila wiki')),
                                      ),
                                      ButtonSegment(
                                        value: 'monthly',
                                        label: Text(
                                            _t('Monthly', 'Kila mwezi')),
                                      ),
                                    ],
                                    selected: {_recurrenceType},
                                    onSelectionChanged: (s) => setState(
                                        () => _recurrenceType = s.first),
                                    style: ButtonStyle(
                                      foregroundColor:
                                          WidgetStateProperty.resolveWith(
                                        (states) =>
                                            states.contains(WidgetState.selected)
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                      ),
                                      backgroundColor:
                                          WidgetStateProperty.resolveWith(
                                        (states) =>
                                            states.contains(WidgetState.selected)
                                                ? AppColors.tealAccent
                                                : Colors.transparent,
                                      ),
                                    ),
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

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                          child: Text(_t('Cancel', 'Ghairi')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const ShimmerBox(
                                  width: 88,
                                  height: 14,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                )
                              : Text(_t('Add', 'Ongeza')),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() =>
          _dateController.text = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);

      final date = _dateController.text;
      final nextDue = _isRecurring
          ? RecurringExpenseTemplate.computeNextDue(
              _recurrenceType, DateTime.parse(date))
          : '';

      final expense = Expense(
        id: '',
        category: _selectedCategory,
        amount: _amountController.text.trim(),
        date: date,
        note: _noteController.text.trim(),
        recipient: _recipientController.text.trim(),
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring ? _recurrenceType : '',
        nextDueDate: nextDue,
      );

      await repo.addExpense(uid: user.uid, context: ctx, expense: expense);

      // Auto-create payable debt when expense is not fully paid to supplier
      if (_isCreditPurchase) {
        final amount =
            double.tryParse(_amountController.text.trim()) ?? 0;
        if (amount > 0) {
          final dueDate = DateTime.now().add(const Duration(days: 30));
          final dueDateStr =
              '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
          await ref.read(debtRepositoryProvider).save(Debt(
            id: '',
            partyName: _recipientController.text.trim(),
            partyPhone: _supplierPhoneCtrl.text.trim(),
            type: 'payable',
            originalAmount: amount,
            dueDate: dueDateStr,
            note: _t(
              'Expense: $_selectedCategory',
              'Matumizi: $_selectedCategory',
            ),
            createdBy: user.uid,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      }

      // Save template so the system can auto-recreate it next cycle
      if (_isRecurring) {
        await repo.addRecurringTemplate(
          uid: user.uid,
          context: ctx,
          templateData: {
            'category': _selectedCategory,
            'amount': _amountController.text.trim(),
            'note': _noteController.text.trim(),
            'recipient': _recipientController.text.trim(),
            'recurrenceType': _recurrenceType,
            'nextDueDate': nextDue,
            'isActive': true,
          },
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRecurring
                ? _t(
                    'Expense added & recurring schedule set',
                    'Matumizi yameongezwa na ratiba imewekwa',
                  )
                : _isCreditPurchase
                    ? _t(
                        'Expense added – debt recorded in Payables',
                        'Matumizi yameongezwa – deni limerekodiwa kwenye Madeni',
                      )
                    : _t('Expense added', 'Matumizi yameongezwa')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Error: ${e.toString()}', 'Kosa: ${e.toString()}')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
