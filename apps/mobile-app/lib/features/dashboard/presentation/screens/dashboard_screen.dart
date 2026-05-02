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
  Future<Map<String, dynamic>?> _profileFuture = Future.value();

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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final isBusinessContext = _isBusinessContext(snapshot.data);
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                  20,
                  24,
                ),
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
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    if (_showHeavyContent)
                      _UnifiedHeroCard(
                        isBusinessContext: isBusinessContext,
                        totalCash: totalCash,
                        totalExpenses: totalExpenses,
                        customerCount: customerCount,
                        budgetHealth: budgetHealth.toDouble(),
                        businessName: _getBusinessName(snapshot.data),
                        logoUrl: _getBusinessLogoUrl(snapshot.data),
                      )
                    else
                      const _DashboardHeroSkeleton(),
                    const SizedBox(height: 20),
                    if (isBusinessContext) ...[
                      _ModuleGrid(showHeavyContent: _showHeavyContent),
                      const SizedBox(height: 28),
                    ] else
                      const SizedBox(height: 8),
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
          ShimmerBox(width: 100, height: 12, borderRadius: BorderRadius.all(Radius.circular(999))),
          SizedBox(height: 12),
          ShimmerBox(width: 180, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
          SizedBox(height: 16),
          Row(
            children: [
              ShimmerBox(width: 80, height: 10, borderRadius: BorderRadius.all(Radius.circular(999))),
              SizedBox(width: 24),
              ShimmerBox(width: 80, height: 10, borderRadius: BorderRadius.all(Radius.circular(999))),
            ],
          ),
        ],
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

class _UnifiedHeroCard extends StatefulWidget {
  final bool isBusinessContext;
  final double totalCash;
  final double totalExpenses;
  final int customerCount;
  final double budgetHealth;
  final String? businessName;
  final String? logoUrl;

  const _UnifiedHeroCard({
    required this.isBusinessContext,
    required this.totalCash,
    required this.totalExpenses,
    required this.customerCount,
    required this.budgetHealth,
    this.businessName,
    this.logoUrl,
  });

  @override
  State<_UnifiedHeroCard> createState() => _UnifiedHeroCardState();
}

class _UnifiedHeroCardState extends State<_UnifiedHeroCard> {
  bool _detailsVisible = true;

  @override
  Widget build(BuildContext context) {
    return widget.isBusinessContext
        ? _buildCreditCard()
        : _buildPersonalCard();
  }

  // ── Business: premium credit card ──────────────────────────────────────────
  Widget _buildCreditCard() {
    final name = widget.businessName ?? _tr('My Business', 'Biashara yangu');
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    final amountText = _detailsVisible
        ? _fmtCompactAmount(widget.totalCash)
        : '••••••••••';
    final clientsText = _detailsVisible ? '${widget.customerCount}' : '••';
    final expText =
        _detailsVisible ? _fmtCompactAmount(widget.totalExpenses) : '••••';
    final net = widget.totalCash - widget.totalExpenses;
    final netText = _detailsVisible ? _fmtCompactAmount(net) : '••••';
    final netColor =
        net >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171);
    final now = DateTime.now();
    final validThru =
        '${now.month.toString().padLeft(2, '0')}/${(now.year + 3).toString().substring(2)}';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.navySecondary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.navyPrimary,
                Color(0xFF142B5E),
                AppColors.navySecondary,
              ],
              stops: [0.0, 0.52, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // ── Decorative background ──────────────────────────────
              Positioned(
                right: -50, top: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                left: -30, bottom: -35,
                child: Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.yellowBrand.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 55, bottom: -18,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tealAccent.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Top-edge shine line
              Positioned(
                left: 0, right: 0, top: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Card content ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: chip + brand label + logo
                    Row(
                      children: [
                        const _CardChip(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'MALI UP',
                            style: TextStyle(
                              color:
                                  AppColors.yellowBrand.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.8,
                            ),
                          ),
                        ),
                        // Logo — rounded square
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: widget.logoUrl != null &&
                                    widget.logoUrl!.isNotEmpty
                                ? Image.network(
                                    widget.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _BusinessLogoFallback(
                                            initial: initial),
                                  )
                                : _BusinessLogoFallback(initial: initial),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Masked card number dots
                    Text(
                      '••••  ••••  ••••  ••••',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Balance label + show/hide toggle
                    Row(
                      children: [
                        Text(
                          _tr('TOTAL BALANCE', 'JUMLA YA FEDHA'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 9,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(
                              () => _detailsVisible = !_detailsVisible),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _detailsVisible
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : AppColors.yellowBrand
                                      .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _detailsVisible
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : AppColors.yellowBrand
                                        .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _detailsVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  size: 13,
                                  color: _detailsVisible
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppColors.yellowBrand,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _detailsVisible
                                      ? _tr('Hide', 'Ficha')
                                      : _tr('Show', 'Onyesha'),
                                  style: TextStyle(
                                    color: _detailsVisible
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : AppColors.yellowBrand,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Balance amount
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                      child: Text(
                        amountText,
                        key: ValueKey(_detailsVisible),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Footer: business name + valid thru
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'VALID THRU',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.38),
                                fontSize: 7,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              validThru,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Stats bar — full width, clips with outer ClipRRect
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.symmetric(horizontal: -22),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        border: Border(
                          top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                      child: Row(
                        children: [
                          _CardStat(
                            label: _tr('Clients', 'Wateja'),
                            value: clientsText,
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          _CardStat(
                            label: _tr('Expenses', 'Gharama'),
                            value: expText,
                            valueColor:
                                _detailsVisible && widget.totalExpenses > 0
                                    ? const Color(0xFFF87171)
                                    : null,
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          _CardStat(
                            label: _tr('Net', 'Faida'),
                            value: netText,
                            valueColor:
                                _detailsVisible ? netColor : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Personal: clean white card ──────────────────────────────────────────────
  Widget _buildPersonalCard() {
    final healthColor = widget.budgetHealth >= 60
        ? AppColors.success
        : widget.budgetHealth >= 30
            ? AppColors.warning
            : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('Budget Health', 'Afya ya Bajeti'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.budgetHealth.round()}%',
                        style: TextStyle(
                          color: healthColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: _tr('Cash', 'Fedha'),
                  value: _fmtCompactAmount(widget.totalCash),
                ),
                const _StatDivider(),
                _StatChip(
                  icon: Icons.payments_rounded,
                  label: _tr('Spent', 'Gharama'),
                  value: _fmtCompactAmount(widget.totalExpenses),
                  valueColor:
                      widget.totalExpenses > 0 ? AppColors.error : null,
                ),
                const _StatDivider(),
                _StatChip(
                  icon: Icons.shield_rounded,
                  label: _tr('Health', 'Hali'),
                  value: '${widget.budgetHealth.round()}%',
                  valueColor: healthColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessLogoFallback extends StatelessWidget {
  final String initial;
  const _BusinessLogoFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42,
      color: AppColors.yellowBrand,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.navyPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CardStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── EMV chip widget ────────────────────────────────────────────────────────────
class _CardChip extends StatelessWidget {
  const _CardChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A843), Color(0xFFF0C832), Color(0xFFB8902A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
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
      ..color = const Color(0xFF8B6010).withValues(alpha: 0.55)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Outer inset rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, w - 6, h - 6),
        const Radius.circular(2),
      ),
      paint,
    );
    // Vertical center line
    canvas.drawLine(Offset(w / 2, 3), Offset(w / 2, h - 3), paint);
    // Horizontal center line
    canvas.drawLine(Offset(3, h / 2), Offset(w - 3, h / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final bool showHeavyContent;

  const _ModuleGrid({required this.showHeavyContent});

  static const _modules = [
    (icon: Icons.receipt_long_rounded, labelEn: 'Tuma ankara', labelSw: 'Tuma ankara', color: Color(0xFF0D1B3E), route: AppRouter.salesPath),
    (icon: Icons.inventory_2_rounded, labelEn: 'Hisa zangu', labelSw: 'Hisa zangu', color: Color(0xFF1A6E8A), route: AppRouter.inventoryPath),
    (icon: Icons.people_alt_rounded, labelEn: 'Wateja wangu', labelSw: 'Wateja wangu', color: Color(0xFF059669), route: AppRouter.crmPath),
    (icon: Icons.payments_rounded, labelEn: 'Gharama zangu', labelSw: 'Gharama zangu', color: Color(0xFFD97706), route: AppRouter.expensesPath),
    (icon: Icons.account_balance_rounded, labelEn: 'Madeni', labelSw: 'Madeni', color: Color(0xFFDC2626), route: AppRouter.debtPath),
    (icon: Icons.account_balance_wallet_rounded, labelEn: 'Mtiririko wa Fedha', labelSw: 'Mtiririko wa Fedha', color: Color(0xFF7C3AED), route: AppRouter.cashFlowPath),
  ];

  @override
  Widget build(BuildContext context) {
    if (!showHeavyContent) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
        ),
        itemCount: 6,
        itemBuilder: (context, i) => const ShimmerBox(
          height: 90,
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: _modules.length,
      itemBuilder: (context, index) {
        final module = _modules[index];
        final label = _tr(module.labelEn, module.labelSw);
        return InkWell(
          onTap: () => context.go(module.route),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(module.icon, size: 18, color: module.color),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
  String? nameValue = profile?['displayName'] as String? ?? 
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
