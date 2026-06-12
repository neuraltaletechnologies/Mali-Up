import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/finance_providers.dart';
import '../../domain/models/cash_account.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class AddAccountDialog extends ConsumerStatefulWidget {
  final CashAccount? existing;
  const AddAccountDialog({super.key, this.existing});

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  bool _isLoading = false;
  String _type = 'Cash';

  static const _accountTypes = [
    ('Cash', 'Fedha Taslimu', Icons.payments_outlined),
    ('Mobile Money', 'Pesa ya Simu', Icons.smartphone_outlined),
    ('Bank', 'Benki', Icons.account_balance_outlined),
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final acc = widget.existing;
    if (acc != null) {
      _nameController.text = acc.name;
      _accountNumberController.text = acc.accountNumber ?? '';
      _initialBalanceController.text = acc.balance > 0 ? acc.balance.toStringAsFixed(0) : '';
      _type = acc.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

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
                    _isEditing
                        ? _t('Edit Account', 'Hariri Akaunti')
                        : _t('Add Account', 'Ongeza Akaunti'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),

                  // Account type selector
                  Text(
                    _t('Account Type', 'Aina ya Akaunti'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _accountTypes.map((entry) {
                      final selected = _type == entry.$1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _type = entry.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.secondary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.secondary
                                      : AppColors.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    entry.$3,
                                    size: 22,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    LocalizationService.isSwahili
                                        ? entry.$2
                                        : entry.$1,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _t('Account Name', 'Jina la Akaunti'),
                      hintText: _t(
                        _type == 'Cash'
                            ? 'e.g. Main Cash Drawer'
                            : _type == 'Mobile Money'
                                ? 'e.g. Business M-Pesa'
                                : 'e.g. CRDB Business Account',
                        _type == 'Cash'
                            ? 'mfano: Sanduku la Fedha'
                            : _type == 'Mobile Money'
                                ? 'mfano: M-Pesa ya Biashara'
                                : 'mfano: Akaunti CRDB',
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
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _t('Enter account name', 'Weka jina la akaunti')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Account number (optional, for Bank/Mobile Money)
                  if (_type != 'Cash') ...[
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: InputDecoration(
                        labelText: _t(
                          _type == 'Mobile Money'
                              ? 'Phone Number (Optional)'
                              : 'Account Number (Optional)',
                          _type == 'Mobile Money'
                              ? 'Nambari ya Simu (Hiari)'
                              : 'Nambari ya Akaunti (Hiari)',
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
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Opening balance (only when creating)
                  if (!_isEditing)
                    TextFormField(
                      controller: _initialBalanceController,
                      decoration: InputDecoration(
                        labelText: _t('Opening Balance', 'Salio la Awali'),
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
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                          return _t('Enter valid amount', 'Weka kiasi halali');
                        }
                        return null;
                      },
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
                            backgroundColor: AppColors.secondary,
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
                              : Text(_isEditing
                                  ? _t('Save', 'Hifadhi')
                                  : _t('Add', 'Ongeza')),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(cashRepositoryProvider);

      if (_isEditing) {
        // SyncCashRepository preserves the stored balance on edits —
        // balance only moves through transactions.
        final updated = widget.existing!.copyWith(
          name: _nameController.text.trim(),
          type: _type,
          accountNumber: _accountNumberController.text.trim().isNotEmpty
              ? _accountNumberController.text.trim()
              : null,
        );
        await repo.saveAccount(updated);
      } else {
        final balance =
            double.tryParse(_initialBalanceController.text.trim()) ?? 0.0;
        final account = CashAccount(
          id: '',
          name: _nameController.text.trim(),
          type: _type,
          balance: balance,
          accountNumber: _accountNumberController.text.trim().isNotEmpty
              ? _accountNumberController.text.trim()
              : null,
        );
        await repo.saveAccount(account);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? _t('Account updated', 'Akaunti imesasishwa')
                : _t('Account added', 'Akaunti imeongezwa')),
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
