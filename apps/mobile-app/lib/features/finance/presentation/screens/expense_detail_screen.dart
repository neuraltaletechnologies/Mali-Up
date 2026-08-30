import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../domain/models/expense.dart';
import 'add_expense_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Category meta (mirrors expense_list_screen)
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

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  late Expense _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  Future<void> _delete() async {
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo
          .scopeCollection(
            uid: user.uid,
            context: ctx,
            childCollection: 'expenses',
          )
          .doc(_expense.id)
          .delete();
      // ignore: use_build_context_synchronously
      if (mounted) Navigator.of(context).pop({'deleted': true});
    } catch (_) {}
  }

  void _openEdit() async {
    final result = await showAppSheet<Map<String, dynamic>>(
      context,
      maxHeightFactor: 0.92,
      builder: (_) => AddExpenseScreen(expenseToEdit: _expense),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  void _viewReceipt() {
    if (_expense.receiptUrl.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullReceiptScreen(url: _expense.receiptUrl),
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cat = _CatX.fromKey(_expense.category);
    final amount = double.tryParse(_expense.amount) ?? 0;
    final hasReceipt = _expense.receiptUrl.isNotEmpty;
    final title = _expense.note.trim().isNotEmpty
        ? _expense.note.trim()
        : cat.label;
    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    MediaQuery.viewInsetsOf(context).bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(cat.icon, size: 20, color: cat.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyPrimary,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  cat.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _fmtDate(_expense.date),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (_expense.recipient.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '·',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textDisabled,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _expense.recipient,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'TZS ${_fmtNum(amount)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 16),
                      _SheetSectionLabel(
                        _tr('Expense details', 'Maelezo ya gharama'),
                      ),
                      const SizedBox(height: 8),
                      _DetailsCard(expense: _expense, cat: cat),
                      if (hasReceipt) ...[
                        const SizedBox(height: 16),
                        _SheetSectionLabel(_tr('Receipt', 'Risiti')),
                        const SizedBox(height: 8),
                        _ReceiptPreviewCard(
                          url: _expense.receiptUrl,
                          onView: _viewReceipt,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  MediaQuery.paddingOf(context).bottom + 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x120D1B3E),
                      blurRadius: 18,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 48,
                      child: OutlinedButton(
                        onPressed: _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _openEdit,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(
                            _tr('Edit Expense', 'Hariri Gharama'),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navyPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kept for the optional full-screen presentation used by older deep links.
  // ignore: unused_element
  Widget _buildSliverAppBar(_Cat cat, bool hasReceipt) {
    return SliverAppBar(
      expandedHeight: hasReceipt ? 220 : 160,
      pinned: true,
      backgroundColor: AppColors.navyPrimary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, size: 20),
          onPressed: _openEdit,
          tooltip: _tr('Edit', 'Hariri'),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          onPressed: _delete,
          tooltip: _tr('Delete', 'Futa'),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasReceipt
            ? _ReceiptHeroBackground(
                url: _expense.receiptUrl,
                onTap: _viewReceipt,
              )
            : _GradientBackground(cat: cat),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SliverAppBar backgrounds
// ─────────────────────────────────────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  final _Cat cat;

  const _GradientBackground({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyPrimary, cat.color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(cat.icon, size: 36, color: Colors.white),
        ),
      ),
    );
  }
}

class _ReceiptHeroBackground extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _ReceiptHeroBackground({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                color: AppColors.navyPrimary,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.zoom_out_map_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _tr('View receipt', 'Angalia risiti'),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content cards
// ─────────────────────────────────────────────────────────────────────────────

class _SheetSectionLabel extends StatelessWidget {
  final String text;

  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Expense expense;
  final _Cat cat;

  const _DetailsCard({required this.expense, required this.cat});

  @override
  Widget build(BuildContext context) {
    final payMethod = _PayMethodLabel.fromKey(expense.paymentMethod);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (expense.note.isNotEmpty) ...[
            _DetailRow(
              icon: Icons.notes_rounded,
              label: _tr('Description', 'Maelezo'),
              value: expense.note,
            ),
            const Divider(height: 1, color: AppColors.border),
          ],
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: _tr('Date', 'Tarehe'),
            value: _fmtDate(expense.date),
          ),
          const Divider(height: 1, color: AppColors.border),
          _DetailRow(
            icon: payMethod.icon,
            label: _tr('Payment Method', 'Njia ya Malipo'),
            value: payMethod.label,
          ),
          if (expense.recipient.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: _tr('Paid to', 'Imelipwa kwa'),
              value: expense.recipient,
            ),
          ],
          if (expense.isRecurring) ...[
            const Divider(height: 1, color: AppColors.border),
            _DetailRow(
              icon: Icons.repeat_rounded,
              label: _tr('Frequency', 'Marudio'),
              value: expense.recurrenceType == 'weekly'
                  ? _tr('Every week', 'Kila wiki')
                  : _tr('Every month', 'Kila mwezi'),
              valueColor: AppColors.tealAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary,
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

class _ReceiptPreviewCard extends StatelessWidget {
  final String url;
  final VoidCallback onView;

  const _ReceiptPreviewCard({required this.url, required this.onView});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.navyPrimary,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Receipt attached', 'Risiti imeambatishwa'),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tr('Tap to view full receipt', 'Gusa kuona risiti kamili'),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// Kept with the legacy full-screen presentation above.
// ignore: unused_element
class _ActionsCard extends StatelessWidget {
  final bool isRejected;
  final bool isApproved;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionsCard({
    required this.isRejected,
    required this.isApproved,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.edit_rounded,
            label: _tr('Edit expense', 'Hariri gharama'),
            color: AppColors.navyPrimary,
            onTap: onEdit,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: _tr('Delete expense', 'Futa gharama'),
            color: AppColors.error,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full receipt viewer
// ─────────────────────────────────────────────────────────────────────────────

class _FullReceiptScreen extends StatelessWidget {
  final String url;

  const _FullReceiptScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _tr('Receipt', 'Risiti'),
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            tooltip: _tr('Open in browser', 'Fungua kivinjari'),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method label helper (local to this file)
// ─────────────────────────────────────────────────────────────────────────────

class _PayMethodLabel {
  final String label;
  final IconData icon;

  const _PayMethodLabel({required this.label, required this.icon});

  static _PayMethodLabel fromKey(String key) {
    return switch (key) {
      'mpesa' => const _PayMethodLabel(
        label: 'M-Pesa',
        icon: Icons.phone_android_rounded,
      ),
      'bank' => _PayMethodLabel(
        label: _tr('Bank Transfer', 'Benki'),
        icon: Icons.account_balance_rounded,
      ),
      'card' => _PayMethodLabel(
        label: _tr('Card', 'Kadi'),
        icon: Icons.credit_card_rounded,
      ),
      'credit' => _PayMethodLabel(
        label: _tr('On credit', 'Kwa mkopo'),
        icon: Icons.credit_score_rounded,
      ),
      _ => _PayMethodLabel(
        label: _tr('Cash', 'Taslimu'),
        icon: Icons.payments_rounded,
      ),
    };
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

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
