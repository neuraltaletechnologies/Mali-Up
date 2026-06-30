import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
import '../../data/reports_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─── Hub Screen ───────────────────────────────────────────────────────────────

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);
    final planAsync = ref.watch(planStatusProvider);
    final locked = planAsync.whenOrNull(data: (s) => !s.limits.fullReports) ?? true;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 50, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Financial Reports', 'Ripoti za Kifedha'),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tr('Full picture of your business finances', 'Picha kamili ya fedha za biashara yako'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  _DateRangeBar(range: range),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _SectionHeader(label: _tr('PROFIT & POSITION', 'FAIDA & HALI')),
          _ReportCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.success,
            title: _tr('Profit & Loss', 'Faida na Hasara'),
            subtitle: _tr('Revenue vs expenses for any period', 'Mapato dhidi ya gharama kwa kipindi chochote'),
            route: '/reports/pnl',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          _ReportCard(
            icon: Icons.account_balance_rounded,
            iconColor: AppColors.secondary,
            title: _tr('Balance Sheet', 'Karatasi ya Mizania'),
            subtitle: _tr('Assets, liabilities and owner equity snapshot', 'Rasilimali, madeni na hisa ya mmiliki'),
            route: '/reports/balance-sheet',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          _ReportCard(
            icon: Icons.water_drop_rounded,
            iconColor: AppColors.tealAccent,
            title: _tr('Cash Flow Statement', 'Taarifa ya Mtiririko wa Fedha'),
            subtitle: _tr('All inflows and outflows by activity', 'Mapato yote na matumizi kwa shughuli'),
            route: '/reports/cash-flow',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          _SectionHeader(label: _tr('SALES & EXPENSES', 'MAUZO & GHARAMA')),
          _ReportCard(
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.yellowBrand,
            title: _tr('Sales Report', 'Ripoti ya Mauzo'),
            subtitle: _tr('By product, customer, staff and payment method', 'Kwa bidhaa, mteja, mfanyakazi na njia ya malipo'),
            route: '/reports/sales',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          _ReportCard(
            icon: Icons.pie_chart_rounded,
            iconColor: AppColors.warning,
            title: _tr('Expense Report', 'Ripoti ya Gharama'),
            subtitle: _tr('By category, vendor and period with trends', 'Kwa kategoria, muuzaji na kipindi na mwenendo'),
            route: '/reports/expenses',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          _ReportCard(
            icon: Icons.percent_rounded,
            iconColor: AppColors.purpleAccent,
            title: _tr('VAT Summary', 'Muhtasari wa VAT'),
            subtitle: _tr('VAT collected vs paid — TRA compliance', 'VAT iliyokusanywa dhidi ya kulipwa — kufuata TRA'),
            route: '/reports/vat',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          _SectionHeader(label: _tr('AGING & STOCK', 'UMRI & HISA')),
          _ReportCard(
            icon: Icons.people_alt_rounded,
            iconColor: AppColors.error,
            title: _tr('Accounts Receivable Aging', 'Umri wa Madai'),
            subtitle: _tr('Customer overdue invoices with collection priority', 'Ankara zilizopita muda kwa wateja na kipaumbele cha ukusanyaji'),
            route: '/reports/ar-aging',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          _ReportCard(
            icon: Icons.local_shipping_rounded,
            iconColor: AppColors.warning,
            title: _tr('Accounts Payable Aging', 'Umri wa Madeni'),
            subtitle: _tr('Supplier aging with upcoming due dates', 'Umri wa wasambazaji na tarehe za malipo yanayokuja'),
            route: '/reports/ap-aging',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          _ReportCard(
            icon: Icons.inventory_2_rounded,
            iconColor: AppColors.success,
            title: _tr('Inventory Valuation', 'Tathmini ya Hisa'),
            subtitle: _tr('Stock on hand valued at cost — FIFO & weighted average', 'Hisa iliyopo kwa gharama — FIFO na wastani uliopimwa'),
            route: '/reports/inventory-valuation',
            locked: locked,
            onLockedTap: () => planAsync.whenOrNull(data: (s) => showUpgradeSheet(context, currentStatus: s)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─── Date Range Bar ───────────────────────────────────────────────────────────

class _DateRangeBar extends ConsumerWidget {
  final ReportDateRange range;
  const _DateRangeBar({required this.range});

  static const _periods = [
    ReportPeriod.thisMonth,
    ReportPeriod.lastMonth,
    ReportPeriod.thisQuarter,
    ReportPeriod.thisYear,
    ReportPeriod.custom,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSwahili = LocalizationService.isSwahili;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        separatorBuilder: (_, i) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final period = _periods[i];
          final isSelected = range.period == period;
          final dummy = ReportDateRange.forPeriod(period);
          final label = isSwahili ? dummy.labelSw : dummy.label;

          return GestureDetector(
            onTap: () async {
              if (period == ReportPeriod.custom) {
                await _pickCustomRange(context, ref);
              } else {
                ref.read(reportDateRangeProvider.notifier).setPeriod(period);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.secondary : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month),
        end: now,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.secondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(reportDateRangeProvider.notifier).setCustomRange(picked.start, picked.end);
    }
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Row(
          children: [
            const Expanded(child: Divider(height: 1, color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Expanded(child: Divider(height: 1, color: AppColors.border)),
          ],
        ),
      ),
    );
  }
}

// ─── Report Card ──────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String route;
  final bool locked;
  final VoidCallback? onLockedTap;

  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.route,
    this.locked = false,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: locked ? onLockedTap : () => context.go(route),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared date range bar widget (used by sub-screens) ──────────────────────

class ReportDateRangeBar extends ConsumerWidget {
  const ReportDateRangeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);
    return _DateRangeBar(range: range);
  }
}

// ─── Shared export row (PDF + CSV) used by sub-screens ───────────────────────

class ReportExportRow extends StatelessWidget {
  final VoidCallback onPdf;
  final VoidCallback onCsv;

  const ReportExportRow({super.key, required this.onPdf, required this.onCsv});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCsv,
            icon: const Icon(Icons.table_chart_rounded, size: 16),
            label: const Text('CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared stat card ─────────────────────────────────────────────────────────

class ReportStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const ReportStatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared section title ─────────────────────────────────────────────────────

class ReportSectionTitle extends StatelessWidget {
  final String title;
  const ReportSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Shared currency formatter ────────────────────────────────────────────────

String formatCurrency(double v) {
  final formatted = v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'TZS $formatted';
}

String formatPercent(double v) => '${v.toStringAsFixed(1)}%';
