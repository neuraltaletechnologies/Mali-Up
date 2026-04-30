import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../customer/domain/models/customer.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../debt/domain/models/debt.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../finance/data/finance_providers.dart';
import '../../../finance/domain/models/cash_account.dart';
import '../../../finance/domain/models/expense.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _firstRewardSeenKey = 'dashboard_first_reward_seen';
  static const _showIncomeSeriesKey = 'dashboard_show_income_series';
  static const _showExpenseSeriesKey = 'dashboard_show_expense_series';

  int _entryRewardTrigger = 0;
  bool _showEntryReward = false;
  bool _showPersonalIncome = true;
  bool _showPersonalExpense = true;
  bool _showHeavyContent = false;
  Timer? _clockTimer;
  Future<Map<String, dynamic>?> _profileFuture = Future.value(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _profileFuture = _fetchUserProfile();
      });
      _loadChartVisibilityPrefs();
      _showFirstEntryRewardIfNeeded();
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted) {
          setState(() {
            _showHeavyContent = true;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return _tr('Good morning', 'Habari za asubuhi');
    if (hour >= 12 && hour < 17) return _tr('Good afternoon', 'Habari za mchana');
    if (hour >= 17 && hour < 21) return _tr('Good evening', 'Habari za jioni');
    if (hour >= 21) return _tr('Good night', 'Usiku mwema');
    return _tr('Good midnight', 'Usiku wa manane mwema');
  }

  Future<void> _loadChartVisibilityPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final showIncome = prefs.getBool(_showIncomeSeriesKey) ?? true;
    final showExpense = prefs.getBool(_showExpenseSeriesKey) ?? true;
    if (!mounted) return;
    setState(() {
      _showPersonalIncome = showIncome;
      _showPersonalExpense = showExpense;
    });
  }

  Future<void> _persistChartVisibilityPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showIncomeSeriesKey, _showPersonalIncome);
    await prefs.setBool(_showExpenseSeriesKey, _showPersonalExpense);
  }

  Future<void> _showFirstEntryRewardIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_firstRewardSeenKey) ?? false;
    if (seen || !mounted) return;

    setState(() {
      _showEntryReward = true;
      _entryRewardTrigger++;
    });

    await prefs.setBool(_firstRewardSeenKey, true);
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _showEntryReward = false);
  }

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.data();
  }

  bool _isBusinessContext(Map<String, dynamic>? profile) {
    final defaultContext = (profile?['defaultContext'] as String?)?.toLowerCase();
    if (defaultContext != null && defaultContext.isNotEmpty) {
      return defaultContext.startsWith('business');
    }
    final defaultAccountType =
        (profile?['defaultAccountType'] as String?)?.toLowerCase();
    return defaultAccountType == 'business';
  }

  @override
  Widget build(BuildContext context) {
    final customers = _showHeavyContent
      ? ref.watch(customerListProvider)
      : const AsyncLoading<List<Customer>>();
    final debts = _showHeavyContent
      ? ref.watch(debtListProvider)
      : const AsyncLoading<List<Debt>>();
    final customerCount = _showHeavyContent
      ? customers.maybeWhen(data: (items) => items.length, orElse: () => 0)
      : 0;
    final debtItems = _showHeavyContent
      ? debts.maybeWhen(data: (items) => items, orElse: () => const [])
      : const [];
    final AsyncValue<List<Expense>> expenses = _showHeavyContent
      ? ref.watch(expenseListProvider)
      : const AsyncLoading<List<Expense>>();
    final AsyncValue<List<CashAccount>> cashAccounts = _showHeavyContent
      ? ref.watch(cashAccountListProvider)
      : const AsyncLoading<List<CashAccount>>();
    final expenseItems = _showHeavyContent
      ? expenses.maybeWhen(data: (items) => items, orElse: () => const [])
      : const [];
    final cashAccountItems = _showHeavyContent
      ? cashAccounts.maybeWhen(data: (items) => items, orElse: () => const [])
      : const [];
    final totalExpenses = expenseItems.fold<double>(
      0,
      (total, item) => total + _numericValue(item.amount),
    );
    final totalCash = cashAccountItems.fold<double>(
      0,
      (total, item) => total + _numericValue(item.balance),
    );
    final budgetHealth = totalCash <= 0 ? 0 : ((totalCash - totalExpenses) / totalCash * 100).clamp(0, 100);

    return Scaffold(
      body: Stack(
        children: [
          const AmbientEmotionBackground(
            palette: [
              AppColors.primary,
              AppColors.secondaryLight,
              AppColors.success,
            ],
            intensity: 0.56,
          ),
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final isBusinessContext = _isBusinessContext(snapshot.data);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snapshot.connectionState != ConnectionState.done)
                      const _DashboardHeaderSkeleton()
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_timeBasedGreeting()}, ${_displayName(snapshot.data)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                      ),
                                ),
                                Text(
                                  isBusinessContext
                                      ? _tr(
                                          "Here's what's happening in your business today",
                                          'Haya ndiyo yanayoendelea kwenye biashara yako leo',
                                        )
                                      : _tr(
                                          "Here's your personal money pulse for today",
                                          'Huu ndio mwendo wa fedha zako binafsi leo',
                                        ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const EmotionalLottieSpot(
                            scene: EmotionalLottieScene.dashboard,
                            size: 72,
                            fallbackMood: CompanionMood.calm,
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                    if (_showHeavyContent)
                      Row(
                        children: [
                          Expanded(
                            child: _KPICard(
                              title: isBusinessContext
                                  ? _tr('Today Revenue', 'Mapato ya Leo')
                                  : _tr('Monthly Budget Health', 'Afya ya Bajeti ya Mwezi'),
                              value: isBusinessContext ? _fmtCompactAmount(totalCash) : '${budgetHealth.round()}%',
                              icon: isBusinessContext
                                  ? Icons.trending_up
                                  : Icons.favorite_outline,
                              color: isBusinessContext
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _KPICard(
                              title: isBusinessContext
                                ? _tr('Active Clients', 'Wateja Hai')
                                : _tr('Tracked Expenses', 'Matumizi Yanayofuatiliwa'),
                              value: isBusinessContext
                                  ? '$customerCount'
                                  : '${expenseItems.length}',
                              icon: isBusinessContext
                                  ? Icons.people_outline
                                  : Icons.receipt_long_outlined,
                              color: isBusinessContext
                                  ? AppColors.primary
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      )
                    else
                      const _DashboardLoadingStrip(),
                    const SizedBox(height: 24),
                    if (_showHeavyContent)
                      if (isBusinessContext)
                        _DebtQuickView(debts: debtItems)
                      else
                        const _PersonalFinanceQuickView()
                    else
                      const _DashboardLoadingCard(),
                    const SizedBox(height: 32),
                    Text(
                      isBusinessContext
                          ? _tr('Sales Performance', 'Utendaji wa Mauzo')
                          : _tr('Mwenendo wa Pesa Binafsi', 'Mwenendo wa Pesa Binafsi'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isBusinessContext
                              ? _tr('Last 7 days revenue trend with peak and average markers.', 'Mwenendo wa mapato ya siku 7 zilizopita na alama za kilele na wastani.')
                              : _tr('Weekly flow of income and spending, including upcoming pressure points.', 'Mtiririko wa wiki wa mapato na matumizi, ukiwemo msukumo wa gharama unaokuja.'),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isBusinessContext
                                ? '${customerCount >= 1 ? '+' : ''}${(customerCount * 1.2).toStringAsFixed(1)}%'
                                : '${budgetHealth >= 0 ? '+' : ''}${budgetHealth.toStringAsFixed(1)}%',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_showHeavyContent)
                      _ChartLegendRow(
                        isBusinessContext: isBusinessContext,
                        showPersonalIncome: _showPersonalIncome,
                        showPersonalExpense: _showPersonalExpense,
                        onToggleIncome: isBusinessContext
                            ? null
                            : () {
                                setState(() {
                                  _showPersonalIncome = !_showPersonalIncome;
                                });
                                unawaited(_persistChartVisibilityPrefs());
                              },
                        onToggleExpense: isBusinessContext
                            ? null
                            : () {
                                setState(() {
                                  _showPersonalExpense = !_showPersonalExpense;
                                });
                                unawaited(_persistChartVisibilityPrefs());
                              },
                      )
                    else
                      const _DashboardLoadingPillRow(),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: _showHeavyContent
                          ? _SalesLineChart(
                              isBusinessContext: isBusinessContext,
                              showPersonalIncome: _showPersonalIncome,
                              showPersonalExpense: _showPersonalExpense,
                              expenses: expenseItems,
                              debts: debtItems,
                            )
                          : const _DashboardChartPlaceholder(),
                    ),
                    const SizedBox(height: 32),
                    _showHeavyContent
                        ? _RecentTransactionsList(
                            title: isBusinessContext
                                ? _tr('Recent Transactions', 'Miamala ya Karibuni')
                                : _tr('Recent Personal Activity', 'Shughuli za Kibinafsi za Karibuni'),
                            expenses: expenseItems,
                            debts: debtItems,
                          )
                        : const _DashboardLoadingList(),
                  ],
                ),
              );
            },
          ),
          if (_showEntryReward)
            Positioned(
              top: 62,
              right: 38,
              child: EmotionalSuccessBurst(
                trigger: _entryRewardTrigger,
                color: AppColors.primaryDark,
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardLoadingStrip extends StatelessWidget {
  const _DashboardLoadingStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _DashboardLoadingCard(),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _DashboardLoadingCard(),
        ),
      ],
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: ShimmerBox(
          width: 120,
          height: 12,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      ),
    );
  }
}

class _DashboardLoadingPillRow extends StatelessWidget {
  const _DashboardLoadingPillRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DashboardLoadingPill(),
        _DashboardLoadingPill(),
      ],
    );
  }
}

class _DashboardLoadingPill extends StatelessWidget {
  const _DashboardLoadingPill();

  @override
  Widget build(BuildContext context) {
    return const ShimmerBox(
      width: 84,
      height: 28,
      borderRadius: BorderRadius.all(Radius.circular(999)),
    );
  }
}

class _DashboardChartPlaceholder extends StatelessWidget {
  const _DashboardChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: ShimmerBox(
          width: 140,
          height: 12,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      ),
    );
  }
}

class _DashboardLoadingList extends StatelessWidget {
  const _DashboardLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 8),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  ShimmerBox(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(14))),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 180, height: 12, borderRadius: BorderRadius.all(Radius.circular(999))),
                        SizedBox(height: 8),
                        ShimmerBox(width: 120, height: 10, borderRadius: BorderRadius.all(Radius.circular(999))),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  ShimmerBox(width: 64, height: 12, borderRadius: BorderRadius.all(Radius.circular(999))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeaderSkeleton extends StatelessWidget {
  const _DashboardHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: 220,
                height: 18,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              SizedBox(height: 10),
              ShimmerBox(
                width: 260,
                height: 12,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        ShimmerBox(width: 72, height: 72, borderRadius: BorderRadius.all(Radius.circular(18))),
      ],
    );
  }
}

class _DebtQuickView extends StatelessWidget {
  final List<dynamic> debts;
  const _DebtQuickView({required this.debts});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRouter.debtPath),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.error.withValues(alpha: 0.05)],
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Debt Exposure', 'Mzigo wa Madeni'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _fmtCompactAmount(debts.fold<double>(0, (total, debt) => total + _numericValue(debt.amount))),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.error,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _tr('PAYABLE', 'DENI LA KULIPA'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.error,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalFinanceQuickView extends StatelessWidget {
  const _PersonalFinanceQuickView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Personal Focus', 'Kipaumbele Binafsi'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _tr('Quickly jump into your personal priorities.', 'Nenda haraka kwenye vipaumbele vyako binafsi.'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickRouteCard(
                  icon: Icons.payments_outlined,
                  title: _tr('Expenses', 'Matumizi'),
                  subtitle: _tr('Track spending', 'Fuatilia matumizi'),
                  route: AppRouter.expensesPath,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickRouteCard(
                  icon: Icons.account_balance_rounded,
                  title: _tr('Debt', 'Madeni'),
                  subtitle: _tr('Obligations', 'Simamia majukumu'),
                  route: AppRouter.debtPath,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickRouteCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: _tr('Cash Flow', 'Mtiririko wa Fedha'),
                  subtitle: _tr('Plan this week', 'Panga wiki hii'),
                  route: AppRouter.cashFlowPath,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickRouteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _QuickRouteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.secondary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  final bool isBusinessContext;
  final bool showPersonalIncome;
  final bool showPersonalExpense;
  final List<dynamic> expenses;
  final List<dynamic> debts;

  const _SalesLineChart({
    required this.isBusinessContext,
    required this.showPersonalIncome,
    required this.showPersonalExpense,
    required this.expenses,
    required this.debts,
  });

  @override
  Widget build(BuildContext context) {
    final businessSalesPoints = _buildSpotsFromAmountStrings(
      debts
          .where((debt) => (debt.type as String?)?.toLowerCase() == 'receivable')
          .map((debt) => debt.amount as String?)
          .toList(),
    );
    final personalIncomePoints = _buildSpotsFromAmountStrings(
      debts
          .where((debt) => (debt.type as String?)?.toLowerCase() == 'receivable')
          .map((debt) => debt.amount as String?)
          .toList(),
    );
    final personalExpensePoints = _buildSpotsFromAmountStrings(
      expenses.map((expense) => expense.amount as String?).toList(),
    );

    final unit = isBusinessContext ? 'M' : 'k';
    final lineBarsData = <LineChartBarData>[];
    final seriesNames = <String>[];

    if (isBusinessContext) {
      seriesNames.add(_tr('Sales', 'Mauzo'));
      lineBarsData.add(
        LineChartBarData(
          spots: businessSalesPoints,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final isPeak = spot.y >= 5;
              return FlDotCirclePainter(
                radius: isPeak ? 4.8 : 3.6,
                color: isPeak ? AppColors.success : AppColors.primary,
                strokeWidth: 1.5,
                strokeColor: AppColors.background,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.primary.withValues(alpha: 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    } else {
      if (showPersonalIncome) {
        seriesNames.add(_tr('Income', 'Mapato'));
        lineBarsData.add(
          LineChartBarData(
            spots: personalIncomePoints,
            isCurved: true,
            color: AppColors.success,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.6,
                color: AppColors.success,
                strokeWidth: 1.5,
                strokeColor: AppColors.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.28),
                  AppColors.success.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
      }

      if (showPersonalExpense) {
        seriesNames.add(_tr('Expense', 'Matumizi'));
        lineBarsData.add(
          LineChartBarData(
            spots: personalExpensePoints,
            isCurved: true,
            color: AppColors.error,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.4,
                color: AppColors.error,
                strokeWidth: 1.2,
                strokeColor: AppColors.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withValues(alpha: 0.18),
                  AppColors.error.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
      }
    }

    if (lineBarsData.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _tr('Select a series to view the chart', 'Chagua mfululizo kuona chati'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: isBusinessContext ? 6.0 : 4.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.glassBorder.withValues(alpha: 0.45),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 2,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${value.toStringAsFixed(0)}$unit',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final days = [
                  _tr('Mon', 'Jt3'),
                  _tr('Tue', 'Jn4'),
                  _tr('Wed', 'Jt5'),
                  _tr('Thu', 'Alh'),
                  _tr('Fri', 'Ijm'),
                  _tr('Sat', 'Jm1'),
                  _tr('Sun', 'Jp2'),
                ];
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.secondary,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final seriesName = spot.barIndex < seriesNames.length
                    ? seriesNames[spot.barIndex]
                    : _tr('Series', 'Mfululizo');
                return LineTooltipItem(
                  '$seriesName: TSh ${spot.y.toStringAsFixed(1)}$unit',
                  Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: lineBarsData,
      ),
    );
  }
}

class _ChartLegendRow extends StatelessWidget {
  final bool isBusinessContext;
  final bool showPersonalIncome;
  final bool showPersonalExpense;
  final VoidCallback? onToggleIncome;
  final VoidCallback? onToggleExpense;

  const _ChartLegendRow({
    required this.isBusinessContext,
    required this.showPersonalIncome,
    required this.showPersonalExpense,
    required this.onToggleIncome,
    required this.onToggleExpense,
  });

  @override
  Widget build(BuildContext context) {
    final chips = isBusinessContext
        ? [
            _LegendChip(
              label: _tr('Sales', 'Mauzo'),
              color: AppColors.primary,
              selected: true,
            ),
          ]
        : <Widget>[
            _LegendChip(
              label: _tr('Income', 'Mapato'),
              color: AppColors.success,
              selected: showPersonalIncome,
              onTap: onToggleIncome,
            ),
            _LegendChip(
              label: _tr('Expense', 'Matumizi'),
              color: AppColors.error,
              selected: showPersonalExpense,
              onTap: onToggleExpense,
            ),
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _LegendChip({
    required this.label,
    required this.color,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? color.withValues(alpha: 0.12)
        : AppColors.surface.withValues(alpha: 0.45);
    final borderColor = selected
        ? color.withValues(alpha: 0.22)
        : AppColors.border.withValues(alpha: 0.8);

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.secondary : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  final String title;
  final List<dynamic> expenses;
  final List<dynamic> debts;

  const _RecentTransactionsList({
    this.title = 'Recent Transactions',
    this.expenses = const [],
    this.debts = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                _tr('View All', 'Ona Zote'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _items[index];
            final isExpense = item['kind'] == 'expense';
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isExpense ? AppColors.error : AppColors.success)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExpense
                        ? Icons.north_east_rounded
                        : Icons.south_west_rounded,
                    color: isExpense ? AppColors.error : AppColors.success,
                    size: 20,
                  ),
                ),
                title: Text(
                  item['title'] as String,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                ),
                subtitle: Text(
                  item['subtitle'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                ),
                trailing: Text(
                  item['amount'] as String,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isExpense ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Map<String, String>> get _items {
    final expenseItems = expenses.take(3).map((expense) {
      final amount = _fmtCompactAmount(_numericValue(expense.amount));
      final category = (expense.category as String?)?.trim().isNotEmpty == true
          ? expense.category as String
          : _tr('Expense', 'Matumizi');
      final date = (expense.date as String?)?.trim().isNotEmpty == true
          ? expense.date as String
          : '-';
      return <String, String>{
        'kind': 'expense',
        'title': category,
        'subtitle': '${_tr('Expense', 'Matumizi')}  $date',
        'amount': '-$amount',
      };
    });

    final debtItems = debts.take(3).map((debt) {
      final amount = _fmtCompactAmount(_numericValue(debt.amount));
      final party = (debt.partyName as String?)?.trim().isNotEmpty == true
          ? debt.partyName as String
          : _tr('Debt item', 'Kipengee cha deni');
      final type = (debt.type as String?)?.toLowerCase() == 'receivable'
          ? _tr('Receivable', 'Inayodaiwa')
          : _tr('Payable', 'Inayolipwa');
      final sign = (debt.type as String?)?.toLowerCase() == 'receivable' ? '+' : '-';
      return <String, String>{
        'kind': 'debt',
        'title': party,
        'subtitle': '$type  ${debt.dueDate}',
        'amount': '$sign$amount',
      };
    });

    final merged = <Map<String, String>>[
      ...expenseItems,
      ...debtItems,
    ];
    return merged.isEmpty
        ? <Map<String, String>>[
            {
              'kind': 'debt',
              'title': _tr('No activity yet', 'Bado hakuna shughuli'),
              'subtitle': _tr('Add transactions to see activity here.', 'Ongeza miamala ili kuona shughuli hapa.'),
              'amount': _fmtCompactAmount(0),
            },
          ]
        : merged.take(4).toList();
  }
}

double _numericValue(Object? raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toDouble();
  final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(cleaned) ?? 0;
}

String _fmtCompactAmount(double amount) {
  if (amount >= 1000000) return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
  return 'TSh ${amount.toStringAsFixed(0)}';
}

String _displayName(Map<String, dynamic>? profile) {
  final explicit = (profile?['displayName'] as String?)?.trim();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final fallback = (profile?['name'] as String?)?.trim();
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return 'there';
}

List<FlSpot> _buildSpotsFromAmountStrings(List<String?> values) {
  final source = values
      .map(_numericValue)
      .where((value) => value > 0)
      .take(7)
      .toList();

  if (source.isEmpty) {
    return List<FlSpot>.generate(7, (index) => FlSpot(index.toDouble(), 0));
  }

  final max = source.reduce((a, b) => a > b ? a : b);
  final normalized = source
      .map((value) => max == 0 ? 0.0 : (value / max) * 5)
      .toList();
  while (normalized.length < 7) {
    normalized.insert(0, 0);
  }
  return List<FlSpot>.generate(
    7,
    (index) => FlSpot(index.toDouble(), normalized[index]),
  );
}
