import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../customer/data/customer_providers.dart';
import '../../data/inventory_providers.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _tr('Search by name, category or SKU...', 'Tafuta kwa jina, kategoria au SKU...'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
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
      useRootNavigator: true,
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _skuController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _reorderPointController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _supplierController = TextEditingController();
  String _selectedCategory = 'General';
  String _selectedUnit = 'pcs';
  bool _isLoading = false;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Food & Beverages',
    'Office Supplies',
    'Tools & Equipment',
    'Beauty & Personal Care',
    'Home & Garden',
    'Sports & Recreation',
    'Books & Media',
    'Toys & Games',
    'Health & Medical',
    'Automotive',
    'Other',
  ];

  final List<String> _units = [
    'pcs',
    'kg',
    'liters',
    'boxes',
    'bottles',
    'bags',
    'meters',
    'pairs',
    'sets',
    'dozens',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _currentStockController.dispose();
    _reorderPointController.dispose();
    _unitPriceController.dispose();
    _unitController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
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
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr('Add New Item', 'Ongeza Bidhaaa Mpya'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _tr('Item Name', 'Jina la Bidhaaa'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _tr(
                          'Please enter item name',
                          'Tafadhali weka jina la bidhaaa',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: _tr('Description', 'Maelezo'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: _tr('Category', 'Kundi'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _currentStockController,
                          decoration: InputDecoration(
                            labelText: _tr('Current Stock', 'Akiba ya Sasa'),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _tr('Required', 'Inahitajika');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _reorderPointController,
                          decoration: InputDecoration(
                            labelText: _tr('Reorder Point', 'Pointi ya Upya'),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _tr('Required', 'Inahitajika');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitPriceController,
                          decoration: InputDecoration(
                            labelText: _tr('Unit Price', 'Bei ya Kimoja'),
                            border: const OutlineInputBorder(),
                            prefixText: 'TZS ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _tr('Required', 'Inahitajika');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          decoration: InputDecoration(
                            labelText: _tr('Unit', 'Kimoja'),
                            border: const OutlineInputBorder(),
                          ),
                          items: _units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedUnit = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skuController,
                    decoration: InputDecoration(
                      labelText: _tr('SKU (Optional)', 'SKU (Hiari)'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _supplierController,
                    decoration: InputDecoration(
                      labelText: _tr('Supplier (Optional)', 'Mtoaji (Hiari)'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(_tr('Cancel', 'Ghairi')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addItem,
                          child: _isLoading
                              ? const ShimmerBox(
                                  width: 88,
                                  height: 14,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                )
                              : Text(_tr('Add Item', 'Ongeza Bidhaaa')),
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

  void _addItem() async {
    if (_formKey.currentState!.validate()) {
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
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'currentStock': double.tryParse(_currentStockController.text) ?? 0,
          'reorderPoint': double.tryParse(_reorderPointController.text) ?? 0,
          'unitPrice': double.tryParse(_unitPriceController.text) ?? 0,
          'unit': _selectedUnit,
          'sku': _skuController.text.trim(),
          'supplier': _supplierController.text.trim(),
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(_tr('Item added successfully', 'Bidhaaa imeongezwa kwa mafanikio')),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('${_tr("Error", "Kosa")}: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
