import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../shared/widgets/main_shell_page.dart';

class AppRouter {
  static const String loginPath = '/login';
  static const String dashboardPath = '/';
  static const String salesPath = '/sales';
  static const String inventoryPath = '/inventory';
  static const String settingsPath = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: loginPath,
    routes: [
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginScreen(),
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
            builder: (context, state) => const Scaffold(body: Center(child: Text('Sales'))),
          ),
          GoRoute(
            path: inventoryPath,
            builder: (context, state) => const Scaffold(body: Center(child: Text('Inventory'))),
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
