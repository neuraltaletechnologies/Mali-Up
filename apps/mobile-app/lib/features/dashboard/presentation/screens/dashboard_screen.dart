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
import '../../../sales/data/sales_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

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
    final prefs   = await SharedPreferences.getInstance();
    final pending = prefs.getBool('pending_website_interest') ?? false;
    if (!pending || !mounted) return;
    await prefs.remove('pending_website_interest');
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider);
    final customerCount = customers.maybeWhen(data: (items) => items.length, orElse: () => 0);
    final AsyncValue<List<Expense>> expenses = ref.watch(expenseListProvider);
    final AsyncValue<List<CashAccount>> cashAccounts = ref.watch(cashAccountListProvider);
    final expenseItems = expenses.maybeWhen(data: (items) => items, orElse: () => const []);
    final cashAccountItems = cashAccounts.maybeWhen(data: (items) => items, orElse: () => const []);
    final totalExpenses = expenseItems.fold<double>(
      0,
      (total, item) => total + _numericValue(item.amount),
    );
    final totalCash = cashAccountItems.fold<double>(
      0,
      (total, item) => total + _numericValue(item.balance),
    );
    final salesItems = ref.watch(salesInvoiceListProvider).maybeWhen(
            data: (items) => items,
            orElse: () => const <Map<String, dynamic>>[],
          );
    final inventoryItems = ref.watch(inventoryItemListProvider).maybeWhen(
            data: (items) => items,
            orElse: () => const <Map<String, dynamic>>[],
          );
    final todayRevenue = _revenueForPeriod(salesItems, 0);
    final weekRevenue = _revenueForPeriod(salesItems, 6);
    final monthRevenue = _monthRevenue(salesItems);
    final lastWeekRevenue = _revenueForRange(salesItems, 13, 7);
    final weeklyChange = lastWeekRevenue > 0
        ? ((weekRevenue - lastWeekRevenue) / lastWeekRevenue * 100)
        : (weekRevenue > 0 ? 100.0 : 0.0);
    final unpaidSales = salesItems.where((inv) {
      final s = readInvoiceStatus(inv).toLowerCase();
      return s == 'unpaid' || s == 'partial';
    }).toList();
    final totalOutstanding = unpaidSales.fold<double>(0, (sum, inv) {
      final amt = parseNumericAmount(inv['amount']);
      final paid = parseNumericAmount(inv['amountPaid']);
      return sum + (amt - paid).clamp(0.0, amt);
    });
    final overdueCount = unpaidSales.where((inv) {
      final d = readTimestamp(inv['createdAt']);
      if (d == null) return false;
      return DateTime.now().difference(d).inDays > 30;
    }).length;
    final lowStockItems = inventoryItems.where((item) {
      final stock = parseStock(item['currentStock'] ?? item['stock']);
      final reorder = parseStock(item['reorderPoint'] ?? 5);
      return stock <= reorder;
    }).toList();
    final netProfit = monthRevenue - totalExpenses;
    final profitMargin = monthRevenue > 0 ? netProfit / monthRevenue * 100 : 0.0;
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdaysSw = ['Jt3', 'Jn4', 'Jt5', 'Alh', 'Ijm', 'Jm1', 'Jp2'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateLabel = '${_tr(weekdays[now.weekday - 1], weekdaysSw[now.weekday - 1])}, ${now.day} ${months[now.month - 1]}';

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
                    // ── Greeting header ────────────────────────────────────
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
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_timeBasedGreeting()}, ${_displayName(snapshot.data)} 👋',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

                    // ── Hero card ──────────────────────────────────────────
                    if (_showHeavyContent)
                      _UnifiedHeroCard(
                        totalCash: totalCash,
                        totalExpenses: totalExpenses,
                        customerCount: customerCount,
                        businessName: _getBusinessName(snapshot.data),
                        logoUrl: _getBusinessLogoUrl(snapshot.data),
                      )
                    else
                      const _DashboardHeroSkeleton(),

                    const SizedBox(height: 24),

                    // ── Quick access modules ───────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tr('Quick Access', 'Ufikiaji wa Haraka'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _ModuleGrid(showHeavyContent: true),

                    const SizedBox(height: 28),

                    // ── Sales Performance ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('Sales Performance', 'Utendaji wa Mauzo'),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tr('Last 7 days', 'Siku 7 zilizopita'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${weeklyChange >= 0 ? '+' : ''}${weeklyChange.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
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
                        salesItems: salesItems,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Top Performers ─────────────────────────────────────
                    if (salesItems.isNotEmpty) ...[
                      _TopPerformersSection(salesItems: salesItems),
                      const SizedBox(height: 28),
                    ],

                    // ── Recent Activity ────────────────────────────────────
                    _RecentTransactionsList(
                      title: _tr('Recent Activity', 'Shughuli za Karibuni'),
                      expenses: expenseItems,
                      salesItems: salesItems,
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
  final double totalCash;
  final double totalExpenses;
  final int customerCount;
  final String? businessName;
  final String? logoUrl;

  const _UnifiedHeroCard({
    required this.totalCash,
    required this.totalExpenses,
    required this.customerCount,
    this.businessName,
    this.logoUrl,
  });

  @override
  State<_UnifiedHeroCard> createState() => _UnifiedHeroCardState();
}

class _UnifiedHeroCardState extends State<_UnifiedHeroCard> {
  bool _detailsVisible = false;

  static const _cardGrad1 = Color(0xFF003153);
  static const _cardGrad2 = Color(0xFF102450);
  static const _cardGrad3 = Color(0xFF003153);

  @override
  Widget build(BuildContext context) {
    final name = widget.businessName ?? _tr('My Business', 'Biashara yangu');
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    final amountText = _detailsVisible
        ? _fmtCompactAmount(widget.totalCash)
        : '••••••••';
    final clientsText = _detailsVisible ? '${widget.customerCount}' : '••';
    final expText = _detailsVisible ? _fmtCompactAmount(widget.totalExpenses) : '••••';
    final net = widget.totalCash - widget.totalExpenses;
    final netText = _detailsVisible ? _fmtCompactAmount(net) : '••••';
    final netColor = net >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171);

    // Standard ISO credit card ratio: 85.6mm × 53.98mm
    // Width is capped so the card doesn't deform on large screens.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: AspectRatio(
          aspectRatio: 1.586,
          child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [_cardGrad1, _cardGrad2, _cardGrad3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.48, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: _cardGrad1.withValues(alpha: 0.50),
              blurRadius: 32,
              offset: const Offset(0, 14),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Large decorative circle top-right
            Positioned(
              right: -60, top: -60,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.035),
                ),
              ),
            ),
            // Small accent circle bottom-left
            Positioned(
              left: -35, bottom: -35,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellowBrand.withValues(alpha: 0.07),
                ),
              ),
            ),
            // Subtle gold shimmer line along top edge
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.yellowBrand.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: chip · brand · logo ───────────────────
                  Row(
                    children: [
                      const _CardChip(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MALI UP',
                              style: TextStyle(
                                color: AppColors.yellowBrand,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.8,
                              ),
                            ),
                            Text(
                              _tr('Business Account', 'Akaunti ya Biashara'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.48),
                                fontSize: 8.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Business logo — circular
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.yellowBrand,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellowBrand.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: widget.logoUrl != null && widget.logoUrl!.isNotEmpty
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

                  const Spacer(),

                  // ── Balance ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr('TOTAL BALANCE', 'JUMLA YA FEDHA'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.44),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: Text(
                                amountText,
                                key: ValueKey(_detailsVisible),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _detailsVisible = !_detailsVisible),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            _detailsVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Business name (cardholder position) ───────────
                  Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // ── Stats footer ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CardStatItem(
                          label: _tr('Clients', 'Wateja'),
                          value: clientsText,
                        ),
                        Container(
                          width: 1, height: 22,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        _CardStatItem(
                          label: _tr('Expenses', 'Gharama'),
                          value: expText,
                          color: expText == '••••' ? null : const Color(0xFFF87171),
                        ),
                        Container(
                          width: 1, height: 22,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        _CardStatItem(
                          label: _tr('Net', 'Faida'),
                          value: netText,
                          color: netText == '••••' ? null : netColor,
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
        ),   // AspectRatio
      ),     // ConstrainedBox
    );       // Center
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

// ── EMV gold chip ──────────────────────────────────────────────────────────────
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

  const _CardStatItem({
    required this.label,
    required this.value,
    this.color,
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

class _ModuleGrid extends StatelessWidget {
  final bool showHeavyContent;

  const _ModuleGrid({required this.showHeavyContent});

  static const _modules = [
    (icon: Icons.payments_rounded, labelEn: 'Gharama zangu', labelSw: 'Gharama zangu', color: Color(0xFFD97706), route: AppRouter.expensesPath),
    (icon: Icons.account_balance_rounded, labelEn: 'Madeni', labelSw: 'Madeni', color: Color(0xFFDC2626), route: AppRouter.debtPath),
    (icon: Icons.account_balance_wallet_rounded, labelEn: 'Mtiririko wa Fedha', labelSw: 'Mtiririko wa Fedha', color: Color(0xFF7C3AED), route: AppRouter.cashFlowPath),
  ];

  @override
  Widget build(BuildContext context) {
    final itemCount = showHeavyContent ? _modules.length : 6;

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (!showHeavyContent) {
            return const _HorizontalModuleSkeleton();
          }

          final module = _modules[index];
          final label = _tr(module.labelEn, module.labelSw);
          return SizedBox(
            width: 106,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (module.route == AppRouter.debtPath) {
                    _openDebtPanel(context);
                    return;
                  }
                  context.go(module.route);
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: module.color.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: module.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: module.color.withValues(alpha: 0.15)),
                          ),
                          child: Icon(module.icon, size: 18, color: module.color),
                        ),
                        Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.secondary.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
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

  void _openDebtPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const FractionallySizedBox(
          heightFactor: 0.92,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: AppColors.background,
              child: DebtTrackingScreen(),
            ),
          ),
        );
      },
    );
  }
}

class _HorizontalModuleSkeleton extends StatelessWidget {
  const _HorizontalModuleSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 106,
      child: ShimmerBox(
        height: 108,
      ),
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesItems;

  const _SalesLineChart({required this.salesItems});

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpotsFromInvoices(salesItems);

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
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 2,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(0),
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
                final now = DateTime.now();
                final date = DateTime(now.year, now.month, now.day)
                    .subtract(Duration(days: 6 - value.toInt()));
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                const daysSw = ['Jt3', 'Jn4', 'Jt5', 'Alh', 'Ijm', 'Jm1', 'Jp2'];
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
            getTooltipItems: (spots) => spots.map((spot) {
              return LineTooltipItem(
                '${_tr('Sales', 'Mauzo')}: ${_fmtCompactAmount(spot.y)}',
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
        ],
      ),
    );
  }
}

// ─── Website Interest Nudge ───────────────────────────────────────────────────

class _WebsiteInterestSheet extends StatefulWidget {
  const _WebsiteInterestSheet();

  @override
  State<_WebsiteInterestSheet> createState() => _WebsiteInterestSheetState();
}

class _WebsiteInterestSheetState extends State<_WebsiteInterestSheet> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    // Use a stable Container as the modal root — AnimatedSwitcher as a bare
    // root causes renderObject.child mismatches when the modal route sees
    // two overlapping children during the transition.
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

// ── Nudge banner ──────────────────────────────────────────────────────────────

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
          BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, -4)),
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
          // Handle
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

          // Icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.yellowBrand,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),

          // Headline
          Text(
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
          const SizedBox(height: 10),

          // Body
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

          // Primary CTA
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

          // Dismiss link
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

// ── Requirements form ─────────────────────────────────────────────────────────

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
  bool _submitted  = false;

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
      // Load user profile for WhatsApp message
      String personName = '';
      String businessName = '';
      String businessType = '';
      String phone = '';

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data() ?? {};
        personName = ((data['displayName'] ?? data['name']) as String?)?.trim() ?? '';
        phone = (data['phone'] as String?)?.trim() ?? user.phoneNumber ?? '';

        final businesses = data['businesses'];
        if (businesses is List && businesses.isNotEmpty) {
          final biz = businesses.first as Map;
          businessName = (biz['name'] as String?)?.trim() ?? '';
          businessType = (biz['category'] as String?)?.trim() ?? '';
        }
      } catch (_) {}

      final notes = _notesCtrl.text.trim();

      // Store lead in Firestore
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

      if (mounted) setState(() { _submitting = false; _submitted = true; });

      // Build and launch WhatsApp message
      final whatsappMsg = _buildWhatsAppMessage(
        personName: personName.isNotEmpty ? personName : _tr('Business Owner', 'Mmiliki wa Biashara'),
        businessName: businessName,
        businessType: businessType,
        phone: phone,
        notes: notes,
      );
      final opened = await _launchWhatsAppRequest(whatsappMsg);
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
    final buffer = StringBuffer();
    buffer.writeln(_tr(
      'Hello Neuraltale Technologies Team,',
      'Habari Timu ya Neuraltale Technologies,',
    ));
    buffer.writeln();
    buffer.writeln(_tr(
      'I would like assistance creating a website for my business.',
      'Ningependa msaada wa kuunda tovuti kwa biashara yangu.',
    ));
    buffer.writeln();
    buffer.writeln('${_tr("Name", "Jina")}: $personName');
    if (businessName.isNotEmpty) {
      buffer.writeln('${_tr("Business", "Biashara")}: $businessName');
    }
    if (businessType.isNotEmpty) {
      buffer.writeln('${_tr("Business Type", "Aina ya Biashara")}: $businessType');
    }
    if (phone.isNotEmpty) {
      buffer.writeln('${_tr("Phone", "Simu")}: $phone');
    }
    if (notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${_tr("Additional Notes", "Maelezo ya Ziada")}:');
      buffer.writeln(notes);
    }
    buffer.writeln();
    buffer.writeln(_tr('Thank you.', 'Asante.'));
    return buffer.toString().trim();
  }

  Future<bool> _launchWhatsAppRequest(String message) async {
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
          BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, -4)),
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
          // Handle
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
              child: Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 48),
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
    final backgroundColor = selected
        ? color.withValues(alpha: 0.12)
        : AppColors.surface.withValues(alpha: 0.45);
    final borderColor = selected
        ? color.withValues(alpha: 0.22)
        : AppColors.border.withValues(alpha: 0.8);

    return Semantics(
      selected: selected,
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
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  final String title;
  final List<dynamic> expenses;
  final List<Map<String, dynamic>> salesItems;

  const _RecentTransactionsList({
    this.title = 'Recent Activity',
    this.expenses = const [],
    this.salesItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    final items = _items;
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
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              _tr('No activity yet', 'Bado hakuna shughuli'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSale = item['kind'] == 'sale';
              final amountStr = item['amount'] as String;
              final isPositive = amountStr.startsWith('+');
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSale
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: isPositive ? AppColors.success : AppColors.error,
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
                    amountStr,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isPositive ? AppColors.success : AppColors.error,
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

  List<Map<String, dynamic>> get _items {
    final result = <Map<String, dynamic>>[];

    for (final inv in salesItems) {
      final date = readTimestamp(inv['createdAt']);
      final amount = parseNumericAmount(inv['amount']);
      final customer = (inv['customerName'] ?? '').toString().trim();
      result.add({
        'kind': 'sale',
        'title': customer.isEmpty ? _tr('Walk-in', 'Mteja wa kawaida') : customer,
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

    return result.take(10).toList();
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

// ── Revenue helpers ───────────────────────────────────────────────────────────

double _revenueForPeriod(List<Map<String, dynamic>> invoices, int daysBack) {
  final now = DateTime.now();
  final cutoff = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysBack));
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

double _revenueForRange(
    List<Map<String, dynamic>> invoices, int fromDaysAgo, int toDaysAgo) {
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

List<FlSpot> _buildSpotsFromInvoices(List<Map<String, dynamic>> invoices) {
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
  final maxVal =
      daily.values.isEmpty ? 1.0 : daily.values.reduce((a, b) => a > b ? a : b);
  return List.generate(7, (i) {
    final v = daily[i] ?? 0;
    return FlSpot(i.toDouble(), maxVal > 0 ? (v / maxVal) * 5 : 0);
  });
}

// ── Revenue Overview Card ─────────────────────────────────────────────────────

// ── Half-card skeleton ────────────────────────────────────────────────────────

class _DashboardHalfCardSkeleton extends StatelessWidget {
  const _DashboardHalfCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 64, height: 10, borderRadius: BorderRadius.all(Radius.circular(999))),
          SizedBox(height: 10),
          ShimmerBox(width: 88, height: 18, borderRadius: BorderRadius.all(Radius.circular(6))),
          SizedBox(height: 6),
          ShimmerBox(width: 56, height: 9, borderRadius: BorderRadius.all(Radius.circular(999))),
        ],
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
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 74,
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
                  width: 132,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: alertColor.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOut ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                            size: 12,
                            color: alertColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOut ? _tr('Out', 'Imekwisha') : _tr('Low', 'Ndogo'),
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
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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

  Map<String, double> _aggregateByMonth(
      String Function(Map<String, dynamic>) keyFn,
      double Function(Map<String, dynamic>) valueFn) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final result = <String, double>{};
    for (final inv in salesItems) {
      final ts = readTimestamp(inv['createdAt']);
      if (ts == null || ts.isBefore(monthStart)) continue;
      final key = keyFn(inv);
      if (key.isEmpty) continue;
      result[key] = (result[key] ?? 0) + valueFn(inv);
    }
    return result;
  }

  Map<String, double> get _topProducts {
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

  Map<String, double> get _topCustomers => _aggregateByMonth(
        (inv) => (inv['customerName'] ?? '').toString().trim(),
        (inv) => parseNumericAmount(inv['amount']),
      );

  @override
  Widget build(BuildContext context) {
    final products = (_topProducts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .toList();
    final customers = (_topCustomers.entries.toList()
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
            label: _tr('Best Products', 'Bidhaaa Bora'),
            color: AppColors.tealAccent,
            entries: products,
          ),
        if (products.isNotEmpty && customers.isNotEmpty) const SizedBox(height: 10),
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
                final pct = maxVal > 0 ? (entry.value / maxVal).clamp(0.0, 1.0) : 0.0;
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$rank Rank',
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
                            style: TextStyle(
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
                              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.65)),
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

