import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../config/routing.dart';

class MainShellPage extends StatelessWidget {
  final Widget child;
  const MainShellPage({super.key, required this.child});

  static int _calculateIndex(String location) {
    if (location.startsWith(AppRouter.salesPath)) return 1;
    if (location.startsWith(AppRouter.inventoryPath)) return 2;
    if (location.startsWith(AppRouter.settingsPath)) return 3;
    return 0; // Dashboard
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _calculateIndex(location);

    return Scaffold(
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
                context.go(AppRouter.settingsPath);
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
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
