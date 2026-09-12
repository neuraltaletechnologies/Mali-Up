import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/page_tour.dart';
import '../../data/finance_providers.dart';
import '../../domain/payment_method_accounts.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Activates one of the four built-in payment channels (Taslimu, M-Pesa,
/// Benki, Kadi). The user must enter the actual money currently in the
/// channel — that becomes the account's opening balance. Until a channel is
/// activated it cannot receive sale money or pay for stock purchases.
class ActivateAccountSheet extends ConsumerStatefulWidget {
  final PaymentMethodSpec spec;
  const ActivateAccountSheet({super.key, required this.spec});

  @override
  ConsumerState<ActivateAccountSheet> createState() =>
      _ActivateAccountSheetState();
}

class _ActivateAccountSheetState extends ConsumerState<ActivateAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _balanceController = TextEditingController();
  final _accountNumberController = TextEditingController();
  bool _isLoading = false;

  final _tourBalanceKey = GlobalKey(debugLabel: 'activate_account_tour_balance');
  final _tourSubmitKey = GlobalKey(debugLabel: 'activate_account_tour_submit');

  @override
  void initState() {
    super.initState();
    PageTour.maybeAutoStart(
      context: context,
      seenKey: 'page_tour_seen_activate_account_v1',
      steps: [
        TourStep(
          targetKey: _tourBalanceKey,
          title: _t('Enter the Amount', 'Weka Kiasi'),
          description: _t(
            'Required — the money actually there right now.',
            'Inahitajika — pesa iliyopo sasa hivi.',
          ),
          inputController: _balanceController,
        ),
        TourStep(
          targetKey: _tourSubmitKey,
          title: _t('Activate', 'Washa'),
          description: _t('Tap here to activate this account.', 'Bonyeza hapa kuwasha akaunti hii.'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final name = spec.nameFor(LocalizationService.isSwahili ? 'sw' : 'en');

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tealAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(spec.icon,
                            color: AppColors.tealAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _t('Activate $name', 'Washa $name'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _t(
                      'Count the money currently in $name and enter the exact amount. Sales paid via $name will be added to this balance.',
                      'Hesabu pesa iliyopo sasa kwenye $name kisha weka kiasi halisi. Mauzo yanayolipwa kwa $name yataongezwa kwenye salio hili.',
                    ),
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    key: _tourBalanceKey,
                    controller: _balanceController,
                    autofocus: true,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText:
                          _t('Money present now', 'Pesa iliyopo sasa'),
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
                      final raw = (v ?? '').trim();
                      if (raw.isEmpty) {
                        return _t('Enter the actual amount present',
                            'Weka kiasi halisi kilichopo');
                      }
                      final parsed = double.tryParse(raw);
                      if (parsed == null || parsed < 0) {
                        return _t('Enter valid amount', 'Weka kiasi halali');
                      }
                      return null;
                    },
                  ),

                  if (spec.type != 'Cash') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accountNumberController,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: _t(
                          spec.type == 'Mobile Money'
                              ? 'Phone Number (Optional)'
                              : 'Account Number (Optional)',
                          spec.type == 'Mobile Money'
                              ? 'Nambari ya Simu (Hiari)'
                              : 'Nambari ya Akaunti (Hiari)',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],

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
                        key: _tourSubmitKey,
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
                              : Text(_t('Activate', 'Washa')),
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
      final balance =
          double.tryParse(_balanceController.text.trim()) ?? 0.0;
      final number = _accountNumberController.text.trim();
      await ref.read(cashRepositoryProvider).activateMethodAccount(
            widget.spec.toAccount(
              openingBalance: balance,
              accountNumber: number.isNotEmpty ? number : null,
            ),
          );

      if (mounted) {
        Navigator.pop(context, true);
        AppNotification.success(
          context,
          _t('${widget.spec.nameEn} activated', '${widget.spec.nameSw} imewashwa'),
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, _t('Error: ${e.toString()}', 'Kosa: ${e.toString()}'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
