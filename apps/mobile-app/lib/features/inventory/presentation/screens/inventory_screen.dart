import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/page_intro_header.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const PageIntroHeader(
            title: 'Keep stock healthy',
            subtitle: 'Catch low stock early and keep your products ready for every sale.',
            scene: EmotionalLottieScene.onboarding,
          ),

          // Inventory Stats Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryBox(
                    label: 'Total Items',
                    value: '142',
                    borderColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryBox(
                    label: 'Stock Value',
                    value: 'TSh 12.8M',
                    borderColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Low Stock Alert Banner (Horizontal Scrollable)
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _AlertCard(
                  title: 'Low Stock: Coca-Cola 500ml',
                  subtitle: 'Only 5 units left',
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                _AlertCard(
                  title: 'Expiring Soon: Milk 1L',
                  subtitle: '24 units • 3 days left',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Search & Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(Icons.category_outlined, color: AppColors.secondary),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Product List Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Products Portfolio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Stock Level',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Products List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: 15,
              separatorBuilder: (context, index) => const SizedBox(height: 1),
              itemBuilder: (context, index) {
                return _ProductListItem(
                  name: index % 2 == 0 ? 'Samsung Galaxy S23' : 'iPhone 15 Pro Max',
                  sku: 'ELEC-GAD-${200 + index}',
                  price: 'TSh ${1200000 + (index * 50000)}',
                  stock: 10 + index,
                  unit: 'units',
                  isLow: index < 2,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondary),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color borderColor;

  const _SummaryBox({required this.label, required this.value, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.secondary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _AlertCard({required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 11,
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

class _ProductListItem extends StatelessWidget {
  final String name;
  final String sku;
  final String price;
  final int stock;
  final String unit;
  final bool isLow;

  const _ProductListItem({
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.unit,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
      ),
      title: Text(
        name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        sku,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$stock $unit', 
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isLow ? AppColors.error : AppColors.success, 
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Text(
            price,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
