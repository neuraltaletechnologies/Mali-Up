import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/routing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../debt/data/debt_providers.dart';

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
  Timer? _clockTimer;
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchUserProfile();
    _loadChartVisibilityPrefs();
    _showFirstEntryRewardIfNeeded();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    if (hour >= 21) return 'Good night';
    return 'Good midnight';
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
    final customers = ref.watch(customerListProvider);
    final debts = ref.watch(debtListProvider);
    final customerCount =
        customers.maybeWhen(data: (items) => items.length, orElse: () => 0);
    final debtItems =
        debts.maybeWhen(data: (items) => items, orElse: () => const []);

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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_timeBasedGreeting()}, Neuraltale',
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
                                    ? "Here's what's happening in your business today"
                                    : "Here's your personal money pulse for today",
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
                    Row(
                      children: [
                        Expanded(
                          child: _KPICard(
                            title: isBusinessContext
                                ? 'Today Revenue'
                                : 'Monthly Budget Health',
                            value: isBusinessContext ? 'TSh 1.2M' : '78%',
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
                                ? 'Active Clients'
                                : 'Tracked Expenses',
                            value: isBusinessContext
                                ? '$customerCount'
                                : '${debtItems.length + 12}',
                            icon: isBusinessContext
                                ? Icons.people_outline
                                : Icons.receipt_long_outlined,
                            color: isBusinessContext
                                ? AppColors.primary
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (isBusinessContext)
                      _DebtQuickView(debts: debtItems)
                    else
                      const _PersonalFinanceQuickView(),
                    const SizedBox(height: 32),
                    Text(
                      isBusinessContext
                          ? 'Sales Performance'
                          : 'Personal Cash Trend',
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
                                ? 'Last 7 days revenue trend with peak and average markers.'
                                : 'Weekly flow of income and spending, including upcoming pressure points.',
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
                            isBusinessContext ? '+12.4%' : '+4.8%',
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
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: _SalesLineChart(
                        isBusinessContext: isBusinessContext,
                        showPersonalIncome: _showPersonalIncome,
                        showPersonalExpense: _showPersonalExpense,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _RecentTransactionsList(
                      title: isBusinessContext
                          ? 'Recent Transactions'
                          : 'Recent Personal Activity',
                    ),
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
                  'Debt Exposure',
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
                      'TSh 4.2M',
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
                        'PAYABLE',
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
            'Personal Focus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quickly jump into your personal priorities.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _QuickRouteCard(
                  icon: Icons.payments_outlined,
                  title: 'Expenses',
                  subtitle: 'Track spending',
                  route: AppRouter.expensesPath,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _QuickRouteCard(
                  icon: Icons.account_balance_rounded,
                  title: 'Debt',
                  subtitle: 'Manage obligations',
                  route: AppRouter.debtPath,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _QuickRouteCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Cash Flow',
                  subtitle: 'Plan this week',
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

  const _SalesLineChart({
    required this.isBusinessContext,
    required this.showPersonalIncome,
    required this.showPersonalExpense,
  });

  @override
  Widget build(BuildContext context) {
    const businessSalesPoints = <FlSpot>[
      FlSpot(0, 3),
      FlSpot(1, 1.5),
      FlSpot(2, 4.2),
      FlSpot(3, 2.8),
      FlSpot(4, 5.1),
      FlSpot(5, 3.6),
      FlSpot(6, 4.4),
    ];

    const personalIncomePoints = <FlSpot>[
      FlSpot(0, 2.8),
      FlSpot(1, 2.2),
      FlSpot(2, 3.4),
      FlSpot(3, 2.6),
      FlSpot(4, 3.2),
      FlSpot(5, 2.5),
      FlSpot(6, 3.0),
    ];

    const personalExpensePoints = <FlSpot>[
      FlSpot(0, 1.6),
      FlSpot(1, 1.9),
      FlSpot(2, 1.7),
      FlSpot(3, 2.1),
      FlSpot(4, 1.8),
      FlSpot(5, 2.0),
      FlSpot(6, 1.7),
    ];

    final unit = isBusinessContext ? 'M' : 'k';
    final lineBarsData = <LineChartBarData>[];
    final seriesNames = <String>[];

    if (isBusinessContext) {
      seriesNames.add('Sales');
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
        seriesNames.add('Income');
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
        seriesNames.add('Expense');
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
            'Select a series to view the chart',
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
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
                    : 'Series';
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
        ? const [
            _LegendChip(
              label: 'Sales',
              color: AppColors.primary,
              selected: true,
            ),
          ]
        : <Widget>[
            _LegendChip(
              label: 'Income',
              color: AppColors.success,
              selected: showPersonalIncome,
              onTap: onToggleIncome,
            ),
            _LegendChip(
              label: 'Expense',
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

  const _RecentTransactionsList({
    this.title = 'Recent Transactions',
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
                'View All',
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
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final isExpense = index % 2 != 0;
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
                  isExpense ? 'Shop Rent Payment' : 'Product Sale #2409',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                ),
                subtitle: Text(
                  isExpense
                      ? 'Expense  Oct 01, 2026'
                      : 'Revenue  Today, 10:45 AM',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                ),
                trailing: Text(
                  isExpense ? '-850,000' : '+45,000',
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
}
