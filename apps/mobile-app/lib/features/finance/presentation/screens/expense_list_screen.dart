import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../data/finance_providers.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/recurring_expense_template.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Category meta
// ─────────────────────────────────────────────────────────────────────────────

enum _Cat {
  rent,
  utilities,
  salaries,
  transport,
  marketing,
  supplies,
  other,
}

extension _CatX on _Cat {
  String get key => name;

  String get label => switch (this) {
        _Cat.rent => _tr('Rent', 'Kodi'),
        _Cat.utilities => _tr('Utilities', 'Huduma'),
        _Cat.salaries => _tr('Salaries', 'Mishahara'),
        _Cat.transport => _tr('Transport', 'Usafiri'),
        _Cat.marketing => _tr('Marketing', 'Masoko'),
        _Cat.supplies => _tr('Supplies', 'Vifaa'),
        _Cat.other => _tr('Other', 'Nyingine'),
      };

  IconData get icon => switch (this) {
        _Cat.rent => Icons.home_rounded,
        _Cat.utilities => Icons.bolt_rounded,
        _Cat.salaries => Icons.people_rounded,
        _Cat.transport => Icons.local_shipping_rounded,
        _Cat.marketing => Icons.campaign_rounded,
        _Cat.supplies => Icons.inventory_2_rounded,
        _Cat.other => Icons.more_horiz_rounded,
      };

  Color get color => switch (this) {
        _Cat.rent => AppColors.navyPrimary,
        _Cat.utilities => AppColors.tealAccent,
        _Cat.salaries => AppColors.success,
        _Cat.transport => AppColors.warning,
        _Cat.marketing => const Color(0xFF7C3AED),
        _Cat.supplies => const Color(0xFFB45309),
        _Cat.other => AppColors.textMuted,
      };

  static _Cat fromKey(String key) => _Cat.values.firstWhere(
        (c) => c.key == key.toLowerCase(),
        orElse: () => _Cat.other,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  _Cat? _filterCat; // null = show all

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

  void _prevMonth() {
    final cur = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).setMonth(
          DateTime(cur.year, cur.month - 1),
        );
  }

  void _nextMonth() {
    final cur = ref.read(selectedMonthProvider);
    final next = DateTime(cur.year, cur.month + 1);
    if (next.isAfter(DateTime.now())) return;
    ref.read(selectedMonthProvider.notifier).setMonth(next);
  }

  void _openAdd({Expense? edit}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddExpenseScreen(expenseToEdit: edit),
    ));
  }

  void _openDetail(Expense expense) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExpenseDetailScreen(expense: expense),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final total = ref.watch(monthTotalSpendProvider);
    final expenses = ref.watch(expensesByMonthProvider);
    final isLoading = ref.watch(expenseListProvider).isLoading;

    final pendingCount = expenses.where((e) => e.status == 'pending').length;
    final withReceipt = expenses.where((e) => e.receiptUrl.isNotEmpty).length;

    final now = DateTime.now();
    final canGoNext = DateTime(month.year, month.month + 1)
        .isBefore(DateTime(now.year, now.month + 1));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _ExpenseDarkHeader(
            month: month,
            total: total,
            pendingCount: pendingCount,
            withReceipt: withReceipt,
            loading: isLoading,
            onPrev: _prevMonth,
            onNext: _nextMonth,
            canGoNext: canGoNext,
          ),
          const SizedBox(height: _ExpenseDarkHeader._pillHalf + 8),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ExpensesTab(
                  filterCat: _filterCat,
                  onFilterChanged: (c) => setState(() => _filterCat = c),
                  onTap: _openDetail,
                  onEdit: (e) => _openAdd(edit: e),
                ),
                const _BudgetTab(),
                const _RecurringTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton.extended(
              onPressed: _openAdd,
              backgroundColor: AppColors.yellowBrand,
              foregroundColor: AppColors.navyPrimary,
              elevation: 3,
              icon: const Icon(Icons.receipt_long_rounded, size: 20),
              label: Text(
                _tr('Add Expense', 'Ongeza Matumizi'),
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            )
          : _tabCtrl.index == 2
              ? FloatingActionButton.extended(
                  heroTag: 'add-recurring-fab',
                  onPressed: () => _showAddRecurringSheet(context),
                  backgroundColor: AppColors.yellowBrand,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 3,
                  icon: const Icon(Icons.repeat_rounded, size: 20),
                  label: Text(
                    _tr('Add Recurring', 'Ongeza ya Kawaida'),
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                )
              : null,
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            labelStyle: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: AppColors.navyPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.navyPrimary,
            indicatorWeight: 2.5,
            tabs: [
              Tab(text: _tr('Expenses', 'Matumizi')),
              Tab(text: _tr('Budget', 'Bajeti')),
              Tab(text: _tr('Recurring', 'Mara kwa Mara')),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  void _showAddRecurringSheet(BuildContext context) {
    showAppSheet(
      context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddRecurringSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Expenses list
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensesTab extends ConsumerWidget {
  final _Cat? filterCat;
  final ValueChanged<_Cat?> onFilterChanged;
  final ValueChanged<Expense> onTap;
  final ValueChanged<Expense> onEdit;

  const _ExpensesTab({
    required this.filterCat,
    required this.onFilterChanged,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesByMonthProvider);
    final isLoading = ref.watch(expenseListProvider).isLoading;

    final filtered = filterCat == null
        ? expenses
        : expenses.where((e) => e.category == filterCat!.key).toList();

    if (isLoading) {
      return const ExpensePageSkeleton();
    }

    return Column(
      children: [
        // Category filter pills
        _CategoryPills(
          selected: filterCat,
          onSelect: onFilterChanged,
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_outlined,
                  title: filterCat == null
                      ? _tr('No expenses this month',
                          'Hakuna matumizi mwezi huu')
                      : _tr('No ${filterCat!.label} expenses',
                          'Hakuna matumizi ya ${filterCat!.label}'),
                  subtitle: _tr(
                    'Tap + to log a purchase or bill.',
                    'Bonyeza + kurekodi ununuzi au bili.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _ExpenseCard(
                    expense: filtered[i],
                    onTap: () => onTap(filtered[i]),
                    onEdit: () => onEdit(filtered[i]),
                    onDelete: () => _deleteExpense(ctx, ref, filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _deleteExpense(
      BuildContext context, WidgetRef ref, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_tr('Delete Expense?', 'Futa Gharama?'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          _tr('This cannot be undone.', 'Hii haiwezi kutenduliwa.'),
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_tr('Cancel', 'Ghairi'),
                style: GoogleFonts.dmSans(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(_tr('Delete', 'Futa'),
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo
          .scopeCollection(
              uid: user.uid, context: ctx, childCollection: 'expenses')
          .doc(expense.id)
          .delete();
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Expense deleted', 'Gharama imefutwa')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }
}

class _CategoryPills extends StatelessWidget {
  final _Cat? selected;
  final ValueChanged<_Cat?> onSelect;

  const _CategoryPills({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _Pill(
                  label: _tr('All', 'Zote'),
                  active: selected == null,
                  color: AppColors.navyPrimary,
                  onTap: () => onSelect(null),
                ),
                ..._Cat.values.map((cat) => _Pill(
                      label: cat.label,
                      icon: cat.icon,
                      active: selected == cat,
                      color: cat.color,
                      onTap: () =>
                          onSelect(selected == cat ? null : cat),
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? color : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12,
                    color: active ? Colors.white : color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = _CatX.fromKey(expense.category);
    final amount = double.tryParse(expense.amount) ?? 0;
    final isPending = expense.status == 'pending';
    final isRejected = expense.status == 'rejected';

    return ListSwipeCard(
      itemKey: ValueKey(expense.id),
      onEdit: onEdit,
      onDelete: onDelete,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isRejected ? AppColors.errorBg : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadowCard,
                  blurRadius: 6,
                  offset: Offset(0, 1)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left stripe — category color indicator
                Container(width: 3.5, color: cat.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Category icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(cat.icon, size: 20, color: cat.color),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      expense.note.isNotEmpty
                                          ? expense.note
                                          : cat.label,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isRejected
                                              ? AppColors.error
                                              : AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPending)
                                    _StatusBadge(
                                        label: _tr('Pending', 'Inasubiri'),
                                        color: AppColors.warning),
                                  if (isRejected)
                                    _StatusBadge(
                                        label: _tr('Rejected', 'Imekataliwa'),
                                        color: AppColors.error),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    cat.label,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('·',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          color: AppColors.textDisabled)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _fmtDate(expense.date),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: AppColors.textMuted),
                                  ),
                                  if (expense.receiptUrl.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.receipt_rounded,
                                        size: 11,
                                        color: AppColors.tealAccent),
                                  ],
                                  if (expense.isRecurring) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.repeat_rounded,
                                        size: 11,
                                        color: AppColors.textMuted),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Amount
                        Text(
                          'TZS ${_fmtNum(amount)}',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isRejected
                                  ? AppColors.error
                                  : AppColors.navyPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Budget vs Actual
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetTab extends ConsumerStatefulWidget {
  const _BudgetTab();

  @override
  ConsumerState<_BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends ConsumerState<_BudgetTab> {
  @override
  Widget build(BuildContext context) {
    final spend = ref.watch(categorySpendProvider);
    final budgets = ref.watch(categoryBudgetProvider);
    final monthlyTrend = ref.watch(sixMonthSpendProvider);
    final month = ref.watch(selectedMonthProvider);

    final totalBudget =
        budgets.values.fold(0.0, (s, v) => s + v);
    final totalSpend = spend.values.fold(0.0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Summary card
        _BudgetSummaryCard(
          totalBudget: totalBudget,
          totalSpend: totalSpend,
          month: month,
        ),
        const SizedBox(height: 16),
        // Per-category rows
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text(
                  _tr('Category Breakdown', 'Mgawanyo wa Makundi'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4),
                ),
              ),
              ..._Cat.values.map((cat) {
                final spent = spend[cat.key] ?? 0;
                final budget = budgets[cat.key] ?? 0;
                return Column(
                  children: [
                    const Divider(height: 1, color: AppColors.border),
                    _BudgetRow(
                      cat: cat,
                      spent: spent,
                      budget: budget,
                      month: month,
                      onBudgetSaved: (_) => setState(() {}),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Trend chart
        _TrendChart(data: monthlyTrend),
      ],
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpend;
  final DateTime month;

  const _BudgetSummaryCard({
    required this.totalBudget,
    required this.totalSpend,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final hasBudget = totalBudget > 0;
    final pct =
        hasBudget ? (totalSpend / totalBudget).clamp(0.0, 1.0) : 0.0;
    final overBudget = hasBudget && totalSpend > totalBudget;
    final barColor = overBudget
        ? AppColors.error
        : pct > 0.85
            ? AppColors.warning
            : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyPrimary, AppColors.navySecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
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
                      _tr('Total Spend', 'Jumla Iliyotumika'),
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: Colors.white54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${_fmtNum(totalSpend)}',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 24, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _tr('Budget', 'Bajeti'),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasBudget
                        ? 'TZS ${_fmtNum(totalBudget)}'
                        : _tr('Not set', 'Haijawekwa'),
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasBudget ? Colors.white70 : Colors.white30),
                  ),
                ],
              ),
            ],
          ),
          if (hasBudget) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${(pct * 100).toStringAsFixed(0)}% ${_tr("used", "imetumika")}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: Colors.white54),
                ),
                if (overBudget) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _tr('OVER BUDGET', 'IMEZIDI BAJETI'),
                      style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFC8181)),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'TZS ${_fmtNum(totalBudget - totalSpend > 0 ? totalBudget - totalSpend : 0)} ${_tr("left", "imesalia")}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetRow extends ConsumerStatefulWidget {
  final _Cat cat;
  final double spent;
  final double budget;
  final DateTime month;
  final ValueChanged<double> onBudgetSaved;

  const _BudgetRow({
    required this.cat,
    required this.spent,
    required this.budget,
    required this.month,
    required this.onBudgetSaved,
  });

  @override
  ConsumerState<_BudgetRow> createState() => _BudgetRowState();
}

class _BudgetRowState extends ConsumerState<_BudgetRow> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.budget > 0 ? widget.budget.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final v = double.tryParse(_ctrl.text) ?? 0;
    setState(() => _editing = false);
    await saveBudget(
      container: ProviderScope.containerOf(context),
      category: widget.cat.key,
      amount: v,
      month: widget.month.month,
      year: widget.month.year,
    );
    widget.onBudgetSaved(v);
  }

  @override
  Widget build(BuildContext context) {
    final hasBudget = widget.budget > 0;
    final pct = hasBudget
        ? (widget.spent / widget.budget).clamp(0.0, 1.0)
        : 0.0;
    final overBudget = hasBudget && widget.spent > widget.budget;
    final barColor = overBudget
        ? AppColors.error
        : pct > 0.85
            ? AppColors.warning
            : widget.cat.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.cat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.cat.icon,
                    size: 15, color: widget.cat.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.cat.label,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              if (_editing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.jetBrainsMono(fontSize: 13),
                        decoration: InputDecoration(
                          prefixText: 'TZS ',
                          prefixStyle: GoogleFonts.dmSans(
                              fontSize: 11, color: AppColors.textMuted),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                        onSubmitted: (_) => _saveBudget(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _saveBudget,
                      child: const Icon(Icons.check_rounded,
                          size: 18, color: AppColors.success),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _editing = false),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textMuted),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TZS ${_fmtNum(widget.spent)}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: overBudget
                              ? AppColors.error
                              : AppColors.textPrimary),
                    ),
                    if (hasBudget) ...[
                      Text(
                        ' / ${_fmtShort(widget.budget)}',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.textMuted),
                      ),
                    ],
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _editing = true),
                      child: const Icon(Icons.edit_rounded,
                          size: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
            ],
          ),
          if (hasBudget) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _editing = true),
              child: Text(
                _tr('+ Set budget', '+ Weka bajeti'),
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: widget.cat.color,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<({int month, int year, double total})> data;

  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.every((d) => d.total == 0)) return const SizedBox.shrink();

    final maxY =
        data.map((d) => d.total).reduce((a, b) => a > b ? a : b) * 1.25;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('6-Month Trend', 'Mwenendo wa Miezi 6'),
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY == 0 ? 1 : maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      'TZS ${_fmtShort(rod.toY)}',
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
                            months[data[idx].month - 1],
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  final isCurrentMonth = data[i].month == DateTime.now().month &&
                      data[i].year == DateTime.now().year;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].total,
                        color: isCurrentMonth
                            ? AppColors.navyPrimary
                            : AppColors.navyPrimary.withValues(alpha: 0.35),
                        width: 22,
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Recurring templates
// ─────────────────────────────────────────────────────────────────────────────

class _RecurringTab extends ConsumerWidget {
  const _RecurringTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(recurringTemplateListProvider);

    return templatesAsync.when(
      loading: () => const SkeletonList(itemCount: 4),
      error: (e, _) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: _tr('Could not load recurring expenses', 'Imeshindwa kupakia matumizi ya kujirudia'),
        subtitle: _tr('Check your connection and try again.', 'Angalia muunganiko wako na ujaribu tena.'),
        actionLabel: _tr('Try again', 'Jaribu tena'),
        onAction: () => ref.invalidate(recurringTemplateListProvider),
      ),
      data: (templates) {
        if (templates.isEmpty) {
          return const EmptyState(
            icon: Icons.autorenew_rounded,
            title: 'No recurring expenses yet',
            subtitle:
                'Set up auto-logged expenses for bills that repeat every month.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: templates.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => _RecurringCard(
            template: templates[i],
            onDelete: () => _deleteTemplate(ctx, ref, templates[i]),
            onToggle: (active) =>
                _toggleTemplate(ctx, ref, templates[i], active),
          ),
        );
      },
    );
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    WidgetRef ref,
    RecurringExpenseTemplate t,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Remove recurring?', 'Ondoa inayojirudia?'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(_tr('Remove', 'Ondoa')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo.deleteRecurringTemplate(
          uid: user.uid, context: ctx, templateId: t.id);
    } catch (_) {}
  }

  Future<void> _toggleTemplate(
    BuildContext context,
    WidgetRef ref,
    RecurringExpenseTemplate t,
    bool active,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo
          .scopeCollection(
              uid: user.uid, context: ctx, childCollection: 'expense_templates')
          .doc(t.id)
          .update({'isActive': active});
    } catch (_) {}
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringExpenseTemplate template;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _RecurringCard({
    required this.template,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cat = _CatX.fromKey(template.category);
    final amount = double.tryParse(template.amount) ?? 0;

    return ListSwipeCard(
      itemKey: ValueKey(template.id),
      onDelete: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: template.isActive ? Colors.white : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
                color: template.isActive ? cat.color : AppColors.border,
                width: 3.5),
            right: const BorderSide(color: AppColors.border),
            top: const BorderSide(color: AppColors.border),
            bottom: const BorderSide(color: AppColors.border),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cat.color.withValues(
                    alpha: template.isActive ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(cat.icon,
                  size: 20,
                  color: template.isActive ? cat.color : AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.note.isNotEmpty ? template.note : cat.label,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: template.isActive
                            ? AppColors.textPrimary
                            : AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.repeat_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        template.recurrenceLabel,
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      if (template.nextDueDate.isNotEmpty) ...[
                        const Icon(Icons.schedule_rounded,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          _tr('Due: ', 'Inakuja: ') +
                              template.nextDueDateLabel,
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TZS ${_fmtNum(amount)}',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: template.isActive
                          ? AppColors.textPrimary
                          : AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Switch.adaptive(
                  value: template.isActive,
                  onChanged: onToggle,
                  activeThumbColor: cat.color,
                  activeTrackColor: cat.color.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Recurring Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet();

  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  _Cat _cat = _Cat.rent;
  String _frequency = 'monthly';
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  int _dayOfMonth = 1;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _recipientCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final now = DateTime.now();
      final nextDue = _frequency == 'monthly'
          ? DateTime(now.year, now.month, _dayOfMonth)
          : now.add(const Duration(days: 7));
      final nextDueStr =
          '${nextDue.year}-${nextDue.month.toString().padLeft(2, '0')}-${nextDue.day.toString().padLeft(2, '0')}';
      await repo.addRecurringTemplate(
        uid: user.uid,
        context: ctx,
        templateData: {
          'category': _cat.key,
          'note': _nameCtrl.text.trim(),
          'amount': _amountCtrl.text.trim(),
          'recipient': _recipientCtrl.text.trim(),
          'recurrenceType': _frequency,
          'nextDueDate': nextDueStr,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 4),
              Text(
                _tr('New Recurring Expense', 'Gharama Mpya ya Kujirudia'),
                style: GoogleFonts.dmSans(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              // Category grid (compact)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _Cat.values.map((cat) {
                  final active = cat == _cat;
                  return GestureDetector(
                    onTap: () => setState(() => _cat = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? cat.color : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: active ? cat.color : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon,
                              size: 13,
                              color: active ? Colors.white : cat.color),
                          const SizedBox(width: 5),
                          Text(cat.label,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _OutlineField(
                controller: _nameCtrl,
                label: _tr('Name / Description', 'Jina / Maelezo'),
                icon: Icons.label_rounded,
              ),
              const SizedBox(height: 10),
              _OutlineField(
                controller: _amountCtrl,
                label: _tr('Amount (TZS)', 'Kiasi (TZS)'),
                icon: Icons.payments_rounded,
                numeric: true,
              ),
              const SizedBox(height: 10),
              _OutlineField(
                controller: _recipientCtrl,
                label: _tr('Recipient (optional)', 'Mlipwaji (hiari)'),
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              // Frequency
              Row(
                children: [
                  Expanded(
                    child: _FreqChip(
                      label: _tr('Monthly', 'Kila Mwezi'),
                      active: _frequency == 'monthly',
                      onTap: () =>
                          setState(() => _frequency = 'monthly'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FreqChip(
                      label: _tr('Weekly', 'Kila Wiki'),
                      active: _frequency == 'weekly',
                      onTap: () =>
                          setState(() => _frequency = 'weekly'),
                    ),
                  ),
                ],
              ),
              if (_frequency == 'monthly') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                        _tr('Day of month:', 'Siku ya mwezi:'),
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _dayOfMonth,
                      items: List.generate(
                              28,
                              (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('${i + 1}',
                                      style: GoogleFonts.dmSans())))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _dayOfMonth = v ?? 1),
                      underline: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          _tr('Save', 'Hifadhi'),
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

class _FreqChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FreqChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.navyPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.navyPrimary : AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark Header
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseDarkHeader extends StatelessWidget {
  static const double _pillHalf = 22.0;

  final DateTime month;
  final double total;
  final int pendingCount;
  final int withReceipt;
  final bool loading;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _ExpenseDarkHeader({
    required this.month,
    required this.total,
    required this.pendingCount,
    required this.withReceipt,
    required this.loading,
    required this.onPrev,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white70),
                    onPressed: onPrev,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _monthLabel(month),
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                        color: canGoNext ? Colors.white70 : Colors.white24),
                    onPressed: canGoNext ? onNext : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  Text(
                    _tr('Expenses', 'Matumizi'),
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              loading
                  ? Container(
                      height: 34,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )
                  : Text(
                      'TZS ${_fmtNum(total)}',
                      style: GoogleFonts.dmSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
              const SizedBox(height: 4),
              Text(
                _tr('total spent this month', 'jumla iliyotumika mwezi huu'),
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white54),
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
                  value: 'TZS ${_fmtShort(total)}',
                  label: _tr('Spent', 'Imetumika'),
                  valueColor: AppColors.error,
                ),
                const _PillDivider(),
                _PillStat(
                  value: '$pendingCount',
                  label: _tr('Pending', 'Zinasubiri'),
                  valueColor:
                      pendingCount > 0 ? AppColors.warning : AppColors.success,
                ),
                const _PillDivider(),
                _PillStat(
                  value: '$withReceipt',
                  label: _tr('Receipts', 'Risiti'),
                  valueColor: AppColors.tealAccent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _OutlineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool numeric;

  const _OutlineField({
    required this.controller,
    required this.label,
    required this.icon,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: GoogleFonts.dmSans(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.navyPrimary, width: 2),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtNum(double v) {
  if (v == 0) return '0';
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtShort(double v) {
  if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
  if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _monthLabel(DateTime d) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[d.month - 1]} ${d.year}';
}
