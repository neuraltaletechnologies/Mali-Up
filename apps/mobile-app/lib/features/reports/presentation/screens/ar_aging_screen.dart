import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reports_providers.dart';
import '../../services/report_export_service.dart';
import 'reports_hub_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class ArAgingScreen extends ConsumerWidget {
  const ArAgingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(arAgingProvider);
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
          _tr('AR Aging', 'Umri wa Madai'),
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
          // Grand total card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  _tr('Total Outstanding Receivables', 'Jumla ya Madai Yanayosubiri'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(report.grandTotal),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Aging bar chart overview
          _AgingSummaryBar(report: report),
          const SizedBox(height: 12),

          // Bucket cards
          _AgingBucketCard(
            bucket: report.current,
            color: AppColors.success,
            label: _tr('Current (0–30 days)', 'Sasa (siku 0–30)'),
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 8),
          _AgingBucketCard(
            bucket: report.days31to60,
            color: AppColors.yellowBrand,
            label: _tr('30–60 Days', 'Siku 30–60'),
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 8),
          _AgingBucketCard(
            bucket: report.days61to90,
            color: AppColors.warning,
            label: _tr('60–90 Days', 'Siku 60–90'),
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 8),
          _AgingBucketCard(
            bucket: report.over90,
            color: AppColors.error,
            label: _tr('Over 90 Days — CRITICAL', 'Zaidi ya siku 90 — MUHIMU'),
            icon: Icons.error_outline_rounded,
          ),
          const SizedBox(height: 16),

          ReportExportRow(
            onPdf: () => ReportExportService.shareArAgingPdf(report, periodLabel),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.arAgingCsv(report),
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

// ─── Aging summary bar ────────────────────────────────────────────────────────

class _AgingSummaryBar extends StatelessWidget {
  final ArAgingReport report;
  const _AgingSummaryBar({required this.report});

  @override
  Widget build(BuildContext context) {
    final total = report.grandTotal;

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
          ReportSectionTitle(title: _tr('Aging Distribution', 'Mgawanyo wa Umri')),
          const SizedBox(height: 8),
          // Stacked visual bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 16,
                child: Row(children: [
                  _BarSegment(flex: report.current.total / total, color: AppColors.success),
                  _BarSegment(flex: report.days31to60.total / total, color: AppColors.yellowBrand),
                  _BarSegment(flex: report.days61to90.total / total, color: AppColors.warning),
                  _BarSegment(flex: report.over90.total / total, color: AppColors.error),
                ]),
              ),
            ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _AgingLegend(label: '0–30', amount: report.current.total, color: AppColors.success, count: report.current.items.length),
            _AgingLegend(label: '31–60', amount: report.days31to60.total, color: AppColors.yellowBrand, count: report.days31to60.items.length),
            _AgingLegend(label: '61–90', amount: report.days61to90.total, color: AppColors.warning, count: report.days61to90.items.length),
            _AgingLegend(label: '90+', amount: report.over90.total, color: AppColors.error, count: report.over90.items.length),
          ]),
        ],
      ),
    );
  }
}

class _BarSegment extends StatelessWidget {
  final double flex;
  final Color color;
  const _BarSegment({required this.flex, required this.color});

  @override
  Widget build(BuildContext context) {
    if (flex <= 0) return const SizedBox.shrink();
    return Expanded(flex: (flex * 100).round(), child: Container(color: color));
  }
}

class _AgingLegend extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final int count;

  const _AgingLegend({required this.label, required this.amount, required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      Text('$count inv', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    ]);
  }
}

// ─── Aging bucket card ────────────────────────────────────────────────────────

class _AgingBucketCard extends StatefulWidget {
  final AgingBucket bucket;
  final Color color;
  final String label;
  final IconData icon;

  const _AgingBucketCard({
    required this.bucket,
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  State<_AgingBucketCard> createState() => _AgingBucketCardState();
}

class _AgingBucketCardState extends State<_AgingBucketCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bucket = widget.bucket;
    if (bucket.items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.label, style: TextStyle(color: widget.color, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('${bucket.items.length} ${_tr('invoices', 'ankara')}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(formatCurrency(bucket.total),
                      style: TextStyle(color: widget.color, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
          // Items
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...bucket.items.map((inv) => _InvoiceRow(invoice: inv, accentColor: widget.color)),
          ],
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final Color accentColor;

  const _InvoiceRow({required this.invoice, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final customer = (invoice['customerName'] ?? invoice['customer'] ?? _tr('Unknown', 'Haijulikani')).toString();
    final number = '#${(invoice['invoiceNumber'] ?? invoice['id'].toString()).toString().characters.take(8)}';
    final ageDays = invoice['_ageDays'] as int? ?? 0;
    final amount = invoice['_amount'] as double? ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                Text(number, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondary)),
              Text('$ageDays ${_tr('days', 'siku')}', style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
