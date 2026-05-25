import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reports_providers.dart';
import '../../services/report_export_service.dart';
import 'reports_hub_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class ApAgingScreen extends ConsumerWidget {
  const ApAgingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(apAgingProvider);
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
          _tr('AP Aging', 'Umri wa Madeni'),
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
          // Grand total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Text(
                _tr('Total Outstanding Payables', 'Jumla ya Madeni Yanayosubiri'),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                formatCurrency(report.grandTotal),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                _tr('Total cash required to clear all payables', 'Jumla ya pesa inayohitajika kulipa madeni yote'),
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Summary distribution
          _ApDistributionCard(report: report),
          const SizedBox(height: 12),

          // Bucket cards
          _ApBucketCard(
            bucket: report.current,
            color: AppColors.success,
            label: _tr('Current (0–30 days)', 'Sasa (siku 0–30)'),
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 8),
          _ApBucketCard(
            bucket: report.days31to60,
            color: AppColors.yellowBrand,
            label: _tr('30–60 Days', 'Siku 30–60'),
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 8),
          _ApBucketCard(
            bucket: report.days61to90,
            color: AppColors.warning,
            label: _tr('60–90 Days — Pay Soon', 'Siku 60–90 — Lipa Hivi Karibuni'),
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 8),
          _ApBucketCard(
            bucket: report.over90,
            color: AppColors.error,
            label: _tr('Over 90 Days — OVERDUE', 'Zaidi ya siku 90 — IMEPITA MUDA'),
            icon: Icons.error_outline_rounded,
          ),
          const SizedBox(height: 16),

          // Cash requirement note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tr(
                    'Prioritize paying 60+ day buckets to maintain supplier relationships.',
                    'Weka kipaumbele kulipa vikundi vya siku 60+ kudumisha uhusiano na wasambazaji.',
                  ),
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          ReportExportRow(
            onPdf: () => ReportExportService.shareApAgingPdf(report, periodLabel),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.apAgingCsv(report),
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

// ─── Distribution overview ────────────────────────────────────────────────────

class _ApDistributionCard extends StatelessWidget {
  final ApAgingReport report;
  const _ApDistributionCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final total = report.grandTotal;
    final buckets = [
      (label: '0–30', total: report.current.total, color: AppColors.success, count: report.current.items.length),
      (label: '31–60', total: report.days31to60.total, color: AppColors.yellowBrand, count: report.days31to60.items.length),
      (label: '61–90', total: report.days61to90.total, color: AppColors.warning, count: report.days61to90.items.length),
      (label: '90+', total: report.over90.total, color: AppColors.error, count: report.over90.items.length),
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
          ReportSectionTitle(title: _tr('Payable Distribution', 'Mgawanyo wa Madeni')),
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: buckets.map((b) {
                    final flex = b.total / total;
                    if (flex <= 0) return const SizedBox.shrink();
                    return Expanded(flex: (flex * 100).round(), child: Container(color: b.color));
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: buckets.map((b) => Column(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 4),
              Text(b.label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('${b.count}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Bucket card ──────────────────────────────────────────────────────────────

class _ApBucketCard extends StatefulWidget {
  final AgingBucket bucket;
  final Color color;
  final String label;
  final IconData icon;

  const _ApBucketCard({
    required this.bucket,
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  State<_ApBucketCard> createState() => _ApBucketCardState();
}

class _ApBucketCardState extends State<_ApBucketCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.bucket.items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color.withValues(alpha: 0.3)),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.label, style: TextStyle(color: widget.color, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('${widget.bucket.items.length} ${_tr('expenses', 'gharama')}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(formatCurrency(widget.bucket.total),
                      style: TextStyle(color: widget.color, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...widget.bucket.items.map((item) => _ExpenseRow(item: item, accentColor: widget.color)),
          ],
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accentColor;

  const _ExpenseRow({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final vendor = (item['recipient'] ?? _tr('Unknown vendor', 'Muuzaji asiyejulikana')).toString();
    final category = (item['category'] ?? '').toString();
    final ageDays = item['_ageDays'] as int? ?? 0;
    final amount = item['_amount'] as double? ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor.isNotEmpty ? vendor : _tr('Unknown', 'Haijulikana'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                if (category.isNotEmpty)
                  Text(category, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency(amount),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondary)),
              Text('$ageDays ${_tr('days', 'siku')}',
                  style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
