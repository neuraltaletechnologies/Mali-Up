import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_flow.dart' deferred as onboarding_flow;
import '../features/onboarding/presentation/screens/language_selection_screen.dart' deferred as language_selection;
import '../features/dashboard/presentation/screens/dashboard_screen.dart' deferred as dashboard_screen;
import '../features/settings/presentation/screens/settings_screen.dart' deferred as settings_screen;
import '../features/business/presentation/screens/manage_businesses_screen.dart' deferred as manage_businesses_screen;
import '../shared/widgets/main_shell_page.dart';
import '../features/sales/presentation/screens/sales_screen.dart' deferred as sales_screen;
import '../features/inventory/presentation/screens/inventory_screen.dart' deferred as inventory_screen;
import '../features/customer/presentation/screens/customer_list_screen.dart' deferred as customer_screen;
import '../features/debt/presentation/screens/debt_tracking_screen.dart' deferred as debt_screen;
import '../features/finance/presentation/screens/expense_list_screen.dart' deferred as expense_screen;
import '../features/finance/presentation/screens/cash_flow_screen.dart' deferred as cashflow_screen;

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
  static const String businessesPath = '/businesses';

  static GoRouter createRouter({
    required bool showLanguageSelection,
    required bool showOnboarding,
    required bool hasActiveSession,
    String? authenticatedInitialPath,
  }) {
    return GoRouter(
      initialLocation: hasActiveSession
          ? (authenticatedInitialPath ?? dashboardPath)
          : showLanguageSelection
          ? languageSelectionPath
          : showOnboarding
              ? onboardingPath
              : loginPath,
      routes: [
        GoRoute(
          path: languageSelectionPath,
          builder: (context, state) => _buildDeferredRoute(
            loadLibrary: language_selection.loadLibrary,
            builder: () => language_selection.LanguageSelectionScreen(
              onLanguageSelected: () => context.go(onboardingPath),
            ),
          ),
        ),
        GoRoute(
          path: onboardingPath,
          builder: (context, state) => _buildDeferredRoute(
            loadLibrary: onboarding_flow.loadLibrary,
            builder: () => onboarding_flow.OnboardingFlow(
              onComplete: () => context.go(
                registerPath,
                extra: {'fromOnboarding': true},
              ),
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
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: dashboard_screen.loadLibrary,
                builder: () => dashboard_screen.DashboardScreen(),
              ),
            ),
            GoRoute(
              path: salesPath,
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: sales_screen.loadLibrary,
                builder: () => sales_screen.SalesScreen(),
              ),
            ),
            GoRoute(
              path: inventoryPath,
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: inventory_screen.loadLibrary,
                builder: () => inventory_screen.InventoryScreen(),
              ),
            ),
            GoRoute(
              path: crmPath,
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: customer_screen.loadLibrary,
                builder: () => customer_screen.CustomerListScreen(),
              ),
            ),
            GoRoute(
              path: debtPath,
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: debt_screen.loadLibrary,
                builder: () => debt_screen.DebtTrackingScreen(),
              ),
            ),
            GoRoute(
              path: expensesPath,
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: expense_screen.loadLibrary,
                builder: () => expense_screen.ExpenseListScreen(),
              ),
            ),
            GoRoute(
              path: cashFlowPath,
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: cashflow_screen.loadLibrary,
                builder: () => cashflow_screen.CashFlowScreen(),
              ),
            ),
            GoRoute(
              path: settingsPath,
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: settings_screen.loadLibrary,
                builder: () => settings_screen.SettingsScreen(),
              ),
            ),
            GoRoute(
              path: businessesPath,
              builder: (context, state) => _buildDeferredRoute(
                loadLibrary: manage_businesses_screen.loadLibrary,
                builder: () => manage_businesses_screen.ManageBusinessesScreen(),
              ),
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

  static Widget _buildDeferredRoute({
    required Future<void> Function() loadLibrary,
    required Widget Function() builder,
  }) {
    return FutureBuilder<void>(
      future: loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
