import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/page_intro_header.dart';
import '../../data/inventory_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemListProvider);

    return Scaffold(
      body: Column(
        children: [
          PageIntroHeader(
            title: _tr('Keep stock healthy', 'Dhibiti stoo iwe salama'),
            subtitle: _tr(
              'Catch low stock early and keep your products ready for every sale.',
              'Baini upungufu wa stoo mapema na weka bidhaa tayari kwa kila mauzo.',
            ),
            scene: EmotionalLottieScene.onboarding,
          ),
          Expanded(
            child: inventoryAsync.when(
              loading: () => const InventoryPageSkeleton(),
              error: (error, _) => Center(
                child: Text(
                  _tr(
                    'Unable to load inventory right now.',
                    'Imeshindikana kupakia stoo kwa sasa.',
                  ),
                ),
              ),
              data: (items) {
                final totalItems = items.length;
                final stockValue = items.fold<double>(0, (sum, item) {
                  final qty = parseStock(item['stock'] ?? item['quantity']);
                  final unitPrice = parseUnitPrice(
                    item['price'] ?? item['unitPrice'],
                  );
                  return sum + (qty * unitPrice);
                });
                final lowStock = items
                    .where(
                      (item) =>
                          parseStock(item['stock'] ?? item['quantity']) <= 5,
                    )
                    .toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryBox(
                              label: _tr('Total Items', 'Jumla ya Bidhaa'),
                              value: '$totalItems',
                              borderColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryBox(
                              label: _tr('Stock Value', 'Thamani ya Stoo'),
                              value: _fmtAmount(stockValue),
                              borderColor: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (lowStock.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: lowStock.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = lowStock[index];
                            final name =
                                (item['name'] ?? item['productName'] ?? 'Item')
                                    .toString();
                            final stock = parseStock(
                              item['stock'] ?? item['quantity'],
                            );
                            return _AlertCard(
                              title: '${_tr('Low Stock', 'Stoo Chini')}: $name',
                              subtitle:
                                  '${_tr('Only', 'Zimebaki')} $stock ${_tr('units', 'vipande')}',
                              color: AppColors.error,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Text(
                                _tr(
                                  'No inventory items yet.',
                                  'Bado hakuna bidhaa za stoo.',
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 1),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final name =
                                    (item['name'] ??
                                            item['productName'] ??
                                            'Item')
                                        .toString();
                                final sku =
                                    (item['sku'] ??
                                            item['code'] ??
                                            item['id'] ??
                                            '')
                                        .toString();
                                final stock = parseStock(
                                  item['stock'] ?? item['quantity'],
                                );
                                final price = parseUnitPrice(
                                  item['price'] ?? item['unitPrice'],
                                );
                                return _ProductListItem(
                                  name: name,
                                  sku: sku,
                                  price: _fmtAmount(price),
                                  stock: stock,
                                  unit: _tr('units', 'vipande'),
                                  isLow: stock <= 5,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtAmount(double amount) {
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color borderColor;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.borderColor,
  });

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

  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

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
        child: const Icon(
          Icons.inventory_2_outlined,
          color: AppColors.textMuted,
        ),
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
