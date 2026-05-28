import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../data/customer_providers.dart';
import '../../domain/models/customer.dart';
import '../widgets/add_customer_dialog.dart';
import 'customer_detail_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Segment filter
// ─────────────────────────────────────────────────────────────────────────────

enum _Segment { all, vip, wholesale, retail, blacklisted, hasBalance }

extension _SegmentX on _Segment {
  String get label => switch (this) {
        _Segment.all => _tr('All', 'Wote'),
        _Segment.vip => 'VIP',
        _Segment.wholesale => _tr('Wholesale', 'Jumla'),
        _Segment.retail => _tr('Retail', 'Reja reja'),
        _Segment.blacklisted => _tr('Blacklisted', 'Orodha Nyeusi'),
        _Segment.hasBalance => _tr('Owes Balance', 'Ana Deni'),
      };

  Color get color => switch (this) {
        _Segment.all => AppColors.navyPrimary,
        _Segment.vip => const Color(0xFFB45309),
        _Segment.wholesale => AppColors.tealAccent,
        _Segment.retail => AppColors.navySecondary,
        _Segment.blacklisted => AppColors.error,
        _Segment.hasBalance => AppColors.warning,
      };

  bool matches(Customer c) => switch (this) {
        _Segment.all => true,
        _Segment.vip => c.tags.any((t) => t.toLowerCase() == 'vip'),
        _Segment.wholesale =>
          c.tags.any((t) => t.toLowerCase().contains('jumla') ||
              t.toLowerCase().contains('wholesale')),
        _Segment.retail =>
          c.tags.any((t) => t.toLowerCase().contains('reja') ||
              t.toLowerCase().contains('retail')),
        _Segment.blacklisted =>
          c.tags.any((t) => t.toLowerCase().contains('nyeusi') ||
              t.toLowerCase().contains('black')),
        _Segment.hasBalance => (double.tryParse(c.balance) ?? 0) > 0,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchCtrl = TextEditingController();
  _Segment _segment = _Segment.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Customer> _filter(List<Customer> all) {
    var list = all.where(_segment.matches).toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.contains(q) ||
              c.email.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final all = customersAsync.maybeWhen(data: (d) => d, orElse: () => <Customer>[]);
    final filtered = _filter(all);

    final totalBalance = all.fold<double>(
        0, (s, c) => s + (double.tryParse(c.balance) ?? 0));
    final debtCount = all.where((c) => (double.tryParse(c.balance) ?? 0) > 0).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(all.length, totalBalance, debtCount),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _tr('Search by name, phone…', 'Tafuta kwa jina, simu…'),
                hintStyle:
                    GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ),
          _FilterPills(
            selected: _segment,
            customers: all,
            onSelect: (s) => setState(() => _segment = s),
          ),
          Expanded(
            child: customersAsync.isLoading
                ? const CustomerPageSkeleton()
                : filtered.isEmpty
                    ? _Empty(query: _searchCtrl.text, segment: _segment)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _CustomerCard(customer: filtered[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.navyPrimary,
        child: const Icon(Icons.person_add_alt_1_rounded,
            color: AppColors.yellowBrand),
      ),
    );
  }

  Widget _buildHeader(int count, double totalBalance, int debtCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyPrimary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.people_rounded,
                  label: '$count ${_tr("clients", "wateja")}',
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'TZS ${_fmtShort(totalBalance)}',
                  label2: _tr('receivable', 'inadaiwa'),
                  color: totalBalance > 0 ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.warning_amber_rounded,
                  label: '$debtCount ${_tr("with debt", "wenye deni")}',
                  color: debtCount > 0 ? AppColors.error : Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCustomerDialog(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter pills
// ─────────────────────────────────────────────────────────────────────────────

class _FilterPills extends StatelessWidget {
  final _Segment selected;
  final List<Customer> customers;
  final ValueChanged<_Segment> onSelect;

  const _FilterPills(
      {required this.selected, required this.customers, required this.onSelect});

  int _count(_Segment s) => s == _Segment.all
      ? customers.length
      : customers.where(s.matches).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1, color: AppColors.border),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _Segment.values.map((s) {
                final active = s == selected;
                final count = _count(s);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onSelect(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: active ? s.color : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? s.color : AppColors.border,
                          width: active ? 0 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.label,
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    active ? Colors.white : AppColors.textMuted),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : AppColors.textMuted),
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer card
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  Color get _accentColor {
    if (customer.tags.any((t) =>
        t.toLowerCase().contains('black') ||
        t.toLowerCase().contains('nyeusi'))) {
      return AppColors.error;
    }
    if (customer.tags.any((t) => t.toLowerCase() == 'vip')) {
      return const Color(0xFFB45309);
    }
    if (customer.tags.any((t) =>
        t.toLowerCase().contains('jumla') ||
        t.toLowerCase().contains('wholesale'))) {
      return AppColors.tealAccent;
    }
    return AppColors.navyPrimary;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo
          .scopeCollection(
              uid: user.uid, context: ctx, childCollection: 'customers')
          .doc(customer.id)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Customer deleted', 'Mteja amefutwa')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Delete failed', 'Imeshindwa kufuta')),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = double.tryParse(customer.balance) ?? 0;
    final hasBalance = balance > 0;
    final accent = _accentColor;

    return Dismissible(
      key: ValueKey(customer.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            builder: (_) => _EditCustomerSheet(customer: customer),
          );
          return false;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(_tr('Delete Customer?', 'Futa Mteja?'),
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            content: Text(
              _tr('Delete "${customer.name}"? This cannot be undone.',
                  'Futa "${customer.name}"? Hii haiwezi kutenduliwa.'),
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
        if (confirmed == true) {
          // ignore: use_build_context_synchronously
          await _delete(context, ref);
          return true;
        }
        return false;
      },
      background: _swipeHint(
        icon: Icons.edit_rounded,
        label: _tr('Edit', 'Hariri'),
        color: AppColors.navyPrimary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
      ),
      secondaryBackground: _swipeHint(
        icon: Icons.delete_outline_rounded,
        label: _tr('Delete', 'Futa'),
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(customer: customer),
          ));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: accent, width: 3.5),
              right: const BorderSide(color: AppColors.border),
              top: const BorderSide(color: AppColors.border),
              bottom: const BorderSide(color: AppColors.border),
            ),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadowCard,
                  blurRadius: 6,
                  offset: Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.1),
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: accent),
                ),
              ),
              const SizedBox(width: 12),
              // Name + phone + tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (customer.isOrganisation)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.tealAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _tr('ORG', 'SHIRIKA'),
                              style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tealAccent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.phone,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    if (customer.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        children: customer.tags.take(3).map((t) {
                          final tagColor = _tagColor(t);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: tagColor.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              t,
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: tagColor),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _tr('Balance', 'Salio'),
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasBalance
                        ? 'TZS ${_fmtShort(balance)}'
                        : _tr('Clear', 'Safi'),
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: hasBalance ? AppColors.error : AppColors.success),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textDisabled),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _tagColor(String tag) {
    final t = tag.toLowerCase();
    if (t == 'vip') return const Color(0xFFB45309);
    if (t.contains('black') || t.contains('nyeusi')) return AppColors.error;
    if (t.contains('jumla') || t.contains('wholesale')) return AppColors.tealAccent;
    return AppColors.navySecondary;
  }

  Widget _swipeHint({
    required IconData icon,
    required String label,
    required Color color,
    required Alignment alignment,
    required EdgeInsets padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: alignment,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final String query;
  final _Segment segment;

  const _Empty({required this.query, required this.segment});

  @override
  Widget build(BuildContext context) {
    final msg = query.isNotEmpty
        ? _tr('No results for "$query"', 'Hakuna matokeo ya "$query"')
        : _tr('No customers in this group',
            'Hakuna wateja katika kikundi hiki');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              query.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.group_off_rounded,
              size: 56,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Customer Sheet (preserved from original)
// ─────────────────────────────────────────────────────────────────────────────

class _EditCustomerSheet extends ConsumerStatefulWidget {
  final Customer customer;
  const _EditCustomerSheet({required this.customer});

  @override
  ConsumerState<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends ConsumerState<_EditCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _tinCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _creditLimitCtrl;
  late bool _isOrg;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _phoneCtrl = TextEditingController(text: widget.customer.phone);
    _emailCtrl = TextEditingController(text: widget.customer.email);
    _tinCtrl = TextEditingController(text: widget.customer.tinNumber);
    _addressCtrl = TextEditingController(text: widget.customer.address);
    _creditLimitCtrl = TextEditingController(
      text: widget.customer.creditLimit > 0
          ? widget.customer.creditLimit.toStringAsFixed(0)
          : '',
    );
    _isOrg = widget.customer.isOrganisation;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _tinCtrl.dispose();
    _addressCtrl.dispose();
    _creditLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);

      final limit = double.tryParse(_creditLimitCtrl.text) ?? 0;
      final updates = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'isOrganisation': _isOrg,
        'address': _addressCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (limit > 0) 'creditLimit': limit,
      };
      final tin = _tinCtrl.text.trim();
      if (tin.isNotEmpty) updates['tinNumber'] = tin;

      await repo
          .scopeCollection(
              uid: user.uid, context: ctx, childCollection: 'customers')
          .doc(widget.customer.id)
          .update(updates);

      nav.pop();
      msg.showSnackBar(SnackBar(
        content: Text(_tr('Customer updated', 'Mteja amesasishwa')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      msg.showSnackBar(SnackBar(
        content: Text(_tr('Failed to update', 'Imeshindwa kusasisha')),
      ));
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 2),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20, 12, 20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr('Edit Customer', 'Hariri Mteja'),
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary),
                  ),
                  const SizedBox(height: 16),
                  // Individual / Organisation toggle
                  _TypeToggleRow(
                    isOrg: _isOrg,
                    onChanged: (v) => setState(() => _isOrg = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec(
                      _isOrg
                          ? _tr('Organisation Name *', 'Jina la Shirika *')
                          : _tr('Customer Name *', 'Jina la Mteja *'),
                      _isOrg
                          ? Icons.business_outlined
                          : Icons.person_outline_rounded,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tr('Please enter a name', 'Tafadhali weka jina')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        _dec(_tr('Phone Number *', 'Namba ya Simu *'),
                            Icons.phone_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tr('Please enter phone number',
                            'Tafadhali weka namba ya simu')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec(
                        _tr('Email (Optional)', 'Barua pepe (Hiari)'),
                        Icons.email_outlined),
                  ),
                  if (_isOrg) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tinCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _dec(
                          _tr('TIN Number (Optional)',
                              'Namba ya TIN (Hiari)'),
                          Icons.numbers_outlined),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(
                        _tr('Address (Optional)', 'Anwani (Hiari)'),
                        Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _creditLimitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dec(
                        _tr('Credit Limit (TZS, 0 = no limit)',
                            'Kikomo cha Mkopo (TZS, 0 = bila kikomo)'),
                        Icons.credit_score_rounded),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(_tr('Cancel', 'Ghairi'),
                              style: GoogleFonts.dmSans()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navyPrimary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSaving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : Text(
                                  _tr('Save Changes', 'Hifadhi Mabadiliko'),
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggleRow extends StatelessWidget {
  final bool isOrg;
  final ValueChanged<bool> onChanged;

  const _TypeToggleRow({required this.isOrg, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleTab(
            label: _tr('Individual', 'Mtu Binafsi'),
            icon: Icons.person_outline_rounded,
            active: !isOrg,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _ToggleTab(
            label: _tr('Organisation', 'Shirika'),
            icon: Icons.business_outlined,
            active: isOrg,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleTab(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.navyPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: active ? Colors.white : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? label2;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, this.label2, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (label2 != null)
                    Text(
                      label2!,
                      style: GoogleFonts.dmSans(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}
