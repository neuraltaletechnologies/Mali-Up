import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../config/routing.dart';
import 'logo.dart';


class MainShellPage extends StatelessWidget {
  final Widget child;
  const MainShellPage({super.key, required this.child});

  static int _calculateIndex(String location) {
    if (location.startsWith(AppRouter.salesPath)) return 1;
    if (location.startsWith(AppRouter.inventoryPath)) return 2;
    if (location.startsWith(AppRouter.crmPath)) return 3;
    return 0; // Dashboard
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _calculateIndex(location);

    return Scaffold(
      appBar: currentIndex != 0 ? null : AppBar(
        title: const MaliUpLogo(size: 32), // Uses Mali Up Wordmark
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Center(child: MaliUpLogo(size: 40)),
            ),
            _DrawerItem(
              icon: Icons.account_balance_rounded,
              label: 'Debt Tracking',
              onTap: () {
                context.pop();
                context.push(AppRouter.debtPath);
              },
            ),
            _DrawerItem(
              icon: Icons.payments_outlined,
              label: 'Expense Management',
              onTap: () {
                context.pop();
                context.push(AppRouter.expensesPath);
              },
            ),
            _DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cash Flow & Accounts',
              onTap: () {
                context.pop();
                context.push(AppRouter.cashFlowPath);
              },
            ),
            _DrawerItem(
              icon: Icons.bar_chart_rounded,
              label: 'Financial Reports',
              onTap: () {},
            ),
            const Divider(height: 32, indent: 16, endIndent: 16),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Business Settings',
              onTap: () {},
            ),

            const Spacer(),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              onTap: () => context.go(AppRouter.loginPath),
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.secondary.withOpacity(0.08), width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0: context.go(AppRouter.dashboardPath); break;
              case 1: context.go(AppRouter.salesPath); break;
              case 2: context.go(AppRouter.inventoryPath); break;
              case 3: context.go(AppRouter.crmPath); break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_outlined),
              activeIcon: Icon(Icons.receipt_rounded),
              label: 'Sales',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Stock',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Customers',
            ),
          ],
        ),
      ),
    );
  }
}


class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(label, style: TextStyle(color: color ?? AppColors.textPrimary)),
      onTap: onTap,
    );
  }
}

