import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/routing.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../debt/presentation/screens/debt_tracking_screen.dart';
import '../../../finance/data/finance_providers.dart';
import '../../../finance/domain/models/cash_account.dart';
import '../../../finance/domain/models/expense.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../rbac/data/rbac_providers.dart';
import '../../../sales/data/sales_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ── Period selector enum ──────────────────────────────────────────────────────
enum _DashPeriod { today, week, month, year }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _firstRewardSeenKey = 'dashboard_first_reward_seen';

  int _entryRewardTrigger = 0;
  bool _showEntryReward = false;
  bool _showHeavyContent = false;
  _DashPeriod _selectedPeriod = _DashPeriod.week;
  Timer? _clockTimer;
  Future<Map<String, dynamic>?> _profileFuture = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _profileFuture = _fetchUserProfile();
        _showHeavyContent = true;
      });
      _showFirstEntryRewardIfNeeded();
      _checkWebsiteInterestNudge();
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return _tr('Good morning', 'Habari za asubuhi');
    if (hour >= 12 && hour < 17) return _tr('Good afternoon', 'Habari za mchana');
    if (hour >= 17 && hour < 21) return _tr('Good evening', 'Habari za jioni');
    if (hour >= 21) return _tr('Good night', 'Usiku mwema');
    return _tr('Good midnight', 'Usiku wa manane mwema');
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

  Future<void> _checkWebsiteInterestNudge() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool('pending_website_interest') ?? false;
    if (!pending || !mounted) return;
    await prefs.remove('pending_website_interest');
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    showAppSheet<void>(
      context,
      builder: (_) => const _WebsiteInterestSheet(),
    );
  }

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions());
      return snapshot.data() ?? {};
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return {};
    }
  }

  String? _getBusinessName(Map<String, dynamic>? profile) {
    final businesses = profile?['businesses'];
    if (businesses is! List || businesses.isEmpty) return null;
    final selectedId = profile?['selectedBusinessId'] as String?;
    final business = selectedId != null
        ? businesses.whereType<Map>().cast<Map<String, dynamic>>().firstWhere(
            (b) => b['id'] == selectedId,
            orElse: () => businesses.first as Map<String, dynamic>,
          )
        : businesses.first as Map<String, dynamic>;
    return (business['name'] as String?)?.trim();
  }

  String? _getBusinessLogoUrl(Map<String, dynamic>? profile) {
    final businesses = profile?['businesses'];
    if (businesses is! List || businesses.isEmpty) return null;
    final selectedId = profile?['selectedBusinessId'] as String?;
    final business = selectedId != null
        ? businesses.whereType<Map>().cast<Map<String, dynamic>>().firstWhere(
            (b) => b['id'] == selectedId,
            orElse: () => businesses.first as Map<String, dynamic>,
          )
        : businesses.first as Map<String, dynamic>;
    return (business['logoUrl'] as String?)?.trim();
  }

  String? _getBusinessPlan(Map<String, dynamic>? profile) {
    final businesses = profile?['businesses'];
    if (businesses is! List || businesses.isEmpty) return null;
    final selectedId = profile?['selectedBusinessId'] as String?;
    final business = selectedId != null
        ? businesses.whereType<Map>().cast<Map<String, dynamic>>().firstWhere(
            (b) => b['id'] == selectedId,
            orElse: () => businesses.first as Map<String, dynamic>,
          )
        : businesses.first as Map<String, dynamic>;
    return (business['plan'] as String?)?.trim();
  }

  @override
  Widget build(BuildContext context) {
    // ── Data ────────────────────────────────────────────────────────────────
    final permissions = ref.watch(permissionServiceProvider);
    final customers = ref.watch(customerListProvider);
    final customerCount = customers.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
    final AsyncValue<List<Expense>> expenses = ref.watch(expenseListProvider);
    final AsyncValue<List<CashAccount>> cashAccounts = ref.watch(
      cashAccountListProvider,
    );
    final expenseItems = expenses.maybeWhen(
      data: (items) => items,
      orElse: () => const <Expense>[],
    );
    final cashAccountItems = cashAccounts.maybeWhen(
      data: (items) => items,
      orElse: () => const <CashAccount>[],
    );
    final now2 = DateTime.now();
    final monthExpenses = expenseItems.where((e) {
      final d = DateTime.tryParse(e.date);
      return d != null && d.year == now2.year && d.month == now2.month;
    }).fold<double>(0, (t, e) => t + _numericValue(e.amount));
    final totalCash = cashAccountItems.fold<double>(0, (t, a) => t + a.balance);
    final salesAsyncValue = ref.watch(salesInvoiceListProvider);
    final salesItems = salesAsyncValue.maybeWhen(
      data: (items) => items,
      orElse: () => const <Map<String, dynamic>>[],
    );
    final activityLoading = expenses.isLoading || salesAsyncValue.isLoading;
    final inventoryItems = ref
        .watch(inventoryItemListProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <Map<String, dynamic>>[],
        );

    // ── Revenue calculations ─────────────────────────────────────────────────
    final todayRevenue = _revenueForPeriod(salesItems, 0);
    final weekRevenue = _revenueForPeriod(salesItems, 6);
    final monthRevenue = _monthRevenue(salesItems);
    final yearRevenue = _yearRevenue(salesItems);
    final yesterdayRevenue = _revenueForRange(salesItems, 1, 1);
    final lastWeekRevenue = _revenueForRange(salesItems, 13, 7);
    final lastMonthRevenue = _revenueForLastMonth(salesItems);

    final selectedRevenue = switch (_selectedPeriod) {
      _DashPeriod.today => todayRevenue,
      _DashPeriod.week => weekRevenue,
      _DashPeriod.month => monthRevenue,
      _DashPeriod.year => yearRevenue,
    };
    final comparisonRevenue = switch (_selectedPeriod) {
      _DashPeriod.today => yesterdayRevenue,
      _DashPeriod.week => lastWeekRevenue,
      _DashPeriod.month => lastMonthRevenue,
      _DashPeriod.year => 0.0,
    };
    final periodChange = comparisonRevenue > 0
        ? ((selectedRevenue - comparisonRevenue) / comparisonRevenue * 100)
        : (selectedRevenue > 0 ? 100.0 : 0.0);

    // ── Profit snapshot inputs ──────────────────────────────────────────────
    final netProfit = monthRevenue - monthExpenses;

    // ── Receivables ──────────────────────────────────────────────────────────
    final now = DateTime.now();
    final unpaidSales = salesItems.where((inv) {
      final s = readInvoiceStatus(inv).toLowerCase();
      return s == 'unpaid' || s == 'partial';
    }).toList();
    final totalOutstanding = unpaidSales.fold<double>(0, (total, inv) {
      final amt = parseNumericAmount(inv['amount']);
      final paid = parseNumericAmount(inv['amountPaid']);
      return total + (amt - paid).clamp(0.0, amt);
    });
    double aging30 = 0, aging60 = 0, aging90plus = 0;
    int overdueCount = 0;
    for (final inv in unpaidSales) {
      final d = readTimestamp(inv['createdAt']);
      if (d == null) continue;
      final age = now.difference(d).inDays;
      final balance =
          parseNumericAmount(inv['amount']) -
          parseNumericAmount(inv['amountPaid']);
      if (age > 30) { overdueCount++; }
      if (age <= 30) {
        aging30 += balance;
      } else if (age <= 60) {
        aging60 += balance;
      } else {
        aging90plus += balance;
      }
    }

    // ── Low stock ────────────────────────────────────────────────────────────
    final lowStockItems = inventoryItems.where((item) {
      final stock = parseStock(item['currentStock'] ?? item['stock']);
      final reorder = parseStock(item['reorderPoint'] ?? 5);
      return stock <= reorder;
    }).toList();

    // ── Chart data ───────────────────────────────────────────────────────────
    final chartData = _buildChartData(salesItems);
    final chartSpots = chartData.spots;
    final dailyValues = chartData.dailyValues;

    // ── Date label ───────────────────────────────────────────────────────────
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdaysSw = ['Jt3', 'Jn4', 'Jt5', 'Alh', 'Ijm', 'Jm1', 'Jp2'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateLabel =
        '${_tr(weekdays[now.weekday - 1], weekdaysSw[now.weekday - 1])}, ${now.day} ${months[now.month - 1]}';

    // ── Insights ─────────────────────────────────────────────────────────────
    final insights = _generateInsights(
      weekRevenue: weekRevenue,
      lastWeekRevenue: lastWeekRevenue,
      salesItems: salesItems,
      lowStockCount: lowStockItems.length,
      lowStockItems: lowStockItems,
      totalOutstanding: totalOutstanding,
      netProfit: netProfit,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 8,
                  20,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting header ──────────────────────────────────
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
                                  dateLabel,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.4,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_timeBasedGreeting()}, ${_displayName(snapshot.data)} 👋',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.secondary,
                                        height: 1.2,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tr(
                                    "Here's your business at a glance",
                                    'Muhtasari wa biashara yako leo',
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const EmotionalLottieSpot(
                            scene: EmotionalLottieScene.dashboard,
                            size: 64,
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // ── Hero card ────────────────────────────────────────
                    if (_showHeavyContent)
                      _UnifiedHeroCard(
                        totalCash: totalCash,
                        monthRevenue: monthRevenue,
                        monthExpenses: monthExpenses,
                        customerCount: customerCount,
                        businessName: _getBusinessName(snapshot.data),
                        logoUrl: _getBusinessLogoUrl(snapshot.data),
                        plan: _getBusinessPlan(snapshot.data),
                      )
                    else
                      const _DashboardHeroSkeleton(),

                    const SizedBox(height: 24),

                    // ── Revenue snapshot + period switcher ───────────────
                    if (permissions.canViewSales || permissions.isOwner) ...[
                      _RevenueSnapshotCard(
                        selectedPeriod: _selectedPeriod,
                        revenue: selectedRevenue,
                        comparisonRevenue: comparisonRevenue,
                        periodChange: periodChange,
                        onPeriodChanged: (p) =>
                            setState(() => _selectedPeriod = p),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Outstanding receivables ──────────────────────────
                    if ((permissions.canViewDebt || permissions.isOwner) &&
                        totalOutstanding > 0) ...[
                      _OutstandingReceivablesCard(
                        totalOutstanding: totalOutstanding,
                        overdueCount: overdueCount,
                        aging30: aging30,
                        aging60: aging60,
                        aging90plus: aging90plus,
                        onViewAll: () => _openDebtPanel(context),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Sales Performance ────────────────────────────────
                    if (permissions.canViewSales || permissions.isOwner) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr('Sales Performance', 'Utendaji wa Mauzo'),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _tr('Last 7 days', 'Siku 7 zilizopita'),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          _ChangeBadge(
                            change: lastWeekRevenue > 0
                                ? ((weekRevenue - lastWeekRevenue) /
                                      lastWeekRevenue *
                                      100)
                                : (weekRevenue > 0 ? 100.0 : 0.0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _ChartLegendRow(),
                      const SizedBox(height: 14),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                        child: _SalesLineChart(
                          spots: chartSpots,
                          dailyValues: dailyValues,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Low stock alerts ─────────────────────────────────
                    if ((permissions.canViewInventory || permissions.isOwner) &&
                        lowStockItems.isNotEmpty) ...[
                      _LowStockAlertsSection(items: lowStockItems),
                      const SizedBox(height: 28),
                    ],

                    // ── Top Performers ───────────────────────────────────
                    if ((permissions.canViewSales || permissions.isOwner) &&
                        salesItems.isNotEmpty) ...[
                      _TopPerformersSection(salesItems: salesItems),
                      const SizedBox(height: 28),
                    ],

                    // ── Cash position ────────────────────────────────────
                    if ((permissions.canViewCashFlow || permissions.isOwner) &&
                        cashAccountItems.isNotEmpty) ...[
                      _CashPositionCard(
                        accounts: cashAccountItems,
                        totalCash: totalCash,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Business insights ────────────────────────────────
                    if (insights.isNotEmpty) ...[
                      _BusinessInsightsCard(insights: insights),
                      const SizedBox(height: 28),
                    ],

                    // ── Recent activity ──────────────────────────────────
                    _RecentTransactionsList(
                      title: _tr('Recent Activity', 'Shughuli za Karibuni'),
                      expenses: expenseItems,
                      salesItems: salesItems,
                      isLoading: activityLoading,
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

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _openDebtPanel(BuildContext context) {
    showAppSheet(
      context,
      builder: (_) => const ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: AppColors.background,
          child: DebtTrackingScreen(),
        ),
      ),
    );
  }
}

// ── Change badge ──────────────────────────────────────────────────────────────
class _ChangeBadge extends StatelessWidget {
  final double change;
  const _ChangeBadge({required this.change});

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Revenue Snapshot Card ─────────────────────────────────────────────────────
class _RevenueSnapshotCard extends StatelessWidget {
  final _DashPeriod selectedPeriod;
  final double revenue;
  final double comparisonRevenue;
  final double periodChange;
  final ValueChanged<_DashPeriod> onPeriodChanged;

  const _RevenueSnapshotCard({
    required this.selectedPeriod,
    required this.revenue,
    required this.comparisonRevenue,
    required this.periodChange,
    required this.onPeriodChanged,
  });

  String _periodLabel(_DashPeriod p) => switch (p) {
    _DashPeriod.today => _tr('Today', 'Leo'),
    _DashPeriod.week => _tr('Week', 'Wiki'),
    _DashPeriod.month => _tr('Month', 'Mwezi'),
    _DashPeriod.year => _tr('Year', 'Mwaka'),
  };

  String _comparisonLabel(_DashPeriod p) => switch (p) {
    _DashPeriod.today => _tr('vs yesterday', 'vs jana'),
    _DashPeriod.week => _tr('vs last week', 'vs wiki iliyopita'),
    _DashPeriod.month => _tr('vs last month', 'vs mwezi uliopita'),
    _DashPeriod.year => '',
  };

  @override
  Widget build(BuildContext context) {
    final isPositive = periodChange >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;
    final compLabel = _comparisonLabel(selectedPeriod);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _DashPeriod.values.map((p) {
                final selected = p == selectedPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onPeriodChanged(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.navyPrimary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? AppColors.navyPrimary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _periodLabel(p),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Revenue amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('Revenue', 'Mapato'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmtAmount(revenue),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navyPrimary,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (compLabel.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: changeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${periodChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      compLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Outstanding Receivables Card ──────────────────────────────────────────────
class _OutstandingReceivablesCard extends StatelessWidget {
  final double totalOutstanding;
  final int overdueCount;
  final double aging30;
  final double aging60;
  final double aging90plus;
  final VoidCallback onViewAll;

  const _OutstandingReceivablesCard({
    required this.totalOutstanding,
    required this.overdueCount,
    required this.aging30,
    required this.aging60,
    required this.aging90plus,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
                      _tr('Outstanding Receivables', 'Madeni Yanayosubiri'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmtAmount(totalOutstanding),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.error,
                        height: 1.0,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (overdueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$overdueCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.error,
                        ),
                      ),
                      Text(
                        _tr('Overdue', 'Imechelewa'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Aging chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (aging30 > 0)
                _AgingChip(
                  label: _tr('0–30 Days', 'Siku 0–30'),
                  amount: aging30,
                  color: AppColors.warning,
                ),
              if (aging60 > 0)
                _AgingChip(
                  label: _tr('31–60 Days', 'Siku 31–60'),
                  amount: aging60,
                  color: const Color(0xFFEA580C),
                ),
              if (aging90plus > 0)
                _AgingChip(
                  label: _tr('90+ Days', 'Siku 90+'),
                  amount: aging90plus,
                  color: AppColors.error,
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: Text(_tr('View All Debts', 'Ona Madeni Yote')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navyPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgingChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AgingChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _fmtCompactAmount(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cash Position Card ────────────────────────────────────────────────────────
class _CashPositionCard extends StatelessWidget {
  final List<CashAccount> accounts;
  final double totalCash;

  const _CashPositionCard({required this.accounts, required this.totalCash});

  @override
  Widget build(BuildContext context) {
    // Group by type
    final cash = accounts.where((a) => a.type.toLowerCase() == 'cash').toList();
    final mpesa = accounts
        .where((a) => a.type.toLowerCase().contains('mobile'))
        .toList();
    final bank = accounts.where((a) => a.type.toLowerCase() == 'bank').toList();

    final cashTotal = cash.fold(0.0, (s, a) => s + a.balance);
    final mpesaTotal = mpesa.fold(0.0, (s, a) => s + a.balance);
    final bankTotal = bank.fold(0.0, (s, a) => s + a.balance);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: AppColors.tealAccent,
              ),
              const SizedBox(width: 7),
              Text(
                _tr('Cash Position', 'Hali ya Fedha'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
              const Spacer(),
              Text(
                _fmtAmount(totalCash),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navyPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (cashTotal > 0)
                _CashChip(
                  icon: Icons.payments_outlined,
                  label: _tr('Cash', 'Taslimu'),
                  amount: cashTotal,
                  color: AppColors.success,
                ),
              if (mpesaTotal > 0)
                _CashChip(
                  icon: Icons.phone_android_rounded,
                  label: 'M-Pesa',
                  amount: mpesaTotal,
                  color: AppColors.tealAccent,
                ),
              if (bankTotal > 0)
                _CashChip(
                  icon: Icons.account_balance_rounded,
                  label: _tr('Bank', 'Benki'),
                  amount: bankTotal,
                  color: AppColors.navySecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _CashChip({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                _fmtCompactAmount(amount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Business Insights Card ────────────────────────────────────────────────────
class _BusinessInsightsCard extends StatelessWidget {
  final List<String> insights;

  const _BusinessInsightsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navyPrimary.withValues(alpha: 0.04),
            AppColors.tealAccent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.yellowBrand,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _tr('Business Insights', 'Mwanga wa Biashara'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tealAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton widgets ──────────────────────────────────────────────────────────

class _DashboardHeroSkeleton extends StatelessWidget {
  const _DashboardHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: 100,
            height: 12,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          SizedBox(height: 12),
          ShimmerBox(
            width: 180,
            height: 28,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              ShimmerBox(
                width: 80,
                height: 10,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              SizedBox(width: 24),
              ShimmerBox(
                width: 80,
                height: 10,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ],
          ),
        ],
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
        ShimmerBox(
          width: 72,
          height: 72,
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ],
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _UnifiedHeroCard extends StatefulWidget {
  final double totalCash;
  final double monthRevenue;
  final double monthExpenses;
  final int customerCount;
  final String? businessName;
  final String? logoUrl;
  final String? plan;

  const _UnifiedHeroCard({
    required this.totalCash,
    required this.monthRevenue,
    required this.monthExpenses,
    required this.customerCount,
    this.businessName,
    this.logoUrl,
    this.plan,
  });

  @override
  State<_UnifiedHeroCard> createState() => _UnifiedHeroCardState();
}

class _UnifiedHeroCardState extends State<_UnifiedHeroCard> {
  bool _detailsVisible = false;

  static const _gradA = Color(0xFF0A1628);
  static const _gradB = Color(0xFF0D2A4A);
  static const _gradC = Color(0xFF091520);

  @override
  Widget build(BuildContext context) {
    final name = widget.businessName ?? _tr('My Business', 'Biashara yangu');
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    final amountText = _detailsVisible
        ? _fmtCompactAmount(widget.totalCash)
        : '••••••';
    final clientsText = _detailsVisible ? '${widget.customerCount}' : '••';
    final expText = _detailsVisible
        ? _fmtCompactAmount(widget.monthExpenses)
        : '••••';
    final net = widget.monthRevenue - widget.monthExpenses;
    final netText = _detailsVisible ? _fmtCompactAmount(net) : '••••';
    final netColor = net >= 0
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AspectRatio(
          aspectRatio: 1.65,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [_gradA, _gradB, _gradC],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D1B3E).withValues(alpha: 0.65),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative arc — top-right
                Positioned(
                  right: -70,
                  top: -70,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                // Decorative arc — bottom-left (teal tint)
                Positioned(
                  left: -55,
                  bottom: -55,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tealAccent.withValues(alpha: 0.09),
                    ),
                  ),
                ),
                // Top shimmer line
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: chip | name + plan | logo ──────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _CardChip(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.yellowBrand,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (widget.plan ?? 'Trial').toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.42),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Business logo avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.yellowBrand,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.yellowBrand.withValues(
                                    alpha: 0.40,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: widget.logoUrl != null &&
                                    widget.logoUrl!.isNotEmpty
                                ? Image.network(
                                    widget.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _BusinessLogoFallback(initial: initial),
                                  )
                                : _BusinessLogoFallback(initial: initial),
                          ),
                        ],
                      ),

                      // Flexible space pushes balance down to vertical centre
                      const Spacer(),

                      // ── Balance section ──────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _tr('TOTAL BALANCE', 'JUMLA YA FEDHA'),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.48),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                  child: Text(
                                    amountText,
                                    key: ValueKey(_detailsVisible),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Eye toggle — framed button
                          GestureDetector(
                            onTap: () => setState(
                              () => _detailsVisible = !_detailsVisible,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Icon(
                                _detailsVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Stats row ────────────────────────────────────────
                      Row(
                        children: [
                          _CardStatItem(
                            label: _tr('Clients', 'Wateja'),
                            value: clientsText,
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          _CardStatItem(
                            label: _tr('Expenses', 'Gharama'),
                            value: expText,
                            color: expText == '••••'
                                ? null
                                : const Color(0xFFF87171),
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          _CardStatItem(
                            label: _tr('Net', 'Faida'),
                            value: netText,
                            color: netText == '••••' ? null : netColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessLogoFallback extends StatelessWidget {
  final String initial;
  const _BusinessLogoFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.yellowBrand,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.navyPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCFA23A), Color(0xFFEDC84A), Color(0xFFAF8520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7A5000).withValues(alpha: 0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 3, w - 8, h - 6),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawLine(Offset(w / 2, 3), Offset(w / 2, h - 3), paint);
    canvas.drawLine(Offset(4, h / 2), Offset(w - 4, h / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _CardStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _CardStatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Module grid ───────────────────────────────────────────────────────────────

class _ModuleGrid extends StatelessWidget {
  final bool showHeavyContent;

  const _ModuleGrid({required this.showHeavyContent});

  static const _modules = [
    (
      icon: Icons.payments_rounded,
      labelEn: 'Gharama zangu',
      labelSw: 'Gharama zangu',
      color: Color(0xFFD97706),
      route: AppRouter.expensesPath,
    ),
    (
      icon: Icons.account_balance_rounded,
      labelEn: 'Madeni',
      labelSw: 'Madeni',
      color: Color(0xFFDC2626),
      route: AppRouter.debtPath,
    ),
    (
      icon: Icons.account_balance_wallet_rounded,
      labelEn: 'Mtiririko wa Fedha',
      labelSw: 'Mtiririko wa Fedha',
      color: Color(0xFF7C3AED),
      route: AppRouter.cashFlowPath,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final itemCount = showHeavyContent ? _modules.length : 6;

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (!showHeavyContent) return const _HorizontalModuleSkeleton();

          final module = _modules[index];
          final label = _tr(module.labelEn, module.labelSw);
          return SizedBox(
            width: 96,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (module.route == AppRouter.debtPath) {
                    _openDebtPanelFromModule(context);
                    return;
                  }
                  context.go(module.route);
                },
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: module.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            module.icon,
                            size: 15,
                            color: module.color,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.secondary.withValues(alpha: 0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDebtPanelFromModule(BuildContext context) {
    showAppSheet(
      context,
      builder: (_) => const ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: AppColors.background,
          child: DebtTrackingScreen(),
        ),
      ),
    );
  }
}

class _HorizontalModuleSkeleton extends StatelessWidget {
  const _HorizontalModuleSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 96, child: ShimmerBox(height: 84));
  }
}

// ── Sales chart ───────────────────────────────────────────────────────────────

class _SalesLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Map<int, double> dailyValues;

  const _SalesLineChart({required this.spots, required this.dailyValues});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 6.0,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.glassBorder.withValues(alpha: 0.45),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final now = DateTime.now();
                final date = DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).subtract(Duration(days: 6 - value.toInt()));
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                const daysSw = [
                  'Jt3',
                  'Jn4',
                  'Jt5',
                  'Alh',
                  'Ijm',
                  'Jm1',
                  'Jp2',
                ];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _tr(days[date.weekday - 1], daysSw[date.weekday - 1]),
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
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.secondary,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final actual = dailyValues[spot.x.toInt()] ?? 0;
              return LineTooltipItem(
                '${_tr('Sales', 'Mauzo')}: ${_fmtCompactAmount(actual)}',
                Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) {
                final isPeak = spot.y >= 4.5;
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
        ],
      ),
    );
  }
}

// ── Chart legend ──────────────────────────────────────────────────────────────

class _ChartLegendRow extends StatelessWidget {
  const _ChartLegendRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _LegendChip(
          label: 'Sales / Mauzo',
          color: AppColors.primary,
          selected: true,
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;

  const _LegendChip({
    required this.label,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.surface.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.22)
                : AppColors.border.withValues(alpha: 0.8),
          ),
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
    );
  }
}

// ── Low Stock Alerts ──────────────────────────────────────────────────────────

class _LowStockAlertsSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _LowStockAlertsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _tr('Low Stock Alerts', 'Tahadhari ya Bidhaa Ndogo'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(AppRouter.inventoryPath),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _tr('View All', 'Ona Zote'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final name = (item['name'] ?? '').toString();
              final stock = parseStock(item['currentStock'] ?? item['stock']);
              final reorder = parseStock(item['reorderPoint'] ?? 5);
              final unit = (item['unit'] ?? 'pcs').toString();
              final isOut = stock <= 0;
              final alertColor = isOut ? AppColors.error : AppColors.warning;

              return InkWell(
                onTap: () => context.go(AppRouter.inventoryPath),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 138,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: alertColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOut
                                ? Icons.error_outline_rounded
                                : Icons.warning_amber_rounded,
                            size: 11,
                            color: alertColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOut
                                ? _tr('Out', 'Imekwisha')
                                : _tr('Low', 'Ndogo'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: alertColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        '$stock / $reorder $unit',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Top Performers ────────────────────────────────────────────────────────────

class _TopPerformersSection extends StatelessWidget {
  final List<Map<String, dynamic>> salesItems;

  const _TopPerformersSection({required this.salesItems});

  Map<String, double> _topProducts() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final result = <String, double>{};
    for (final inv in salesItems) {
      final ts = readTimestamp(inv['createdAt']);
      if (ts == null || ts.isBefore(monthStart)) continue;
      final invItems = (inv['items'] as List?)?.whereType<Map>().toList() ?? [];
      for (final item in invItems) {
        final name = (item['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        result[name] = (result[name] ?? 0) + parseNumericAmount(item['total']);
      }
    }
    return result;
  }

  Map<String, double> _topCustomers() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final result = <String, double>{};
    for (final inv in salesItems) {
      final ts = readTimestamp(inv['createdAt']);
      if (ts == null || ts.isBefore(monthStart)) continue;
      final key = (inv['customerName'] ?? '').toString().trim();
      if (key.isEmpty) continue;
      result[key] = (result[key] ?? 0) + parseNumericAmount(inv['amount']);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final products =
        (_topProducts().entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3)
            .toList();
    final customers =
        (_topCustomers().entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3)
            .toList();

    if (products.isEmpty && customers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Top Performers', 'Wabora wa Mwezi'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _tr('This month', 'Mwezi huu'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        if (products.isNotEmpty)
          _PerformerSubsection(
            icon: Icons.inventory_2_outlined,
            label: _tr('Best Products', 'Bidhaa Bora'),
            color: AppColors.tealAccent,
            entries: products,
          ),
        if (products.isNotEmpty && customers.isNotEmpty)
          const SizedBox(height: 10),
        if (customers.isNotEmpty)
          _PerformerSubsection(
            icon: Icons.star_outline_rounded,
            label: _tr('Top Customers', 'Wateja Bora'),
            color: AppColors.primary,
            entries: customers,
          ),
      ],
    );
  }
}

class _PerformerSubsection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<MapEntry<String, double>> entries;

  const _PerformerSubsection({
    required this.icon,
    required this.label,
    required this.color,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = entries.isNotEmpty ? entries.first.value : 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final rank = index + 1;
                final entry = entries[index];
                final pct = maxVal > 0
                    ? (entry.value / maxVal).clamp(0.0, 1.0)
                    : 0.0;
                return Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr('Performance', 'Utendaji'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: color.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(
                                color.withValues(alpha: 0.65),
                              ),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _fmtCompactAmount(entry.value),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Activity (date-grouped) ────────────────────────────────────────────

class _RecentTransactionsList extends StatelessWidget {
  final String title;
  final List<dynamic> expenses;
  final List<Map<String, dynamic>> salesItems;
  final bool isLoading;

  const _RecentTransactionsList({
    this.title = 'Recent Activity',
    this.expenses = const [],
    this.salesItems = const [],
    this.isLoading = false,
  });

  List<Map<String, dynamic>> get _sortedItems {
    final result = <Map<String, dynamic>>[];
    for (final inv in salesItems) {
      final date = readTimestamp(inv['createdAt']);
      final amount = parseNumericAmount(inv['amount']);
      final customer = (inv['customerName'] ?? '').toString().trim();
      result.add({
        'kind': 'sale',
        'title': customer.isEmpty
            ? _tr('Walk-in', 'Mteja wa kawaida')
            : customer,
        'subtitle': (inv['invoiceNumber'] ?? _tr('Sale', 'Mauzo')).toString(),
        'amount': '+${_fmtCompactAmount(amount)}',
        'date': date,
      });
    }
    for (final expense in expenses) {
      final amount = _numericValue(expense.amount);
      final category = (expense.category as String?)?.trim().isNotEmpty == true
          ? expense.category as String
          : _tr('Expense', 'Matumizi');
      final dateStr = (expense.date as String?)?.trim() ?? '';
      final date = DateTime.tryParse(dateStr);
      result.add({
        'kind': 'expense',
        'title': category,
        'subtitle': '${_tr('Expense', 'Matumizi')}  $dateStr',
        'amount': '-${_fmtCompactAmount(amount)}',
        'date': date,
      });
    }
    result.sort((a, b) {
      final da = a['date'] as DateTime?;
      final db = b['date'] as DateTime?;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return result.take(20).toList();
  }

  String _groupLabel(DateTime? date) {
    if (date == null) return _tr('Earlier', 'Mapema');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return _tr('Today', 'Leo');
    if (diff == 1) return _tr('Yesterday', 'Jana');
    if (diff <= 7) return _tr('This Week', 'Wiki Hii');
    return _tr('Earlier', 'Mapema');
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedItems;

    // Build grouped list
    final grouped = <Map<String, dynamic>>[];
    String? lastLabel;
    for (final item in items) {
      final label = _groupLabel(item['date'] as DateTime?);
      if (label != lastLabel) {
        grouped.add({'type': 'header', 'label': label});
        lastLabel = label;
      }
      grouped.add({'type': 'item', ...item});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
        const SizedBox(height: 12),
        if (isLoading)
          Column(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ShimmerBox(
                  width: double.infinity,
                  height: 64,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ),
          )
        else if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: 10),
                Text(
                  _tr(
                    'No activity yet. Your business is ready\nfor its first transaction.',
                    'Bado hakuna shughuli. Biashara yako\niko tayari kwa muamala wa kwanza.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final row = grouped[index];
              if (row['type'] == 'header') {
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12, bottom: 8),
                  child: Text(
                    row['label'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }

              final isSale = row['kind'] == 'sale';
              final amountStr = row['amount'] as String;
              final isPositive = amountStr.startsWith('+');

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            (isPositive ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        isSale
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: isPositive ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      row['title'] as String,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      row['subtitle'] as String,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      amountStr,
                      style: TextStyle(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
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

// ── Website nudge ─────────────────────────────────────────────────────────────

class _WebsiteInterestSheet extends StatefulWidget {
  const _WebsiteInterestSheet();

  @override
  State<_WebsiteInterestSheet> createState() => _WebsiteInterestSheetState();
}

class _WebsiteInterestSheetState extends State<_WebsiteInterestSheet> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _WebsiteRequirementsForm(
        onDone: () => Navigator.of(context).pop(),
      );
    }
    return _WebsiteNudgeBanner(
      onGetStarted: () => setState(() => _showForm = true),
      onDismiss: () => Navigator.of(context).pop(),
    );
  }
}

class _WebsiteNudgeBanner extends StatelessWidget {
  const _WebsiteNudgeBanner({
    required this.onGetStarted,
    required this.onDismiss,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.yellowBrand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _tr(
                    "Let's build you a website for your business?",
                    'Tujenge tovuti ya biashara yako?',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _tr(
              'Get a professional website designed for your business and start reaching more customers online.',
              'Pata tovuti ya kitaalamu iliyoundwa kwa biashara yako na uanze kufikia wateja zaidi mtandaoni.',
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: AppColors.yellowBrand,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onGetStarted,
              child: Text(
                _tr('Get Started', 'Anza Sasa'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: onDismiss,
              child: Text(
                _tr('Maybe Later', 'Labda Baadaye'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteRequirementsForm extends StatefulWidget {
  const _WebsiteRequirementsForm({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_WebsiteRequirementsForm> createState() =>
      _WebsiteRequirementsFormState();
}

class _WebsiteRequirementsFormState extends State<_WebsiteRequirementsForm> {
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      widget.onDone();
      return;
    }
    setState(() => _submitting = true);
    try {
      String personName = '', businessName = '', businessType = '', phone = '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data() ?? {};
        personName =
            ((data['displayName'] ?? data['name']) as String?)?.trim() ?? '';
        phone = (data['phone'] as String?)?.trim() ?? user.phoneNumber ?? '';
        final businesses = data['businesses'];
        if (businesses is List && businesses.isNotEmpty) {
          final biz = businesses.first as Map;
          businessName = (biz['name'] as String?)?.trim() ?? '';
          businessType = (biz['category'] as String?)?.trim() ?? '';
        }
      } catch (_) {}

      final notes = _notesCtrl.text.trim();
      final msg = _buildWhatsAppMessage(
        personName: personName.isNotEmpty
            ? personName
            : _tr('Business Owner', 'Mmiliki wa Biashara'),
        businessName: businessName,
        businessType: businessType,
        phone: phone,
        notes: notes,
      );
      final whatsappLaunch = _launchWhatsApp(msg);

      try {
        await FirebaseFirestore.instance
            .collection('websiteRequests')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'personName': personName,
              'businessName': businessName,
              'businessType': businessType,
              'phone': phone,
              'notes': notes,
              'requestedAt': FieldValue.serverTimestamp(),
              'status': 'pending',
            }, SetOptions(merge: true));
      } catch (_) {}

      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
      }

      final opened = await whatsappLaunch;
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                'Could not open WhatsApp. Please make sure it is installed.',
                'Imeshindwa kufungua WhatsApp. Hakikisha imesakinishwa.',
              ),
            ),
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 1600));
      if (mounted) widget.onDone();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _buildWhatsAppMessage({
    required String personName,
    required String businessName,
    required String businessType,
    required String phone,
    required String notes,
  }) {
    final b = StringBuffer();
    b.writeln(
      _tr(
        'Hello Neuraltale Technologies Team,',
        'Habari Timu ya Neuraltale Technologies,',
      ),
    );
    b.writeln();
    b.writeln(
      _tr(
        'I would like assistance creating a website for my business.',
        'Ningependa msaada wa kuunda tovuti kwa biashara yangu.',
      ),
    );
    b.writeln();
    b.writeln('${_tr("Name", "Jina")}: $personName');
    if (businessName.isNotEmpty) {
      b.writeln('${_tr("Business", "Biashara")}: $businessName');
    }
    if (businessType.isNotEmpty) {
      b.writeln('${_tr("Business Type", "Aina ya Biashara")}: $businessType');
    }
    if (phone.isNotEmpty) {
      b.writeln('${_tr("Phone", "Simu")}: $phone');
    }
    if (notes.isNotEmpty) {
      b.writeln();
      b.writeln('${_tr("Additional Notes", "Maelezo ya Ziada")}:' );
      b.writeln(notes);
    }
    b.writeln();
    b.writeln(_tr('Thank you.', 'Asante.'));
    return b.toString().trim();
  }

  Future<bool> _launchWhatsApp(String message) async {
    const phone = '255653520829';
    final primaryUrl = Uri.https('wa.me', '/$phone', {'text': message});
    final fallbackUrl = Uri.https('api.whatsapp.com', '/send', {
      'phone': phone,
      'text': message,
    });
    try {
      if (await launchUrl(primaryUrl, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}
    try {
      return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (_submitted) ...[
            const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                _tr("We'll be in touch!", 'Tutawasiliana nawe hivi karibuni!'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                ),
              ),
            ),
          ] else ...[
            Text(
              _tr('Tell us what you need', 'Tuambie unachohitaji'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tr(
                'Any requirements or ideas for your website? (optional)',
                'Je, una mahitaji au mawazo yoyote kwa tovuti yako? (si lazima)',
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.navyPrimary,
              ),
              decoration: InputDecoration(
                hintText: _tr(
                  'e.g. I sell clothing and want an online store…',
                  'mfano Nauza nguo na nataka duka la mtandaoni…',
                ),
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDisabled,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.navyPrimary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: AppColors.yellowBrand,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.yellowBrand,
                        ),
                      )
                    : Text(
                        _tr('Submit', 'Wasilisha'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: widget.onDone,
                child: Text(
                  _tr('Cancel', 'Ghairi'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helper functions ──────────────────────────────────────────────────────────

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

String _fmtAmount(double amount) {
  final abs = amount.abs();
  String formatted;
  if (abs >= 1000000) {
    formatted = '${(abs / 1000000).toStringAsFixed(1)}M';
  } else if (abs >= 1000) {
    formatted = '${(abs / 1000).toStringAsFixed(0)}K';
  } else {
    formatted = abs.toStringAsFixed(0);
  }
  return 'TSh $formatted';
}

String _displayName(Map<String, dynamic>? profile) {
  String? nameValue =
      profile?['displayName'] as String? ??
      profile?['name'] as String? ??
      profile?['fullName'] as String?;
  if (nameValue == null || nameValue.trim().isEmpty) {
    nameValue = FirebaseAuth.instance.currentUser?.displayName;
  }
  if (nameValue != null && nameValue.trim().isNotEmpty) {
    return nameValue.trim().split(' ').first;
  }
  return 'there';
}

// ── Revenue helpers ───────────────────────────────────────────────────────────

double _revenueForPeriod(List<Map<String, dynamic>> invoices, int daysBack) {
  final now = DateTime.now();
  final cutoff = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: daysBack));
  return invoices.fold<double>(0, (total, inv) {
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(cutoff)) return total;
    return total + parseNumericAmount(inv['amount']);
  });
}

double _monthRevenue(List<Map<String, dynamic>> invoices) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);
  return invoices.fold<double>(0, (total, inv) {
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(monthStart)) return total;
    return total + parseNumericAmount(inv['amount']);
  });
}

double _yearRevenue(List<Map<String, dynamic>> invoices) {
  final now = DateTime.now();
  final yearStart = DateTime(now.year);
  return invoices.fold<double>(0, (total, inv) {
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(yearStart)) return total;
    return total + parseNumericAmount(inv['amount']);
  });
}

double _revenueForRange(
  List<Map<String, dynamic>> invoices,
  int fromDaysAgo,
  int toDaysAgo,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final from = today.subtract(Duration(days: fromDaysAgo));
  final to = today.subtract(Duration(days: toDaysAgo));
  return invoices.fold<double>(0, (total, inv) {
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(from) || d.isAfter(to)) return total;
    return total + parseNumericAmount(inv['amount']);
  });
}

double _revenueForLastMonth(List<Map<String, dynamic>> invoices) {
  final now = DateTime.now();
  final lastMonthStart = DateTime(now.year, now.month - 1);
  final lastMonthEnd = DateTime(now.year, now.month);
  return invoices.fold<double>(0, (total, inv) {
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(lastMonthStart) || !d.isBefore(lastMonthEnd)) return total;
    return total + parseNumericAmount(inv['amount']);
  });
}

// ── Chart data builder (fixes tooltip normalisation bug) ──────────────────────

({List<FlSpot> spots, Map<int, double> dailyValues}) _buildChartData(
  List<Map<String, dynamic>> invoices,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daily = <int, double>{};
  for (final inv in invoices) {
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) continue;
    final d = DateTime(ts.year, ts.month, ts.day);
    final daysAgo = today.difference(d).inDays;
    if (daysAgo < 0 || daysAgo > 6) continue;
    final idx = 6 - daysAgo;
    daily[idx] = (daily[idx] ?? 0) + parseNumericAmount(inv['amount']);
  }
  final maxVal = daily.values.isEmpty
      ? 1.0
      : daily.values.reduce((a, b) => a > b ? a : b);
  final spots = List.generate(7, (i) {
    final v = daily[i] ?? 0;
    return FlSpot(i.toDouble(), maxVal > 0 ? (v / maxVal) * 5 : 0);
  });
  return (spots: spots, dailyValues: daily);
}

// ── Insights generator ────────────────────────────────────────────────────────

List<String> _generateInsights({
  required double weekRevenue,
  required double lastWeekRevenue,
  required List<Map<String, dynamic>> salesItems,
  required int lowStockCount,
  required List<Map<String, dynamic>> lowStockItems,
  required double totalOutstanding,
  required double netProfit,
}) {
  final insights = <String>[];

  // Revenue trend
  if (lastWeekRevenue > 0 && weekRevenue > 0) {
    final change = (weekRevenue - lastWeekRevenue) / lastWeekRevenue * 100;
    if (change.abs() >= 5) {
      if (change > 0) {
        insights.add(
          _tr(
            'Sales increased ${change.toStringAsFixed(0)}% compared to last week. Keep it up!',
            'Mauzo yaliongezeka ${change.toStringAsFixed(0)}% ikilinganishwa na wiki iliyopita.',
          ),
        );
      } else {
        insights.add(
          _tr(
            'Sales dropped ${change.abs().toStringAsFixed(0)}% vs last week. Consider a promotion.',
            'Mauzo yalishuka ${change.abs().toStringAsFixed(0)}% ikilinganishwa na wiki iliyopita.',
          ),
        );
      }
    }
  }

  // Top customers concentration
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);
  final customerRevenue = <String, double>{};
  double monthTotal = 0;
  for (final inv in salesItems) {
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null || ts.isBefore(monthStart)) continue;
    final key = (inv['customerName'] ?? '').toString().trim();
    final amt = parseNumericAmount(inv['amount']);
    monthTotal += amt;
    if (key.isNotEmpty) {
      customerRevenue[key] = (customerRevenue[key] ?? 0) + amt;
    }
  }
  if (monthTotal > 0 && customerRevenue.length >= 3) {
    final sorted = customerRevenue.values.toList()
      ..sort((a, b) => b.compareTo(a));
    final top3 = sorted.take(3).fold(0.0, (s, v) => s + v);
    final top3Pct = (top3 / monthTotal * 100).round();
    if (top3Pct >= 40) {
      insights.add(
        _tr(
          'Your top 3 customers account for $top3Pct% of this month\'s revenue.',
          'Wateja wako 3 bora wanachangia $top3Pct% ya mapato ya mwezi huu.',
        ),
      );
    }
  }

  // Low stock warning
  if (lowStockCount > 0) {
    final outOfStock = lowStockItems
        .where((i) => parseStock(i['currentStock'] ?? i['stock']) <= 0)
        .length;
    if (outOfStock > 0) {
      insights.add(
        _tr(
          '$outOfStock product${outOfStock > 1 ? 's are' : ' is'} out of stock. Reorder to avoid lost sales.',
          'Bidhaa $outOfStock zimekwisha. Agiza upya kuzuia kupoteza mauzo.',
        ),
      );
    } else {
      insights.add(
        _tr(
          '$lowStockCount product${lowStockCount > 1 ? 's are' : ' is'} running low. Consider restocking soon.',
          'Bidhaa $lowStockCount zinaisha. Fikiria kuagiza upya hivi karibuni.',
        ),
      );
    }
  }

  // Outstanding debt
  if (totalOutstanding > 0) {
    insights.add(
      _tr(
        'You have ${_fmtCompactAmount(totalOutstanding)} in outstanding receivables. Follow up to improve cash flow.',
        'Una ${_fmtCompactAmount(totalOutstanding)} katika madeni yanayosubiri. Fuatilia kuboresha mtiririko wa fedha.',
      ),
    );
  }

  // Profitability
  if (netProfit > 0) {
    insights.add(
      _tr(
        'Business is profitable this month — great work!',
        'Biashara inafanya faida mwezi huu — kazi nzuri!',
      ),
    );
  }

  return insights.take(3).toList();
}
