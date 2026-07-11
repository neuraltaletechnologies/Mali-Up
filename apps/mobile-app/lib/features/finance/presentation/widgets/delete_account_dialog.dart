import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/finance_providers.dart';
import '../../domain/models/cash_account.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

final _amountFormat = NumberFormat('#,###', 'en_US');

/// Confirms and deletes a cash-flow account.
///
/// Returns `true` only when the account was deleted. Accounts must have a zero
/// balance first so deleting a card cannot make tracked money disappear.
Future<bool> confirmAndDeleteCashAccount(
  BuildContext context,
  WidgetRef ref,
  CashAccount account,
) async {
  if (account.balance != 0) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t('Empty the account first', 'Toa pesa yote kwanza'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _t(
            'This account still holds TZS ${_amountFormat.format(account.balance)}. Withdraw or transfer it to another account before deleting.',
            'Akaunti hii bado ina TZS ${_amountFormat.format(account.balance)}. Toa au hamisha kwenda akaunti nyingine kabla ya kufuta.',
          ),
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_t('OK', 'Sawa')),
          ),
        ],
      ),
    );
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _t('Delete Account?', 'Futa Akaunti?'),
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
      ),
      content: Text(
        _t(
          'Delete "${account.name}"? This cannot be undone.',
          'Futa "${account.name}"? Hii haiwezi kutenduliwa.',
        ),
        style: GoogleFonts.dmSans(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(_t('Cancel', 'Ghairi')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(
            _t('Delete', 'Futa'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  try {
    await ref.read(cashRepositoryProvider).deleteAccount(account.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Account deleted', 'Akaunti imefutwa')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Could not delete the account. Please try again.',
              'Imeshindikana kufuta akaunti. Jaribu tena.',
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
}
