import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/nav_aware_fab.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../../shared/widgets/silent_refresh.dart';
import '../../data/cash_flow_providers.dart';
import '../../data/finance_providers.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../domain/payment_method_accounts.dart';
import '../widgets/activate_account_sheet.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/delete_account_dialog.dart';
import 'account_detail_screen.dart';
import 'cash_flow_statement_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

final _numFmt = NumberFormat('#,###', 'en_US');
String _fmtCompact(double v) {
  final sign = v < 0 ? '-' : '';
  final a = v.abs();
  if (a >= 1000000) return '${sign}TZS ${(a / 1000000).toStringAsFixed(1)}M';
  if (a >= 1000) return '${sign}TZS ${(a / 1000).toStringAsFixed(0)}K';
  return '${sign}TZS ${_numFmt.format(a)}';
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
          const SizedBox(height: HeaderStatsPill.pillHalf + 8),
          _CashFlowTabBar(tabController: _tabController),
          Expanded(
            child: SilentRefresh(
              onRefresh: () => ref.read(syncServiceProvider).syncNow(),
              child: TabBarView(
                controller: _tabController,
                children: const [_OverviewTab(), _StatementTab()],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: NavAwareFab(child: _CashFlowFab()),
    );
  }
}

// ── Dark Header ───────────────────────────────────────────────────────────────

class _CashFlowDarkHeader extends ConsumerWidget {
  const _CashFlowDarkHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(totalCashPositionProvider);
    final inflow = ref.watch(monthlyInflowProvider);
    final outflow = ref.watch(monthlyOutflowProvider);
    final month = ref.watch(cfMonthProvider);
    final monthNotifier = ref.read(cfMonthProvider.notifier);
    final isCurrentMonth =
        month.year == DateTime.now().year &&
        month.month == DateTime.now().month;

    Future<void> onAddAccount() async {
      await showAppSheet(context, builder: (_) => const AddAccountDialog());
    }

    return DarkHeaderShell(
      title: Text(
        _tr('Cash Flow', 'Mtiririko'),
        style: GoogleFonts.dmSans(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: monthNotifier.prev,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat.yMMM().format(month),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: isCurrentMonth ? null : monthNotifier.next,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isCurrentMonth ? Colors.white24 : Colors.white70,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAddAccount,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_card_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      pill: HeaderStatsPill(
        stats: [
          HeaderPillStat(
            value: _fmtCompact(inflow),
            label: _tr('Inflow', 'Mapato'),
            color: AppColors.success,
          ),
          HeaderPillStat(
            value: _fmtCompact(outflow),
            label: _tr('Outflow', 'Matumizi'),
            color: AppColors.error,
          ),
          HeaderPillStat(
            value: _fmtCompact(total),
            label: _tr('Position', 'Hali'),
            color: AppColors.tealAccent,
          ),
        ],
      ),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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

// ── FAB ───────────────────────────────────────────────────────────────────────

class _CashFlowFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showAppSheet<void>(
        context,
        maxHeightFactor: 0.9,
        builder: (_) => const AddTransactionDialog(),
      ),
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
    final recentTxns = ref.watch(cfTransactionsByMonthProvider);

    return SingleChildScrollView(
      physics: silentRefreshPhysics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => showAppSheet<void>(
              context,
              maxHeightFactor: 0.82,
              builder: (_) => const _AccountsSheet(),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('My Accounts', 'Akaunti Zangu'),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _tr('Manage', 'Simamia'),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealAccent,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: AppColors.tealAccent,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 104,
            child: accountsAsync.when(
              data: (accounts) {
                // The four built-in payment channels always show first —
                // activated ones as live accounts, the rest as "activate"
                // prompts. Custom accounts follow.
                final byId = {for (final a in accounts) a.id: a};
                final custom = accounts
                    .where(
                      (a) => !PaymentMethodAccounts.isMethodAccountId(a.id),
                    )
                    .toList();
                const specs = PaymentMethodAccounts.specs;

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: specs.length + custom.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    if (i < specs.length) {
                      final spec = specs[i];
                      final account = byId[spec.accountId];
                      if (account == null) {
                        return _ActivateMethodCard(spec: spec);
                      }
                      return _AccountCard(
                        account: account,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountDetailScreen(account: account),
                          ),
                        ),
                      );
                    }
                    final account = custom[i - specs.length];
                    return _AccountCard(
                      account: account,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountDetailScreen(account: account),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, _) => const ShimmerBox(
                  width: 150,
                  height: 104,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
              error: (_, _) => Center(
                child: Text(
                  _tr(
                    'Unable to load accounts.',
                    'Imeshindikana kupakia akaunti.',
                  ),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
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
                'No transactions this month',
                'Hakuna miamala mwezi huu',
              ),
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
      physics: silentRefreshPhysics,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        color: Colors.white60,
                        fontSize: 12,
                      ),
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

class _AccountsSheet extends ConsumerWidget {
  const _AccountsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(cashAccountListProvider);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('My Accounts', 'Akaunti Zangu'),
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showAppSheet<void>(
                      context,
                      builder: (_) => const AddAccountDialog(),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text(_tr('Add', 'Ongeza')),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _tr(
                    'View balances, activate payment channels, or add an account.',
                    'Angalia salio, washa njia za malipo, au ongeza akaunti.',
                  ),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: accountsAsync.when(
                  loading: () => const SkeletonList(itemCount: 4),
                  error: (_, _) => EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: _tr(
                      'Could not load accounts',
                      'Imeshindikana kupakia akaunti',
                    ),
                    subtitle: _tr('Try again.', 'Jaribu tena.'),
                  ),
                  data: (accounts) {
                    final byId = {
                      for (final account in accounts) account.id: account,
                    };
                    final custom = accounts
                        .where(
                          (account) => !PaymentMethodAccounts.isMethodAccountId(
                            account.id,
                          ),
                        )
                        .toList();
                    final entries =
                        <({PaymentMethodSpec? spec, CashAccount? account})>[
                          ...PaymentMethodAccounts.specs.map(
                            (spec) =>
                                (spec: spec, account: byId[spec.accountId]),
                          ),
                          ...custom.map(
                            (account) => (spec: null, account: account),
                          ),
                        ];
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final account = entry.account;
                        final spec = entry.spec;
                        final name =
                            account?.name ??
                            spec!.nameFor(
                              LocalizationService.isSwahili ? 'sw' : 'en',
                            );
                        final icon =
                            spec?.icon ??
                            switch (account!.type) {
                              'Cash' => Icons.payments_outlined,
                              'Bank' => Icons.account_balance_outlined,
                              'Card' => Icons.credit_card_outlined,
                              _ => Icons.smartphone_outlined,
                            };
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  (account == null
                                          ? AppColors.warning
                                          : AppColors.tealAccent)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              icon,
                              size: 19,
                              color: account == null
                                  ? AppColors.warning
                                  : AppColors.tealAccent,
                            ),
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                          subtitle: Text(
                            account == null
                                ? _tr('Tap to activate', 'Gusa kuwasha')
                                : account.type,
                            style: GoogleFonts.dmSans(fontSize: 11),
                          ),
                          trailing: account == null
                              ? const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.warning,
                                  size: 18,
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _fmtCompact(account.balance),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyPrimary,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                          onTap: () {
                            if (account == null) {
                              showAppSheet<void>(
                                context,
                                builder: (_) =>
                                    ActivateAccountSheet(spec: spec!),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AccountDetailScreen(account: account),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final CashAccount account;
  final VoidCallback onTap;
  const _AccountCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  switch (account.type) {
                    'Cash' => Icons.payments_outlined,
                    'Bank' => Icons.account_balance_outlined,
                    'Card' => Icons.credit_card_outlined,
                    _ => Icons.smartphone_outlined,
                  },
                  color: AppColors.textMuted,
                  size: 16,
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(28, 28),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  tooltip: _tr('Account actions', 'Vitendo vya akaunti'),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                    size: 17,
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await confirmAndDeleteCashAccount(context, ref, account);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _tr('Delete account', 'Futa akaunti'),
                            style: GoogleFonts.dmSans(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              _fmtCompact(account.balance),
              style: GoogleFonts.dmSans(
                color: AppColors.navyPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              account.name,
              style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 10.5,
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

/// A built-in payment channel that has not been activated yet. Tapping it
/// opens the activation sheet where the user enters the money actually
/// present in the channel. Until then the channel cannot move money.
class _ActivateMethodCard extends StatelessWidget {
  final PaymentMethodSpec spec;
  const _ActivateMethodCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    final name = spec.nameFor(LocalizationService.isSwahili ? 'sw' : 'en');
    return GestureDetector(
      onTap: () => showAppSheet(
        context,
        builder: (_) => ActivateAccountSheet(spec: spec),
      ),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(spec.icon, color: AppColors.textMuted, size: 16),
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.warning,
                  size: 14,
                ),
              ],
            ),
            const Spacer(),
            Text(
              name,
              style: GoogleFonts.dmSans(
                color: AppColors.navyPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tr('Tap to activate', 'Gusa kuwasha'),
                style: GoogleFonts.dmSans(
                  color: AppColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
    final prefix = txn.isTransfer
        ? ''
        : txn.isDeposit
        ? '+'
        : '-';

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
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      label: _tr('Out', 'Nje'),
                      value: data.outflow,
                      color: AppColors.error,
                    ),
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
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted),
        ),
        Text(
          _fmtCompact(value),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
