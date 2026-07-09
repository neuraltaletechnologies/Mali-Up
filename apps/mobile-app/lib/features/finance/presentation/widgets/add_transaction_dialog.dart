import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../data/finance_providers.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class AddTransactionDialog extends ConsumerStatefulWidget {
  /// Pre-select a specific account as context (e.g. opened from AccountDetailScreen).
  final CashAccount? defaultAccount;

  const AddTransactionDialog({super.key, this.defaultAccount});

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _referenceController = TextEditingController();
  final _dateController = TextEditingController();

  String _type = 'deposit'; // deposit | withdrawal | transfer
  String _activityCategory = 'operating';
  String? _fromAccountId;
  String? _toAccountId;
  bool _isLoading = false;

  static const _activityCategories = [
    ('operating', 'Operating', 'Uendeshaji'),
    ('investing', 'Investing', 'Uwekezaji'),
    ('financing', 'Financing', 'Ufadhili'),
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = _today();
    if (widget.defaultAccount != null) {
      _fromAccountId = widget.defaultAccount!.id;
      _toAccountId = widget.defaultAccount!.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _referenceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _today() => DateTime.now().toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(cashAccountListProvider);
    final accounts = accountsAsync.maybeWhen(
      data: (d) => d,
      orElse: () => <CashAccount>[],
    );

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
                  const SheetHandle(),
                  const SizedBox(height: 4),
                  Text(
                    _t('Record Transaction', 'Rekodi Muamala'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),

                  // Transaction type tabs
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _TypeTab(
                          label: _t('Deposit', 'Amana'),
                          icon: Icons.add_circle_outline,
                          selected: _type == 'deposit',
                          color: AppColors.success,
                          onTap: () => setState(() => _type = 'deposit'),
                        ),
                        _TypeTab(
                          label: _t('Withdrawal', 'Kutoa'),
                          icon: Icons.remove_circle_outline,
                          selected: _type == 'withdrawal',
                          color: AppColors.error,
                          onTap: () => setState(() => _type = 'withdrawal'),
                        ),
                        _TypeTab(
                          label: _t('Transfer', 'Hamisha'),
                          icon: Icons.swap_horiz_rounded,
                          selected: _type == 'transfer',
                          color: AppColors.tealAccent,
                          onTap: () => setState(() => _type = 'transfer'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: _t('Amount', 'Kiasi'),
                      prefixText: 'TZS ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return _t('Enter amount', 'Weka kiasi');
                      }
                      if (double.tryParse(v) == null || double.parse(v) <= 0) {
                        return _t('Enter valid amount', 'Weka kiasi halali');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // From account (withdrawal / transfer)
                  if (_type == 'withdrawal' || _type == 'transfer') ...[
                    _AccountDropdown(
                      label: _type == 'transfer'
                          ? _t('From Account', 'Akaunti ya Kutoa')
                          : _t('Account', 'Akaunti'),
                      accounts: accounts,
                      value: _fromAccountId,
                      excludeId: _type == 'transfer' ? _toAccountId : null,
                      onChanged: (id) => setState(() => _fromAccountId = id),
                      validator: (v) => (v == null || v.isEmpty)
                          ? _t('Select account', 'Chagua akaunti')
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // To account (deposit / transfer)
                  if (_type == 'deposit' || _type == 'transfer') ...[
                    _AccountDropdown(
                      label: _type == 'transfer'
                          ? _t('To Account', 'Akaunti ya Kupokea')
                          : _t('Account', 'Akaunti'),
                      accounts: accounts,
                      value: _toAccountId,
                      excludeId: _type == 'transfer' ? _fromAccountId : null,
                      onChanged: (id) => setState(() => _toAccountId = id),
                      validator: (v) => (v == null || v.isEmpty)
                          ? _t('Select account', 'Chagua akaunti')
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  TextFormField(
                    controller: _descController,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: _t('Description', 'Maelezo'),
                      hintText: _t(
                        'e.g. Cash sale proceeds',
                        'mfano: Mapato ya mauzo',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _t('Enter description', 'Weka maelezo')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Date
                  TextFormField(
                    controller: _dateController,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: _t('Date', 'Tarehe'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        onPressed: _pickDate,
                      ),
                    ),
                    readOnly: true,
                    validator: (v) => (v == null || v.isEmpty)
                        ? _t('Select date', 'Chagua tarehe')
                        : null,
                  ),

                  // Activity category (not for transfers)
                  if (_type != 'transfer') ...[
                    const SizedBox(height: 16),
                    Text(
                      _t('Activity Category', 'Kundi la Shughuli'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: _activityCategories
                          .map((e) => ButtonSegment(
                                value: e.$1,
                                label: Text(
                                  LocalizationService.isSwahili ? e.$3 : e.$2,
                                  style: GoogleFonts.dmSans(fontSize: 12),
                                ),
                              ))
                          .toList(),
                      selected: {_activityCategory},
                      onSelectionChanged: (s) =>
                          setState(() => _activityCategory = s.first),
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.tealAccent
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ],

                  // Reference (optional)
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _referenceController,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: _t('Reference (Optional)', 'Kumbukumbu (Hiari)'),
                      hintText: _t('e.g. Receipt #001', 'mfano: Risiti #001'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_t('Save', 'Hifadhi')),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(
          () => _dateController.text = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Only persist the account side(s) the type actually uses — the
      // defaultAccount prefill sets both, and a stale id on the unused side
      // would attribute the transaction to the wrong account.
      final fromId = (_type == 'withdrawal' || _type == 'transfer')
          ? (_fromAccountId ?? '')
          : '';
      final toId = (_type == 'deposit' || _type == 'transfer')
          ? (_toAccountId ?? '')
          : '';
      if (_type == 'transfer' && fromId == toId) {
        throw Exception(_t(
          'Transfer accounts must differ',
          'Akaunti za kuhamisha lazima zitofautiane',
        ));
      }

      final txn = CashTransaction(
        id: '',
        type: _type,
        amount: double.parse(_amountController.text.trim()),
        fromAccountId: fromId,
        toAccountId: toId,
        description: _descController.text.trim(),
        date: _dateController.text,
        reference: _referenceController.text.trim(),
        activityCategory:
            _type == 'transfer' ? 'operating' : _activityCategory,
        createdBy: user.uid,
      );

      // Saves locally (incl. balance adjustments) and queues the sync.
      await ref.read(cashRepositoryProvider).addTransaction(txn);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Transaction saved', 'Muamala umehifadhiwa')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Error: ${e.toString()}', 'Kosa: ${e.toString()}')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? color : AppColors.textMuted),
              SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final String label;
  final List<CashAccount> accounts;
  final String? value;
  final String? excludeId;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.value,
    required this.onChanged,
    this.excludeId,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final filtered =
        excludeId != null ? accounts.where((a) => a.id != excludeId).toList() : accounts;

    return DropdownButtonFormField<String>(
      initialValue: (value != null && filtered.any((a) => a.id == value)) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: filtered
          .map((a) => DropdownMenuItem(
                value: a.id,
                child: Row(
                  children: [
                    Icon(
                      switch (a.type) {
                        'Cash' => Icons.payments_outlined,
                        'Bank' => Icons.account_balance_outlined,
                        'Card' => Icons.credit_card_outlined,
                        _ => Icons.smartphone_outlined,
                      },
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
