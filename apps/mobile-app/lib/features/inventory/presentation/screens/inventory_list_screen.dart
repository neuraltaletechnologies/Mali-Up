import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../data/inventory_provider.dart';
import '../../domain/models/inventory_item.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// Provider declaration
final inventoryProvider = ChangeNotifierProvider<InventoryProvider>((ref) {
  return InventoryProvider();
});

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryNotifier = ref.watch(inventoryProvider);
    final items = inventoryNotifier.items;
    final isLoading = inventoryNotifier.isLoading;
    final error = inventoryNotifier.error;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('Manage your inventory efficiently', 'Dhibiti akiba yako kwa ufanisi'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tr(
                          'Track stock levels, get alerts for low items, and manage reordering.',
                          'Fuatilia viwango vya akiba, pata tahadhari kwa bidhaa chache, na dhibiti upya upatikaji.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const EmotionalLottieSpot(
                  scene: EmotionalLottieScene.dashboard,
                  size: 62,
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _tr('Inventory Summary', 'Muhtasari wa Akiba'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryStat(
                      label: _tr('Total Items', 'Jumla ya Bidhaa'),
                      value: '${items.length}',
                      icon: Icons.inventory_2_outlined,
                    ),
                    _SummaryStat(
                      label: _tr('Low Stock', 'Akiba Ndogo'),
                      value: '${inventoryNotifier.getLowStockItems().length}',
                      icon: Icons.warning_amber_outlined,
                      color: Colors.orange,
                    ),
                    _SummaryStat(
                      label: _tr('Out of Stock', 'Imekuwa Hakuna'),
                      value: '${inventoryNotifier.getOutOfStockItems().length}',
                      icon: Icons.error_outline_outlined,
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: _buildInventoryList(items, isLoading, error, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.secondary),
        label: Text(
          _tr('Add Item', 'Ongeza Bidhaa'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryList(List<InventoryItem> items, bool isLoading, String? error, WidgetRef ref) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _tr('Error loading inventory', 'Hitilafu ya kupakia akiba'),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _tr('No inventory items', 'Hakuna bidhaa za akiba'),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _tr('Add your first inventory item to get started', 'Ongeza bidhaa yako ya kwanza ya akiba kuanza'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddItemDialog(context),
              child: const Text('Add Item'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
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
    showDialog(
      context: context,
      builder: (context) => const AddItemDialog(),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? AppColors.primary;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: defaultColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: defaultColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStockColor(item.stockStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: _getStockColor(item.stockStatus),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (item.sku.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item.sku}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.currentStock} ${item.unit}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _getStockColor(item.stockStatus),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'TZS ${item.unitPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getStockColor(item.stockStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStockColor(item.stockStatus).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  item.stockStatus,
                  style: TextStyle(
                    color: _getStockColor(item.stockStatus),
                    fontSize: 10,
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
        return Colors.red;
      case 'Low Stock':
        return Colors.orange;
      default:
        return Colors.green;
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
    return AlertDialog(
      title: Text(
        _tr('Add New Item', 'Ongeza Bidhaa Mpya'),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _tr('Item Name', 'Jina la Bidhaa'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _tr('Please enter item name', 'Tafadhali weka jina la bidhaa');
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
                  value: _selectedCategory,
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
                        value: _selectedUnit,
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(_tr('Cancel', 'Ghairi')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addItem,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_tr('Add Item', 'Ongeza Bidhaa')),
        ),
      ],
    );
  }

  void _addItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final success = await ref.read(inventoryProvider.notifier).addInventoryItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          currentStock: double.parse(_currentStockController.text.trim()),
          reorderPoint: double.parse(_reorderPointController.text.trim()),
          unitPrice: double.parse(_unitPriceController.text.trim()),
          unit: _selectedUnit,
          sku: _skuController.text.trim(),
          supplier: _supplierController.text.trim(),
        );

        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_tr('Item added successfully', 'Bidhaa imeongezwa kwa mafanikio')),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_tr('Failed to add item', 'Imeshindikana kuongeza bidhaa')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
