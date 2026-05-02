import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/customer_providers.dart';
import '../widgets/add_customer_dialog.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

String _fmtCustomerBalance(double amount) {
  if (amount >= 1_000_000)
    return 'TSh ${(amount / 1_000_000).toStringAsFixed(1)}M';
  if (amount >= 1_000) return 'TSh ${(amount / 1_000).toStringAsFixed(0)}K';
  return 'TSh ${amount.toStringAsFixed(0)}';
}

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customers = ref.watch(customerListProvider);
    final customerItems = customers.maybeWhen(
      data: (items) => items,
      orElse: () => const [],
    );
    final totalBalance = customerItems.fold<double>(
      0,
      (sum, c) => sum + (double.tryParse(c.balance) ?? 0),
    );

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Active Customers', 'Wateja Hai'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CRM Summary Header - Compact card style
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
                  label: _tr('Clients', 'Wateja'),
                  value: '${customerItems.length}',
                  icon: Icons.people_alt_outlined,
                ),
                Container(width: 1, height: 20, color: AppColors.border),
                _CompactStat(
                  label: _tr('Balance', 'Salio'),
                  value: _fmtBalance(totalBalance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: customerItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final customer = customerItems[index];
                return _CustomerCard(customer: customer);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.person_add_alt_1_rounded,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  static String _fmtBalance(double amount) {
    if (amount >= 1_000_000) {
      return 'TSh ${(amount / 1_000_000).toStringAsFixed(1)}M';
    }
    if (amount >= 1_000) {
      return 'TSh ${(amount / 1_000).toStringAsFixed(0)}K';
    }
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCustomerDialog(),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
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


class _CustomerCard extends StatelessWidget {
  final dynamic customer; // Type to be specific in real use
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawBalance = double.tryParse(customer.balance) ?? 0;
    final hasBalance = rawBalance > 0;

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
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  customer.name[0],
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(customer.phone, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _tr('Outstanding Balance', 'Salio Linalodaiwa'),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtCustomerBalance(rawBalance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: hasBalance ? AppColors.error : AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: customer.tags
                    .map<Widget>(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              Text(
                '${_tr('Last Tx', 'Muamala wa Mwisho')}: ${customer.lastTransactionDate}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
