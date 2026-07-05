import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/nav_aware_fab.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
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

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${_monthShort(d.month)} ${d.year}';
}

String _monthShort(int m) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][m - 1];

// ── Sort options ──────────────────────────────────────────────────────────────

enum _DebtSort { nameAz, nameZa, amountHigh, amountLow, dueDateAsc }

extension _DebtSortX on _DebtSort {
  String get label => switch (this) {
        _DebtSort.nameAz => _tr('Name A–Z', 'Jina A–Z'),
        _DebtSort.nameZa => _tr('Name Z–A', 'Jina Z–A'),
        _DebtSort.amountHigh => _tr('Amount ↑', 'Kiasi ↑'),
        _DebtSort.amountLow => _tr('Amount ↓', 'Kiasi ↓'),
        _DebtSort.dueDateAsc => _tr('Due Date', 'Tarehe ya Mwisho'),
      };
}

// ── Filter helper ─────────────────────────────────────────────────────────────

List<Debt> _applyDebtFilters(
  List<Debt> debts,
  String query,
  String? bucket,
  _DebtSort sort,
) {
  var list = debts;
  if (bucket != null) {
    list = list.where((d) => d.agingBucket == bucket).toList();
  }
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list
        .where((d) =>
            d.partyName.toLowerCase().contains(q) ||
            d.partyPhone.contains(q))
        .toList();
  }
  list = List.from(list);
  switch (sort) {
    case _DebtSort.nameAz:
      list.sort((a, b) => a.partyName.compareTo(b.partyName));
    case _DebtSort.nameZa:
      list.sort((a, b) => b.partyName.compareTo(a.partyName));
    case _DebtSort.amountHigh:
      list.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    case _DebtSort.amountLow:
      list.sort((a, b) => a.remainingAmount.compareTo(b.remainingAmount));
    case _DebtSort.dueDateAsc:
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
  return list;
}

String _bucketLabel(String bucket) => switch (bucket) {
      'current' => _tr('Current', 'Sasa'),
      '0-30' => '0–30 days',
      '31-60' => '31–60 days',
      '61-90' => '61–90 days',
      '90+' => '90+ days',
      _ => bucket,
    };

// ── Main Screen ───────────────────────────────────────────────────────────────

class DebtTrackingScreen extends ConsumerStatefulWidget {
  const DebtTrackingScreen({super.key});

  @override
  ConsumerState<DebtTrackingScreen> createState() => _DebtTrackingScreenState();
}

class _DebtTrackingScreenState extends ConsumerState<DebtTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  bool _searchExpanded = false;
  String _query = '';
  String? _filterBucket;
  _DebtSort _sort = _DebtSort.nameAz;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilters =>
      (_filterBucket != null ? 1 : 0) + (_sort != _DebtSort.nameAz ? 1 : 0);

  void _openAdd({bool isReceivable = true, Debt? edit}) async {
    final plan = await ref.read(planStatusProvider.future);
    if (!mounted) return;
    if (!plan.limits.manualDebt) {
      await showUpgradeSheet(
        context,
        currentStatus: plan,
        featureKey: PlanFeatureKey.manualDebt,
        triggerReason: _tr(
          'Manual entry is available on paid plans.',
          'Kuongeza deni kunahitaji mpango wa malipo.',
        ),
      );
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDebtScreen(
        initialIsReceivable: isReceivable,
        debtToEdit: edit,
      ),
    );
  }

  void _openDetail(Debt debt) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DebtDetailScreen(debt: debt),
    ));
  }

  void _openFilterSheet() {
    showAppSheet<void>(
      context,
      builder: (_) => _DebtFilterSheet(
        currentBucket: _filterBucket,
        currentSort: _sort,
        onApply: (bucket, sort) => setState(() {
          _filterBucket = bucket;
          _sort = sort;
        }),
      ),
    );
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
            searchCtrl: _searchCtrl,
            query: _query,
            searchExpanded: _searchExpanded,
            onToggleSearch: () => setState(() {
              _searchExpanded = !_searchExpanded;
              if (!_searchExpanded) {
                _searchCtrl.clear();
                _query = '';
              }
            }),
            onSearchChanged: (v) => setState(() => _query = v),
            activeFilters: _activeFilters,
            onFilterTap: _openFilterSheet,
          ),
          const SizedBox(height: _DebtDarkHeader._pillHalf + 8),
          _DebtTabBar(tabController: _tabCtrl),
          if (_filterBucket != null)
            _ActiveFilterChip(
              label: _bucketLabel(_filterBucket!),
              onRemove: () => setState(() => _filterBucket = null),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ReceivablesTab(
                  onTap: _openDetail,
                  query: _query,
                  filterBucket: _filterBucket,
                  sort: _sort,
                ),
                _PayablesTab(
                  onTap: _openDetail,
                  query: _query,
                  sort: _sort,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: NavAwareFab(
        child: FloatingActionButton.extended(
          onPressed: () => _openAdd(isReceivable: _tabCtrl.index == 0),
          backgroundColor: AppColors.yellowBrand,
          foregroundColor: AppColors.navyPrimary,
          icon: Icon(Icons.add_rounded),
          label: Text(
            _tabCtrl.index == 0
                ? _tr('Add Receivable', 'Ongeza Dai')
                : _tr('Add Payable', 'Ongeza Deni'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
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
  final TextEditingController searchCtrl;
  final String query;
  final bool searchExpanded;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final int activeFilters;
  final VoidCallback onFilterTap;

  const _DebtDarkHeader({
    required this.totalReceivables,
    required this.totalPayables,
    required this.searchCtrl,
    required this.query,
    required this.searchExpanded,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.activeFilters,
    required this.onFilterTap,
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
          padding: EdgeInsets.fromLTRB(20, top + AppTheme.headerTopPadding, 20, _pillHalf + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Debt Tracker', 'Madeni'),
                          style: GoogleFonts.dmSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              net >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: net >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 12,
                            ),
                            SizedBox(width: 4),
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
                  // Search button
                  GestureDetector(
                    onTap: onToggleSearch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: searchExpanded
                            ? AppColors.yellowBrand.withValues(alpha: 0.18)
                            : Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: searchExpanded
                              ? AppColors.yellowBrand
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        searchExpanded
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: searchExpanded
                            ? AppColors.yellowBrand
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter button
                  GestureDetector(
                    onTap: onFilterTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: activeFilters > 0
                                ? AppColors.yellowBrand.withValues(alpha: 0.18)
                                : Colors.white12,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activeFilters > 0
                                  ? AppColors.yellowBrand
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: activeFilters > 0
                                ? AppColors.yellowBrand
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                        if (activeFilters > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.yellowBrand,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.navyPrimary, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: searchExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            controller: searchCtrl,
                            autofocus: true,
                            onChanged: onSearchChanged,
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: _tr(
                                'Search by name or phone…',
                                'Tafuta kwa jina au simu…',
                              ),
                              hintStyle: GoogleFonts.dmSans(
                                  fontSize: 14, color: Colors.white38),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  size: 18, color: Colors.white54),
                              suffixIcon: query.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        searchCtrl.clear();
                                        onSearchChanged('');
                                      },
                                      child: const Icon(Icons.close_rounded,
                                          size: 16, color: Colors.white54),
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white12,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.yellowBrand, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
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

// ── Active filter chip ────────────────────────────────────────────────────────

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close_rounded,
                      size: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Receivables
// ─────────────────────────────────────────────────────────────────────────────

class _ReceivablesTab extends ConsumerWidget {
  final void Function(Debt) onTap;
  final String query;
  final String? filterBucket;
  final _DebtSort sort;

  const _ReceivablesTab({
    required this.onTap,
    required this.query,
    required this.filterBucket,
    required this.sort,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivables = ref.watch(receivablesProvider);
    final isLoading = ref.watch(debtListProvider).isLoading;
    final filtered = _applyDebtFilters(receivables, query, filterBucket, sort);

    return CustomScrollView(
      slivers: [
        if (isLoading)
          const SliverDebtListSkeleton()
        else if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: query.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.check_circle_outline_rounded,
              title: query.isNotEmpty
                  ? _tr('No results for "$query"', 'Hakuna matokeo ya "$query"')
                  : _tr("You're all settled up!", 'Umesawazishwa kikamilifu!'),
              subtitle: query.isNotEmpty
                  ? _tr('Try a different search term.',
                      'Jaribu neno tofauti la kutafuta.')
                  : _tr(
                      'No outstanding amounts owed to you right now.',
                      'Hakuna kiasi kinachokudaiwa kwa sasa.',
                    ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => ListSwipeCard(
                itemKey: ValueKey(filtered[i].id),
                onEdit: () => onTap(filtered[i]),
                onDelete: () => _deleteDebt(ctx, ref, filtered[i]),
                child: _DebtCard(
                  debt: filtered[i],
                  isLast: i == filtered.length - 1,
                  onTap: () => onTap(filtered[i]),
                ),
              ),
              childCount: filtered.length,
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Payables
// ─────────────────────────────────────────────────────────────────────────────

class _PayablesTab extends ConsumerWidget {
  final void Function(Debt) onTap;
  final String query;
  final _DebtSort sort;

  const _PayablesTab({
    required this.onTap,
    required this.query,
    required this.sort,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payables = ref.watch(payablesProvider);
    final isLoading = ref.watch(debtListProvider).isLoading;

    // Bucket filter doesn't apply to payables — they're grouped by overdue status
    final allFiltered = _applyDebtFilters(payables, query, null, sort);

    final overdue = allFiltered.where((d) => d.daysOverdue > 0).toList();
    final dueSoon = allFiltered
        .where((d) => d.daysOverdue <= 0 && d.daysOverdue >= -7)
        .toList();
    final upcoming = allFiltered.where((d) => d.daysOverdue < -7).toList();

    Widget body;
    if (isLoading) {
      body = const DebtTabSkeleton(key: ValueKey('skeleton'));
    } else if (allFiltered.isEmpty) {
      body = KeyedSubtree(
        key: const ValueKey('empty'),
        child: EmptyState(
          icon: query.isNotEmpty
              ? Icons.search_off_rounded
              : Icons.handshake_outlined,
          title: query.isNotEmpty
              ? _tr('No results for "$query"', 'Hakuna matokeo ya "$query"')
              : _tr('No outstanding bills', 'Hakuna bili zilizo wazi'),
          subtitle: query.isNotEmpty
              ? _tr('Try a different search term.',
                  'Jaribu neno tofauti la kutafuta.')
              : _tr(
                  'All your supplier payments are up to date.',
                  'Malipo yote ya wasambazaji yamekamilika.',
                ),
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
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _deleteDebt(BuildContext context, WidgetRef ref, Debt debt) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_tr('Delete Entry', 'Futa Rekodi'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
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
// Debt card — compact single-row style
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

  Color get _ageColor => switch (debt.agingBucket) {
        'current' => AppColors.success,
        '0-30' => AppColors.warning,
        '31-60' => const Color(0xFFE07010),
        '61-90' => const Color(0xFFDC4A26),
        '90+' => AppColors.error,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final isReceivable = debt.type == 'receivable';
    final daysOver = debt.daysOverdue;
    final avatarColor =
        isReceivable ? AppColors.success : AppColors.error;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.12),
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
                      color: avatarColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.partyName,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (debt.partyPhone.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          debt.partyPhone,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Amount + aging badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmtAmt(debt.remainingAmount),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
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
                          fontWeight: FontWeight.w600,
                          color: _ageColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textDisabled),
              ],
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.only(top: 12, left: 54),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: AppColors.border,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter / Sort Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DebtFilterSheet extends StatefulWidget {
  final String? currentBucket;
  final _DebtSort currentSort;
  final void Function(String? bucket, _DebtSort sort) onApply;

  const _DebtFilterSheet({
    required this.currentBucket,
    required this.currentSort,
    required this.onApply,
  });

  @override
  State<_DebtFilterSheet> createState() => _DebtFilterSheetState();
}

class _DebtFilterSheetState extends State<_DebtFilterSheet> {
  String? _bucket;
  late _DebtSort _sort;

  static const _buckets = [
    (key: 'current', label: 'Current'),
    (key: '0-30', label: '0–30 days'),
    (key: '31-60', label: '31–60 days'),
    (key: '61-90', label: '61–90 days'),
    (key: '90+', label: '90+ days'),
  ];

  @override
  void initState() {
    super.initState();
    _bucket = widget.currentBucket;
    _sort = widget.currentSort;
  }

  void _reset() => setState(() {
        _bucket = null;
        _sort = _DebtSort.nameAz;
      });

  void _apply() {
    widget.onApply(_bucket, _sort);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetHandle(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('Sort & Filter', 'Panga na Chuja'),
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _reset,
                    child: Text(
                      _tr('Reset', 'Futa'),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.tealAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetLabel(_tr('Sort by', 'Panga kwa')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _DebtSort.values
                    .map((s) => _FilterChip(
                          label: s.label,
                          selected: _sort == s,
                          onTap: () => setState(() => _sort = s),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _SheetLabel(_tr('Aging — Receivables', 'Umri wa Madeni')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: _tr('All', 'Yote'),
                    selected: _bucket == null,
                    onTap: () => setState(() => _bucket = null),
                  ),
                  ..._buckets.map((b) => _FilterChip(
                        label: b.label,
                        selected: _bucket == b.key,
                        onTap: () => setState(
                            () => _bucket = _bucket == b.key ? null : b.key),
                      )),
                ],
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _tr('Apply', 'Tumia'),
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w700),
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

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navyPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header (payables grouping)
// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 8),
          Text(
            '$label  ($count)',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
