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
      appBar: currentIndex != 0 ? null : AppBar( // Show AppBar in Shell only for items that don't have their own internal ones, or just use internal ones.
         title: const Text('MALIAPP'),
         leading: Builder(
           builder: (context) => IconButton(
             icon: const Icon(Icons.menu),
             onPressed: () => Scaffold.of(context).openDrawer(),
           ),
         ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.surface),
              child: Center(child: MaliappLogo(size: 60)),
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
              onTap: () {},
            ),
            _DrawerItem(
              icon: Icons.bar_chart_rounded,
              label: 'Financial Reports',
              onTap: () {},
            ),
            const Spacer(),
            const Divider(color: AppColors.glassBorder),
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
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go(AppRouter.dashboardPath);
                break;
              case 1:
                context.go(AppRouter.salesPath);
                break;
              case 2:
                context.go(AppRouter.inventoryPath);
                break;
              case 3:
                context.go(AppRouter.crmPath);
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_outlined),
              activeIcon: Icon(Icons.receipt_rounded),
              label: 'Sales',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people_rounded),
              label: 'CRM',
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

