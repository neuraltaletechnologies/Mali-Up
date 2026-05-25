import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reports_providers.dart';
import '../../services/report_export_service.dart';
import 'reports_hub_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class CashFlowReportScreen extends ConsumerWidget {
  const CashFlowReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(cashFlowReportProvider);
    final range = ref.watch(reportDateRangeProvider);
    final isSwahili = LocalizationService.isSwahili;
    final periodLabel = isSwahili ? range.labelSw : range.label;
    final isPositive = report.netOperating >= 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.secondary),
        title: Text(
          _tr('Cash Flow Statement', 'Taarifa ya Mtiririko wa Fedha'),
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
          // Opening/closing balance chips
          Row(children: [
            Expanded(child: ReportStatCard(
              label: _tr('Opening Balance', 'Salio la Mwanzo'),
              value: formatCurrency(report.openingBalance),
              icon: Icons.account_balance_wallet_outlined,
            )),
            const SizedBox(width: 10),
            Expanded(child: ReportStatCard(
              label: _tr('Closing Balance', 'Salio la Mwisho'),
              value: formatCurrency(report.closingBalance),
              valueColor: report.closingBalance >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.account_balance_wallet_rounded,
            )),
          ]),
          const SizedBox(height: 10),

          // Net flow highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPositive ? AppColors.successBg : AppColors.errorBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isPositive ? AppColors.success : AppColors.error),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('Net Cash Flow', 'Mtiririko Halisi wa Fedha'),
                      style: TextStyle(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPositive
                          ? _tr('Positive — cash surplus', 'Chanya — ziada ya pesa')
                          : _tr('Negative — cash deficit', 'Hasi — upungufu wa pesa'),
                      style: TextStyle(
                        fontSize: 11,
                        color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${isPositive ? '+' : ''}${formatCurrency(report.netOperating)}',
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Waterfall visual
          _CashWaterfallCard(report: report),
          const SizedBox(height: 12),

          // Operating activities detail
          _CashActivityCard(
            title: _tr('Operating Inflows', 'Mapato ya Uendeshaji'),
            icon: Icons.arrow_downward_rounded,
            color: AppColors.success,
            amount: report.operatingInflows,
            items: report.lineItems.where((l) => l.isInflow).toList(),
          ),
          const SizedBox(height: 8),
          _CashActivityCard(
            title: _tr('Operating Outflows', 'Matumizi ya Uendeshaji'),
            icon: Icons.arrow_upward_rounded,
            color: AppColors.error,
            amount: report.operatingOutflows,
            items: report.lineItems.where((l) => !l.isInflow).toList(),
          ),
          const SizedBox(height: 16),

          ReportExportRow(
            onPdf: () => ReportExportService.shareCashFlowPdf(report, periodLabel),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.cashFlowCsv(report, periodLabel),
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

// ─── Cash waterfall bar chart ─────────────────────────────────────────────────

class _CashWaterfallCard extends StatelessWidget {
  final CashFlowReport report;
  const _CashWaterfallCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final maxVal = [
      report.openingBalance,
      report.operatingInflows,
      report.operatingOutflows,
      report.closingBalance,
    ].fold(0.0, (m, v) => v.abs() > m ? v.abs() : m);

    final groups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(
        toY: report.openingBalance,
        color: AppColors.secondary,
        width: 28,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      )]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(
        toY: report.operatingInflows,
        color: AppColors.success,
        width: 28,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      )]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(
        toY: report.operatingOutflows,
        color: AppColors.error.withValues(alpha: 0.8),
        width: 28,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      )]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(
        toY: report.closingBalance,
        color: report.closingBalance >= 0 ? AppColors.success : AppColors.error,
        width: 28,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      )]),
    ];

    final labels = [
      _tr('Opening', 'Mwanzo'),
      _tr('Inflows', 'Mapato'),
      _tr('Outflows', 'Matumizi'),
      _tr('Closing', 'Mwisho'),
    ];

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
          ReportSectionTitle(title: _tr('Cash Flow Overview', 'Muhtasari wa Mtiririko wa Fedha')),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              maxY: maxVal * 1.2,
              barGroups: groups,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labels[idx], style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
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

// ─── Activity card ────────────────────────────────────────────────────────────

class _CashActivityCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double amount;
  final List<({String label, double amount, bool isInflow})> items;

  const _CashActivityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.amount,
    required this.items,
  });

  @override
  State<_CashActivityCard> createState() => _CashActivityCardState();
}

class _CashActivityCardState extends State<_CashActivityCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.title,
                        style: TextStyle(color: widget.color, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  Text(formatCurrency(widget.amount),
                      style: TextStyle(color: widget.color, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
          if (_expanded && widget.items.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            ...widget.items.take(20).map((item) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(item.label,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    formatCurrency(item.amount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.isInflow ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            )),
            if (widget.items.length > 20)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Text(
                  '+ ${widget.items.length - 20} ${_tr('more transactions', 'miamala mingine')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
