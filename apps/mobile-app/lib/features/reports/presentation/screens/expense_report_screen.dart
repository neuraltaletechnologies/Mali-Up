import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reports_providers.dart';
import '../../services/report_export_service.dart';
import 'reports_hub_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class ExpenseReportScreen extends ConsumerWidget {
  const ExpenseReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(expenseReportProvider);
    final range = ref.watch(reportDateRangeProvider);
    final isSwahili = LocalizationService.isSwahili;
    final periodLabel = isSwahili ? range.labelSw : range.label;

    final sortedCategories = report.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topVendors = (report.byVendor.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.secondary),
        title: Text(
          _tr('Expense Report', 'Ripoti ya Gharama'),
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
          Row(children: [
            Expanded(child: ReportStatCard(
              label: _tr('Total Expenses', 'Jumla ya Gharama'),
              value: formatCurrency(report.totalExpenses),
              valueColor: AppColors.error,
              icon: Icons.trending_down_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: ReportStatCard(
              label: _tr('Transactions', 'Miamala'),
              value: '${report.expenseCount}',
              icon: Icons.receipt_rounded,
            )),
          ]),
          const SizedBox(height: 16),

          // Category breakdown with horizontal bars
          if (sortedCategories.isNotEmpty) ...[
            _CategoryBreakdownCard(
              categories: sortedCategories,
              total: report.totalExpenses,
            ),
            const SizedBox(height: 12),
          ],

          // 6-month trend
          _ExpenseTrendCard(trend: report.trend),
          const SizedBox(height: 12),

          // Payment method split
          if (report.byPaymentMethod.isNotEmpty) ...[
            _PaymentMethodCard(byMethod: report.byPaymentMethod, total: report.totalExpenses),
            const SizedBox(height: 12),
          ],

          // Top vendors
          if (topVendors.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportSectionTitle(title: _tr('Top Vendors', 'Wauzaji Wakuu')),
                  ...topVendors.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(e.value.key, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ]),
                        Text(formatCurrency(e.value.value),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          ReportExportRow(
            onPdf: () => ReportExportService.shareExpensePdf(report, periodLabel),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.expenseCsv(report, periodLabel),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_tr('CSV copied to clipboard', 'CSV imenakiliwa')),
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

// ─── Category horizontal bar card ────────────────────────────────────────────

class _CategoryBreakdownCard extends StatelessWidget {
  final List<MapEntry<String, double>> categories;
  final double total;

  const _CategoryBreakdownCard({required this.categories, required this.total});

  static const _palette = [
    AppColors.error, AppColors.warning, AppColors.tealAccent,
    AppColors.secondary, AppColors.purpleAccent, AppColors.success,
  ];

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
          ReportSectionTitle(title: _tr('By Category', 'Kwa Kategoria')),
          ...categories.asMap().entries.take(8).map((e) {
            final pct = total > 0 ? e.value.value / total : 0.0;
            final color = _palette[e.key % _palette.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text(e.value.key, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                    Text(
                      '${formatCurrency(e.value.value)} (${(pct * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.border,
                      color: color,
                      minHeight: 5,
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

// ─── Expense trend line chart ─────────────────────────────────────────────────

class _ExpenseTrendCard extends StatelessWidget {
  final List<({int month, int year, double total})> trend;
  const _ExpenseTrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final spots = trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList();

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
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: LineChart(LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.error,
                  barWidth: 2.5,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.error.withValues(alpha: 0.08),
                  ),
                  dotData: const FlDotData(show: false),
                ),
              ],
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                      return Text(monthLabel(trend[idx].month),
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted));
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

// ─── Payment method card ──────────────────────────────────────────────────────

class _PaymentMethodCard extends StatelessWidget {
  final Map<String, double> byMethod;
  final double total;
  const _PaymentMethodCard({required this.byMethod, required this.total});

  @override
  Widget build(BuildContext context) {
    final entries = byMethod.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
          ReportSectionTitle(title: _tr('By Payment Method', 'Kwa Njia ya Malipo')),
          ...entries.map((e) {
            final pct = total > 0 ? e.value / total * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text('${formatCurrency(e.value)} · ${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
