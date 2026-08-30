import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/validation_banner.dart';
import '../../data/finance_providers.dart';
import '../../data/payment_account_service.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/payment_method_accounts.dart';

/// Shared payment-account picker used everywhere money moves: quick sale,
/// invoices, expenses, debt repayments. Lists the four built-in channels
/// (locked with an "activate first" prompt until activated in Cash Flow)
/// plus every custom account the user created, and optionally a trailing
/// "On Account" credit chip for invoicing.
class PaymentAccountChips extends ConsumerStatefulWidget {
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

  /// Called when an unactivated built-in payment method is double-tapped.
  /// The spec contains all info needed to show the activation sheet.
  final ValueChanged<PaymentMethodSpec>? onActivateMethod;

  const PaymentAccountChips({
    super.key,
    required this.selectedAccountId,
    this.selectedIsCredit = false,
    this.allowCredit = false,
    required this.onSelectAccount,
    this.onSelectCredit,
    this.lockUnactivated = true,
    this.onActivationRequired,
    this.onActivateMethod,
  });

  @override
  ConsumerState<PaymentAccountChips> createState() =>
      _PaymentAccountChipsState();
}

class _PaymentAccountChipsState extends ConsumerState<PaymentAccountChips> {
  String? _activationMessage;

  /// Id of the account we last auto-selected, so we fire the callback once per
  /// distinct sole account instead of on every rebuild.
  String? _autoSelectedFor;

  /// When the business has exactly one usable money account there is nothing to
  /// choose — pre-select it so the user doesn't have to tap. Only fires while
  /// the caller has no selection yet and isn't on credit, so it never overrides
  /// an edit-screen prefill, a user's later choice, or an "On Account" invoice.
  void _maybeAutoSelectSoleAccount(List<CashAccount> accounts) {
    if (widget.selectedAccountId != null || widget.selectedIsCredit) return;
    if (accounts.length != 1) return;
    final sole = accounts.first;
    if (_autoSelectedFor == sole.id) return;
    _autoSelectedFor = sole.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.selectedAccountId == null &&
          !widget.selectedIsCredit) {
        widget.onSelectAccount(sole);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref
        .watch(cashAccountListProvider)
        .maybeWhen(data: (d) => d, orElse: () => const <CashAccount>[]);
    _maybeAutoSelectSoleAccount(accounts);
    final byId = {for (final a in accounts) a.id: a};
    final custom = accounts
        .where((a) => !PaymentMethodAccounts.isMethodAccountId(a.id))
        .toList();

    void snackActivationRequired(String methodKey) {
      final message = activationRequiredMessage(methodKey);
      if (widget.onActivationRequired != null) {
        widget.onActivationRequired!(message);
        return;
      }
      setState(() => _activationMessage = message);
    }

    void selectAccount(CashAccount account) {
      if (_activationMessage != null) {
        setState(() => _activationMessage = null);
      }
      widget.onSelectAccount(account);
    }

    void selectCredit() {
      if (_activationMessage != null) {
        setState(() => _activationMessage = null);
      }
      widget.onSelectCredit?.call();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final spec in PaymentMethodAccounts.specs)
              _PaymentChip(
                icon: byId[spec.accountId] == null
                    ? Icons.lock_outline_rounded
                    : spec.icon,
                label: spec.nameFor(
                  LocalizationService.isSwahili ? 'sw' : 'en',
                ),
                active:
                    !widget.selectedIsCredit &&
                    widget.selectedAccountId == spec.accountId,
                enabled: byId[spec.accountId] != null,
                spec: byId[spec.accountId] == null ? spec : null,
                onTap: () {
                  final account = byId[spec.accountId];
                  if (account != null) {
                    selectAccount(account);
                    return;
                  }
                  if (widget.lockUnactivated) {
                    snackActivationRequired(spec.methodKey);
                    return;
                  }
                  selectAccount(spec.toAccount(openingBalance: 0));
                },
                onDoubleTap: widget.onActivateMethod != null &&
                        byId[spec.accountId] == null
                    ? () => widget.onActivateMethod!(spec)
                    : null,
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
                active:
                    !widget.selectedIsCredit &&
                    widget.selectedAccountId == account.id,
                enabled: true,
                onTap: () => selectAccount(account),
              ),
            if (widget.allowCredit)
              _PaymentChip(
                icon: Icons.receipt_long_outlined,
                label: LocalizationService.tr(
                  en: 'On Account',
                  sw: 'Kwa Mkopo',
                ),
                active: widget.selectedIsCredit,
                enabled: true,
                onTap: selectCredit,
              ),
          ],
        ),
        if (widget.onActivationRequired == null)
          ValidationBanner(
            message: _activationMessage,
            onDismiss: () => setState(() => _activationMessage = null),
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
  final PaymentMethodSpec? spec;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const _PaymentChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    this.spec,
    required this.onTap,
    this.onDoubleTap,
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
      onDoubleTap: onDoubleTap,
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
            if (spec != null && onDoubleTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.touch_app_rounded,
                size: 12,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
