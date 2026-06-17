import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
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

    return Scaffold(
      body: Column(
        children: [
          _DebtDarkHeader(
            totalReceivables: totalRec,
            totalPayables: totalPay,
          ),
          const SizedBox(height: _DebtDarkHeader._pillHalf + 8),
          _DebtTabBar(tabController: _tabCtrl),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ReceivablesTab(onTap: _openDetail),
                _PayablesTab(onTap: _openDetail),
                const _AgingTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAdd(isReceivable: _tabCtrl.index == 0),
              backgroundColor: AppColors.yellowBrand,
              foregroundColor: AppColors.navyPrimary,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _tabCtrl.index == 0
                    ? _tr('Add Receivable', 'Ongeza Dai')
                    : _tr('Add Payable', 'Ongeza Deni'),
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

// ── Dark Header ───────────────────────────────────────────────────────────────

class _DebtDarkHeader extends StatelessWidget {
  static const double _pillHalf = 22.0;

  final double totalReceivables;
  final double totalPayables;

  const _DebtDarkHeader({
    required this.totalReceivables,
    required this.totalPayables,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final net = totalReceivables - totalPayables;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, _pillHalf + 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('Debt Tracker', 'Ufuatiliaji wa Madeni'),
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          net >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: net >= 0 ? AppColors.success : AppColors.error,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmtAmt(net.abs())} ${net >= 0 ? _tr('in your favour', 'unafaidi') : _tr('against you', 'dhidi yako')}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -_pillHalf,
          left: 24,
          right: 24,
          child: Container(
            height: _pillHalf * 2,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(_pillHalf),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyPrimary.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PillStat(
                  value: _fmtAmt(totalReceivables),
                  label: _tr('Owed to You', 'Unachodai'),
                  valueColor: AppColors.success,
                ),
                const _PillDivider(),
                _PillStat(
                  value: _fmtAmt(totalPayables),
                  label: _tr('You Owe', 'Unadaiwa'),
                  valueColor: AppColors.error,
                ),
                const _PillDivider(),
                _PillStat(
                  value: _fmtAmt(net.abs()),
                  label: _tr('Net', 'Net'),
                  valueColor: net >= 0 ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _DebtTabBar extends StatelessWidget {
  final TabController tabController;
  const _DebtTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            labelStyle:
                GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: AppColors.navyPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.navyPrimary,
            indicatorWeight: 2.5,
            tabs: [
              Tab(text: _tr('Receivables', 'Wadai')),
              Tab(text: _tr('Payables', 'Madeni')),
              Tab(text: _tr('Aging', 'Uchambuzi')),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

// ── Pill widgets ──────────────────────────────────────────────────────────────

class _PillStat extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const _PillStat({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: AppColors.border);
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
          SliverToBoxAdapter(child: EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: _tr("You're all settled up!", 'Umesawazishwa kikamilifu!'),
            subtitle: _tr('No outstanding amounts owed to you right now.',
                'Hakuna kiasi kinachokudaiwa kwa sasa.'),
          ))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => ListSwipeCard(
                itemKey: ValueKey(filtered[i].id),
                onEdit: () => widget.onTap(filtered[i]),
                onDelete: () => _deleteDebt(ctx, ref, filtered[i]),
                child: _DebtCard(
                  debt: filtered[i],
                  isLast: i == filtered.length - 1,
                  onTap: () => widget.onTap(filtered[i]),
                ),
              ),
              childCount: filtered.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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
        child: EmptyState(
          icon: Icons.handshake_outlined,
          title: _tr('No outstanding bills', 'Hakuna bili zilizo wazi'),
          subtitle: _tr('All your supplier payments are up to date.',
              'Malipo yote ya wasambazaji yamekamilika.'),
        ),
      );
    } else {
      final lastDebt = upcoming.isNotEmpty
          ? upcoming.last
          : dueSoon.isNotEmpty
              ? dueSoon.last
              : overdue.isNotEmpty
                  ? overdue.last
                  : null;
      final lastDebtId = lastDebt?.id;

      body = KeyedSubtree(
        key: const ValueKey('content'),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: 14),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (overdue.isNotEmpty) ...[
                    _SectionHeader(
                      label: _tr('Overdue', 'Zimechelewa'),
                      color: AppColors.error,
                      count: overdue.length,
                    ),
                    ...overdue.map((d) => ListSwipeCard(
                          itemKey: ValueKey(d.id),
                          onEdit: () => onTap(d),
                          onDelete: () => _deleteDebt(context, ref, d),
                          child: _DebtCard(
                            debt: d,
                            isLast: d.id == lastDebtId,
                            onTap: () => onTap(d),
                          ),
                        )),
                  ],
                  if (dueSoon.isNotEmpty) ...[
                    _SectionHeader(
                      label: _tr('Due This Week', 'Inakaribia'),
                      color: AppColors.warning,
                      count: dueSoon.length,
                    ),
                    ...dueSoon.map((d) => ListSwipeCard(
                          itemKey: ValueKey(d.id),
                          onEdit: () => onTap(d),
                          onDelete: () => _deleteDebt(context, ref, d),
                          child: _DebtCard(
                            debt: d,
                            isLast: d.id == lastDebtId,
                            onTap: () => onTap(d),
                          ),
                        )),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    _SectionHeader(
                      label: _tr('Upcoming', 'Zijazo'),
                      color: AppColors.textMuted,
                      count: upcoming.length,
                    ),
                    ...upcoming.map((d) => ListSwipeCard(
                          itemKey: ValueKey(d.id),
                          onEdit: () => onTap(d),
                          onDelete: () => _deleteDebt(context, ref, d),
                          child: _DebtCard(
                            debt: d,
                            isLast: d.id == lastDebtId,
                            onTap: () => onTap(d),
                          ),
                        )),
                  ],
                ]),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _deleteDebt(BuildContext context, WidgetRef ref, Debt debt) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_tr('Delete Entry', 'Futa Rekodi'),
          style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(_tr(
        'This cannot be undone. All payment records will also be deleted.',
        'Haiwezi kurejeshwa. Rekodi zote za malipo pia zitafutwa.',
      )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(_tr('Cancel', 'Ghairi')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(_tr('Delete', 'Futa')),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(debtRepositoryProvider).delete(debt.id);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(_tr(
          'Could not delete entry. Please try again.',
          'Imeshindwa kufuta rekodi. Jaribu tena.',
        )),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final bool isLast;
  final VoidCallback onTap;

  const _DebtCard({
    required this.debt,
    required this.isLast,
    required this.onTap,
  });

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

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isReceivable
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    debt.partyName.isNotEmpty
                        ? debt.partyName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isReceivable
                          ? AppColors.success
                          : AppColors.error,
                    ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: debt.paidPercent,
                backgroundColor: AppColors.border,
                color: isReceivable ? AppColors.success : AppColors.error,
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
            if (!isLast)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              ),
          ],
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


