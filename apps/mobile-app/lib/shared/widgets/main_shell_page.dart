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

  static String _pageTitle(String location) {
    if (location.startsWith(AppRouter.salesPath)) return 'Sales & Invoices';
    if (location.startsWith(AppRouter.inventoryPath)) return 'Inventory';
    if (location.startsWith(AppRouter.crmPath)) return 'Customers';
    if (location.startsWith(AppRouter.debtPath)) return 'Debt & Payables';
    if (location.startsWith(AppRouter.expensesPath)) return 'Expenses';
    if (location.startsWith(AppRouter.cashFlowPath)) return 'Cash Flow';
    if (location.startsWith(AppRouter.settingsPath)) return 'Settings';
    return 'Dashboard';
  }

  static bool _isSelected(String location, String route) {
    return location == route || location.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _calculateIndex(location);
    final title = _pageTitle(location);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const MaliUpLogo(size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go(AppRouter.settingsPath),
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
              icon: Icons.grid_view_rounded,
              label: 'Dashboard',
              selected: _isSelected(location, AppRouter.dashboardPath),
              onTap: () {
                context.pop();
                context.go(AppRouter.dashboardPath);
              },
            ),
            _DrawerItem(
              icon: Icons.receipt_rounded,
              label: 'Sales & Invoices',
              selected: _isSelected(location, AppRouter.salesPath),
              onTap: () {
                context.pop();
                context.go(AppRouter.salesPath);
              },
            ),
            _DrawerItem(
              icon: Icons.inventory_2_rounded,
              label: 'Inventory',
              selected: _isSelected(location, AppRouter.inventoryPath),
              onTap: () {
                context.pop();
                context.go(AppRouter.inventoryPath);
              },
            ),
            _DrawerItem(
              icon: Icons.people_rounded,
              label: 'Customers',
              selected: _isSelected(location, AppRouter.crmPath),
              onTap: () {
                context.pop();
                context.go(AppRouter.crmPath);
              },
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),
            _DrawerItem(
              icon: Icons.account_balance_rounded,
              label: 'Debt Tracking',
              selected: _isSelected(location, AppRouter.debtPath),
              onTap: () {
                context.pop();
                context.go(AppRouter.debtPath);
              },
            ),
            _DrawerItem(
              icon: Icons.payments_outlined,
              label: 'Expense Management',
              selected: _isSelected(location, AppRouter.expensesPath),
              onTap: () {
                context.pop();
                context.go(AppRouter.expensesPath);
              },
            ),
            _DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cash Flow & Accounts',
              selected: _isSelected(location, AppRouter.cashFlowPath),
              onTap: () {
                context.pop();
                context.go(AppRouter.cashFlowPath);
              },
            ),
            const Divider(height: 32, indent: 16, endIndent: 16),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Business Settings',
              selected: _isSelected(location, AppRouter.settingsPath),
              onTap: () {
                context.pop();
                context.go(AppRouter.settingsPath);
              },
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
            top: BorderSide(color: AppColors.secondary.withValues(alpha: 0.08), width: 1.5),
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
  final bool selected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.textPrimary;
    final highlightColor = color ?? AppColors.primary;

    return ListTile(
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: selected ? highlightColor : baseColor),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? highlightColor : baseColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
      ),
      onTap: onTap,
    );
  }
}

