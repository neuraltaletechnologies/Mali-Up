import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reports_providers.dart';
import '../../services/report_export_service.dart';
import 'reports_hub_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(salesReportProvider);
    final range = ref.watch(reportDateRangeProvider);
    final isSwahili = LocalizationService.isSwahili;
    final periodLabel = isSwahili ? range.labelSw : range.label;

    final topProducts =
        (report.byProduct.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .toList();

    final topCustomers =
        (report.byCustomer.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.secondary),
        title: Text(
          _tr('Sales Report', 'Ripoti ya Mauzo'),
          style: GoogleFonts.dmSans(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
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
          Row(
            children: [
              Expanded(
                child: ReportStatCard(
                  label: _tr('Total Revenue', 'Jumla ya Mapato'),
                  value: formatCurrency(report.totalRevenue),
                  valueColor: AppColors.success,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ReportStatCard(
                  label: _tr('Invoices', 'Ankara'),
                  value: '${report.invoiceCount}',
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ReportStatCard(
            label: _tr('Average Invoice Value', 'Wastani wa Thamani ya Ankara'),
            value: formatCurrency(report.averageInvoiceValue),
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 16),

          // Payment method breakdown + pie chart
          if (report.byPaymentMethod.isNotEmpty) ...[
            _PaymentPieCard(report: report),
            const SizedBox(height: 12),
          ],

          // 6-month trend
          _SalesTrendCard(trend: report.trend),
          const SizedBox(height: 12),

          // Top products
          if (topProducts.isNotEmpty) ...[
            _RankedListCard(
              title: _tr('Top Products', 'Bidhaa Bora'),
              entries: topProducts,
              total: report.totalRevenue,
            ),
            const SizedBox(height: 12),
          ],

          // Top customers
          if (topCustomers.isNotEmpty) ...[
            _RankedListCard(
              title: _tr('Top Customers', 'Wateja Bora'),
              entries: topCustomers,
              total: report.totalRevenue,
              icon: Icons.people_alt_rounded,
            ),
            const SizedBox(height: 16),
          ],

          ReportExportRow(
            onPdf: () => exportReportPdf(
              context,
              () => ReportExportService.shareSalesPdf(report, periodLabel),
            ),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.salesCsv(report, periodLabel),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _tr(
                        'CSV copied to clipboard',
                        'CSV imenakiliwa kwenye ubao wa kunakili',
                      ),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─── Payment pie card ─────────────────────────────────────────────────────────

class _PaymentPieCard extends StatelessWidget {
  final SalesReport report;
  const _PaymentPieCard({required this.report});

  static const _colors = [
    AppColors.yellowBrand,
    AppColors.secondary,
    AppColors.success,
    AppColors.tealAccent,
    AppColors.purpleAccent,
    AppColors.warning,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = report.byPaymentMethod.entries.toList();

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
          ReportSectionTitle(
            title: _tr('By Payment Method', 'Kwa Njia ya Malipo'),
          ),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: entries.asMap().entries.map((e) {
                      final pct = report.totalRevenue > 0
                          ? e.value.value / report.totalRevenue * 100
                          : 0.0;
                      return PieChartSectionData(
                        value: e.value.value,
                        color: _colors[e.key % _colors.length],
                        radius: 44,
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((e) {
                    final color = _colors[e.key % _colors.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value.key,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            formatCurrency(e.value.value),
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sales trend bar chart ────────────────────────────────────────────────────

class _SalesTrendCard extends StatelessWidget {
  final List<({int month, int year, double total})> trend;
  const _SalesTrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final groups = trend.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.total,
            gradient: const LinearGradient(
              colors: [AppColors.yellowBrand, AppColors.secondary],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
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
          ReportSectionTitle(
            title: _tr(
              'Revenue Trend (6 months)',
              'Mwenendo wa Mapato (miezi 6)',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                barGroups: groups,
                gridData: const FlGridData(drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          monthLabel(trend[idx].month),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ranked list card ─────────────────────────────────────────────────────────

class _RankedListCard extends StatelessWidget {
  final String title;
  final List<MapEntry<String, double>> entries;
  final double total;
  final IconData? icon;

  const _RankedListCard({
    required this.title,
    required this.entries,
    required this.total,
    this.icon,
  });

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
          ...entries.asMap().entries.map((e) {
            final pct = total > 0 ? e.value.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.value.key,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatCurrency(e.value.value),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.border,
                      color: AppColors.yellowBrand,
                      minHeight: 4,
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
