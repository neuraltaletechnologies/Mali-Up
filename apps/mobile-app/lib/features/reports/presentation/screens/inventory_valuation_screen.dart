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

class InventoryValuationScreen extends ConsumerWidget {
  const InventoryValuationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(inventoryValuationProvider);
    final now = DateTime.now();
    final dateLabel = '${now.day}/${now.month}/${now.year}';

    final sortedCategories = report.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.secondary),
        title: Text(
          _tr('Inventory Valuation', 'Tathmini ya Hisa'),
          style: GoogleFonts.dmSans(color: AppColors.secondary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                _tr('As of $dateLabel', 'Hadi $dateLabel'),
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.tealAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('Total Inventory Value', 'Jumla ya Thamani ya Hisa'),
                        style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formatCurrency(report.totalValue),
                        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _tr('Weighted average cost method', 'Njia ya wastani uliopimwa wa gharama'),
                        style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${report.totalSkus}',
                      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    Text(_tr('SKUs', 'Bidhaa'), style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11)),
                    SizedBox(height: 8),
                    Text(
                      report.totalUnits.toStringAsFixed(0),
                      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(_tr('total units', 'vitengo vyote'), style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // FIFO vs Weighted Average note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.tealAccent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tr(
                      'Valuation uses unit selling price as cost proxy. For FIFO accuracy, record purchase prices in inventory.',
                      'Tathmini inatumia bei ya mauzo kama mbadala wa gharama. Kwa usahihi wa FIFO, rekodi bei za ununuzi kwenye hisa.',
                    ),
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // By category pie chart
          if (sortedCategories.isNotEmpty) ...[
            _CategoryPieCard(categories: sortedCategories, total: report.totalValue),
            const SizedBox(height: 12),
          ],

          // Item list
          if (report.items.isNotEmpty) ...[
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
                  ReportSectionTitle(title: _tr('Stock Items — Ranked by Value', 'Bidhaa — Zilizoainishwa kwa Thamani')),
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(_tr('Item', 'Bidhaa'), style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                        Expanded(flex: 2, child: Text(_tr('Stock', 'Hisa'), style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text(_tr('Value', 'Thamani'), style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  ...report.items.take(50).toList().asMap().entries.map((e) {
                    final item = e.value;
                    final pct = report.totalValue > 0 ? item.totalValue / report.totalValue : 0.0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: e.key.isOdd ? AppColors.surface : Colors.white,
                        border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(item.category,
                                    style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.stock.toStringAsFixed(0)} ${item.unit}',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatCurrency(item.totalValue),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary),
                                ),
                                Text(
                                  '${(pct * 100).toStringAsFixed(1)}%',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (report.items.length > 50)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+ ${report.items.length - 50} ${_tr('more items', 'bidhaa zaidi')}',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          ReportExportRow(
            onPdf: () => ReportExportService.shareInventoryPdf(report, dateLabel),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.inventoryCsv(report),
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

// ─── Category pie chart card ──────────────────────────────────────────────────

class _CategoryPieCard extends StatelessWidget {
  final List<MapEntry<String, double>> categories;
  final double total;

  const _CategoryPieCard({required this.categories, required this.total});

  static const _colors = [
    AppColors.secondary, AppColors.tealAccent, AppColors.success,
    AppColors.yellowBrand, AppColors.purpleAccent, AppColors.warning,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    final top = categories.take(6).toList();

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
          ReportSectionTitle(title: _tr('Value by Category', 'Thamani kwa Kategoria')),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(PieChartData(
                  sections: top.asMap().entries.map((e) {
                    final pct = total > 0 ? e.value.value / total * 100 : 0.0;
                    return PieChartSectionData(
                      value: e.value.value,
                      color: _colors[e.key % _colors.length],
                      radius: 50,
                      title: '${pct.toStringAsFixed(0)}%',
                      titleStyle: GoogleFonts.dmSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 24,
                )),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: top.asMap().entries.map((e) {
                    final color = _colors[e.key % _colors.length];
                    final pct = total > 0 ? e.value.value / total * 100 : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.value.key,
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('${pct.toStringAsFixed(1)}%',
                                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
                          ]),
                        ),
                      ]),
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
