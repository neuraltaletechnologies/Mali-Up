import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/nav_aware_fab.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
import '../../../team/data/creator_providers.dart';
import '../../../team/presentation/widgets/issued_by.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../data/cash_flow_providers.dart';
import '../../data/finance_providers.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/delete_account_dialog.dart';
import 'reconciliation_screen.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

final _fmt = NumberFormat('#,###', 'en_US');
String _fmtAmt(double v) => 'TZS ${_fmt.format(v)}';

class AccountDetailScreen extends ConsumerWidget {
  final CashAccount account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live row so the balance updates after adding a transaction —
    // the constructor argument is only a snapshot from navigation time.
    final liveMatches = ref
        .watch(cashAccountListProvider)
        .maybeWhen(data: (d) => d, orElse: () => const <CashAccount>[])
        .where((a) => a.id == account.id);
    final liveAccount = liveMatches.isEmpty ? account : liveMatches.first;
    final transactions = ref.watch(accountTransactionsProvider(account.id));
    // Resolve creator labels up-front — issuedByLabel watches providers, so it
    // must run during build, not lazily inside itemBuilder.
    final issuedByFor = <String, String?>{
      for (final t in transactions) t.id: issuedByLabel(ref, t.createdBy),
    };
    final reconciliations = ref.watch(
      accountReconciliationsProvider(account.id),
    );
    final lastRecon = reconciliations.isNotEmpty ? reconciliations.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(liveAccount.name),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: _t('Reconcile', 'Linganisha'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReconciliationScreen(account: liveAccount),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: _t('Delete', 'Futa'),
            onPressed: () async {
              final deleted = await confirmAndDeleteCashAccount(
                context,
                ref,
                liveAccount,
              );
              if (deleted && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Account summary header
          _AccountHeader(account: liveAccount, lastReconDate: lastRecon?.date),

          // Transaction list
          Expanded(
            child: transactions.isEmpty
                ? EmptyState(
                    icon: Icons.swap_horiz_rounded,
                    title: _t('No transactions yet', 'Hakuna miamala bado'),
                    subtitle: _t(
                      'Tap + to record a deposit or withdrawal.',
                      'Bonyeza + kurekodi amana au kutoa.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _TxnTile(
                      txn: transactions[i],
                      accountId: account.id,
                      issuedBy: issuedByFor[transactions[i].id],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: NavAwareFab(
        child: FloatingActionButton(
          onPressed: () async {
            // Same gate as the cash flow screen's FAB — a downgraded plan can
            // still open this screen through existing accounts.
            final plan = await ref.read(planStatusProvider.future);
            if (!context.mounted) return;
            if (!plan.limits.cashFlow) {
              await showUpgradeSheet(
                context,
                currentStatus: plan,
                featureKey: PlanFeatureKey.cashFlow,
                triggerReason: _t(
                  'Required a Growth or Business plan.',
                  'unahitaji mpango wa Growth au Business.',
                ),
              );
              return;
            }
            if (!context.mounted) return;
            await showAppSheet(
              context,
              builder: (_) => AddTransactionDialog(defaultAccount: liveAccount),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.secondary),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final CashAccount account;
  final String? lastReconDate;
  const _AccountHeader({required this.account, this.lastReconDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Current Balance', 'Salio la Sasa'),
            style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtAmt(account.balance),
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (lastReconDate != null && lastReconDate!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white54,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _t(
                    'Last reconciled: $lastReconDate',
                    'Mwisho kulinganishwa: $lastReconDate',
                  ),
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final CashTransaction txn;
  final String accountId;

  /// Resolved "issued by" label — null hides it (solo business).
  final String? issuedBy;

  const _TxnTile({
    required this.txn,
    required this.accountId,
    this.issuedBy,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming =
        txn.isDeposit || (txn.isTransfer && txn.toAccountId == accountId);
    final color = txn.isTransfer
        ? AppColors.tealAccent
        : isIncoming
        ? AppColors.success
        : AppColors.error;
    final icon = txn.isTransfer
        ? Icons.swap_horiz_rounded
        : isIncoming
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
    final prefix = txn.isTransfer
        ? ''
        : isIncoming
        ? '+'
        : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      txn.date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (txn.reference.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          txn.reference,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                    if (issuedBy != null) ...[
                      const SizedBox(width: 6),
                      Flexible(child: IssuedByInline(value: issuedBy!)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$prefix${_fmtAmt(txn.amount)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
