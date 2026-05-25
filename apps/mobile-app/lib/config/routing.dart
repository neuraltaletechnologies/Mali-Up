import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/returning_user_screen.dart';
import '../features/onboarding/presentation/screens/new_user_info_screen.dart';
import '../features/onboarding/presentation/screens/business_details_screen.dart';
import '../features/onboarding/presentation/screens/security_setup_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_success_screen.dart';
import '../features/onboarding/providers/onboarding_notifier.dart';
import '../features/onboarding/domain/models/onboarding_state.dart';
import '../shared/widgets/main_shell_page.dart';

// Deferred imports — loaded on first navigation to avoid bundling everything upfront.
import '../features/onboarding/presentation/screens/language_selection_screen.dart'
    deferred as screen_welcome;
import '../features/auth/presentation/screens/register_screen.dart'
    deferred as screen_phone;
import '../features/auth/presentation/screens/otp_verification_screen.dart'
    deferred as screen_otp;
import '../features/dashboard/presentation/screens/dashboard_screen.dart'
    deferred as screen_dashboard;
import '../features/settings/presentation/screens/settings_screen.dart'
    deferred as screen_settings;
import '../features/settings/presentation/screens/subscription_screen.dart'
    deferred as screen_subscription;
import '../features/business/presentation/screens/manage_businesses_screen.dart'
    deferred as screen_businesses;
import '../features/sales/presentation/screens/sales_screen.dart'
    deferred as screen_sales;
import '../features/inventory/presentation/screens/inventory_screen.dart'
    deferred as screen_inventory;
import '../features/customer/presentation/screens/customer_list_screen.dart'
    deferred as screen_customers;
import '../features/debt/presentation/screens/debt_tracking_screen.dart'
    deferred as screen_debt;
import '../features/finance/presentation/screens/expense_list_screen.dart'
    deferred as screen_expenses;
import '../features/finance/presentation/screens/cash_flow_screen.dart'
    deferred as screen_cashflow;
import '../features/team/presentation/screens/team_screen.dart'
    deferred as screen_team;

// ─── ROUTE PATHS ─────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  // ── Onboarding (7 screens) ────────────────────────────────────────────────
  static const splash      = '/splash';
  static const welcome     = '/welcome';     // Screen 1 — language picker
  static const phone       = '/phone';       // Screen 2 — phone entry
  static const otp         = '/otp';         // Screen 3 — OTP verify
  static const returning   = '/returning';   // Screen 4A — returning user
  static const newUser     = '/new-user';    // Screen 4B — new user info
  static const business    = '/business';    // Screen 5 — business details
  static const security    = '/security';    // Screen 6 — password + PIN
  static const success     = '/success';     // Screen 7 — success screen

  // ── Main app shell ────────────────────────────────────────────────────────
  static const dashboard   = '/';
  static const sales       = '/sales';
  static const inventory   = '/inventory';
  static const crm         = '/crm';
  static const debt        = '/debt';
  static const expenses    = '/expenses';
  static const cashflow    = '/cashflow';
  static const team        = '/team';
  static const settings    = '/settings';
  static const subscription = '/subscription';
  static const businesses  = '/businesses';
  static const login       = '/login';

  static const _onboardingPaths = {
    welcome, phone, otp, returning, newUser, business, security, success,
  };

  static bool isOnboardingPath(String path) => _onboardingPaths.contains(path);
}

// ─── ROUTER PROVIDER ─────────────────────────────────────────────────────────

/// Riverpod provider that owns the [GoRouter] instance.
///
/// The router observes [onboardingNotifierProvider] via [_RouterNotifier] so
/// that any state change (step advance, isComplete flip) triggers a redirect
/// re-evaluation without requiring a manual `context.go()`.
///
/// Usage in main.dart:
/// ```dart
/// final router = ref.watch(goRouterProvider);
/// return MaterialApp.router(routerConfig: router, ...);
/// ```
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: AppRoutes.splash,
    redirect: notifier._redirect,
    routes: _buildRoutes(),
  );
});

// ─── ROUTER NOTIFIER (ChangeNotifier bridge) ──────────────────────────────────

/// Listens to [onboardingNotifierProvider] and calls [notifyListeners] so
/// GoRouter re-runs its redirect function whenever onboarding state changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Any mutation of OnboardingState will trigger a redirect re-check.
    _ref.listen(onboardingNotifierProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;

  /// GoRouter calls this before rendering every route.
  ///
  /// Guard rules (evaluated top-to-bottom — first matching rule wins):
  ///
  /// 1. Splash screen is always accessible.
  /// 2. If onboarding is complete and the path is an onboarding path → dashboard.
  /// 3. If onboarding is NOT complete and the path is a shell path → welcome.
  /// 4. Per-step guards prevent skipping ahead (e.g. OTP without a verificationId).
  String? _redirect(BuildContext context, GoRouterState routerState) {
    final path = routerState.uri.path;
    final ob = _ref.read(onboardingNotifierProvider);

    // Splash is always allowed — it runs the completion check itself.
    if (path == AppRoutes.splash) return null;

    // ── Post-completion guards ────────────────────────────────────────────
    if (ob.isComplete) {
      // Allow the success screen as the post-completion landing page.
      if (path == AppRoutes.success) return null;
      // Block any other onboarding screen once the flow is done.
      if (AppRoutes.isOnboardingPath(path)) return AppRoutes.dashboard;
      return null; // allow dashboard + shell routes
    }

    // ── Pre-completion: block shell routes until onboarding is done ───────
    if (!AppRoutes.isOnboardingPath(path) && path != AppRoutes.login) {
      return AppRoutes.welcome;
    }

    // ── Step-by-step guards ───────────────────────────────────────────────

    // Screen 3 requires a verificationId (sendOtp must have succeeded).
    if (path == AppRoutes.otp && ob.verificationId.isEmpty) {
      return AppRoutes.phone;
    }

    // Screens 4A and 4B require OTP to have been verified
    // (verificationId set AND currentStep past otpVerify).
    if ((path == AppRoutes.returning || path == AppRoutes.newUser) &&
        ob.currentStep.stepIndex < OnboardingStep.returningUser.stepIndex) {
      return AppRoutes.otp;
    }

    // Screen 4A is only reachable for returning users.
    if (path == AppRoutes.returning && !ob.isReturningUser) {
      return AppRoutes.newUser;
    }

    // Screen 4B is only reachable for new users.
    if (path == AppRoutes.newUser && ob.isReturningUser) {
      return AppRoutes.returning;
    }

    // Screen 5 requires personal info to be entered (or returning-user path).
    if (path == AppRoutes.business) {
      final hasPersonal = ob.firstName.isNotEmpty || ob.isReturningUser;
      if (!hasPersonal) {
        return ob.isReturningUser ? AppRoutes.returning : AppRoutes.newUser;
      }
    }

    // Screen 6 requires a businessName.
    if (path == AppRoutes.security && ob.businessName.isEmpty) {
      return AppRoutes.business;
    }

    // Screen 7 only reachable after saveAndComplete() sets isComplete.
    if (path == AppRoutes.success && !ob.isComplete) {
      return AppRoutes.welcome;
    }

    return null; // no redirect — render the requested route
  }
}

// ─── ROUTE DEFINITIONS ────────────────────────────────────────────────────────

List<RouteBase> _buildRoutes() {
  return [
    // ── Splash ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(
          showLanguageSelection: true,
          showOnboarding: true,
        ),
      ),
    ),

    // ── Screen 1 — Welcome + Language ────────────────────────────────────────
    GoRoute(
      path: AppRoutes.welcome,
      pageBuilder: (context, state) => _authPage(
        state,
        _deferred(
          load: screen_welcome.loadLibrary,
          build: () => screen_welcome.LanguageSelectionScreen(
            onLanguageSelected: () => context.go(AppRoutes.phone),
          ),
        ),
      ),
    ),

    // ── Screen 2 — Phone Entry ───────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.phone,
      pageBuilder: (context, state) => _authPage(
        state,
        _deferred(
          load: screen_phone.loadLibrary,
          build: () => screen_phone.RegisterScreen(fromOnboarding: true),
        ),
      ),
    ),

    // ── Screen 3 — OTP Verification ──────────────────────────────────────────
    GoRoute(
      path: AppRoutes.otp,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _authPage(
          state,
          _deferred(
            load: screen_otp.loadLibrary,
            build: () => screen_otp.OTPVerificationScreen(
              phoneNumber: extra?['phoneNumber'] as String? ?? '',
              isRegistration: extra?['isRegistration'] as bool? ?? true,
              userData: extra?['userData'] as Map<String, dynamic>?,
            ),
          ),
        );
      },
    ),

    // ── Screen 4A — Returning User ───────────────────────────────────────────
    GoRoute(
      path: AppRoutes.returning,
      pageBuilder: (context, state) => _authPage(
        state,
        const ReturningUserScreen(),
      ),
    ),

    // ── Screen 4B — New User Personal Info ───────────────────────────────────
    GoRoute(
      path: AppRoutes.newUser,
      pageBuilder: (context, state) => _authPage(
        state,
        const NewUserInfoScreen(),
      ),
    ),

    // ── Screen 5 — Business Details ──────────────────────────────────────────
    GoRoute(
      path: AppRoutes.business,
      pageBuilder: (context, state) => _authPage(
        state,
        const BusinessDetailsScreen(),
      ),
    ),

    // ── Screen 6 — Password + PIN ────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.security,
      pageBuilder: (context, state) => _authPage(
        state,
        const SecuritySetupScreen(),
      ),
    ),

    // ── Screen 7 — Success ───────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.success,
      pageBuilder: (context, state) => _authPage(
        state,
        const OnboardingSuccessScreen(),
      ),
    ),

    // ── Login (standalone, bypasses onboarding guard) ────────────────────────
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _authPage(
          state,
          LoginScreen(initialPhone: extra?['phone'] as String?),
        );
      },
    ),

    // ── Main app shell ────────────────────────────────────────────────────────
    ShellRoute(
      pageBuilder: (context, state, child) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: MainShellPage(child: child),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => _deferred(
            load: screen_dashboard.loadLibrary,
            build: () => screen_dashboard.DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.sales,
          builder: (context, state) => _deferred(
            load: screen_sales.loadLibrary,
            build: () => screen_sales.SalesScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.inventory,
          builder: (context, state) => _deferred(
            load: screen_inventory.loadLibrary,
            build: () => screen_inventory.InventoryScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.crm,
          builder: (context, state) => _deferred(
            load: screen_customers.loadLibrary,
            build: () => screen_customers.CustomerListScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.debt,
          builder: (context, state) => _deferred(
            load: screen_debt.loadLibrary,
            build: () => screen_debt.DebtTrackingScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.expenses,
          builder: (context, state) => _deferred(
            load: screen_expenses.loadLibrary,
            build: () => screen_expenses.ExpenseListScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.cashflow,
          builder: (context, state) => _deferred(
            load: screen_cashflow.loadLibrary,
            build: () => screen_cashflow.CashFlowScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => _deferred(
            load: screen_settings.loadLibrary,
            build: () => screen_settings.SettingsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.subscription,
          builder: (context, state) => _deferred(
            load: screen_subscription.loadLibrary,
            build: () => screen_subscription.SubscriptionScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.businesses,
          builder: (context, state) => _deferred(
            load: screen_businesses.loadLibrary,
            build: () => screen_businesses.ManageBusinessesScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.team,
          builder: (context, state) => _deferred(
            load: screen_team.loadLibrary,
            build: () => screen_team.TeamScreen(),
          ),
        ),
      ],
    ),
  ];
}

// ─── TRANSITION HELPERS ───────────────────────────────────────────────────────

/// Slide-fade transition used for all onboarding + auth screens.
CustomTransitionPage<void> _authPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Wraps a deferred library in a [FutureBuilder] so the screen renders once
/// its library chunk has loaded. Shows an empty [Scaffold] while loading.
Widget _deferred({
  required Future<void> Function() load,
  required Widget Function() build,
}) {
  return FutureBuilder<void>(
    future: load(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.done) return build();
      return const Scaffold(); // blank frame while chunk loads
    },
  );
}

// ─── BACKWARD-COMPAT FACTORY ─────────────────────────────────────────────────

/// Legacy factory kept so existing [main.dart] callers don't break.
/// Migrate main.dart to use [goRouterProvider] via Riverpod instead.
///
/// ```dart
/// // OLD (main.dart)
/// router: AppRouter.createRouter(showLanguageSelection: ..., showOnboarding: ...)
///
/// // NEW (main.dart)
/// final router = ref.watch(goRouterProvider);
/// ```
@Deprecated('Use goRouterProvider instead')
class AppRouter {
  static const splashPath      = AppRoutes.splash;
  static const dashboardPath   = AppRoutes.dashboard;
  static const loginPath       = AppRoutes.login;
  static const welcomePath     = AppRoutes.welcome;
  static const phonePath       = AppRoutes.phone;
  static const otpPath         = AppRoutes.otp;
  static const returningPath   = AppRoutes.returning;
  static const newUserPath     = AppRoutes.newUser;
  static const businessPath    = AppRoutes.business;
  static const securityPath    = AppRoutes.security;
  static const successPath     = AppRoutes.success;

  // Keep old path names alive for any existing code that references them.
  static const languageSelectionPath = AppRoutes.welcome;
  static const onboardingPath        = AppRoutes.welcome;
  static const registerPath          = AppRoutes.phone;
  static const salesPath             = AppRoutes.sales;
  static const inventoryPath         = AppRoutes.inventory;
  static const crmPath               = AppRoutes.crm;
  static const debtPath              = AppRoutes.debt;
  static const expensesPath          = AppRoutes.expenses;
  static const cashFlowPath          = AppRoutes.cashflow;
  static const teamPath              = AppRoutes.team;
  static const settingsPath          = AppRoutes.settings;
  static const subscriptionPath      = AppRoutes.subscription;
  static const businessesPath        = AppRoutes.businesses;

  static GoRouter createRouter({
    required bool showLanguageSelection,
    required bool showOnboarding,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      routes: _buildRoutes(),
    );
  }
}
