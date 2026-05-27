import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reports_providers.dart';
import '../../services/report_export_service.dart';
import 'reports_hub_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class ProfitLossScreen extends ConsumerWidget {
  const ProfitLossScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(pnlReportProvider);
    final range = ref.watch(reportDateRangeProvider);
    final isSwahili = LocalizationService.isSwahili;
    final periodLabel = isSwahili ? range.labelSw : range.label;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.secondary),
        title: Text(
          _tr('Profit & Loss', 'Faida na Hasara'),
          style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(52),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ReportDateRangeBar(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(children: [
            Expanded(child: ReportStatCard(
              label: _tr('Revenue', 'Mapato'),
              value: formatCurrency(report.revenue),
              valueColor: AppColors.success,
              icon: Icons.trending_up_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: ReportStatCard(
              label: _tr('Expenses', 'Gharama'),
              value: formatCurrency(report.totalExpenses),
              valueColor: AppColors.error,
              icon: Icons.trending_down_rounded,
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ReportStatCard(
              label: _tr('Net Profit', 'Faida Halisi'),
              value: formatCurrency(report.netProfit),
              valueColor: report.netProfit >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.account_balance_wallet_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: ReportStatCard(
              label: _tr('Profit Margin', 'Asilimia ya Faida'),
              value: formatPercent(report.profitMargin),
              valueColor: report.profitMargin >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.percent_rounded,
            )),
          ]),
          const SizedBox(height: 16),

          // 6-month trend chart
          _TrendCard(trend: report.trend),
          const SizedBox(height: 16),

          // Revenue section
          _DetailCard(
            title: _tr('Revenue Breakdown', 'Muundo wa Mapato'),
            children: [
              _LineItem(label: _tr('Total Sales Revenue', 'Mapato ya Mauzo'), value: formatCurrency(report.revenue)),
              _LineItem(label: _tr('VAT Collected', 'VAT Iliyokusanywa'), value: formatCurrency(report.vatCollected)),
              _LineItem(label: _tr('Invoices Paid', 'Ankara Zilizolipwa'), value: '${report.invoiceCount}', isAmount: false),
            ],
          ),
          const SizedBox(height: 12),

          // Expenses section
          _DetailCard(
            title: _tr('Expense Breakdown', 'Muundo wa Gharama'),
            children: [
              ...(() {
                final sorted = report.expenseByCategory.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return sorted.take(10).map((e) => _LineItem(
                  label: e.key,
                  value: formatCurrency(e.value),
                ));
              })(),
              _LineItem(
                label: _tr('Total Expenses', 'Jumla ya Gharama'),
                value: formatCurrency(report.totalExpenses),
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Net profit summary box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: report.netProfit >= 0
                  ? AppColors.successBg
                  : AppColors.errorBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: report.netProfit >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tr('NET PROFIT', 'FAIDA HALISI'),
                  style: TextStyle(
                    color: report.netProfit >= 0 ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  formatCurrency(report.netProfit),
                  style: TextStyle(
                    color: report.netProfit >= 0 ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Export
          ReportExportRow(
            onPdf: () => ReportExportService.sharePnlPdf(report, periodLabel),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.pnlCsv(report, periodLabel),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_tr('CSV copied to clipboard', 'CSV imenakiliwa kwenye ubao wa kunakili')),
                  backgroundColor: AppColors.success,
                ));
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── 6-month trend chart ──────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  final List<({int month, int year, double revenue, double expenses})> trend;
  const _TrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    const barWidth = 10.0;
    final groups = trend.asMap().entries.map((e) {
      return BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(
          toY: e.value.revenue,
          color: AppColors.success,
          width: barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: e.value.expenses,
          color: AppColors.error.withValues(alpha: 0.75),
          width: barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ]);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportSectionTitle(title: _tr('6-Month Trend', 'Mwenendo wa Miezi 6')),
          Row(children: [
            _Legend(color: AppColors.success, label: _tr('Revenue', 'Mapato')),
            const SizedBox(width: 14),
            _Legend(color: AppColors.error, label: _tr('Expenses', 'Gharama')),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              barGroups: groups,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                      return Text(
                        monthLabel(trend[idx].month),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    ]);
  }
}

// ─── Detail card ──────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportSectionTitle(title: title),
          ...children,
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool isAmount;

  const _LineItem({required this.label, required this.value, this.bold = false, this.isAmount = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: bold ? AppColors.secondary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
          Text(value,
              style: TextStyle(
                color: bold ? AppColors.secondary : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
