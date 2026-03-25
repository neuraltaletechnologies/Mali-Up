import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/finance_providers.dart';

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(cashAccountListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow'),
        actions: [
          IconButton(icon: const Icon(Icons.account_balance_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accounts Horizontal Scroll
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text('My Accounts', style: TextStyle(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: accounts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return _AccountCard(account: account);
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Inflow/Outflow Comparison Board
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  children: [
                    const Text('Monthly Flow Summary', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _FlowStat(label: 'Inflow', value: '4.8M', color: AppColors.success, icon: Icons.south_west_rounded),
                        Container(width: 1, height: 40, color: AppColors.glassBorder),
                        _FlowStat(label: 'Outflow', value: '1.2M', color: AppColors.error, icon: Icons.north_east_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Recent Money Movements
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Money Movements', style: TextStyle(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _MovementListItem(index: index);
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.swap_horiz_rounded, color: AppColors.secondary),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final dynamic account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary.withOpacity(0.05)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, const Color(0xFF334155).withOpacity(0.4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                child: Icon(
                  account.type == 'Cash' ? Icons.payments_outlined : (account.type == 'Bank' ? Icons.account_balance_outlined : Icons.smartphone_outlined),
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const Text('TZS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(account.balance, style: const TextStyle(color: AppColors.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(account.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FlowStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _FlowStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MovementListItem extends StatelessWidget {
  final int index;
  const _MovementListItem({required this.index});

  @override
  Widget build(BuildContext context) {
    bool isInflow = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isInflow ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color: isInflow ? AppColors.success : AppColors.error,
        ),
        title: Text(isInflow ? 'Deposit: Cash Sale' : 'Withdraw: Petty Cash', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: const Text('To Business M-Pesa • Today, 2:30 PM', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: Text(isInflow ? '+45,000' : '-12,000', style: TextStyle(color: isInflow ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
