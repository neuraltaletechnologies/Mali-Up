import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/nav_aware_fab.dart';
import '../../../../shared/widgets/silent_refresh.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
import '../../data/finance_providers.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/expense_category.dart';
import '../expense_category_style.dart';
import '../providers/expense_providers.dart';
import '../widgets/manage_expense_categories_sheet.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Category meta
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String? _filterCategoryKey;

  void _prevMonth() {
    final cur = ref.read(selectedMonthProvider);
    ref
        .read(selectedMonthProvider.notifier)
        .setMonth(DateTime(cur.year, cur.month - 1));
  }

  void _nextMonth() {
    final cur = ref.read(selectedMonthProvider);
    final next = DateTime(cur.year, cur.month + 1);
    if (next.isAfter(DateTime.now())) return;
    ref.read(selectedMonthProvider.notifier).setMonth(next);
  }

  void _openAdd({Expense? edit}) async {
    final plan = await ref.read(planStatusProvider.future);
    if (!mounted) return;
    if (!plan.limits.expenseTracking) {
      await showUpgradeSheet(
        context,
        currentStatus: plan,
        featureKey: PlanFeatureKey.expenseTracking,
        triggerReason: _tr(
          'Required a Growth or Business plan.',
          'Unahitaji mpango wa Growth au Business.',
        ),
      );
      return;
    }
    final result = await showAppSheet<Map<String, dynamic>>(
      context,
      maxHeightFactor: 0.92,
      builder: (_) => AddExpenseScreen(expenseToEdit: edit),
    );
    if (!mounted) return;
    // Shown from the list screen (not the sheet) so the toast clears the pill
    // nav bar and paints over the "Add Expense" button. Navy background, white
    // text — the app's default notification look.
    if (result?['saved'] == true && result?['creditRecorded'] == true) {
      AppNotification.info(
        context,
        _tr(
          'Expense saved – balance recorded in Payables',
          'Gharama imehifadhiwa – salio limerekodiwa kwenye Madeni',
        ),
        icon: Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _openDetail(Expense expense) async {
    await showAppSheet<Map<String, dynamic>>(
      context,
      maxHeightFactor: 0.92,
      builder: (_) => ExpenseDetailScreen(expense: expense),
    );
  }

  Future<void> _openCategoryManager() async {
    await showAppSheet<void>(
      context,
      maxHeightFactor: 0.88,
      builder: (_) => const ManageExpenseCategoriesSheet(),
    );
    if (!mounted || _filterCategoryKey == null) return;
    final categories =
        ref.read(expenseCategoryListProvider).valueOrNull ??
        ExpenseCategory.defaults;
    if (!categories.any((category) => category.key == _filterCategoryKey)) {
      setState(() => _filterCategoryKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final total = ref.watch(monthTotalSpendProvider);
    final expenses = ref.watch(expensesByMonthProvider);
    final isLoading = ref.watch(expenseListProvider).isLoading;
    final categories =
        ref.watch(expenseCategoryListProvider).valueOrNull ??
        ExpenseCategory.defaults;

    final withReceipt = expenses.where((e) => e.receiptUrl.isNotEmpty).length;

    final now = DateTime.now();
    final canGoNext = DateTime(
      month.year,
      month.month + 1,
    ).isBefore(DateTime(now.year, now.month + 1));

    final filtered = _filterCategoryKey == null
        ? expenses
        : expenses.where((e) => e.category == _filterCategoryKey).toList();
    final selectedCategory = _filterCategoryKey == null
        ? null
        : categories.firstWhere(
            (category) => category.key == _filterCategoryKey,
            orElse: () => ExpenseCategory.fallback(_filterCategoryKey!),
          );

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: NavAwareFab(
        child: FloatingActionButton.extended(
          onPressed: _openAdd,
          backgroundColor: AppColors.yellowBrand,
          foregroundColor: AppColors.navyPrimary,
          elevation: 3,
          icon: const Icon(Icons.receipt_long_rounded, size: 20),
          label: Text(
            _tr('Add Expense', 'Ongeza Matumizi'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: Column(
        children: [
          _ExpenseDarkHeader(
            month: month,
            total: total,
            withReceipt: withReceipt,
            expenseCount: expenses.length,
            onPrev: _prevMonth,
            onNext: _nextMonth,
            canGoNext: canGoNext,
          ),
          const SizedBox(height: HeaderStatsPill.pillHalf + 8),
          // Category filter pills
          _CategoryPills(
            categories: categories,
            selectedKey: _filterCategoryKey,
            onSelect: (key) => setState(() => _filterCategoryKey = key),
            onManage: _openCategoryManager,
          ),
          Expanded(
            child: SilentRefresh(
              onRefresh: () => triggerSilentSync(context, ref),
              child: isLoading
                  ? const ExpensePageSkeleton()
                  : filtered.isEmpty
                  ? SingleChildScrollView(
                      physics: silentRefreshPhysics,
                      child: EmptyState(
                        icon: Icons.receipt_outlined,
                        title: selectedCategory == null
                            ? _tr(
                                'No expenses this month',
                                'Hakuna matumizi mwezi huu',
                              )
                            : _tr(
                                'No ${selectedCategory.label} expenses',
                                'Hakuna matumizi ya ${selectedCategory.label}',
                              ),
                        subtitle: _tr(
                          'Tap + to log a purchase or bill.',
                          'Bonyeza + kurekodi ununuzi au bili.',
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: silentRefreshPhysics,
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _ExpenseCard(
                        expense: filtered[i],
                        category: categories.firstWhere(
                          (category) => category.key == filtered[i].category,
                          orElse: () =>
                              ExpenseCategory.fallback(filtered[i].category),
                        ),
                        isLast: i == filtered.length - 1,
                        onTap: () => _openDetail(filtered[i]),
                        onEdit: () => _openAdd(edit: filtered[i]),
                        onDelete: () => _deleteExpense(ctx, filtered[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(BuildContext context, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _tr('Delete Expense?', 'Futa Gharama?'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _tr('This cannot be undone.', 'Hii haiwezi kutenduliwa.'),
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _tr('Cancel', 'Ghairi'),
              style: GoogleFonts.dmSans(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              _tr('Delete', 'Futa'),
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      // Goes through the Drift + sync-queue repository — this is what makes
      // it work fully offline. It used to delete straight from Firestore
      // here, which hangs/fails while offline since Firestore's own
      // persistence cache is disabled (see main.dart).
      await ref.read(expenseRepositoryProvider).delete(expense.id);
      if (context.mounted) {
        AppNotification.success(
          context,
          _tr('Expense deleted', 'Gharama imefutwa'),
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppNotification.error(
          context,
          _tr(
            'Could not delete. Try again.',
            'Imeshindikana kufuta. Jaribu tena.',
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark Header
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseDarkHeader extends StatelessWidget {
  final DateTime month;
  final double total;
  final int withReceipt;
  final int expenseCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _ExpenseDarkHeader({
    required this.month,
    required this.total,
    required this.withReceipt,
    required this.expenseCount,
    required this.onPrev,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return DarkHeaderShell(
      title: Text(
        _tr('Expenses', 'Matumizi'),
        style: GoogleFonts.dmSans(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPrev,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white70,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _monthLabel(month),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canGoNext ? onNext : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: canGoNext ? Colors.white70 : Colors.white24,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      pill: HeaderStatsPill(
        stats: [
          HeaderPillStat(
            label: _tr('Spent', 'Imetumika'),
            value: 'TZS ${_fmtShort(total)}',
            color: AppColors.error,
          ),
          HeaderPillStat(
            label: _tr('Entries', 'Rekodi'),
            value: '$expenseCount',
            color: AppColors.navyPrimary,
          ),
          HeaderPillStat(
            label: _tr('Receipts', 'Risiti'),
            value: '$withReceipt',
            color: AppColors.tealAccent,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter pills
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPills extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final String? selectedKey;
  final ValueChanged<String?> onSelect;
  final VoidCallback onManage;

  const _CategoryPills({
    required this.categories,
    required this.selectedKey,
    required this.onSelect,
    required this.onManage,
  });

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _Pill(
                  label: _tr('All', 'Zote'),
                  active: selectedKey == null,
                  color: AppColors.navyPrimary,
                  onTap: () => onSelect(null),
                ),
                ...categories.map(
                  (cat) => _Pill(
                    label: cat.label,
                    icon: cat.icon,
                    active: selectedKey == cat.key,
                    color: cat.color,
                    onTap: () =>
                        onSelect(selectedKey == cat.key ? null : cat.key),
                  ),
                ),
                _Pill(
                  label: _tr('Manage', 'Simamia'),
                  icon: Icons.tune_rounded,
                  active: false,
                  color: AppColors.tealAccent,
                  onTap: onManage,
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? color : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: active ? Colors.white : color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expense card (flat row style like customer cards)
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final ExpenseCategory category;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.category,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = category;
    final amount = double.tryParse(expense.amount) ?? 0;

    return ListSwipeCard(
      itemKey: ValueKey(expense.id),
      onEdit: onEdit,
      onDelete: onDelete,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Column(
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cat.icon, size: 17, color: cat.color),
                  ),
                  const SizedBox(width: 10),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                cat.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '·',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _fmtDate(expense.date),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (expense.receiptUrl.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.receipt_rounded,
                                size: 11,
                                color: AppColors.tealAccent,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  Text(
                    'TZS ${_fmtNum(amount)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 46),
                  child: Divider(
                    height: 1,
                    color: AppColors.border,
                    thickness: 0.8,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

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
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.year}';
}
