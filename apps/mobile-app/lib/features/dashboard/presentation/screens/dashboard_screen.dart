import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../customer/domain/models/customer.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../debt/domain/models/debt.dart';
import '../../../debt/data/debt_providers.dart';
import '../../../debt/presentation/screens/debt_tracking_screen.dart';
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
      });
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
                  MediaQuery.of(context).padding.top + kToolbarHeight + 8,
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
                    _ModuleGrid(showHeavyContent: _showHeavyContent),

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
                            '${customerCount >= 1 ? '+' : ''}${(customerCount * 1.2).toStringAsFixed(1)}%',
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
                    if (_showHeavyContent)
                      const _ChartLegendRow()
                    else
                      const _DashboardLoadingPillRow(),
                    const SizedBox(height: 14),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      child: _showHeavyContent
                          ? _SalesLineChart(
                              expenses: expenseItems,
                              debts: debtItems,
                            )
                          : const _DashboardChartPlaceholder(),
                    ),

                    const SizedBox(height: 28),

                    // ── Recent Transactions ────────────────────────────────
                    _showHeavyContent
                        ? _RecentTransactionsList(
                            title: _tr('Recent Transactions', 'Miamala ya Karibuni'),
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

  static const _cardGrad1 = Color(0xFF0D1B3E);
  static const _cardGrad2 = Color(0xFF102450);
  static const _cardGrad3 = Color(0xFF162C62);

  @override
  Widget build(BuildContext context) {
    final name = widget.businessName ?? _tr('My Business', 'Biashara yangu');
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    final amountText = _detailsVisible
        ? 'TZS ${_fmtCompactAmount(widget.totalCash)}'
        : 'TZS ••••••••';
    final clientsText = _detailsVisible ? '${widget.customerCount}' : '••';
    final expText = _detailsVisible ? _fmtCompactAmount(widget.totalExpenses) : '••••';
    final net = widget.totalCash - widget.totalExpenses;
    final netText = _detailsVisible ? _fmtCompactAmount(net) : '••••';
    final netColor = net >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171);

    // Standard ISO credit card ratio: 85.6mm × 53.98mm
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        width: double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _CardChip(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
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
        childAspectRatio: 0.98,
      ),
      itemCount: _modules.length,
      itemBuilder: (context, index) {
        final module = _modules[index];
        final label = _tr(module.labelEn, module.labelSw);
        return Material(
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
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDebtPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
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

class _SalesLineChart extends StatelessWidget {
  final List<dynamic> expenses;
  final List<dynamic> debts;

  const _SalesLineChart({
    required this.expenses,
    required this.debts,
  });

  @override
  Widget build(BuildContext context) {
    final salesPoints = _buildSpotsFromAmountStrings(
      debts
          .where((debt) => (debt.type as String?)?.toLowerCase() == 'receivable')
          .map((debt) => debt.amount as String?)
          .toList(),
    );

    const unit = 'M';
    final seriesNames = [_tr('Sales', 'Mauzo')];
    final lineBarsData = [
      LineChartBarData(
        spots: salesPoints,
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
    ];

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
