import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/finance_providers.dart';
import '../../data/payment_account_service.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/payment_method_accounts.dart';

/// Shared payment-account picker used everywhere money moves: quick sale,
/// invoices, expenses, debt repayments. Lists the four built-in channels
/// (locked with an "activate first" prompt until activated in Cash Flow)
/// plus every custom account the user created, and optionally a trailing
/// "On Account" credit chip for invoicing.
class PaymentAccountChips extends ConsumerWidget {
  final String? selectedAccountId;
  final bool selectedIsCredit;
  final bool allowCredit;
  final ValueChanged<CashAccount> onSelectAccount;
  final VoidCallback? onSelectCredit;

  /// When false, tapping an unactivated built-in channel still selects it
  /// (as an unpersisted placeholder account) instead of blocking with an
  /// "activate first" snackbar. Used by quotations, which only record the
  /// intended method — no money moves until the quotation is confirmed.
  final bool lockUnactivated;

  /// When set, called with the "activate first" message instead of showing
  /// it as a SnackBar. Callers that render this widget inside a large modal
  /// sheet (which visually sits above the underlying Scaffold's SnackBar)
  /// should provide this and display the message inline themselves.
  final ValueChanged<String>? onActivationRequired;

  const PaymentAccountChips({
    super.key,
    required this.selectedAccountId,
    this.selectedIsCredit = false,
    this.allowCredit = false,
    required this.onSelectAccount,
    this.onSelectCredit,
    this.lockUnactivated = true,
    this.onActivationRequired,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(cashAccountListProvider).maybeWhen(
          data: (d) => d,
          orElse: () => const <CashAccount>[],
        );
    final byId = {for (final a in accounts) a.id: a};
    final custom = accounts
        .where((a) => !PaymentMethodAccounts.isMethodAccountId(a.id))
        .toList();

    void snackActivationRequired(String methodKey) {
      final message = activationRequiredMessage(methodKey);
      if (onActivationRequired != null) {
        onActivationRequired!(message);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final spec in PaymentMethodAccounts.specs)
          _PaymentChip(
            icon: byId[spec.accountId] == null
                ? Icons.lock_outline_rounded
                : spec.icon,
            label: spec.nameFor(LocalizationService.isSwahili ? 'sw' : 'en'),
            active: !selectedIsCredit && selectedAccountId == spec.accountId,
            enabled: byId[spec.accountId] != null,
            onTap: () {
              final account = byId[spec.accountId];
              if (account != null) {
                onSelectAccount(account);
                return;
              }
              if (lockUnactivated) {
                snackActivationRequired(spec.methodKey);
                return;
              }
              onSelectAccount(spec.toAccount(openingBalance: 0));
            },
          ),
        for (final account in custom)
          _PaymentChip(
            icon: switch (account.type) {
              'Cash' => Icons.payments_outlined,
              'Bank' => Icons.account_balance_outlined,
              'Card' => Icons.credit_card_outlined,
              _ => Icons.smartphone_outlined,
            },
            label: account.name,
            active: !selectedIsCredit && selectedAccountId == account.id,
            enabled: true,
            onTap: () => onSelectAccount(account),
          ),
        if (allowCredit)
          _PaymentChip(
            icon: Icons.receipt_long_outlined,
            label: LocalizationService.tr(en: 'On Account', sw: 'Kwa Mkopo'),
            active: selectedIsCredit,
            enabled: true,
            onTap: () => onSelectCredit?.call(),
          ),
      ],
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Colors.white
        : enabled
            ? AppColors.textSecondary
            : AppColors.textDisabled;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.navyPrimary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.navyPrimary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
