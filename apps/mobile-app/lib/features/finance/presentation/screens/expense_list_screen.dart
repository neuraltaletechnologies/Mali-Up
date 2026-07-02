import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
import '../../../customer/data/customer_providers.dart';
import '../../data/finance_providers.dart';
import '../../domain/models/expense.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Category meta
// ─────────────────────────────────────────────────────────────────────────────

enum _Cat { rent, utilities, salaries, transport, marketing, supplies, other }

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

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  _Cat? _filterCat;

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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      builder: (_) => AddExpenseScreen(expenseToEdit: edit),
    );
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

    final filtered = _filterCat == null
        ? expenses
        : expenses.where((e) => e.category == _filterCat!.key).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppColors.yellowBrand,
        foregroundColor: AppColors.navyPrimary,
        elevation: 3,
        icon: Icon(Icons.receipt_long_rounded, size: 20),
        label: Text(
          _tr('Add Expense', 'Ongeza Matumizi'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _ExpenseDarkHeader(
            month: month,
            total: total,
            pendingCount: pendingCount,
            withReceipt: withReceipt,
            expenseCount: expenses.length,
            onPrev: _prevMonth,
            onNext: _nextMonth,
            canGoNext: canGoNext,
          ),
          const SizedBox(height: _ExpenseDarkHeader._pillHalf + 8),
          // Category filter pills
          _CategoryPills(
            selected: _filterCat,
            onSelect: (c) => setState(() => _filterCat = c),
          ),
          Expanded(
            child: isLoading
                ? const SkeletonList(itemCount: 6)
                : filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_outlined,
                        title: _filterCat == null
                            ? _tr('No expenses this month',
                                'Hakuna matumizi mwezi huu')
                            : _tr('No ${_filterCat!.label} expenses',
                                'Hakuna matumizi ya ${_filterCat!.label}'),
                        subtitle: _tr(
                          'Tap + to log a purchase or bill.',
                          'Bonyeza + kurekodi ununuzi au bili.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _ExpenseCard(
                          expense: filtered[i],
                          isLast: i == filtered.length - 1,
                          onTap: () => _openDetail(filtered[i]),
                          onEdit: () => _openAdd(edit: filtered[i]),
                          onDelete: () =>
                              _deleteExpense(ctx, filtered[i]),
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

// ─────────────────────────────────────────────────────────────────────────────
// Dark Header
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseDarkHeader extends StatelessWidget {
  static const double _pillHalf = 22.0;

  final DateTime month;
  final double total;
  final int pendingCount;
  final int withReceipt;
  final int expenseCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _ExpenseDarkHeader({
    required this.month,
    required this.total,
    required this.pendingCount,
    required this.withReceipt,
    required this.expenseCount,
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
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, _pillHalf + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('Expenses', 'Matumizi'),
                      style: GoogleFonts.dmSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Month navigation
                  GestureDetector(
                    onTap: onPrev,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white70, size: 22),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _monthLabel(month),
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70),
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
                      child: Icon(Icons.chevron_right_rounded,
                          color: canGoNext ? Colors.white70 : Colors.white24,
                          size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -_pillHalf,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PillStat(
                    label: _tr('Spent', 'Imetumika'),
                    value: 'TZS ${_fmtShort(total)}',
                    color: AppColors.error,
                  ),
                  const _PillDivider(),
                  _PillStat(
                    label: _tr('Pending', 'Zinasubiri'),
                    value: '$pendingCount',
                    color: pendingCount > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  const _PillDivider(),
                  _PillStat(
                    label: _tr('Receipts', 'Risiti'),
                    value: '$withReceipt',
                    color: AppColors.tealAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter pills
// ─────────────────────────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      onTap: () => onSelect(selected == cat ? null : cat),
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
                    color: active ? Colors.white : AppColors.textMuted),
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
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.isLast,
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
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
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
                                    fontWeight: FontWeight.w700,
                                    color: isRejected
                                        ? AppColors.error
                                        : AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              cat.label,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                            SizedBox(width: 6),
                            Text('·',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textDisabled)),
                            SizedBox(width: 6),
                            Text(
                              _fmtDate(expense.date),
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (expense.receiptUrl.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.receipt_rounded,
                                  size: 11, color: AppColors.tealAccent),
                            ],
                            if (isPending) ...[
                              const SizedBox(width: 6),
                              _StatusBadge(
                                  label: _tr('Pending', 'Inasubiri'),
                                  color: AppColors.warning),
                            ],
                            if (isRejected) ...[
                              const SizedBox(width: 6),
                              _StatusBadge(
                                  label: _tr('Rejected', 'Imekataliwa'),
                                  color: AppColors.error),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Amount
                  Text(
                    'TZS ${_fmtNum(amount)}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isRejected
                            ? AppColors.error
                            : AppColors.navyPrimary),
                  ),
                ],
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.only(top: 13, left: 60),
                  child: Divider(
                      height: 1, color: AppColors.border, thickness: 0.8),
                ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
            fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PillStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PillStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(width: 1, height: 28, color: AppColors.border),
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
