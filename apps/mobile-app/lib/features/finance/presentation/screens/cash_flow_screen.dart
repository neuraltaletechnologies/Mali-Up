import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
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
String _fmtAmt(double v) => 'TSh ${_numFmt.format(v)}';
String _fmtCompact(double v) {
  if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
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
    _tabController = TabController(length: 2, vsync: this);
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
          const _CashFlowDarkHeader(),
          const SizedBox(height: _CashFlowDarkHeader._pillHalf + 8),
          _CashFlowTabBar(tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _OverviewTab(),
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

// ── Dark Header ───────────────────────────────────────────────────────────────

class _CashFlowDarkHeader extends ConsumerWidget {
  static const double _pillHalf = 22.0;

  const _CashFlowDarkHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.of(context).padding.top;
    final total = ref.watch(totalCashPositionProvider);
    final inflow = ref.watch(monthlyInflowProvider);
    final outflow = ref.watch(monthlyOutflowProvider);

    Future<void> onAddAccount() async {
      final plan = await ref.read(planStatusProvider.future);
      if (!context.mounted) return;
      if (!plan.limits.cashFlow) {
        await showUpgradeSheet(
          context,
          currentStatus: plan,
          featureKey: PlanFeatureKey.cashFlow,
          triggerReason: _tr(
            'Cash flow tracking requires a Growth or Business plan.',
            'Ufuatiliaji wa mtiririko wa fedha unahitaji mpango wa Growth au Business.',
          ),
        );
        return;
      }
      if (!context.mounted) return;
      await showAppSheet(context, builder: (_) => const AddAccountDialog());
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dark card — matches inventory/sales header shape exactly
        Container(
          decoration: const BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20 + _pillHalf),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('Cash Flow', 'Mtitiko wa Fedha'),
                      style: GoogleFonts.dmSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmtAmt(total),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAddAccount,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_card_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Stats pill — same shape/shadow/position as inventory
        Positioned(
          bottom: -_pillHalf,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PillStat(
                    value: _fmtCompact(inflow),
                    label: _tr('Inflow', 'Mapato'),
                    color: AppColors.success,
                  ),
                  const _PillDivider(),
                  _PillStat(
                    value: _fmtCompact(outflow),
                    label: _tr('Outflow', 'Matumizi'),
                    color: AppColors.error,
                  ),
                  const _PillDivider(),
                  _PillStat(
                    value: _fmtCompact(total),
                    label: _tr('Position', 'Hali'),
                    color: AppColors.tealAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _CashFlowTabBar extends StatelessWidget {
  final TabController tabController;
  const _CashFlowTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            labelStyle: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: AppColors.navyPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.navyPrimary,
            indicatorWeight: 2.5,
            tabs: [
              Tab(text: _tr('Overview', 'Muhtasari')),
              Tab(text: _tr('Statement', 'Taarifa')),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

// ── Pill widgets (match inventory PillStat / PillDivider exactly) ─────────────

class _PillStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _PillStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(width: 1, height: 28, color: AppColors.border),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _CashFlowFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> onTap() async {
      final plan = await ref.read(planStatusProvider.future);
      if (!context.mounted) return;
      if (!plan.limits.cashFlow) {
        await showUpgradeSheet(
          context,
          currentStatus: plan,
          featureKey: PlanFeatureKey.cashFlow,
          triggerReason: _tr(
            'Cash flow tracking requires a Growth or Business plan.',
            'Ufuatiliaji wa mtiririko wa fedha unahitaji mpango wa Growth au Business.',
          ),
        );
        return;
      }
      if (!context.mounted) return;
      await showAppSheet(context, builder: (_) => const AddTransactionDialog());
    }

    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: AppColors.yellowBrand,
      foregroundColor: AppColors.navyPrimary,
      elevation: 3,
      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
      label: Text(
        _tr('Add Transaction', 'Ongeza Muamala'),
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
      ),
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
    final recentTxns = ref.watch(cfTransactionsByMonthProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthNavigator(month: month),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              _tr('My Accounts', 'Akaunti Zangu'),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
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
                  _tr('Unable to load accounts.',
                      'Imeshindikana kupakia akaunti.'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              _tr('Transactions', 'Miamala'),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
          ),

          if (recentTxns.isEmpty)
            EmptyState(
              icon: Icons.swap_horiz_rounded,
              title: _tr(
                  'No transactions this month', 'Hakuna miamala mwezi huu'),
              subtitle: _tr(
                'Record a deposit or withdrawal to see it here.',
                'Rekodi amana au kutoa ili ione hapa.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recentTxns.length,
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

// ── Tab 2: Statement ──────────────────────────────────────────────────────────

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

          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CashFlowStatementScreen(),
              ),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(
              _tr('Full Statement', 'Taarifa Kamili'),
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.tealAccent,
              side: const BorderSide(color: AppColors.tealAccent),
            ),
          ),
          const SizedBox(height: 16),

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

          // Net cash flow summary — navy card like other summary rows
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
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
                      style: GoogleFonts.dmSans(
                          color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tr('Net Cash Flow', 'Mtiririko Halisi'),
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${netFlow >= 0 ? '+' : ''}${_fmtCompact(netFlow)}',
                  style: GoogleFonts.dmSans(
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
    final isCurrentMonth = month.year == DateTime.now().year &&
        month.month == DateTime.now().month;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: notifier.prev,
            icon: const Icon(Icons.chevron_left, size: 20),
            color: AppColors.navyPrimary,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            DateFormat.yMMMM().format(month),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navyPrimary,
            ),
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : notifier.next,
            icon: const Icon(Icons.chevron_right, size: 20),
            color: isCurrentMonth
                ? AppColors.textDisabled
                : AppColors.navyPrimary,
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
          border: Border.all(color: AppColors.border),
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
                  color: AppColors.textMuted,
                  size: 18,
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 16),
              ],
            ),
            const Spacer(),
            Text(
              _fmtCompact(account.balance),
              style: GoogleFonts.dmSans(
                color: AppColors.navyPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              account.name,
              style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
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
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
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
      data: (list) => list
          .firstWhere(
            (a) => a.id == id,
            orElse: () =>
                const CashAccount(id: '', name: '—', type: '', balance: 0),
          )
          .name,
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
        border: Border.all(color: AppColors.border),
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
                  style: GoogleFonts.dmSans(
                    color: AppColors.navyPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle • ${txn.date}',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$prefix${_fmtCompact(txn.amount)}',
            style: GoogleFonts.dmSans(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
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
        border: Border.all(color: AppColors.border),
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
                  style: GoogleFonts.dmSans(
                    color: AppColors.navyPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
            style: GoogleFonts.dmSans(
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
        Text('$label: ',
            style:
                GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
        Text(
          _fmtCompact(value),
          style: GoogleFonts.dmSans(
              fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
