import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../data/cash_flow_providers.dart';
import '../widgets/add_transaction_dialog.dart';
import 'reconciliation_screen.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

final _fmt = NumberFormat('#,###', 'en_US');
String _fmtAmt(double v) => 'TZS ${_fmt.format(v)}';

class AccountDetailScreen extends ConsumerWidget {
  final CashAccount account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(accountTransactionsProvider(account.id));
    final reconciliations = ref.watch(accountReconciliationsProvider(account.id));
    final lastRecon = reconciliations.isNotEmpty ? reconciliations.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
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
                builder: (_) => ReconciliationScreen(account: account),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Account summary header
          _AccountHeader(account: account, lastReconDate: lastRecon?.date),

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _TxnTile(txn: transactions[i], accountId: account.id),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddTransactionDialog(defaultAccount: account),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondary),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  account.type == 'Cash'
                      ? Icons.payments_outlined
                      : account.type == 'Bank'
                          ? Icons.account_balance_outlined
                          : Icons.smartphone_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.type,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (account.accountNumber != null &&
                        account.accountNumber!.isNotEmpty)
                      Text(
                        account.accountNumber!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _t('Current Balance', 'Salio la Sasa'),
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtAmt(account.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (lastReconDate != null && lastReconDate!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(
                  _t(
                    'Last reconciled: $lastReconDate',
                    'Mwisho kulinganishwa: $lastReconDate',
                  ),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
  const _TxnTile({required this.txn, required this.accountId});

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
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          txn.reference,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
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
