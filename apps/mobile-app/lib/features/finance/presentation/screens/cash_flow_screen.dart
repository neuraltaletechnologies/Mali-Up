import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../data/cash_flow_providers.dart';
import '../../data/finance_providers.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import 'account_detail_screen.dart';
import 'cash_flow_statement_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

final _numFmt = NumberFormat('#,###', 'en_US');
String _fmtAmt(double v) => 'TZS ${_numFmt.format(v)}';
String _fmtCompact(double v) {
  if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
  return _fmtAmt(v);
}

class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with tab bar
          _CashFlowHeader(tabController: _tabController),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _OverviewTab(),
                _TransactionsTab(),
                _StatementTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _CashFlowFab(),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _CashFlowHeader extends ConsumerWidget {
  final TabController tabController;
  const _CashFlowHeader({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPosition = ref.watch(totalCashPositionProvider);

    return Container(
      color: AppColors.secondary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Cash Position', 'Hali ya Fedha'),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmtAmt(totalPosition),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onSelected: (v) {
                      if (v == 'add_account') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AddAccountDialog(),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'add_account',
                        child: Row(
                          children: [
                            const Icon(Icons.add_card_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(_tr('Add Account', 'Ongeza Akaunti')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: tabController,
              indicatorColor: AppColors.primary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: _tr('Overview', 'Muhtasari')),
                Tab(text: _tr('Transactions', 'Miamala')),
                Tab(text: _tr('Statement', 'Taarifa')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _CashFlowFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTransactionDialog(),
      ),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: AppColors.secondary),
    );
  }
}

// ── Tab 1: Overview ───────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(cashAccountListProvider);
    final month = ref.watch(cfMonthProvider);
    final inflow = ref.watch(monthlyInflowProvider);
    final outflow = ref.watch(monthlyOutflowProvider);
    final netFlow = ref.watch(netCashFlowProvider);
    final recentTxns = ref.watch(cfTransactionsByMonthProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigator
          _MonthNavigator(month: month),

          // Account cards
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              _tr('My Accounts', 'Akaunti Zangu'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 150,
            child: accountsAsync.when(
              data: (accounts) => accounts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _NoAccountsCard(),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: accounts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _AccountCard(
                        account: accounts[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountDetailScreen(account: accounts[i]),
                          ),
                        ),
                      ),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SkeletonList(itemCount: 3),
              ),
              error: (_, _) => Center(
                child: Text(
                  _tr('Unable to load accounts.', 'Imeshindikana kupakia akaunti.'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Monthly flow summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FlowSummaryCard(
              inflow: inflow,
              outflow: outflow,
              netFlow: netFlow,
            ),
          ),

          const SizedBox(height: 24),

          // Recent movements
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tr('Recent Movements', 'Mienendo ya Hivi Karibuni'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (recentTxns.length > 5)
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      _tr('See all', 'Tazama zote'),
                      style: const TextStyle(
                        color: AppColors.tealAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (recentTxns.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 52, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      _tr(
                        'No transactions this month.',
                        'Hakuna miamala mwezi huu.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recentTxns.take(5).length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _TxnListTile(
                txn: recentTxns[i],
                accountsAsync: ref.watch(cashAccountListProvider),
              ),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Tab 2: Transactions ───────────────────────────────────────────────────────

class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(cfMonthProvider);
    final txns = ref.watch(cfTransactionsByMonthProvider);

    return Column(
      children: [
        _MonthNavigator(month: month),
        Expanded(
          child: txns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        _tr('No transactions this month.', 'Hakuna miamala mwezi huu.'),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: txns.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _TxnListTile(
                    txn: txns[i],
                    accountsAsync: ref.watch(cashAccountListProvider),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Tab 3: Statement ──────────────────────────────────────────────────────────

class _StatementTab extends ConsumerWidget {
  const _StatementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(cfMonthProvider);
    final byActivity = ref.watch(cfByActivityProvider);
    final netFlow = ref.watch(netCashFlowProvider);
    final monthLabel = DateFormat.yMMMM().format(month);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthNavigator(month: month),
          const SizedBox(height: 8),

          // View full statement button
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CashFlowStatementScreen(),
              ),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(_tr('Full Statement', 'Taarifa Kamili')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.tealAccent,
              side: const BorderSide(color: AppColors.tealAccent),
            ),
          ),
          const SizedBox(height: 16),

          // Activity breakdown cards
          _ActivityCard(
            title: _tr('Operating', 'Uendeshaji'),
            icon: Icons.store_outlined,
            color: AppColors.tealAccent,
            data: byActivity['operating'] ?? (inflow: 0.0, outflow: 0.0),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            title: _tr('Investing', 'Uwekezaji'),
            icon: Icons.trending_up_rounded,
            color: AppColors.purpleAccent,
            data: byActivity['investing'] ?? (inflow: 0.0, outflow: 0.0),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            title: _tr('Financing', 'Ufadhili'),
            icon: Icons.account_balance_outlined,
            color: AppColors.warning,
            data: byActivity['financing'] ?? (inflow: 0.0, outflow: 0.0),
          ),
          const SizedBox(height: 20),

          // Net summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tr('Net Cash Flow', 'Mtiririko Halisi'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${netFlow >= 0 ? '+' : ''}${_fmtCompact(netFlow)}',
                  style: TextStyle(
                    color: netFlow >= 0
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFFFCA5A5),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _MonthNavigator extends ConsumerWidget {
  final DateTime month;
  const _MonthNavigator({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cfMonthProvider.notifier);
    final isCurrentMonth =
        month.year == DateTime.now().year && month.month == DateTime.now().month;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: notifier.prev,
            icon: const Icon(Icons.chevron_left, size: 20),
            color: AppColors.secondary,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            DateFormat.yMMMM().format(month),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : notifier.next,
            icon: const Icon(Icons.chevron_right, size: 20),
            color: isCurrentMonth ? AppColors.textDisabled : AppColors.secondary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final CashAccount account;
  final VoidCallback onTap;
  const _AccountCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.06)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              const Color(0xFF334155).withValues(alpha: 0.35),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  account.type == 'Cash'
                      ? Icons.payments_outlined
                      : account.type == 'Bank'
                          ? Icons.account_balance_outlined
                          : Icons.smartphone_outlined,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 16),
              ],
            ),
            const Spacer(),
            Text(
              _fmtCompact(account.balance),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.secondary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              account.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccountsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_card_outlined,
              color: AppColors.textMuted, size: 28),
          const SizedBox(height: 8),
          Text(
            _tr('Add your first account', 'Ongeza akaunti yako ya kwanza'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FlowSummaryCard extends StatelessWidget {
  final double inflow;
  final double outflow;
  final double netFlow;
  const _FlowSummaryCard({
    required this.inflow,
    required this.outflow,
    required this.netFlow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Text(
            _tr('Monthly Flow Summary', 'Muhtasari wa Mtiririko wa Mwezi'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FlowStat(
                label: _tr('Inflow', 'Mapato'),
                value: _fmtCompact(inflow),
                color: AppColors.success,
                icon: Icons.south_west_rounded,
              ),
              Container(width: 1, height: 40, color: AppColors.glassBorder),
              _FlowStat(
                label: _tr('Outflow', 'Matumizi'),
                value: _fmtCompact(outflow),
                color: AppColors.error,
                icon: Icons.north_east_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: (netFlow >= 0 ? AppColors.successBg : AppColors.errorBg),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  netFlow >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: netFlow >= 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_tr('Net', 'Halisi')}: ${netFlow >= 0 ? '+' : ''}${_fmtCompact(netFlow)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: netFlow >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _FlowStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnListTile extends StatelessWidget {
  final CashTransaction txn;
  final AsyncValue<List<CashAccount>> accountsAsync;
  const _TxnListTile({required this.txn, required this.accountsAsync});

  String _accountName(String id) {
    return accountsAsync.maybeWhen(
      data: (list) => list.firstWhere((a) => a.id == id,
          orElse: () => const CashAccount(
                id: '',
                name: '—',
                type: '',
                balance: 0,
              )).name,
      orElse: () => '—',
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = txn.isTransfer
        ? AppColors.tealAccent
        : txn.isDeposit
            ? AppColors.success
            : AppColors.error;
    final icon = txn.isTransfer
        ? Icons.swap_horiz_rounded
        : txn.isDeposit
            ? Icons.south_west_rounded
            : Icons.north_east_rounded;
    final prefix = txn.isTransfer ? '' : txn.isDeposit ? '+' : '-';

    final subtitle = txn.isTransfer
        ? '${_accountName(txn.fromAccountId)} → ${_accountName(txn.toAccountId)}'
        : txn.isDeposit
            ? '${_tr('To', 'Kwa')}: ${_accountName(txn.toAccountId)}'
            : '${_tr('From', 'Kutoka')}: ${_accountName(txn.fromAccountId)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle • ${txn.date}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$prefix${_fmtCompact(txn.amount)}',
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

class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final ({double inflow, double outflow}) data;

  const _ActivityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final net = data.inflow - data.outflow;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniStat(
                        label: _tr('In', 'Ndani'),
                        value: data.inflow,
                        color: AppColors.success),
                    const SizedBox(width: 12),
                    _MiniStat(
                        label: _tr('Out', 'Nje'),
                        value: data.outflow,
                        color: AppColors.error),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${net >= 0 ? '+' : ''}${_fmtCompact(net)}',
            style: TextStyle(
              color: net >= 0 ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        Text(
          _fmtCompact(value),
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
