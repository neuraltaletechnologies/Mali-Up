import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/routing.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../core/services/app_rating_service.dart';
import '../../../../core/services/business_profile_service.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/rate_app_dialog.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../finance/data/finance_providers.dart';
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

  // Profile cache keys (SharedPreferences).
  static const _kDisplayName = 'cached_profile_display_name';
  static const _kBizName = 'cached_business_name';
  static const _kLogoUrl = 'cached_business_logo_url';
  static const _kPlan = 'cached_business_plan';
  static const _kFetchedAt = 'cached_profile_fetched_at';
  // Only hit Firestore once per day — profile data (name, plan, logo) rarely changes.
  static const _kTtl = Duration(hours: 24);

  int _entryRewardTrigger = 0;
  bool _showEntryReward = false;
  bool _showHeavyContent = false;
  _DashPeriod _selectedPeriod = _DashPeriod.week;
  Timer? _clockTimer;

  // Non-null once the cache has been read (even if fields are empty).
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    BusinessProfileService.updatedNotifier.addListener(
      _onBusinessProfileUpdated,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showHeavyContent = true);
      _maybeRefreshFromFirestore();
      _showFirstEntryRewardIfNeeded();
      _checkWebsiteInterestNudge();
      _maybeShowRateAppPrompt();
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  /// Business logo/name/plan was just edited elsewhere (e.g. Manage Businesses) —
  /// bypass the 24h TTL and refetch now so the Hero card reflects it immediately.
  void _onBusinessProfileUpdated() {
    if (!mounted) return;
    _maybeRefreshFromFirestore(force: true);
  }

  // ── Profile cache helpers ────────────────────────────────────────────────────

  /// Reads cached profile fields from SharedPreferences and shows them instantly.
  void _loadCachedProfile() {
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _profile = {
          'displayName': prefs.getString(_kDisplayName),
          'businesses': [
            {
              'businessName': prefs.getString(_kBizName),
              'logoUrl': prefs.getString(_kLogoUrl),
              'plan': prefs.getString(_kPlan),
            },
          ],
        };
      });
    });
  }

  /// Fetches fresh profile data from Firestore only if the cache is older than
  /// [_kTtl] (default 24 h). Skips the network call entirely on most opens.
  Future<void> _maybeRefreshFromFirestore({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchMs = prefs.getInt(_kFetchedAt) ?? 0;
    final cacheAge = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastFetchMs),
    );
    if (!force && lastFetchMs > 0 && cacheAge < _kTtl) {
      return; // cache is fresh, skip
    }

    final fresh = await _fetchUserProfile();
    if (!mounted || fresh == null) return;
    setState(() => _profile = fresh);
    _saveProfileToPrefs(prefs, fresh);
    await prefs.setInt(_kFetchedAt, DateTime.now().millisecondsSinceEpoch);
  }

  void _saveProfileToPrefs(
    SharedPreferences prefs,
    Map<String, dynamic> profile,
  ) {
    final name =
        profile['displayName'] as String? ??
        profile['name'] as String? ??
        profile['fullName'] as String?;
    if (name != null && name.isNotEmpty) prefs.setString(_kDisplayName, name);
    final bizName = _getBusinessName(profile);
    if (bizName != null && bizName.isNotEmpty) {
      prefs.setString(_kBizName, bizName);
    }
    final logoUrl = _getBusinessLogoUrl(profile);
    if (logoUrl != null && logoUrl.isNotEmpty) {
      prefs.setString(_kLogoUrl, logoUrl);
    }
    final plan = _getBusinessPlan(profile);
    if (plan != null && plan.isNotEmpty) prefs.setString(_kPlan, plan);
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return _tr('Good morning', 'Habari za asubuhi');
    if (hour >= 12 && hour < 17) {
      return _tr('Good afternoon', 'Habari za mchana');
    }
    if (hour >= 17 && hour < 21) return _tr('Good evening', 'Habari za jioni');
    if (hour >= 21) return _tr('Good night', 'Usiku mwema');
    return _tr('Good midnight', 'Usiku mwema');
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
    showAppSheet<void>(context, builder: (_) => const _WebsiteInterestSheet());
  }

  /// Soft-ask for a Play Store rating, gated by [AppRatingService] so it
  /// only fires after a few happy-path moments and never more than a
  /// handful of times total. See AppRatingService for the full policy.
  Future<void> _maybeShowRateAppPrompt() async {
    final eligible = await AppRatingService.shouldPrompt();
    if (!eligible || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    RateAppDialog.show(context);
  }

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final fs = FirebaseFirestore.instance;
      final userSnap = await fs
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions());
      final profile = userSnap.data();
      if (profile == null) return {};

      final isTeamMember = profile['isTeamMember'] == true;
      if (isTeamMember) {
        final bizId = (profile['businessId'] as String?)?.trim() ?? '';
        if (bizId.isNotEmpty) {
          final bizSnap = await fs
              .collection('businesses')
              .doc(bizId)
              .get(const GetOptions());
          if (bizSnap.exists) {
            profile['businesses'] = [
              {'id': bizId, ...?bizSnap.data()},
            ];
          }
        }
      } else {
        final bizSnap = await fs
            .collection('businesses')
            .where('ownerUid', isEqualTo: user.uid)
            .get(const GetOptions());
        profile['businesses'] = bizSnap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList();
      }

      return profile;
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
    // Firestore stores the name under 'businessName' (phone_auth_service) or 'name' (older paths).
    final raw = (business['businessName'] as String?)?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
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
    final expenseItems = expenses.maybeWhen(
      data: (items) => items,
      orElse: () => const <Expense>[],
    );
    final now2 = DateTime.now();
    // Rejected expenses are excluded, matching the P&L / expense reports.
    final countedExpenses = expenseItems
        .where((e) => e.status != 'rejected')
        .toList();
    final monthExpenses = countedExpenses
        .where((e) {
          final d = DateTime.tryParse(e.date);
          return d != null && d.year == now2.year && d.month == now2.month;
        })
        .fold<double>(0, (t, e) => t + _numericValue(e.amount));
    final yearExpenses = countedExpenses
        .where((e) {
          final d = DateTime.tryParse(e.date);
          return d != null && d.year == now2.year;
        })
        .fold<double>(0, (t, e) => t + _numericValue(e.amount));
    // All-time total, regardless of the period selector above — this is the
    // figure the Mali Up hero card's "EXPENSES" stat reads.
    final allTimeExpenses = countedExpenses.fold<double>(
      0,
      (t, e) => t + _numericValue(e.amount),
    );
    final salesAsyncValue = ref.watch(salesInvoiceListProvider);
    final salesItems = salesAsyncValue.maybeWhen(
      data: (items) => items,
      orElse: () => const <Map<String, dynamic>>[],
    );
    // Cash actually on hand: every shilling collected against a sale/invoice
    // (amountPaid — set at sale time for cash sales, incremented by
    // recordPayment for credit collections) minus every recorded expense,
    // all-time. Previously this summed a separate "cash accounts" ledger
    // (Cash Flow feature) that most businesses never touch, so it showed 0
    // or a stale number even after real sales and payments went through.
    final allTimeCollected = salesItems.fold<double>(
      0,
      (t, inv) => t + parseNumericAmount(inv['amountPaid']),
    );
    final totalCash = allTimeCollected - allTimeExpenses;
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
    // Anything confirmed but not fully settled counts: credit invoices are
    // stored with status 'sent', quick credit sales with 'unpaid'/'partial'.
    final now = DateTime.now();
    final unpaidSales = salesItems.where((inv) {
      if (!_isConfirmedSale(inv)) return false;
      final s = readInvoiceStatus(inv).toLowerCase();
      return s != 'paid' && s != 'completed';
    }).toList();
    final totalOutstanding = unpaidSales.fold<double>(0, (total, inv) {
      final amt = readInvoiceTotal(inv);
      final paid = parseNumericAmount(inv['amountPaid']);
      final due = amt - paid;
      return total + (due > 0 ? due : 0);
    });

    // ── Low stock ────────────────────────────────────────────────────────────
    final lowStockItems = inventoryItems.where((item) {
      // Services and customer returns have no stock to track.
      final type = (item['productType'] ?? '').toString();
      if (type == 'service' || type == 'return' || type == 'customerReturn') {
        return false;
      }
      final stock = parseStock(item['currentStock'] ?? item['stock']);
      final reorder = parseStock(item['reorderPoint'] ?? 5);
      return stock <= reorder;
    }).toList();

    // ── Chart data ───────────────────────────────────────────────────────────
    final dailyValues = _buildDailySalesData(salesItems);
    final categorySales = _buildCategorySalesData(salesItems, inventoryItems);

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
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppTheme.pageHorizontalPadding,
              MediaQuery.of(context).padding.top + AppTheme.headerTopPadding,
              AppTheme.pageHorizontalPadding,
              AppTheme.pageVerticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting header ──────────────────────────────────
                if (_profile == null)
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
                              '${_timeBasedGreeting()}, ${_displayName(_profile)} 👋',
                              style: Theme.of(context).textTheme.headlineMedium
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
                    monthExpenses: allTimeExpenses,
                    yearNetProfit: yearRevenue - yearExpenses,
                    customerCount: customerCount,
                    businessName: _getBusinessName(_profile),
                    logoUrl: _getBusinessLogoUrl(_profile),
                    plan: _getBusinessPlan(_profile),
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
                    onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Business insights ────────────────────────────────
                if (insights.isNotEmpty) ...[
                  _BusinessInsightsCard(insights: insights),
                  const SizedBox(height: 24),
                ],

                // ── Sales Performance ────────────────────────────────
                if (permissions.canViewSales || permissions.isOwner) ...[
                  _SalesPerformanceCard(
                    dailyValues: dailyValues,
                    categorySales: categorySales,
                    weekRevenue: weekRevenue,
                    change: lastWeekRevenue > 0
                        ? ((weekRevenue - lastWeekRevenue) /
                              lastWeekRevenue *
                              100)
                        : (weekRevenue > 0 ? 100.0 : 0.0),
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
                    salesItems.isNotEmpty)
                  _TopPerformersSection(salesItems: salesItems),

                // ── Recent activity ──────────────────────────────────
                _RecentTransactionsList(
                  title: _tr('Recent Activity', 'Shughuli za Karibuni'),
                  expenses: expenseItems,
                  salesItems: salesItems,
                  isLoading: activityLoading,
                ),
              ],
            ),
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
    BusinessProfileService.updatedNotifier.removeListener(
      _onBusinessProfileUpdated,
    );
    super.dispose();
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
                        style: GoogleFonts.dmSans(
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
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmtAmount(revenue),
                      style: GoogleFonts.dmSans(
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
                          style: GoogleFonts.dmSans(
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
                      style: GoogleFonts.dmSans(
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

// ── Cash Position Card ────────────────────────────────────────────────────────
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
          Text(
            _tr('Business Insights', 'Mwanga wa Biashara'),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.navyPrimary,
            ),
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
                      style: GoogleFonts.dmSans(
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
  // All-time total, despite the field name inherited from the constructor
  // call site — the "EXPENSES" stat below reads the whole business history,
  // not just the current month.
  final double monthExpenses;
  final double yearNetProfit;
  final int customerCount;
  final String? businessName;
  final String? logoUrl;
  final String? plan;

  const _UnifiedHeroCard({
    required this.totalCash,
    required this.monthRevenue,
    required this.monthExpenses,
    required this.yearNetProfit,
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

  // Matte premium card face — near-black navy with a faint teal cast
  static const _gradA = Color(0xFF091026);
  static const _gradB = Color(0xFF0D1B3E);
  static const _gradC = Color(0xFF0E2C42);

  @override
  Widget build(BuildContext context) {
    final name = widget.businessName ?? _tr('My Business', 'Biashara yangu');
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    final amountText = _detailsVisible
        ? _fmtCompactAmount(widget.totalCash)
        : '•••• ••••';
    final clientsText = _detailsVisible ? '${widget.customerCount}' : '••';
    final expText = _detailsVisible
        ? _fmtCompactAmount(widget.monthExpenses)
        : '••••';
    final netText = _detailsVisible
        ? _fmtCompactAmount(widget.yearNetProfit)
        : '••••';
    final netColor = widget.yearNetProfit >= 0
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AspectRatio(
            aspectRatio: 85.6 / 53.98,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [_gradA, _gradB, _gradC],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.55, 1.0],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                    spreadRadius: -8,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Guilloche-style engraved texture
                  const Positioned.fill(
                    child: CustomPaint(painter: _CardTexturePainter()),
                  ),
                  // Soft sheen sweeping from the top-left corner
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-1.1, -1.2),
                          radius: 1.6,
                          colors: [
                            Colors.white.withValues(alpha: 0.07),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6],
                        ),
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ── Top row: issuer name + plan | contactless | logo ─
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name.toUpperCase(),
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.yellowBrand,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (widget.plan ?? 'Trial').toUpperCase(),
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white.withValues(
                                        alpha: 0.38,
                                      ),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.contactless_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 10),
                            // Business logo avatar
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.yellowBrand,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child:
                                  widget.logoUrl != null &&
                                      widget.logoUrl!.isNotEmpty
                                  ? Image.network(
                                      widget.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _BusinessLogoFallback(
                                            initial: initial,
                                          ),
                                    )
                                  : _BusinessLogoFallback(initial: initial),
                            ),
                          ],
                        ),

                        // ── Chip + balance (card-number position) ────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const _CardChip(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _tr('TOTAL BALANCE', 'JUMLA YA FEDHA'),
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        height: 1.0,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                            offset: const Offset(0, 1.5),
                                            blurRadius: 2,
                                          ),
                                        ],
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
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
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

                        // ── Footer: stats | brand wordmark ───────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _CardFooterStat(
                              label: _tr('CLIENTS', 'WATEJA'),
                              value: clientsText,
                            ),
                            const SizedBox(width: 18),
                            _CardFooterStat(
                              label: _tr('EXPENSES', 'GHARAMA'),
                              value: expText,
                              color: expText == '••••'
                                  ? null
                                  : const Color(0xFFF87171),
                            ),
                            const SizedBox(width: 18),
                            _CardFooterStat(
                              label: _tr('NET YTD', 'FAIDA MWAKA'),
                              value: netText,
                              color: netText == '••••' ? null : netColor,
                            ),
                            const Spacer(),
                            // Brand mark — network-logo position
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'MALI',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' UP',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.yellowBrand,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
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
          style: GoogleFonts.dmSans(
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
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCFA23A), Color(0xFFEDC84A), Color(0xFFAF8520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(5),
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

class _CardFooterStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _CardFooterStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: 7,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: color ?? Colors.white.withValues(alpha: 0.92),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// Fine engraved-line texture reminiscent of guilloche patterns on
/// premium bank cards. Painted once — cheap, static decoration.
class _CardTexturePainter extends CustomPainter {
  const _CardTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    // Sweeping concentric arcs from the top-right corner
    line.color = Colors.white.withValues(alpha: 0.035);
    final arcCenter = Offset(size.width * 1.05, -size.height * 0.25);
    for (var r = size.width * 0.30; r < size.width * 1.15; r += 16) {
      canvas.drawCircle(arcCenter, r, line);
    }

    // Counter-arcs from the bottom-left, teal-tinted
    line.color = AppColors.tealAccent.withValues(alpha: 0.07);
    final arcCenter2 = Offset(-size.width * 0.10, size.height * 1.30);
    for (var r = size.width * 0.22; r < size.width * 0.85; r += 14) {
      canvas.drawCircle(arcCenter2, r, line);
    }

    // Single gold accent arc
    line
      ..color = AppColors.yellowBrand.withValues(alpha: 0.10)
      ..strokeWidth = 1.1;
    canvas.drawCircle(arcCenter, size.width * 0.72, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Sales chart ───────────────────────────────────────────────────────────────

class _SalesPerformanceCard extends StatefulWidget {
  final Map<int, double> dailyValues;
  final List<MapEntry<String, double>> categorySales;
  final double weekRevenue;
  final double change;

  const _SalesPerformanceCard({
    required this.dailyValues,
    required this.categorySales,
    required this.weekRevenue,
    required this.change,
  });

  @override
  State<_SalesPerformanceCard> createState() => _SalesPerformanceCardState();
}

class _SalesPerformanceCardState extends State<_SalesPerformanceCard> {
  static const _categoryColors = [
    AppColors.navyPrimary,
    AppColors.tealAccent,
    AppColors.yellowBrand,
    AppColors.success,
  ];

  int _selectedDay = 6;
  int _selectedCategory = 0;

  DateTime _dateForIndex(int index) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: 6 - index));
  }

  String _dayLabel(int index, {bool long = false}) {
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const sw = ['Jt3', 'Jn4', 'Jt5', 'Alh', 'Ijm', 'Jm1', 'Jp2'];
    const enLong = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const swLong = [
      'Jumatatu',
      'Jumanne',
      'Jumatano',
      'Alhamisi',
      'Ijumaa',
      'Jumamosi',
      'Jumapili',
    ];
    final weekday = _dateForIndex(index).weekday - 1;
    return long
        ? _tr(enLong[weekday], swLong[weekday])
        : _tr(en[weekday], sw[weekday]);
  }

  @override
  Widget build(BuildContext context) {
    final values = List.generate(7, (i) => widget.dailyValues[i] ?? 0);
    final maxValue = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final chartMax = maxValue > 0 ? maxValue * 1.22 : 1.0;
    final peakIndex = values.indexOf(maxValue);
    final categories = widget.categorySales.take(4).toList();
    final safeCategoryIndex = categories.isEmpty
        ? 0
        : _selectedCategory.clamp(0, categories.length - 1);
    final selectedCategory = categories.isEmpty
        ? null
        : categories[safeCategoryIndex];
    final categoryTotal = categories.fold<double>(
      0,
      (total, item) => total + item.value,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                      _tr('Sales Performance', 'Utendaji wa Mauzo'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              _ChangeBadge(change: widget.change),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PerformanceMetric(
                  label: _tr('7-day sales', 'Mauzo ya siku 7'),
                  value: _fmtCompactAmount(widget.weekRevenue),
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PerformanceMetric(
                  label: _dayLabel(_selectedDay, long: true),
                  value: _fmtCompactAmount(values[_selectedDay]),
                  color: AppColors.tealAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, _tr('Daily sales', 'Mauzo ya kila siku')),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: chartMax,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.65),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index > 6) {
                          return const SizedBox.shrink();
                        }
                        final selected = index == _selectedDay;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _dayLabel(index),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: selected
                                      ? AppColors.secondary
                                      : AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response?.spot == null) {
                      return;
                    }
                    setState(() {
                      _selectedDay = response!.spot!.touchedBarGroupIndex;
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.secondary,
                    tooltipBorderRadius: BorderRadius.circular(10),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_dayLabel(group.x, long: true)}\n'
                        '${_fmtCompactAmount(values[group.x])}',
                        Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  final selected = index == _selectedDay;
                  final peak = index == peakIndex && maxValue > 0;
                  final color = selected
                      ? AppColors.yellowBrand
                      : peak
                      ? AppColors.success
                      : AppColors.tealAccent;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        width: 18,
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: chartMax,
                          color: AppColors.background,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PeakDayInsight(
            hasSales: maxValue > 0,
            day: _dayLabel(peakIndex, long: true),
            amount: maxValue,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _sectionTitle(
            context,
            _tr('Sales by category', 'Mauzo kwa kategoria'),
          ),
          const SizedBox(height: 4),
          Text(
            _tr('Tap a segment to inspect it', 'Gusa sehemu kuona maelezo'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 126,
                height: 126,
                child: categories.isEmpty
                    ? _EmptyCategoryRing(context: context)
                    : PieChart(
                        PieChartData(
                          centerSpaceRadius: 34,
                          sectionsSpace: 3,
                          pieTouchData: PieTouchData(
                            enabled: true,
                            touchCallback: (event, response) {
                              final index =
                                  response?.touchedSection?.touchedSectionIndex;
                              if (!event.isInterestedForInteractions ||
                                  index == null ||
                                  index < 0) {
                                return;
                              }
                              setState(() => _selectedCategory = index);
                            },
                          ),
                          sections: categories.asMap().entries.map((item) {
                            final selected = item.key == safeCategoryIndex;
                            return PieChartSectionData(
                              value: item.value.value,
                              color:
                                  _categoryColors[item.key %
                                      _categoryColors.length],
                              radius: selected ? 23 : 18,
                              title: '',
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: categories.isEmpty
                    ? Text(
                        _tr(
                          'No category data yet',
                          'Hakuna data ya kategoria bado',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      )
                    : Column(
                        children: categories.asMap().entries.map((item) {
                          final selected = item.key == safeCategoryIndex;
                          final pct = categoryTotal > 0
                              ? item.value.value / categoryTotal * 100
                              : 0.0;
                          return _CategoryLegendItem(
                            label: item.value.key,
                            percentage: pct,
                            color:
                                _categoryColors[item.key %
                                    _categoryColors.length],
                            selected: selected,
                            onTap: () {
                              setState(() => _selectedCategory = item.key);
                            },
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
          if (selectedCategory != null) ...[
            const SizedBox(height: 12),
            Text(
              _tr(
                '${selectedCategory.key} contributed '
                    '${_fmtCompactAmount(selectedCategory.value)} this week.',
                '${selectedCategory.key} imechangia '
                    '${_fmtCompactAmount(selectedCategory.value)} wiki hii.',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: AppColors.secondary,
      fontWeight: FontWeight.w800,
      fontSize: 12,
    ),
  );
}

class _PerformanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeakDayInsight extends StatelessWidget {
  final bool hasSales;
  final String day;
  final double amount;

  const _PeakDayInsight({
    required this.hasSales,
    required this.day,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.successBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_graph_rounded,
            size: 17,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasSales
                  ? _tr(
                      '$day was your strongest day at '
                          '${_fmtCompactAmount(amount)}.',
                      '$day ilikuwa siku bora kwa ${_fmtCompactAmount(amount)}.',
                    )
                  : _tr(
                      'Record a sale to start seeing daily trends.',
                      'Rekodi mauzo ili kuanza kuona mwenendo wa kila siku.',
                    ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategoryRing extends StatelessWidget {
  final BuildContext context;

  const _EmptyCategoryRing({required this.context});

  @override
  Widget build(BuildContext _) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const CircularProgressIndicator(
          value: 1,
          strokeWidth: 14,
          color: AppColors.border,
        ),
        Text(
          '0%',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CategoryLegendItem extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryLegendItem({
    required this.label,
    required this.percentage,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? color : AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart legend ──────────────────────────────────────────────────────────────

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
                style: GoogleFonts.dmSans(
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
                style: GoogleFonts.dmSans(
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
                            style: GoogleFonts.dmSans(
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
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        '$stock / $reorder $unit',
                        style: GoogleFonts.dmSans(
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
      if (!_isRevenueSale(inv)) continue;
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
      if (!_isRevenueSale(inv)) continue;
      final ts = readTimestamp(inv['createdAt']);
      if (ts == null || ts.isBefore(monthStart)) continue;
      final key = (inv['customerName'] ?? '').toString().trim();
      if (key.isEmpty) continue;
      result[key] = (result[key] ?? 0) + readInvoiceTotal(inv);
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Top Performers', 'Wabora wa Mwezi'),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        Text(
                          _tr('This month', 'Mwezi huu'),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (products.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PerformerSubsection(
                icon: Icons.inventory_2_outlined,
                label: _tr('Best Products', 'Bidhaa Bora'),
                color: AppColors.tealAccent,
                entries: products,
              ),
            ],

            if (products.isNotEmpty && customers.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              ),

            if (customers.isNotEmpty) ...[
              _PerformerSubsection(
                icon: Icons.star_rounded,
                label: _tr('Top Customers', 'Wateja Bora'),
                color: AppColors.primary,
                entries: customers,
              ),
            ],

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// Rank dot colours: gold / silver / bronze
const _rankColors = [Color(0xFFD4A017), Color(0xFF8A9BAE), Color(0xFFB87333)];

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.asMap().entries.map((e) {
            final rank = e.key;
            final entry = e.value;
            final rankColor = _rankColors[rank];
            return Padding(
              padding: EdgeInsets.only(
                bottom: rank < entries.length - 1 ? 6 : 0,
              ),
              child: Row(
                children: [
                  // Rank indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${rank + 1}',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: rankColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  // Name
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  Text(
                    _fmtCompactAmount(entry.value),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            );
          }),
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
      // Quotations, drafts and cancelled invoices are not transactions.
      if (!_isConfirmedSale(inv)) continue;
      final date = readTimestamp(inv['createdAt']);
      final amount = readInvoiceTotal(inv);
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
        const SizedBox(height: 4),
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
                  style: GoogleFonts.dmSans(
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
            padding: EdgeInsets.zero,
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final row = grouped[index];
              if (row['type'] == 'header') {
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12, bottom: 4),
                  child: Text(
                    row['label'] as String,
                    style: GoogleFonts.dmSans(
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
                      style: GoogleFonts.dmSans(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      row['subtitle'] as String,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      amountStr,
                      style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(
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
            style: GoogleFonts.dmSans(
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
                style: GoogleFonts.dmSans(
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
                style: GoogleFonts.dmSans(
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
        AppNotification.error(
          context,
          _tr('Could not open WhatsApp. Please make sure it is installed.', 'Imeshindwa kufungua WhatsApp. Hakikisha imesakinishwa.'),
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
      b.writeln('${_tr("Additional Notes", "Maelezo ya Ziada")}:');
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
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                ),
              ),
            ),
          ] else ...[
            Text(
              _tr('Tell us what you need', 'Tuambie unachohitaji'),
              style: GoogleFonts.dmSans(
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
              style: GoogleFonts.dmSans(
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
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.navyPrimary,
              ),
              decoration: InputDecoration(
                hintText: _tr(
                  'e.g. I sell clothing and want an online store…',
                  'mfano Nauza nguo na nataka duka la mtandaoni…',
                ),
                hintStyle: GoogleFonts.dmSans(
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
                        style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(
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

/// Formats a whole-shilling amount with thousands separators, e.g. 10000
/// becomes "10,000" rather than an approximated "10K"/"10M".
String _fmtWholeNumber(double amount) => amount
    .abs()
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

String _fmtCompactAmount(double amount) {
  final sign = amount < 0 ? '-' : '';
  return '${sign}TSh ${_fmtWholeNumber(amount)}';
}

String _fmtAmount(double amount) {
  final sign = amount < 0 ? '-' : '';
  return '${sign}TSh ${_fmtWholeNumber(amount)}';
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

/// True when the record is a confirmed sale (not a quotation, draft or
/// cancelled invoice) — regardless of whether it has been paid yet.
bool _isConfirmedSale(Map<String, dynamic> inv) {
  if ((inv['type'] ?? '').toString().toLowerCase() == 'quotation') return false;
  final s = readInvoiceStatus(inv).toLowerCase();
  return s != 'draft' && s != 'cancelled';
}

/// True when the sale counts toward revenue. Matches the P&L / sales reports
/// (cash-style): only paid, completed or partially-paid invoices count, so an
/// unpaid credit sale is a receivable, not revenue.
bool _isRevenueSale(Map<String, dynamic> inv) {
  if (!_isConfirmedSale(inv)) return false;
  final s = readInvoiceStatus(inv).toLowerCase();
  return s == 'paid' || s == 'completed' || s == 'partial';
}

double _revenueForPeriod(List<Map<String, dynamic>> invoices, int daysBack) {
  final now = DateTime.now();
  final cutoff = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: daysBack));
  return invoices.fold<double>(0, (total, inv) {
    if (!_isRevenueSale(inv)) return total;
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(cutoff)) return total;
    return total + readInvoiceTotal(inv);
  });
}

double _monthRevenue(List<Map<String, dynamic>> invoices) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);
  return invoices.fold<double>(0, (total, inv) {
    if (!_isRevenueSale(inv)) return total;
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(monthStart)) return total;
    return total + readInvoiceTotal(inv);
  });
}

double _yearRevenue(List<Map<String, dynamic>> invoices) {
  final now = DateTime.now();
  final yearStart = DateTime(now.year);
  return invoices.fold<double>(0, (total, inv) {
    if (!_isRevenueSale(inv)) return total;
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(yearStart)) return total;
    return total + readInvoiceTotal(inv);
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
    if (!_isRevenueSale(inv)) return total;
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(from) || d.isAfter(to)) return total;
    return total + readInvoiceTotal(inv);
  });
}

double _revenueForLastMonth(List<Map<String, dynamic>> invoices) {
  final now = DateTime.now();
  final lastMonthStart = DateTime(now.year, now.month - 1);
  final lastMonthEnd = DateTime(now.year, now.month);
  return invoices.fold<double>(0, (total, inv) {
    if (!_isRevenueSale(inv)) return total;
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) return total;
    final d = DateTime(ts.year, ts.month, ts.day);
    if (d.isBefore(lastMonthStart) || !d.isBefore(lastMonthEnd)) return total;
    return total + readInvoiceTotal(inv);
  });
}

// ── Chart data builder (fixes tooltip normalisation bug) ──────────────────────

Map<int, double> _buildDailySalesData(List<Map<String, dynamic>> invoices) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daily = <int, double>{};
  for (final inv in invoices) {
    if (!_isRevenueSale(inv)) continue;
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null) continue;
    final d = DateTime(ts.year, ts.month, ts.day);
    final daysAgo = today.difference(d).inDays;
    if (daysAgo < 0 || daysAgo > 6) continue;
    final idx = 6 - daysAgo;
    daily[idx] = (daily[idx] ?? 0) + readInvoiceTotal(inv);
  }
  return daily;
}

List<MapEntry<String, double>> _buildCategorySalesData(
  List<Map<String, dynamic>> invoices,
  List<Map<String, dynamic>> inventoryItems,
) {
  final now = DateTime.now();
  final cutoff = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final categoryByProductId = <String, String>{};

  for (final item in inventoryItems) {
    final id = (item['id'] ?? item['productId'] ?? '').toString();
    final category = (item['categoryName'] ?? item['category'] ?? '')
        .toString()
        .trim();
    if (id.isNotEmpty && category.isNotEmpty) {
      categoryByProductId[id] = category;
    }
  }

  final totals = <String, double>{};
  for (final invoice in invoices) {
    if (!_isRevenueSale(invoice)) continue;
    final timestamp = readTimestamp(invoice['createdAt']);
    if (timestamp == null) continue;
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
    if (date.isBefore(cutoff)) continue;

    final invoiceItems = invoice['items'] as List?;
    final rawItems = invoiceItems != null && invoiceItems.isNotEmpty
        ? invoiceItems
        : (invoice['lineItems'] as List?) ?? const [];
    final items = rawItems.whereType<Map>().toList();
    if (items.isEmpty) {
      final category = (invoice['category'] ?? '').toString().trim();
      final label = category.isEmpty ? _tr('Other', 'Nyingine') : category;
      totals[label] =
          (totals[label] ?? 0) + readInvoiceTotal(invoice);
      continue;
    }

    final rawLineTotal = items.fold<double>(0, (total, item) {
      final quantity = _numericValue(item['quantity'] ?? item['qty'] ?? 1);
      final value = _numericValue(item['total'] ?? item['lineTotal']);
      return total +
          (value > 0 ? value : _numericValue(item['unitPrice']) * quantity);
    });
    final invoiceTotal = readInvoiceTotal(invoice);
    final scale = rawLineTotal > 0 && invoiceTotal > 0
        ? invoiceTotal / rawLineTotal
        : 1.0;

    for (final item in items) {
      final productId =
          (item['productId'] ?? item['inventoryItemId'] ?? item['id'] ?? '')
              .toString();
      final storedCategory = (item['categoryName'] ?? item['category'] ?? '')
          .toString()
          .trim();
      final category = storedCategory.isNotEmpty
          ? storedCategory
          : categoryByProductId[productId] ?? _tr('Other', 'Nyingine');
      final quantity = _numericValue(item['quantity'] ?? item['qty'] ?? 1);
      final storedTotal = _numericValue(item['total'] ?? item['lineTotal']);
      final lineTotal = storedTotal > 0
          ? storedTotal
          : _numericValue(item['unitPrice']) * quantity;
      final allocatedTotal = rawLineTotal > 0
          ? lineTotal * scale
          : invoiceTotal / items.length;
      totals[category] = (totals[category] ?? 0) + allocatedTotal;
    }
  }

  final sorted = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (sorted.length <= 4) return sorted;

  final visible = sorted.take(3).toList();
  final other = sorted
      .skip(3)
      .fold<double>(0, (total, item) => total + item.value);
  return [...visible, MapEntry(_tr('Other', 'Nyingine'), other)];
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
    if (!_isRevenueSale(inv)) continue;
    final ts = readTimestamp(inv['createdAt']);
    if (ts == null || ts.isBefore(monthStart)) continue;
    final key = (inv['customerName'] ?? '').toString().trim();
    final amt = readInvoiceTotal(inv);
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
