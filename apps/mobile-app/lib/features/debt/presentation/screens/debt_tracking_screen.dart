import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../data/debt_providers.dart';
import '../../domain/models/debt.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ── Formatting helpers ────────────────────────────────────────────────────────

String _fmtAmt(double v) {
  if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
  return 'TZS ${v.toStringAsFixed(0)}';
}

String _fmtFull(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'TZS $buf';
}

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${_monthShort(d.month)} ${d.year}';
}

String _monthShort(int m) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][m - 1];

// ── Main Screen ───────────────────────────────────────────────────────────────

class DebtTrackingScreen extends ConsumerStatefulWidget {
  const DebtTrackingScreen({super.key});

  @override
  ConsumerState<DebtTrackingScreen> createState() => _DebtTrackingScreenState();
}

class _DebtTrackingScreenState extends ConsumerState<DebtTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openAdd({bool isReceivable = true, Debt? edit}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddDebtScreen(
        initialIsReceivable: isReceivable,
        debtToEdit: edit,
      ),
    ));
  }

  void _openDetail(Debt debt) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DebtDetailScreen(debt: debt),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final totalRec = ref.watch(totalReceivablesProvider);
    final totalPay = ref.watch(totalPayablesProvider);
    final isLoading = ref.watch(debtListProvider).isLoading;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.navyPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HeroHeader(
                totalReceivables: totalRec,
                totalPayables: totalPay,
                isLoading: isLoading,
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.yellowBrand,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: _tr('Receivables', 'Wadai')),
                Tab(text: _tr('Payables', 'Madeni')),
                Tab(text: _tr('Aging', 'Uchambuzi')),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _ReceivablesTab(onTap: _openDetail),
            _PayablesTab(onTap: _openDetail),
            const _AgingTab(),
          ],
        ),
      ),
      floatingActionButton: _tabCtrl.index == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  _openAdd(isReceivable: _tabCtrl.index == 0),
              backgroundColor: _tabCtrl.index == 0
                  ? AppColors.navyPrimary
                  : AppColors.error,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                _tabCtrl.index == 0
                    ? _tr('Add Receivable', 'Ongeza Dai')
                    : _tr('Add Payable', 'Ongeza Deni'),
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final double totalReceivables;
  final double totalPayables;
  final bool isLoading;

  const _HeroHeader({
    required this.totalReceivables,
    required this.totalPayables,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final net = totalReceivables - totalPayables;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyPrimary, Color(0xFF003153)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Debt Tracker', 'Ufuatiliaji wa Madeni'),
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: _tr('Owed to You', 'Unachodai'),
                  value: isLoading ? '—' : _fmtAmt(totalReceivables),
                  color: AppColors.success,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                  width: 1,
                  height: 48,
                  color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: _HeroStat(
                  label: _tr('You Owe', 'Unadaiwa'),
                  value: isLoading ? '—' : _fmtAmt(totalPayables),
                  color: AppColors.error,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                net >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: net >= 0 ? AppColors.success : AppColors.error,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '${_tr('Net', 'Net')}: ${isLoading ? '—' : _fmtAmt(net.abs())} '
                '${net >= 0 ? _tr('in your favour', 'unafaidi') : _tr('against you', 'dhidi yako')}',
                style: GoogleFonts.dmSans(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Receivables
// ─────────────────────────────────────────────────────────────────────────────

class _ReceivablesTab extends ConsumerStatefulWidget {
  final void Function(Debt) onTap;
  const _ReceivablesTab({required this.onTap});

  @override
  ConsumerState<_ReceivablesTab> createState() => _ReceivablesTabState();
}

class _ReceivablesTabState extends ConsumerState<_ReceivablesTab> {
  String? _filterBucket; // null = all

  @override
  Widget build(BuildContext context) {
    final receivables = ref.watch(receivablesProvider);
    final isLoading = ref.watch(debtListProvider).isLoading;

    final filtered = _filterBucket == null
        ? receivables
        : receivables.where((d) => d.agingBucket == _filterBucket).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _AgingFilterPills(
              selected: _filterBucket,
              onSelect: (b) => setState(() =>
                  _filterBucket = (_filterBucket == b) ? null : b),
              counts: _bucketCounts(receivables),
            ),
          ),
        ),
        if (isLoading)
          const SliverDebtListSkeleton()
        else if (filtered.isEmpty)
          SliverToBoxAdapter(child: _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: _tr('All settled!', 'Yote yalilipwa!'),
            subtitle: _tr('No outstanding receivables.', 'Hakuna wadai waliobaki.'),
          ))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DebtCard(
                    debt: filtered[i],
                    onTap: () => widget.onTap(filtered[i]),
                  ),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Map<String, int> _bucketCounts(List<Debt> debts) {
    final map = <String, int>{};
    for (final d in debts) {
      map[d.agingBucket] = (map[d.agingBucket] ?? 0) + 1;
    }
    return map;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Payables
// ─────────────────────────────────────────────────────────────────────────────

class _PayablesTab extends ConsumerWidget {
  final void Function(Debt) onTap;
  const _PayablesTab({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payables = ref.watch(payablesProvider);
    final isLoading = ref.watch(debtListProvider).isLoading;

    final overdue = payables.where((d) => d.daysOverdue > 0).toList();
    final dueSoon = payables
        .where((d) => d.daysOverdue <= 0 && d.daysOverdue >= -7)
        .toList();
    final upcoming = payables
        .where((d) => d.daysOverdue < -7)
        .toList();

    Widget body;
    if (isLoading) {
      body = const DebtTabSkeleton(key: ValueKey('skeleton'));
    } else if (payables.isEmpty) {
      body = KeyedSubtree(
        key: const ValueKey('empty'),
        child: _EmptyState(
          icon: Icons.task_alt_rounded,
          title: _tr('No outstanding bills', 'Hakuna bili zilizo wazi'),
          subtitle: _tr('All your supplier payments are up to date.',
              'Malipo yote ya wasambazaji yamekamilika.'),
        ),
      );
    } else {
      body = KeyedSubtree(
        key: const ValueKey('content'),
        child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                  label: _tr('Overdue', 'Zimechelewa'),
                  color: AppColors.error,
                  count: overdue.length,
                ),
                ...overdue.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DebtCard(debt: d, onTap: () => onTap(d)),
                    )),
              ],
              if (dueSoon.isNotEmpty) ...[
                _SectionHeader(
                  label: _tr('Due This Week', 'Inakaribia'),
                  color: AppColors.warning,
                  count: dueSoon.length,
                ),
                ...dueSoon.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DebtCard(debt: d, onTap: () => onTap(d)),
                    )),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                  label: _tr('Upcoming', 'Zijazo'),
                  color: AppColors.textMuted,
                  count: upcoming.length,
                ),
                ...upcoming.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DebtCard(debt: d, onTap: () => onTap(d)),
                    )),
              ],
            ]),
          ),
        ),
      ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      child: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Aging Report
// ─────────────────────────────────────────────────────────────────────────────

class _AgingTab extends ConsumerWidget {
  const _AgingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aging = ref.watch(receivablesAgingProvider);
    final totalRec = ref.watch(totalReceivablesProvider);
    final writtenOff = ref.watch(writtenOffDebtsProvider);
    final totalWrittenOff =
        writtenOff.fold(0.0, (s, d) => s + d.originalAmount);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Aging bar chart
              _AgingChartCard(aging: aging),
              const SizedBox(height: 14),
              // Bucket breakdown rows
              _BucketBreakdownCard(aging: aging, totalRec: totalRec),
              const SizedBox(height: 14),
              // Total exposure summary
              _ExposureSummaryCard(
                totalRec: totalRec,
                overdueTotal: aging.d0to30 + aging.d31to60 + aging.d61to90 + aging.d90plus,
              ),
              const SizedBox(height: 22),
              // Write-off audit log
              _WriteOffLogCard(
                writtenOff: writtenOff,
                totalWrittenOff: totalWrittenOff,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Aging chart ───────────────────────────────────────────────────────────────

class _AgingChartCard extends StatelessWidget {
  final AgingBuckets aging;
  const _AgingChartCard({required this.aging});

  @override
  Widget build(BuildContext context) {
    final data = [
      (label: '0–30d', value: aging.d0to30, color: AppColors.warning),
      (label: '31–60d', value: aging.d31to60, color: const Color(0xFFE07010)),
      (label: '61–90d', value: aging.d61to90, color: const Color(0xFFDC4A26)),
      (label: '90+d', value: aging.d90plus, color: AppColors.error),
    ];
    final maxY = data.map((d) => d.value).fold(0.0, (a, b) => b > a ? b : a);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Receivables Aging Analysis', 'Uchambuzi wa Wadai'),
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            _tr('Outstanding amount by overdue age', 'Kiasi kilichobaki kwa kuchelewa'),
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY == 0 ? 1 : maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      _fmtAmt(rod.toY),
                      GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      ),
                  rightTitles: const AxisTitles(
                      ),
                  topTitles: const AxisTitles(
                      ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            data[idx].label,
                            style: GoogleFonts.dmSans(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].value,
                        color: data[i].color,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bucket breakdown ──────────────────────────────────────────────────────────

class _BucketBreakdownCard extends StatelessWidget {
  final AgingBuckets aging;
  final double totalRec;
  const _BucketBreakdownCard({required this.aging, required this.totalRec});

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        label: _tr('Current (not overdue)', 'Sasa hivi'),
        count: aging.countCurrent,
        amount: aging.current,
        color: AppColors.success,
      ),
      (
        label: '0–30 ${_tr('days', 'siku')}',
        count: aging.count0to30,
        amount: aging.d0to30,
        color: AppColors.warning,
      ),
      (
        label: '31–60 ${_tr('days', 'siku')}',
        count: aging.count31to60,
        amount: aging.d31to60,
        color: const Color(0xFFE07010),
      ),
      (
        label: '61–90 ${_tr('days', 'siku')}',
        count: aging.count61to90,
        amount: aging.d61to90,
        color: const Color(0xFFDC4A26),
      ),
      (
        label: '90+ ${_tr('days', 'siku')}',
        count: aging.count90plus,
        amount: aging.d90plus,
        color: AppColors.error,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              _tr('Breakdown by Age', 'Mgawanyo kwa Umri'),
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary),
            ),
          ),
          ...rows.map((r) => _BucketRow(
                label: r.label,
                count: r.count,
                amount: r.amount,
                total: totalRec,
                color: r.color,
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  final String label;
  final int count;
  final double amount;
  final double total;
  final Color color;

  const _BucketRow({
    required this.label,
    required this.count,
    required this.amount,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      '$count ${_tr('items', 'vipande')}',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fmtAmt(amount),
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: color.withValues(alpha: 0.12),
                    color: color,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exposure summary ──────────────────────────────────────────────────────────

class _ExposureSummaryCard extends StatelessWidget {
  final double totalRec;
  final double overdueTotal;
  const _ExposureSummaryCard({required this.totalRec, required this.overdueTotal});

  @override
  Widget build(BuildContext context) {
    final overdueRisk =
        totalRec <= 0 ? 0.0 : (overdueTotal / totalRec * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyPrimary,
            AppColors.navyPrimary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white70, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Risk Exposure', 'Hatari ya Madeni'),
                  style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtFull(overdueTotal),
                  style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_tr('overdue of total', 'zimechelewa kati ya jumla')} ${_fmtAmt(totalRec)}',
                  style: GoogleFonts.dmSans(
                      color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: overdueRisk > 50
                  ? AppColors.error
                  : overdueRisk > 25
                      ? AppColors.warning
                      : AppColors.success,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${overdueRisk.toStringAsFixed(0)}%',
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Write-off log ─────────────────────────────────────────────────────────────

class _WriteOffLogCard extends StatelessWidget {
  final List<Debt> writtenOff;
  final double totalWrittenOff;
  const _WriteOffLogCard(
      {required this.writtenOff, required this.totalWrittenOff});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.delete_sweep_outlined,
                    color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tr('Write-off Log', 'Kumbukumbu ya Madeni Yaliyoandikwa'),
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                ),
                if (totalWrittenOff > 0)
                  Text(
                    _fmtAmt(totalWrittenOff),
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          if (writtenOff.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                _tr('No write-offs recorded.', 'Hakuna madeni yaliyoandikwa.'),
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textDisabled),
              ),
            )
          else
            ...writtenOff.map((d) => _WriteOffTile(debt: d)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _WriteOffTile extends StatelessWidget {
  final Debt debt;
  const _WriteOffTile({required this.debt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              debt.partyName.isNotEmpty
                  ? debt.partyName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.partyName,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                if (debt.writeOffReason.isNotEmpty)
                  Text(
                    debt.writeOffReason,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtAmt(debt.originalAmount),
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough),
              ),
              if (debt.writtenOffAt.isNotEmpty)
                Text(
                  _fmtDate(debt.writtenOffAt),
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppColors.textDisabled),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTap;

  const _DebtCard({required this.debt, required this.onTap});

  Color get _ageColor {
    return switch (debt.agingBucket) {
      'current' => AppColors.success,
      '0-30' => AppColors.warning,
      '31-60' => const Color(0xFFE07010),
      '61-90' => const Color(0xFFDC4A26),
      '90+' => AppColors.error,
      _ => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isReceivable = debt.type == 'receivable';
    final daysOver = debt.daysOverdue;

    return Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowCard, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.navyPrimary.withValues(alpha: 0.06),
        highlightColor: AppColors.navyPrimary.withValues(alpha: 0.04),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left stripe
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _ageColor,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Party initial avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isReceivable
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              debt.partyName.isNotEmpty
                                  ? debt.partyName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isReceivable
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  debt.partyName,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (debt.partyPhone.isNotEmpty)
                                  Text(
                                    debt.partyPhone,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          // Amount remaining
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _fmtAmt(debt.remainingAmount),
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary),
                              ),
                              // Age badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _ageColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  daysOver <= 0
                                      ? 'Due ${_fmtDate(debt.dueDate)}'
                                      : '$daysOver ${_tr('days overdue', 'siku zimechelewa')}',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _ageColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Payment progress
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: debt.paidPercent,
                          backgroundColor:
                              AppColors.border,
                          color: isReceivable
                              ? AppColors.success
                              : AppColors.error,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${_tr('Paid', 'Kilicholipwa')}: ${_fmtAmt(debt.paidAmount)}',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                          const Spacer(),
                          if (debt.invoiceRef.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    size: 11, color: AppColors.textDisabled),
                                const SizedBox(width: 3),
                                Text(
                                  debt.invoiceRef,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: AppColors.textDisabled),
                                ),
                              ],
                            ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 16, color: AppColors.textDisabled),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgingFilterPills extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  final Map<String, int> counts;

  const _AgingFilterPills({
    required this.selected,
    required this.onSelect,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final pills = [
      (key: 'current', label: _tr('Current', 'Sasa'), color: AppColors.success),
      (key: '0-30', label: '0–30d', color: AppColors.warning),
      (key: '31-60', label: '31–60d', color: const Color(0xFFE07010)),
      (key: '61-90', label: '61–90d', color: const Color(0xFFDC4A26)),
      (key: '90+', label: '90+d', color: AppColors.error),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: pills.map((p) {
          final isActive = selected == p.key;
          final count = counts[p.key] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(p.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? p.color
                      : p.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? p.color : p.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : p.color,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.3)
                              : p.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isActive ? Colors.white : p.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label  ($count)',
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

