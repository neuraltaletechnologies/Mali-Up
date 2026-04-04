import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../config/routing.dart';
import '../../../../shared/widgets/emotional_design.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../debt/data/debt_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _entryRewardTrigger = 0;
  bool _showEntryReward = false;

  @override
  void initState() {
    super.initState();
    _showFirstEntryRewardIfNeeded();
  }

  Future<void> _showFirstEntryRewardIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('dashboard_first_reward_seen') ?? false;
    if (seen || !mounted) return;

    setState(() {
      _showEntryReward = true;
      _entryRewardTrigger++;
    });

    await prefs.setBool('dashboard_first_reward_seen', true);
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _showEntryReward = false);
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider);
    final debts = ref.watch(debtListProvider);
    final customerCount = customers.maybeWhen(data: (items) => items.length, orElse: () => 0);
    final debtItems = debts.maybeWhen(data: (items) => items, orElse: () => const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mali Up'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, Neuraltale',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            "Here's what's happening today",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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

                // KPI Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (_showEntryReward)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.primary.withValues(alpha: 0.16),
                                        AppColors.primary.withValues(alpha: 0.0),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                            ),
                          const _KPICard(
                            title: 'Today Revenue',
                            value: 'TSh 1.2M',
                            icon: Icons.trending_up,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (_showEntryReward)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.secondaryLight.withValues(alpha: 0.12),
                                        AppColors.secondaryLight.withValues(alpha: 0.0),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                            ),
                          _KPICard(
                            title: 'Active Clients',
                            value: '$customerCount',
                            icon: Icons.people_outline,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Debt Quick View Card
                _DebtQuickView(debts: debtItems),

                const SizedBox(height: 32),

                // Sales Chart Section
                const Text(
                  'Sales Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  height: 200,
                  child: _SalesLineChart(),
                ),

                const SizedBox(height: 32),

                // Recent Transactions
                const _RecentTransactionsList(),
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
                const Text(
                  'Debt Exposure',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'TSh 4.2M',
                      style: TextStyle(color: AppColors.error, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('PAYABLE', style: TextStyle(color: AppColors.error, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  const _SalesLineChart();

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 3),
              const FlSpot(1, 1),
              const FlSpot(2, 4),
              const FlSpot(3, 2),
              const FlSpot(4, 5),
              const FlSpot(5, 3),
              const FlSpot(6, 4),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
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

class _RecentTransactionsList extends StatelessWidget {
  const _RecentTransactionsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
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
                    color: (isExpense ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
                    color: isExpense ? AppColors.error : AppColors.success,
                    size: 20,
                  ),
                ),
                title: Text(
                  isExpense ? 'Shop Rent Payment' : 'Product Sale #2409',
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  isExpense ? 'Expense • Oct 01, 2026' : 'Revenue • Today, 10:45 AM',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                trailing: Text(
                  isExpense ? '-850,000' : '+45,000',
                  style: TextStyle(
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

