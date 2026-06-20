import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../catalog/domain/models/master_category.dart';
import '../../data/inventory_providers.dart';
import '../widgets/category_picker_sheet.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getLowStockCount(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final currentStock = parseStock(item['currentStock']);
      final reorderPoint = parseStock(item['reorderPoint']);
      return currentStock > 0 && currentStock <= reorderPoint;
    }).length;
  }

  int _getOutOfStockCount(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final currentStock = parseStock(item['currentStock']);
      return currentStock == 0;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryAsync = ref.watch(inventoryItemListProvider);
    final allItems = inventoryAsync.maybeWhen(
      data: (items) =>
          items.map((item) => Map<String, dynamic>.from(item)).toList(),
      orElse: () => <Map<String, dynamic>>[],
    );

    // Filter items based on search
    final filteredItems = _searchController.text.isEmpty
        ? allItems
        : allItems
            .where((item) {
              final name = item['name']?.toString().toLowerCase() ?? '';
              final category = item['category']?.toString().toLowerCase() ?? '';
              final sku = item['sku']?.toString().toLowerCase() ?? '';
              final searchText = _searchController.text.toLowerCase();
              return name.contains(searchText) ||
                  category.contains(searchText) ||
                  sku.contains(searchText);
            })
            .toList();

    final isLoading = inventoryAsync.isLoading;
    final error = inventoryAsync.error;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Inventory', 'Akiba'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          AppSearchBar(
            controller: _searchController,
            hintText: _tr('Search by name, category or SKU...', 'Tafuta kwa jina, kategoria au SKU...'),
            onChanged: (_) => setState(() {}),
          ),

          // Inventory Summary - Compact card style
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CompactStat(
                  label: _tr('Total', 'Jumla'),
                  value: '${filteredItems.length}',
                  icon: Icons.inventory_2_outlined,
                ),
                Container(width: 1, height: 20, color: AppColors.border),
                _CompactStat(
                  label: _tr('Low Stock', 'Ndogo'),
                  value: '${_getLowStockCount(filteredItems)}',
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.warning,
                ),
                Container(width: 1, height: 20, color: AppColors.border),
                _CompactStat(
                  label: _tr('Out', 'Hakuna'),
                  value: '${_getOutOfStockCount(filteredItems)}',
                  icon: Icons.error_outline_outlined,
                  color: AppColors.error,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: _buildInventoryList(filteredItems, isLoading, error?.toString()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(
          Icons.add_shopping_cart_rounded,
          color: AppColors.secondary,
        ),
        label: Text(
          _tr('Add Item', 'Ongeza Bidhaaa'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryList(
    List<Map<String, dynamic>> items,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: SkeletonList(),
      );
    }

    if (error != null) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: _tr('Could not load inventory', 'Imeshindwa kupakia bidhaa'),
        subtitle: _tr('Check your connection and try again.',
            'Angalia muunganiko wako na ujaribu tena.'),
      );
    }

    if (items.isEmpty) {
      final hasSearch = _searchController.text.isNotEmpty;
      return EmptyState(
        icon: hasSearch
            ? Icons.search_off_rounded
            : Icons.inventory_2_outlined,
        title: hasSearch
            ? _tr('No matches found', 'Hakuna inayolingana')
            : _tr('Your shelves are empty', 'Rafu zako ziko tupu'),
        subtitle: hasSearch
            ? _tr('Try different search terms.',
                'Jaribu maneno tofauti ya utafutaji.')
            : _tr('Add your first item to start tracking stock.',
                'Ongeza bidhaa yako ya kwanza ili uanze kufuatilia akiba.'),
        actionLabel: hasSearch ? null : _tr('Add Item', 'Ongeza Bidhaa'),
        onAction: hasSearch ? null : () => _showAddItemDialog(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh logic can be implemented here
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _InventoryCard(item: item);
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddItemDialog(),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statColor = color ?? AppColors.primary;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: statColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: statColor,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}


class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockColor = _getStockColor(item['stockStatus']?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: stockColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['category']?.toString() ?? '',
                  style: theme.textTheme.bodySmall,
                ),
                if ((item['sku']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item['sku']}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${parseStock(item['currentStock'])} ${item['unit']?.toString() ?? ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: stockColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'TZS ${parseUnitPrice(item['unitPrice']).toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: stockColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item['stockStatus']?.toString() ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: stockColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStockColor(String status) {
    switch (status) {
      case 'Out of Stock':
        return AppColors.error;
      case 'Low Stock':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }
}

class AddItemDialog extends ConsumerStatefulWidget {
  const AddItemDialog({super.key});

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();

  MasterCategory? _selectedCategory;
  String _selectedUnit = 'pcs';
  bool _isLoading = false;

  static const _units = [
    'pcs', 'kg', 'g', 'liters', 'ml',
    'boxes', 'bottles', 'bags', 'meters', 'pairs', 'sets', 'dozens',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _skuCtrl.dispose();
    _stockCtrl.dispose();
    _reorderCtrl.dispose();
    _priceCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDec({
    required String label,
    required IconData icon,
    String? hint,
    String? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        prefixText: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.navyPrimary.withValues(alpha: 0.4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ── Handle ─────────────────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tr('Add New Item', 'Ongeza Bidhaa Mpya'),
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.textMuted,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, color: AppColors.border),

              // ── Form ────────────────────────────────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24, 20, 24,
                      MediaQuery.viewInsetsOf(context).bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Basic info
                        _SectionLabel(_tr('Product Details', 'Maelezo ya Bidhaa')),
                        const SizedBox(height: 10),

                        // Name
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: _fieldDec(
                            label: _tr('Item name *', 'Jina la bidhaa *'),
                            icon: Icons.inventory_2_outlined,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? _tr('Name is required', 'Jina linahitajika')
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _fieldDec(
                            label: _tr(
                                'Description (optional)', 'Maelezo (hiari)'),
                            icon: Icons.notes_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Category — smart picker
                        _SectionLabel(
                            _tr('Category', 'Kategoria'),
                            subtitle: _tr(
                              'Loaded for your business type',
                              'Imepakiwa kwa aina yako ya biashara',
                            )),
                        const SizedBox(height: 10),
                        CategorySelectField(
                          selected: _selectedCategory,
                          onChanged: (cat) =>
                              setState(() => _selectedCategory = cat),
                        ),
                        const SizedBox(height: 20),

                        // Section: Stock
                        _SectionLabel(_tr('Stock & Pricing', 'Hisa na Bei')),
                        const SizedBox(height: 10),

                        // Stock + Reorder row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'))
                                ],
                                decoration: _fieldDec(
                                  label: _tr('Current stock *', 'Hisa sasa *'),
                                  icon: Icons.warehouse_rounded,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? _tr('Required', 'Inahitajika')
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _reorderCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'))
                                ],
                                decoration: _fieldDec(
                                  label: _tr('Reorder at *', 'Agiza upya *'),
                                  icon: Icons.low_priority_rounded,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? _tr('Required', 'Inahitajika')
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Price + Unit row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _priceCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'))
                                ],
                                decoration: _fieldDec(
                                  label: _tr('Unit price *', 'Bei ya kimoja *'),
                                  icon: Icons.payments_outlined,
                                  prefix: 'TZS ',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? _tr('Required', 'Inahitajika')
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _UnitDropdown(
                                value: _selectedUnit,
                                units: _units,
                                onChanged: (u) =>
                                    setState(() => _selectedUnit = u),
                                fieldDec: _fieldDec(
                                  label: _tr('Unit', 'Kitengo'),
                                  icon: Icons.straighten_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section: Optional fields
                        _SectionLabel(
                            _tr('Optional Details', 'Maelezo ya Ziada')),
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: _skuCtrl,
                          decoration: _fieldDec(
                            label: _tr('SKU / Barcode', 'SKU / Baa-kodi'),
                            icon: Icons.qr_code_rounded,
                            hint: _tr('e.g. ABC-001', 'mfano: ABC-001'),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _supplierCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: _fieldDec(
                            label:
                                _tr('Supplier name', 'Jina la muuzaji mkuu'),
                            icon: Icons.local_shipping_outlined,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.navyPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.navyPrimary,
                                    ),
                                  )
                                : Text(
                                    _tr('Add Item', 'Ongeza Bidhaa'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final inventoryRef = repo.scopeCollection(
        uid: user.uid,
        context: ctx,
        childCollection: 'inventory_items',
      );

      await inventoryRef.add({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        // Smart category — both legacy and structured fields
        'category': _selectedCategory?.categoryName ?? 'General',
        'categoryId': _selectedCategory?.id ?? '',
        'categoryName': _selectedCategory?.categoryName ?? '',
        'currentStock': double.tryParse(_stockCtrl.text) ?? 0,
        'reorderPoint': double.tryParse(_reorderCtrl.text) ?? 0,
        'unitPrice': double.tryParse(_priceCtrl.text) ?? 0,
        'unit': _selectedUnit,
        'sku': _skuCtrl.text.trim(),
        'supplier': _supplierCtrl.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                _tr('Item added!', 'Bidhaa imeongezwa!')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${_tr("Error", "Kosa")}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label helper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionLabel(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unit dropdown — extracted to avoid nested DropdownButtonFormField issues
// ─────────────────────────────────────────────────────────────────────────────

class _UnitDropdown extends StatelessWidget {
  final String value;
  final List<String> units;
  final ValueChanged<String> onChanged;
  final InputDecoration fieldDec;

  const _UnitDropdown({
    required this.value,
    required this.units,
    required this.onChanged,
    required this.fieldDec,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: fieldDec,
      isExpanded: true,
      items: units
          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
          .toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
