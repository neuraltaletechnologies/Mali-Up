import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../../rbac/data/rbac_providers.dart';
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

  bool matches(Customer c) => switch (this) {
        _Segment.all => true,
        _Segment.vip => c.tags.any((t) => t.toLowerCase() == 'vip'),
        _Segment.wholesale => c.tags.any((t) =>
            t.toLowerCase().contains('jumla') ||
            t.toLowerCase().contains('wholesale')),
        _Segment.retail => c.tags.any((t) =>
            t.toLowerCase().contains('reja') ||
            t.toLowerCase().contains('retail')),
        _Segment.blacklisted => c.tags.any((t) =>
            t.toLowerCase().contains('nyeusi') ||
            t.toLowerCase().contains('black')),
        _Segment.hasBalance => c.balanceAmount > 0,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort option
// ─────────────────────────────────────────────────────────────────────────────

enum _CustomerSort { nameAz, nameZa, balanceHigh, balanceLow }

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchCtrl = TextEditingController();
  _Segment _segment = _Segment.all;
  _CustomerSort _sort = _CustomerSort.nameAz;
  bool _searchExpanded = false;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Customer> _filterAndSort(List<Customer> all) {
    var list = all.where(_segment.matches).toList();
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.contains(q) ||
              c.email.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q) ||
              c.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    switch (_sort) {
      case _CustomerSort.nameAz:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _CustomerSort.nameZa:
        list.sort((a, b) => b.name.compareTo(a.name));
      case _CustomerSort.balanceHigh:
        list.sort((a, b) => b.balanceAmount.compareTo(a.balanceAmount));
      case _CustomerSort.balanceLow:
        list.sort((a, b) => a.balanceAmount.compareTo(b.balanceAmount));
    }
    return list;
  }

  void _openFilterSheet(BuildContext ctx) {
    showAppSheet<void>(
      ctx,
      builder: (_) => _CustomerFilterSheet(
        currentSort: _sort,
        currentSegment: _segment,
        onApply: (sort, segment) => setState(() {
          _sort = sort;
          _segment = segment;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(permissionServiceProvider);
    final customersAsync = ref.watch(customerListProvider);
    final showFinancials = ps.canViewDebt || ps.isOwner;

    final all = customersAsync.maybeWhen(
      data: (d) => d,
      orElse: () => <Customer>[],
    );
    final filtered = _filterAndSort(all);

    final activeFilters = (_segment != _Segment.all ? 1 : 0) +
        (_sort != _CustomerSort.nameAz ? 1 : 0);

    return Scaffold(
      floatingActionButton: ps.canManageCustomers || ps.isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              backgroundColor: AppColors.yellowBrand,
              foregroundColor: AppColors.navyPrimary,
              elevation: 3,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: Text(
                _tr('Add Customer', 'Ongeza Mteja'),
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Column(
        children: [
          _CustomerDarkHeader(
            customers: all,
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
            activeFilters: activeFilters,
            onFilterTap: () => _openFilterSheet(context),
            showFinancials: showFinancials,
          ),
          const SizedBox(height: _CustomerDarkHeader._pillHalf + 8),
          if (_segment != _Segment.all)
            _ActiveCustomerFilterChip(
              label: _segment.label,
              onRemove: () => setState(() => _segment = _Segment.all),
            ),
          Expanded(
            child: customersAsync.isLoading
                ? const CustomerPageSkeleton()
                : filtered.isEmpty
                    ? _Empty(query: _query, segment: _segment)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _CustomerCard(
                          customer: filtered[i],
                          showFinancials: showFinancials,
                          canManage: ps.canManageCustomers || ps.isOwner,
                          isLast: i == filtered.length - 1,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showAppSheet(
      context,
      builder: (_) => const AddCustomerDialog(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark Header
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerDarkHeader extends StatelessWidget {
  final List<Customer> customers;
  final TextEditingController searchCtrl;
  final String query;
  final bool searchExpanded;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final int activeFilters;
  final VoidCallback onFilterTap;
  final bool showFinancials;

  const _CustomerDarkHeader({
    required this.customers,
    required this.searchCtrl,
    required this.query,
    required this.searchExpanded,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.activeFilters,
    required this.onFilterTap,
    required this.showFinancials,
  });

  static const double _pillHalf = 22.0;

  Widget _buildPill() {
    final total = customers.length;
    final totalReceivable = showFinancials
        ? customers.fold<double>(0, (s, c) => s + c.balanceAmount)
        : 0.0;
    final debtCount = showFinancials
        ? customers.where((c) => c.balanceAmount > 0).length
        : 0;

    return Container(
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
            label: _tr('Wateja', 'Wateja'),
            value: '$total',
            color: AppColors.tealAccent,
          ),
          const _PillDivider(),
          _PillStat(
            label: _tr('Inadaiwa', 'Inadaiwa'),
            value: showFinancials ? 'TSh ${_fmtShort(totalReceivable)}' : '—',
            color: totalReceivable > 0 ? AppColors.warning : AppColors.success,
          ),
          const _PillDivider(),
          _PillStat(
            label: _tr('Deni', 'Deni'),
            value: showFinancials ? '$debtCount' : '—',
            color: debtCount > 0 ? AppColors.error : AppColors.success,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final hasAlerts =
        showFinancials && customers.any((c) => c.balanceAmount > 0);
    final showDot = hasAlerts || activeFilters > 0;
    final dotColor = hasAlerts ? AppColors.error : AppColors.yellowBrand;

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
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20 + _pillHalf),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('Customers', 'Wateja'),
                      style: GoogleFonts.dmSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Filter button
                  GestureDetector(
                    onTap: onFilterTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: activeFilters > 0
                                ? AppColors.yellowBrand
                                : Colors.white,
                            size: 20,
                          ),
                          if (showDot)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Search button
                  GestureDetector(
                    onTap: onToggleSearch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
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
                                'Search by name, phone, tag…',
                                'Tafuta kwa jina, simu, lebo…',
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
          left: 0,
          right: 0,
          child: Center(child: _buildPill()),
        ),
      ],
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
        const SizedBox(height: 2),
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
      child: Container(
        width: 1,
        height: 28,
        color: AppColors.border,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveCustomerFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveCustomerFilterChip(
      {required this.label, required this.onRemove});

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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
// Filter / Sort Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerFilterSheet extends StatefulWidget {
  final _CustomerSort currentSort;
  final _Segment currentSegment;
  final void Function(_CustomerSort sort, _Segment segment) onApply;

  const _CustomerFilterSheet({
    required this.currentSort,
    required this.currentSegment,
    required this.onApply,
  });

  @override
  State<_CustomerFilterSheet> createState() => _CustomerFilterSheetState();
}

class _CustomerFilterSheetState extends State<_CustomerFilterSheet> {
  late _CustomerSort _sort;
  late _Segment _segment;

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
    _segment = widget.currentSegment;
  }

  void _apply() {
    widget.onApply(_sort, _segment);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _sort = _CustomerSort.nameAz;
      _segment = _Segment.all;
    });
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
              const SheetHandle(),
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
              _SheetSectionLabel(_tr('Sort by', 'Panga kwa')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SortChip(
                    label: _tr('Name A–Z', 'Jina A–Z'),
                    selected: _sort == _CustomerSort.nameAz,
                    onTap: () =>
                        setState(() => _sort = _CustomerSort.nameAz),
                  ),
                  _SortChip(
                    label: _tr('Name Z–A', 'Jina Z–A'),
                    selected: _sort == _CustomerSort.nameZa,
                    onTap: () =>
                        setState(() => _sort = _CustomerSort.nameZa),
                  ),
                  _SortChip(
                    label: _tr('Balance ↑', 'Salio ↑'),
                    selected: _sort == _CustomerSort.balanceHigh,
                    onTap: () =>
                        setState(() => _sort = _CustomerSort.balanceHigh),
                  ),
                  _SortChip(
                    label: _tr('Balance ↓', 'Salio ↓'),
                    selected: _sort == _CustomerSort.balanceLow,
                    onTap: () =>
                        setState(() => _sort = _CustomerSort.balanceLow),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetSectionLabel(_tr('Segment', 'Kundi')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _Segment.values
                    .map((s) => _SortChip(
                          label: s.label,
                          selected: _segment == s,
                          onTap: () => setState(() => _segment = s),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _tr('Apply', 'Tumia'),
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

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

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
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
// Customer card (flat row style)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  final bool showFinancials;
  final bool canManage;
  final bool isLast;

  const _CustomerCard({
    required this.customer,
    required this.showFinancials,
    required this.canManage,
    required this.isLast,
  });

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
      // Offline-first: soft-deletes in Drift (list updates instantly) and
      // queues the remote delete for the sync engine.
      await ref.read(customerRepositoryProvider).delete(customer.id);
      await ref.read(customerAuditLoggerProvider).log(
            AuditLogService.customerDeleted,
            customerId: customer.id,
            customerName: customer.name,
          );
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
          backgroundColor: AppColors.error,
          content: Text(_tr(
            'Could not delete customer. Please try again.',
            'Imeshindwa kufuta mteja. Jaribu tena.',
          )),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = customer.balanceAmount;
    final hasBalance = balance > 0;
    final accent = _accentColor;
    final lastDate = _relativeLastPurchase(customer);
    final hasLastDate = lastDate.isNotEmpty;

    return ListSwipeCard(
      itemKey: ValueKey(customer.id),
      onEdit: canManage
          ? () async {
              await showAppSheet<void>(
                context,
                builder: (_) => _EditCustomerSheet(customer: customer),
              );
            }
          : null,
      onDelete: canManage
          ? () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    _tr('Delete Customer?', 'Futa Mteja?'),
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    _tr(
                      'Delete "${customer.name}"? This cannot be undone.',
                      'Futa "${customer.name}"? Hii haiwezi kutenduliwa.',
                    ),
                    style: GoogleFonts.dmSans(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(_tr('Cancel', 'Ghairi'),
                          style:
                              GoogleFonts.dmSans(color: AppColors.textMuted)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: Text(_tr('Delete', 'Futa'),
                          style:
                              GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await _delete(context, ref);
              }
            }
          : null,
      child: GestureDetector(
        onTap: () {
          showAppSheet<void>(
            context,
            builder: (_) => _CustomerInfoSheet(
              customer: customer,
              showFinancials: showFinancials,
              canManage: canManage,
            ),
          );
        },
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
                      color: accent.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + contact + tags
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: _statusChips(),
                        ),
                        if (customer.displaySubtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            customer.displaySubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                        if (customer.tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: customer.tags
                                .where((t) => t.toLowerCase() != 'contact')
                                .take(3)
                                .map((t) {
                              final tagColor = _tagColor(t);
                              return _TagChip(tag: t, color: tagColor);
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Balance + last date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showFinancials) ...[
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
                              color: hasBalance
                                  ? AppColors.error
                                  : AppColors.success),
                        ),
                        if (hasBalance && customer.creditLimit > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            customer.isOverCreditLimit
                                ? _tr('Over limit!', 'Imezidi!')
                                : '${(customer.creditUtilization * 100).toStringAsFixed(0)}% used',
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: customer.isOverCreditLimit
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ] else ...[
                        const Icon(Icons.lock_outline_rounded,
                            size: 14, color: AppColors.textDisabled),
                      ],
                      if (hasLastDate) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_rounded,
                                size: 10, color: AppColors.textDisabled),
                            const SizedBox(width: 3),
                            Text(
                              lastDate,
                              style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: AppColors.textDisabled),
                            ),
                          ],
                        ),
                      ],
                    ],
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

  Color _tagColor(String tag) {
    final t = tag.toLowerCase();
    if (t == 'vip') return const Color(0xFFB45309);
    if (t.contains('black') || t.contains('nyeusi')) return AppColors.error;
    if (t.contains('jumla') || t.contains('wholesale')) {
      return AppColors.tealAccent;
    }
    return AppColors.navySecondary;
  }

  List<Widget> _statusChips() {
    final chips = <Widget>[];
    final importedFromContacts =
        customer.tags.any((t) => t.toLowerCase() == 'contact');

    chips.add(
      _TagChip(
        tag: importedFromContacts
            ? _tr('FROM CONTACTS', 'KUTOKA MAWASILIANO')
            : _tr('MANUAL', 'KWA MKONO'),
        color:
            importedFromContacts ? AppColors.tealAccent : AppColors.textMuted,
      ),
    );

    if (customer.isOrganisation) {
      chips.add(
        _TagChip(
          tag: _tr('ORG', 'SHIRIKA'),
          color: AppColors.navySecondary,
        ),
      );
    }

    return chips;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small card sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String tag;
  final Color color;
  const _TagChip({required this.tag, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        tag,
        style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
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
    final hasQuery = query.isNotEmpty;
    final isFiltered = segment != _Segment.all;
    return EmptyState(
      icon: hasQuery
          ? Icons.search_off_rounded
          : isFiltered
              ? Icons.filter_list_off_rounded
              : Icons.people_outline_rounded,
      title: hasQuery
          ? _tr('No results for "$query"', 'Hakuna matokeo ya "$query"')
          : isFiltered
              ? _tr('No customers in this group',
                  'Hakuna wateja katika kikundi hiki')
              : _tr('No customers yet', 'Bado hakuna wateja'),
      subtitle: hasQuery
          ? _tr(
              'Try searching by name, phone, or tag.',
              'Jaribu kutafuta kwa jina, simu, au lebo.')
          : isFiltered
              ? _tr('Try a different filter.', 'Jaribu kichujio tofauti.')
              : _tr(
                  'Add your first customer to start tracking sales and balances.',
                  'Ongeza mteja wa kwanza kuanza kufuatilia mauzo na salio.'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Customer Sheet
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
      final limit = double.tryParse(_creditLimitCtrl.text) ?? 0;
      final updated = widget.customer.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        isOrganisation: _isOrg,
        address: _addressCtrl.text.trim(),
        tinNumber: _tinCtrl.text.trim(),
        creditLimit: limit,
      );

      // Offline-first: Drift + sync queue in one transaction.
      await ref.read(customerRepositoryProvider).save(updated);
      await ref.read(customerAuditLoggerProvider).log(
            AuditLogService.customerUpdated,
            customerId: updated.id,
            customerName: updated.name,
          );

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
        backgroundColor: AppColors.error,
        content: Text(_tr(
          'Could not save changes. Please try again.',
          'Imeshindwa kuhifadhi mabadiliko. Jaribu tena.',
        )),
      ));
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 16),
                  Text(
                    _tr('Edit Customer', 'Hariri Mteja'),
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary),
                  ),
                  const SizedBox(height: 16),
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
                    decoration: _dec(
                        _tr('Phone Number *', 'Namba ya Simu *'),
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
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
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

String _fmtShort(double v) {
  if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
  if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

String _e164(String phone) {
  var clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (!clean.startsWith('+') && clean.startsWith('0')) {
    clean = '+255${clean.substring(1)}';
  }
  return clean;
}

/// Renders the last purchase as a relative label. ISO dates (written by the
/// sales flow) become "3 days ago"; legacy free-text values show as-is.
String _relativeLastPurchase(Customer c) {
  final raw = c.lastTransactionDate;
  if (raw.isEmpty || raw == '0' || raw == '—') return '';
  final d = c.lastPurchaseAt;
  if (d == null) return raw;
  final days = DateTime.now().difference(d).inDays;
  if (days <= 0) return _tr('Today', 'Leo');
  if (days == 1) return _tr('Yesterday', 'Jana');
  if (days < 30) return _tr('$days days ago', 'Siku $days zilizopita');
  final months = days ~/ 30;
  if (months < 12) return _tr('${months}mo ago', 'Miezi $months iliyopita');
  return _tr('${months ~/ 12}y ago', 'Zaidi ya mwaka ${months ~/ 12}');
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer info slide-up sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerInfoSheet extends ConsumerWidget {
  final Customer customer;
  final bool showFinancials;
  final bool canManage;

  const _CustomerInfoSheet({
    required this.customer,
    required this.showFinancials,
    required this.canManage,
  });

  Color _accent(Customer c) {
    if (c.tags.any((t) =>
        t.toLowerCase().contains('black') ||
        t.toLowerCase().contains('nyeusi'))) {
      return AppColors.error;
    }
    if (c.tags.any((t) => t.toLowerCase() == 'vip')) {
      return const Color(0xFFB45309);
    }
    if (c.tags.any((t) =>
        t.toLowerCase().contains('jumla') ||
        t.toLowerCase().contains('wholesale'))) {
      return AppColors.tealAccent;
    }
    return AppColors.navyPrimary;
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _whatsapp(String phone) async {
    final e164 = _e164(phone);
    await launchUrl(
      Uri.parse('https://wa.me/$e164'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _remind(Customer c) async {
    final e164 = _e164(c.phone);
    final balance = _fmtShort(c.balanceAmount);
    final msg = '${_tr('Dear', 'Ndugu')} ${c.name},\n\n'
        '${_tr('You have an outstanding balance of TZS $balance.', 'Una deni la TZS $balance kwetu.')}\n\n'
        '${_tr('Please arrange payment at your earliest convenience. Thank you!', 'Tafadhali panga malipo haraka iwezekanavyo. Asante!')}';
    await launchUrl(
      Uri.parse('https://wa.me/$e164?text=${Uri.encodeComponent(msg)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(customerListProvider).valueOrNull
            ?.firstWhere((c) => c.id == customer.id, orElse: () => customer) ??
        customer;

    final balance = live.balanceAmount;
    final hasBalance = balance > 0;
    final accent = _accent(live);
    final initials = _initials(live.name);
    final displayTags =
        live.tags.where((t) => t.toLowerCase() != 'contact').toList();
    final hasPhone = live.phone.isNotEmpty;
    final hasEmail = live.email.isNotEmpty;
    final hasAddress = live.address.isNotEmpty;
    final hasTin = live.tinNumber.isNotEmpty;
    final hasContact = hasPhone || hasEmail || hasAddress || hasTin;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.2)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    live.name,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navyPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (live.isOrganisation) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.navyPrimary
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      _tr('ORG', 'SHIRIKA'),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (hasPhone) ...[
                              const SizedBox(height: 2),
                              Text(
                                live.phone,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (canManage)
                        GestureDetector(
                          onTap: () async {
                            await showAppSheet<void>(
                              context,
                              builder: (_) =>
                                  _EditCustomerSheet(customer: live),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // ── Tags ─────────────────────────────────────────────────
                  if (displayTags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: displayTags
                          .map((t) => _SheetTagChip(tag: t))
                          .toList(),
                    ),
                  ],

                  // ── Balance banner ────────────────────────────────────────
                  if (showFinancials) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: hasBalance
                            ? AppColors.error.withValues(alpha: 0.06)
                            : AppColors.success.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasBalance
                              ? AppColors.error.withValues(alpha: 0.2)
                              : AppColors.success.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasBalance
                                ? Icons.account_balance_wallet_rounded
                                : Icons.check_circle_rounded,
                            size: 16,
                            color: hasBalance
                                ? AppColors.error
                                : AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasBalance
                                  ? _tr(
                                      'Outstanding: TZS ${_fmtShort(balance)}',
                                      'Deni: TZS ${_fmtShort(balance)}',
                                    )
                                  : _tr(
                                      'No outstanding balance',
                                      'Hakuna deni',
                                    ),
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasBalance
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),

                  // ── Quick actions ─────────────────────────────────────────
                  if (hasPhone) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _SheetActionBtn(
                            icon: Icons.phone_rounded,
                            label: _tr('Call', 'Simu'),
                            color: AppColors.success,
                            onTap: () => _call(live.phone),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SheetActionBtn(
                            icon: Icons.chat_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () => _whatsapp(live.phone),
                          ),
                        ),
                        if (showFinancials && hasBalance) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SheetActionBtn(
                              icon: Icons.alarm_rounded,
                              label: _tr('Remind', 'Kumbushia'),
                              color: AppColors.warning,
                              onTap: () => _remind(live),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 14),
                  ],

                  // ── Contact info ──────────────────────────────────────────
                  if (hasContact) ...[
                    Text(
                      _tr('CONTACT INFO', 'MAWASILIANO').toUpperCase(),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          if (hasPhone)
                            _SheetInfoRow(
                              icon: Icons.phone_rounded,
                              label: _tr('Phone', 'Simu'),
                              value: live.phone,
                              isFirst: true,
                              isLast: !hasEmail && !hasAddress && !hasTin,
                            ),
                          if (hasEmail)
                            _SheetInfoRow(
                              icon: Icons.email_rounded,
                              label: _tr('Email', 'Barua pepe'),
                              value: live.email,
                              isFirst: !hasPhone,
                              isLast: !hasAddress && !hasTin,
                            ),
                          if (hasAddress)
                            _SheetInfoRow(
                              icon: Icons.location_on_rounded,
                              label: _tr('Address', 'Anwani'),
                              value: live.address,
                              isFirst: !hasPhone && !hasEmail,
                              isLast: !hasTin,
                            ),
                          if (hasTin)
                            _SheetInfoRow(
                              icon: Icons.numbers_rounded,
                              label: 'TIN',
                              value: live.tinNumber,
                              isFirst: !hasPhone && !hasEmail && !hasAddress,
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── View full profile ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              CustomerDetailScreen(customer: live),
                        ));
                      },
                      icon: const Icon(Icons.person_rounded, size: 18),
                      label: Text(
                        _tr('View Full Profile', 'Ona Profaili Kamili'),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
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

class _SheetActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _SheetInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isFirst)
          const Divider(
              height: 1, indent: 16, endIndent: 16, color: AppColors.border),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_tr('$label copied', '$label imenakiliwa')),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            }
          },
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(14) : Radius.zero,
            bottom: isLast ? const Radius.circular(14) : Radius.zero,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.textMuted),
                ),
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
                      const SizedBox(height: 1),
                      Text(
                        value,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetTagChip extends StatelessWidget {
  final String tag;
  const _SheetTagChip({required this.tag});

  Color _color() {
    final t = tag.toLowerCase();
    if (t == 'vip') return const Color(0xFFB45309);
    if (t.contains('nyeusi') || t.contains('black')) return AppColors.error;
    if (t.contains('jumla') || t.contains('wholesale')) {
      return AppColors.tealAccent;
    }
    return AppColors.navySecondary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        tag,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
