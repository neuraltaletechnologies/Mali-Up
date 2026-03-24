import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MALIAPP'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning, Neuraltale',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "Here's what's happening today",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            // KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _KPICard(
                    title: 'Today Revenue',
                    value: 'TSh 1.2M',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _KPICard(
                    title: 'Active Orders',
                    value: '24',
                    icon: Icons.shopping_basket_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _KPICard(
                    title: 'New Customers',
                    value: '12',
                    icon: Icons.people_outline,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _KPICard(
                    title: 'Stock Alerts',
                    value: '3',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Sales Chart Section
            const Text(
              'Sales Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
              color: Colors.white,
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
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.0),
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
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(color: AppColors.primaryLight)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF334155),
                  child: Icon(Icons.receipt_long_outlined, color: Colors.white, size: 20),
                ),
                title: Text(
                  'Sales Invoice #1204',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Paid via M-Pesa • Today, 10:45 AM', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                trailing: Text(
                  'TSh 45,000',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
