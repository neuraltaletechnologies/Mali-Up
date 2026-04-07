import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_flow.dart';
import '../features/onboarding/presentation/screens/language_selection_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../shared/widgets/main_shell_page.dart';
import '../features/sales/presentation/screens/sales_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/customer/presentation/screens/customer_list_screen.dart';
import '../features/debt/presentation/screens/debt_tracking_screen.dart';
import '../features/finance/presentation/screens/expense_list_screen.dart';
import '../features/finance/presentation/screens/cash_flow_screen.dart';

class AppRouter {
  static const String languageSelectionPath = '/language-selection';
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

  static GoRouter createRouter({
    required bool showLanguageSelection,
    required bool showOnboarding,
    required bool hasActiveSession,
  }) {
    return GoRouter(
      initialLocation: hasActiveSession
          ? dashboardPath
          : showLanguageSelection
          ? languageSelectionPath
          : showOnboarding
              ? onboardingPath
              : loginPath,
      routes: [
        GoRoute(
          path: languageSelectionPath,
          builder: (context, state) => LanguageSelectionScreen(
            onLanguageSelected: () => context.go(onboardingPath),
          ),
        ),
        GoRoute(
          path: onboardingPath,
          builder: (context, state) => OnboardingFlow(
            onComplete: () => context.go(
              registerPath,
              extra: {'fromOnboarding': true},
            ),
          ),
        ),
        GoRoute(
          path: loginPath,
          pageBuilder: (context, state) {
            final extra = state.extra;
            if (extra is Map<String, dynamic>) {
              return _buildAuthTransitionPage(
                state,
                LoginScreen(
                  initialPhone: extra['phone'] as String?,
                  autoSendOtp: extra['autoSendOtp'] as bool? ?? false,
                ),
              );
            }
            return _buildAuthTransitionPage(state, const LoginScreen());
          },
        ),
        GoRoute(
          path: registerPath,
          pageBuilder: (context, state) {
            final extra = state.extra;
            final screen = (extra is Map<String, dynamic>)
                ? RegisterScreen(
                    initialFullName: extra['fullName'] as String?,
                    initialPhone: extra['phone'] as String?,
                    initialEmail: extra['email'] as String?,
                    fromOnboarding: extra['fromOnboarding'] as bool? ?? false,
                  )
                : const RegisterScreen();

            return _buildAuthTransitionPage(state, screen);
          },
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
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }

  static CustomTransitionPage<void> _buildAuthTransitionPage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
        final slide = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curved);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
    );
  }
}
