import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/localization_service.dart';
import '../../core/services/plan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/customer/data/customer_providers.dart';
import '../../features/customer/domain/models/customer.dart';
import '../../features/customer/presentation/widgets/add_customer_dialog.dart';
import 'app_sheet.dart';
import 'mali_components.dart';
import 'upgrade_sheet.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// CustomerPickerField
//
// Tap-to-open customer selector used across debts, invoices, and expenses.
// Shows selected customer as avatar + name + phone or a placeholder prompt.
// Opens CustomerPickerSheet which supports search and inline "Add New".
// ─────────────────────────────────────────────────────────────────────────────

class CustomerPickerField extends ConsumerStatefulWidget {
  final Customer? selected;
  final ValueChanged<Customer?> onSelected;

  /// When true, a clear (×) button appears once a customer is selected.
  final bool clearable;

  /// Label shown above the tile (null = no label row).
  final String? labelEn;
  final String? labelSw;

  const CustomerPickerField({
    super.key,
    required this.selected,
    required this.onSelected,
    this.clearable = true,
    this.labelEn,
    this.labelSw,
  });

  @override
  ConsumerState<CustomerPickerField> createState() =>
      _CustomerPickerFieldState();
}

class _CustomerPickerFieldState extends ConsumerState<CustomerPickerField> {
  void _open() async {
    final customers = ref
        .read(customerListProvider)
        .maybeWhen(data: (d) => d, orElse: () => <Customer>[]);

    if (!mounted) return;

    final picked = await showAppSheet<Customer>(
      context,
      builder: (_) => CustomerPickerSheet(
        customers: customers,
        selected: widget.selected,
      ),
    );

    if (!mounted) return;
    if (picked != null) widget.onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.selected;
    final hasLabel = widget.labelEn != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLabel) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              _tr(widget.labelEn!, widget.labelSw ?? widget.labelEn!),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
        InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: c != null ? AppColors.navyPrimary.withValues(alpha: 0.3) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c != null
                        ? AppColors.navyPrimary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: c != null ? AppColors.navyPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: c == null
                      ? Text(
                          _tr('Select customer (optional)',
                              'Chagua mteja (si lazima)'),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (c.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                c.phone,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                if (c != null && widget.clearable)
                  GestureDetector(
                    onTap: () => widget.onSelected(null),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
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

// ─────────────────────────────────────────────────────────────────────────────
// CustomerPickerSheet — modal bottom sheet with search + add-new
// ─────────────────────────────────────────────────────────────────────────────

class CustomerPickerSheet extends ConsumerStatefulWidget {
  final List<Customer> customers;
  final Customer? selected;

  const CustomerPickerSheet({
    super.key,
    required this.customers,
    this.selected,
  });

  @override
  ConsumerState<CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<CustomerPickerSheet> {
  String _query = '';
  late List<Customer> _customers;

  @override
  void initState() {
    super.initState();
    _customers = widget.customers;
  }

  List<Customer> get _filtered {
    if (_query.isEmpty) return _customers;
    final q = _query.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.phone.contains(_query))
        .toList();
  }

  void _openAddNew() async {
    // Users who have reached their plan's customer limit are gated behind
    // the shared slide-up upgrade sheet instead of the add-customer form.
    // The limit is plan-driven (Firestore `maxCustomers`, admin-editable)
    // and defaults to unlimited. Mirrors the FAB check in
    // customer_list_screen.dart so every "add customer" entry point (here:
    // invoice creation and manual debt entry, which both open via this
    // picker) enforces the same limit.
    final tier =
        ref.read(planStatusProvider).valueOrNull?.tier ?? PlanTier.starter;
    final defs = ref.read(planDefinitionsProvider).valueOrNull;
    final maxCustomers = limitsFor(tier, defs).maxCustomers;
    if (maxCustomers != -1 && widget.customers.length >= maxCustomers) {
      await showUpgradeSheet(
        context,
        featureKey: PlanFeatureKey.customerLimit,
        triggerReason: _tr(
          'You have reached the customer limit for your plan. Upgrade to add more customers.',
          'Umefika kikomo cha wateja kwa mpango wako. Panda mpango kuongeza wateja zaidi.',
        ),
      );
      return;
    }
    if (!mounted) return;

    // AddCustomerDialog is built as a bottom sheet (SheetHandle, rounded top
    // corners, unbounded-height inner scroll view) — it must be presented via
    // showAppSheet, which gives it a bounded height. Presenting it with
    // showDialog instead centers it with unbounded constraints and crashes
    // with a RenderFlex "unbounded height" error the moment it lays out.
    Customer? added;
    await showAppSheet<void>(
      context,
      builder: (_) => AddCustomerDialog(
        initialName: _query.trim(),
        onAdded: (c) => added = c,
      ),
    );
    // AddCustomerDialog closes itself (Navigator.pop with no value) once the
    // customer is saved — the created customer comes back via onAdded above,
    // not via the sheet's own result.
    if (added != null && mounted) {
      Navigator.of(context).pop(added);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (_, ctrl) => Column(
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('Select Customer', 'Chagua Mteja'),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: _tr('Search customers…', 'Tafuta wateja…'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_search_rounded,
                              size: 40, color: AppColors.textDisabled),
                          const SizedBox(height: 10),
                          Text(
                            _query.isEmpty
                                ? _tr('No customers yet', 'Hakuna wateja bado')
                                : _tr('No match found', 'Haipatikani'),
                            style: GoogleFonts.dmSans(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSelected = widget.selected?.id == c.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.navyPrimary.withValues(alpha: 0.1),
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.navyPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: c.displaySubtitle.isNotEmpty
                              ? Text(c.displaySubtitle,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: AppColors.textMuted))
                              : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.navyPrimary, size: 20)
                              : null,
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: OutlinedButton.icon(
                  onPressed: _openAddNew,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: Text(_query.trim().isNotEmpty
                      ? _tr('Add "${_query.trim()}"',
                          'Ongeza "${_query.trim()}"')
                      : _tr('Add New Customer', 'Ongeza Mteja Mpya')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyPrimary,
                    side: const BorderSide(color: AppColors.navyPrimary),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
