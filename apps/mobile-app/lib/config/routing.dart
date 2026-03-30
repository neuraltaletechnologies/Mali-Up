import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_flow.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../shared/widgets/main_shell_page.dart';
import '../features/sales/presentation/screens/sales_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/customer/presentation/screens/customer_list_screen.dart';
import '../features/debt/presentation/screens/debt_tracking_screen.dart';
import '../features/finance/presentation/screens/expense_list_screen.dart';
import '../features/finance/presentation/screens/cash_flow_screen.dart';

class AppRouter {
  static const String onboardingPath = '/onboarding';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String dashboardPath = '/';
  static const String salesPath = '/sales';
  static const String inventoryPath = '/inventory';
  static const String crmPath = '/crm';
  static const String debtPath = '/debt';
  static const String expensesPath = '/expenses';
  static const String cashFlowPath = '/cashflow';
  static const String settingsPath = '/settings';

  static GoRouter createRouter({required bool showOnboarding}) {
    return GoRouter(
      initialLocation: showOnboarding ? onboardingPath : loginPath,
      routes: [
      GoRoute(
        path: onboardingPath,
        builder: (context, state) => OnboardingFlow(
          onComplete: () => context.go(loginPath),
        ),
      ),
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: registerPath,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellPage(child: child),
        routes: [
          GoRoute(
            path: dashboardPath,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: salesPath,
            builder: (context, state) => const SalesScreen(),
          ),
          GoRoute(
            path: inventoryPath,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: crmPath,
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: debtPath,
            builder: (context, state) => const DebtTrackingScreen(),
          ),
          GoRoute(
            path: expensesPath,
            builder: (context, state) => const ExpenseListScreen(),
          ),
          GoRoute(
            path: cashFlowPath,
            builder: (context, state) => const CashFlowScreen(),
          ),
          GoRoute(
            path: settingsPath,
            builder: (context, state) => const Scaffold(body: Center(child: Text('Settings'))),
          ),
        ],
      ),
    ],
    );
  }
}
