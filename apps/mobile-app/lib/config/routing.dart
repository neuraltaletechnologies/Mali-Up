import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/providers/auth_provider.dart' show authStateProvider;
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/intro_slides_screen.dart';
import '../features/onboarding/presentation/screens/phone_entry_screen.dart';
import '../features/onboarding/presentation/screens/pin_login_screen.dart';
import '../features/onboarding/presentation/screens/team_member_setup_screen.dart';
import '../features/onboarding/presentation/screens/new_user_info_screen.dart';
import '../features/onboarding/presentation/screens/pin_reset_screen.dart';
import '../features/onboarding/presentation/screens/business_details_screen.dart';
import '../features/onboarding/presentation/screens/security_setup_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_success_screen.dart';
import '../features/onboarding/providers/onboarding_notifier.dart';
import '../features/onboarding/domain/models/onboarding_state.dart';
import '../shared/widgets/main_shell_page.dart';
import '../shared/widgets/app_sheet.dart';
import '../shared/widgets/shimmer.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';

// Deferred imports — loaded on first navigation to avoid bundling everything upfront.
import '../features/onboarding/presentation/screens/language_selection_screen.dart'
    deferred as screen_welcome;

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
import '../features/reports/presentation/screens/reports_hub_screen.dart'
    deferred as screen_reports;
import '../features/reports/presentation/screens/profit_loss_screen.dart'
    deferred as screen_pnl;
import '../features/reports/presentation/screens/sales_report_screen.dart'
    deferred as screen_sales_report;
import '../features/reports/presentation/screens/expense_report_screen.dart'
    deferred as screen_expense_report;
import '../features/reports/presentation/screens/vat_summary_screen.dart'
    deferred as screen_vat;
import '../features/reports/presentation/screens/ar_aging_screen.dart'
    deferred as screen_ar;
import '../features/reports/presentation/screens/ap_aging_screen.dart'
    deferred as screen_ap;
import '../features/reports/presentation/screens/cash_flow_report_screen.dart'
    deferred as screen_cashflow_report;
import '../features/reports/presentation/screens/balance_sheet_screen.dart'
    deferred as screen_balance;
import '../features/reports/presentation/screens/inventory_valuation_screen.dart'
    deferred as screen_inv_val;
import '../features/settings/presentation/screens/sync_diagnostics_screen.dart'
    deferred as screen_sync_diagnostics;
import '../features/notifications/presentation/screens/notifications_screen.dart'
    deferred as screen_notifications;
import '../features/rbac/data/rbac_providers.dart'
    show
        permissionServiceProvider,
        permissionsLoadedProvider,
        SessionState,
        sessionStateProvider;
import '../features/rbac/presentation/screens/access_denied_screen.dart';
import '../features/team/domain/models/team_member.dart';

// ─── ROUTE PATHS ─────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  // ── Onboarding ────────────────────────────────────────────────────────────
  static const splash = '/splash';
  static const welcome = '/welcome'; // Screen 1 — language picker
  static const intro = '/intro'; // Screen 2 — app intro slides
  static const phone = '/phone'; // Screen 3 — phone entry + lookup
  static const pinLogin = '/pin-login'; // Screen 4A — existing user PIN
  static const teamSetup = '/team-setup'; // Screen 4B — team member first login
  static const newUser = '/new-user'; // Screen 4C — new user personal info
  static const business = '/business'; // Screen 5 — business details
  static const security = '/security'; // Screen 6 — PIN setup (new owners)
  static const success = '/success'; // Screen 7 — success
  static const resetPin = '/reset-pin'; // PIN recovery magic-link target

  // ── Main app shell ────────────────────────────────────────────────────────
  static const dashboard = '/';
  static const sales = '/sales';
  static const inventory = '/inventory';
  static const crm = '/crm';
  static const debt = '/debt';
  static const expenses = '/expenses';
  static const cashflow = '/cashflow';
  static const team = '/team';
  static const settings = '/settings';
  static const subscription = '/subscription';
  static const businesses = '/businesses';
  static const reports = '/reports';
  static const syncDiagnostics = '/sync-diagnostics';
  static const notifications = '/notifications';
  static const login = '/login';
  static const accessDenied = '/access-denied';

  static const _onboardingPaths = {
    welcome,
    intro,
    phone,
    pinLogin,
    teamSetup,
    newUser,
    business,
    security,
    success,
  };

  static bool isOnboardingPath(String path) => _onboardingPaths.contains(path);

  // ── Permission requirements per route ─────────────────────────────────────

  /// Returns the AppPermission required to visit [path], or null if the route
  /// is always accessible to authenticated users (dashboard, access-denied).
  static AppPermission? requiredPermission(String path) {
    // Match on prefix so sub-routes (e.g. /reports/pnl) inherit the guard.
    if (path.startsWith(sales)) return AppPermission.viewSales;
    if (path.startsWith(inventory)) return AppPermission.viewInventory;
    if (path.startsWith(crm)) return AppPermission.viewCustomers;
    if (path.startsWith(debt)) return AppPermission.viewDebt;
    if (path.startsWith(expenses)) return AppPermission.manageExpenses;
    if (path.startsWith(cashflow)) return AppPermission.viewCashFlow;
    if (path.startsWith(team)) return AppPermission.manageTeam;
    if (path.startsWith(reports)) return AppPermission.viewFinancialReports;
    return null;
  }

  /// Routes that only the business owner may access (no team-member permission
  /// maps to these — they control the business itself, not day-to-day ops).
  /// Settings is deliberately NOT here: every signed-in user — owner or team
  /// member — needs to reach it to edit their own profile or sign out.
  /// SettingsScreen itself hides the owner-only sections (plan/subscription,
  /// data export, audit log) from team members.
  static bool isOwnerOnly(String path) =>
      path.startsWith(subscription) ||
      path.startsWith(businesses) ||
      path.startsWith(syncDiagnostics);
}

// ─── ROUTER PROVIDER ─────────────────────────────────────────────────────────

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: AppRoutes.splash,
    redirect: notifier._redirect,
    observers: [AppSheetObserver(), SentryNavigatorObserver()],
    routes: _buildRoutes(),
  );
});

// ─── ROUTER NOTIFIER ─────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(onboardingNotifierProvider, (prev, next) => notifyListeners());
    // Re-evaluate on Firebase Auth sign-in / sign-out so first-login
    // correctly picks up the newly authenticated user.
    _ref.listen(authStateProvider, (prev, next) => notifyListeners());
    // Re-evaluate routes whenever the user's permissions change
    // (e.g. profile loads, role changes, member is suspended).
    _ref.listen(permissionServiceProvider, (prev, next) => notifyListeners());
    _ref.listen(permissionsLoadedProvider, (prev, next) => notifyListeners());
    // Re-evaluate when session bootstrap state changes so we can detect
    // memberNotFound and redirect to the recovery screen.
    _ref.listen(sessionStateProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;

  String? _redirect(BuildContext context, GoRouterState routerState) {
    final path = routerState.uri.path;
    final ob = _ref.read(onboardingNotifierProvider);

    // Splash always allowed — it runs the completion check.
    if (path == AppRoutes.splash) return null;

    // Access-denied screen is always reachable once onboarding is complete.
    if (path == AppRoutes.accessDenied) {
      return ob.isComplete ? null : AppRoutes.welcome;
    }

    // PIN recovery deep link — always reachable, in any auth state. A
    // signed-in user who opens a stale link just gets the "invalid link"
    // screen; a signed-out user gets the reset form.
    if (path == AppRoutes.resetPin) return null;

    // ── Post-completion guards ────────────────────────────────────────────
    if (ob.isComplete) {
      if (path == AppRoutes.success) return null;
      if (AppRoutes.isOnboardingPath(path)) {
        // Hold here until RBAC bootstrap has settled so the dashboard always
        // renders with the correct PermissionService on the first frame.
        //
        // • New owners  → their users/{uid} doc is written concurrently with
        //   Firebase Auth, so there is a race window. Show the success screen.
        // • Returning users / team members → doc already exists, but the
        //   Firestore snapshot is still in-flight immediately after sign-in.
        //   Keep them on their current screen for the sub-second wait.
        //   RoleCacheService means this wait is effectively zero after the
        //   first login (cache hit → permissionsLoaded settles synchronously).
        final loaded = _ref.read(permissionsLoadedProvider);
        if (!loaded) {
          return (!ob.isReturningUser && !ob.isTeamMember)
              ? AppRoutes
                    .success // new-owner buffer screen
              : null; // stay on pin-login / team-setup
        }
        return AppRoutes.dashboard;
      }

      // ── Session bootstrap guard ───────────────────────────────────────
      // If the user's member record can't be found after the profile loaded,
      // redirect to the recovery screen instead of showing a blank dashboard.
      final session = _ref.read(sessionStateProvider);
      if (session == SessionState.memberNotFound) {
        return AppRoutes.accessDenied;
      }

      // ── Permission guards ─────────────────────────────────────────────
      // Skip checks while permissions are still loading to avoid a flash.
      final loaded = _ref.read(permissionsLoadedProvider);
      if (kDebugMode) {
        final ps2 = _ref.read(permissionServiceProvider);
        debugPrint(
          '[Router] redirect path=$path loaded=$loaded '
          'isOwner=${ps2.isOwner} canSales=${ps2.canViewSales}',
        );
      }
      if (loaded) {
        final ps = _ref.read(permissionServiceProvider);

        // Owner-only routes (billing, subscription, business management).
        if (AppRoutes.isOwnerOnly(path) && !ps.isOwner) {
          return AppRoutes.accessDenied;
        }

        // Module-level permission check.
        final required = AppRoutes.requiredPermission(path);
        if (required != null && !ps.can(required)) {
          return AppRoutes.accessDenied;
        }
      }

      return null;
    }

    // ── Pre-completion: block shell routes ────────────────────────────────
    if (!AppRoutes.isOnboardingPath(path) && path != AppRoutes.login) {
      // Fast-path for post-logout: skip language + intro and go to phone entry.
      if (ob.currentStep.stepIndex >= OnboardingStep.phoneEntry.stepIndex) {
        return AppRoutes.phone;
      }
      return AppRoutes.welcome;
    }

    // Fast-path: user has been through intro already (e.g. logged out),
    // skip language + intro screens and land directly on phone entry.
    if (ob.currentStep.stepIndex >= OnboardingStep.phoneEntry.stepIndex &&
        (path == AppRoutes.welcome || path == AppRoutes.intro)) {
      return AppRoutes.phone;
    }

    // ── Step-by-step guards ───────────────────────────────────────────────

    // Screen 3 requires a phone number to have been entered.
    if (path == AppRoutes.phone &&
        ob.currentStep.stepIndex < OnboardingStep.phoneEntry.stepIndex) {
      return AppRoutes.intro;
    }

    // Screens 4A/4B/4C require phone lookup to have run
    // (currentStep must be at or past phoneEntry).
    if ((path == AppRoutes.pinLogin ||
            path == AppRoutes.teamSetup ||
            path == AppRoutes.newUser) &&
        ob.currentStep.stepIndex < OnboardingStep.pinLogin.stepIndex) {
      return AppRoutes.phone;
    }

    // Screen 4A only for returning users (has an existing account).
    if (path == AppRoutes.pinLogin && !ob.isReturningUser) {
      return ob.isTeamMember ? AppRoutes.teamSetup : AppRoutes.newUser;
    }

    // Screen 4B only for pending team members.
    if (path == AppRoutes.teamSetup && !ob.isTeamMember) {
      return ob.isReturningUser ? AppRoutes.pinLogin : AppRoutes.newUser;
    }

    // Screen 4C only for new users (not returning, not team member).
    if (path == AppRoutes.newUser && (ob.isReturningUser || ob.isTeamMember)) {
      return ob.isReturningUser ? AppRoutes.pinLogin : AppRoutes.teamSetup;
    }

    // Screen 5 requires personal info (firstName set, or returning/team user).
    if (path == AppRoutes.business) {
      final hasPersonal =
          ob.firstName.isNotEmpty || ob.isReturningUser || ob.isTeamMember;
      if (!hasPersonal) return AppRoutes.newUser;
    }

    // Screen 6 requires a businessName.
    if (path == AppRoutes.security && ob.businessName.isEmpty) {
      return AppRoutes.business;
    }

    // Screen 7 only after saveAndComplete() sets isComplete.
    if (path == AppRoutes.success && !ob.isComplete) {
      return AppRoutes.welcome;
    }

    return null;
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

    // ── Screen 1 — Language ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.welcome,
      pageBuilder: (context, state) => _authPage(
        state,
        _deferred(
          load: screen_welcome.loadLibrary,
          build: () => screen_welcome.LanguageSelectionScreen(
            onLanguageSelected: () => context.go(AppRoutes.intro),
          ),
        ),
      ),
    ),

    // ── Screen 2 — App intro slides ──────────────────────────────────────────
    GoRoute(
      path: AppRoutes.intro,
      pageBuilder: (context, state) =>
          _authPage(state, const IntroSlidesScreen()),
    ),

    // ── Screen 3 — Phone Entry ───────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.phone,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final isSwitchAccount = extra is Map && extra['switchAccount'] == true;
        return _authPage(
          state,
          PhoneEntryScreen(isSwitchAccount: isSwitchAccount),
        );
      },
    ),

    // ── Screen 4A — PIN Login ────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.pinLogin,
      pageBuilder: (context, state) => _authPage(state, const PinLoginScreen()),
    ),

    // ── Screen 4B — Team Member Setup ───────────────────────────────────────
    GoRoute(
      path: AppRoutes.teamSetup,
      pageBuilder: (context, state) =>
          _authPage(state, const TeamMemberSetupScreen()),
    ),

    // ── Screen 4C — New User Personal Info ───────────────────────────────────
    GoRoute(
      path: AppRoutes.newUser,
      pageBuilder: (context, state) =>
          _authPage(state, const NewUserInfoScreen()),
    ),

    // ── Screen 5 — Business Details ──────────────────────────────────────────
    GoRoute(
      path: AppRoutes.business,
      pageBuilder: (context, state) =>
          _authPage(state, const BusinessDetailsScreen()),
    ),

    // ── Screen 6 — PIN Setup ────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.security,
      pageBuilder: (context, state) =>
          _authPage(state, const SecuritySetupScreen()),
    ),

    // ── Screen 7 — Success ───────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.success,
      pageBuilder: (context, state) =>
          _authPage(state, const OnboardingSuccessScreen()),
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

    // ── PIN recovery (magic-link target, any auth state) ─────────────────────
    GoRoute(
      path: AppRoutes.resetPin,
      pageBuilder: (context, state) => _authPage(
        state,
        PinResetScreen(token: state.uri.queryParameters['token']),
      ),
    ),

    // ── Main app shell ────────────────────────────────────────────────────────
    ShellRoute(
      pageBuilder: (context, state, child) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: MainShellPage(child: child),
        transitionDuration: AppMotion.quick,
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return AppMotion.fadeThrough(
            context,
            animation,
            secondaryAnimation,
            child,
          );
        },
      ),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_dashboard.loadLibrary,
              build: () => screen_dashboard.DashboardScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.sales,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_sales.loadLibrary,
              build: () => screen_sales.SalesScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.inventory,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_inventory.loadLibrary,
              build: () => screen_inventory.InventoryScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.crm,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_customers.loadLibrary,
              build: () => screen_customers.CustomerListScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.debt,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_debt.loadLibrary,
              build: () => screen_debt.DebtTrackingScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.expenses,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_expenses.loadLibrary,
              build: () => screen_expenses.ExpenseListScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.cashflow,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_cashflow.loadLibrary,
              build: () => screen_cashflow.CashFlowScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_settings.loadLibrary,
              build: () => screen_settings.SettingsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.subscription,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_subscription.loadLibrary,
              build: () => screen_subscription.SubscriptionScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businesses,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_businesses.loadLibrary,
              build: () => screen_businesses.ManageBusinessesScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.team,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_team.loadLibrary,
              build: () => screen_team.TeamScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.accessDenied,
          pageBuilder: (context, state) =>
              _primaryPage(state, const AccessDeniedScreen()),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_notifications.loadLibrary,
              build: () => screen_notifications.NotificationsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.syncDiagnostics,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_sync_diagnostics.loadLibrary,
              build: () => screen_sync_diagnostics.SyncDiagnosticsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.reports,
          pageBuilder: (context, state) => _primaryPage(
            state,
            _deferred(
              load: screen_reports.loadLibrary,
              build: () => screen_reports.ReportsHubScreen(),
            ),
          ),
          routes: [
            GoRoute(
              path: 'pnl',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_pnl.loadLibrary,
                  build: () => screen_pnl.ProfitLossScreen(),
                ),
              ),
            ),
            GoRoute(
              path: 'sales',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_sales_report.loadLibrary,
                  build: () => screen_sales_report.SalesReportScreen(),
                ),
              ),
            ),
            GoRoute(
              path: 'expenses',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_expense_report.loadLibrary,
                  build: () => screen_expense_report.ExpenseReportScreen(),
                ),
              ),
            ),
            GoRoute(
              path: 'vat',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_vat.loadLibrary,
                  build: () => screen_vat.VatSummaryScreen(),
                ),
              ),
            ),
            GoRoute(
              path: 'ar-aging',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_ar.loadLibrary,
                  build: () => screen_ar.ArAgingScreen(),
                ),
              ),
            ),
            GoRoute(
              path: 'ap-aging',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_ap.loadLibrary,
                  build: () => screen_ap.ApAgingScreen(),
                ),
              ),
            ),
            GoRoute(
              path: 'cash-flow',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_cashflow_report.loadLibrary,
                  build: () => screen_cashflow_report.CashFlowReportScreen(),
                ),
              ),
            ),
            GoRoute(
              path: 'balance-sheet',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_balance.loadLibrary,
                  build: () => screen_balance.BalanceSheetScreen(),
                ),
              ),
            ),
            GoRoute(
              path: 'inventory-valuation',
              pageBuilder: (context, state) => _detailPage(
                state,
                _deferred(
                  load: screen_inv_val.loadLibrary,
                  build: () => screen_inv_val.InventoryValuationScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

// ─── TRANSITION HELPERS ───────────────────────────────────────────────────────

CustomTransitionPage<void> _authPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    reverseTransitionDuration: AppMotion.reverse,
    transitionsBuilder: AppMotion.sharedAxisHorizontal,
  );
}

CustomTransitionPage<void> _primaryPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.quick,
    reverseTransitionDuration: AppMotion.quick,
    transitionsBuilder: AppMotion.fadeThrough,
  );
}

CustomTransitionPage<void> _detailPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.standard,
    reverseTransitionDuration: AppMotion.reverse,
    transitionsBuilder: AppMotion.sharedAxisHorizontal,
  );
}

Widget _deferred({
  required Future<void> Function() load,
  required Widget Function() build,
}) {
  return FutureBuilder<void>(
    future: load(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.done) return build();
      // Deferred library is loading — show a branded shimmer placeholder
      // instead of a blank white page with a fullscreen spinner.
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 24,
            24,
            24,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: 160,
                height: 20,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              SizedBox(height: 24),
              ShimmerBox(height: 120),
              SizedBox(height: 16),
              ShimmerBox(height: 72),
              SizedBox(height: 16),
              ShimmerBox(height: 72),
            ],
          ),
        ),
      );
    },
  );
}

// ─── BACKWARD-COMPAT FACTORY ─────────────────────────────────────────────────

@Deprecated('Use goRouterProvider instead')
class AppRouter {
  static const splashPath = AppRoutes.splash;
  static const dashboardPath = AppRoutes.dashboard;
  static const loginPath = AppRoutes.login;
  static const welcomePath = AppRoutes.welcome;
  static const phonePath = AppRoutes.phone;
  static const pinLoginPath = AppRoutes.pinLogin;
  static const newUserPath = AppRoutes.newUser;
  static const businessPath = AppRoutes.business;
  static const securityPath = AppRoutes.security;
  static const successPath = AppRoutes.success;

  // Legacy aliases kept so existing code doesn't break at compile time.
  static const languageSelectionPath = AppRoutes.welcome;
  static const onboardingPath = AppRoutes.welcome;
  static const registerPath = AppRoutes.phone;
  static const otpPath = AppRoutes.phone;
  static const returningPath = AppRoutes.pinLogin;
  static const salesPath = AppRoutes.sales;
  static const inventoryPath = AppRoutes.inventory;
  static const crmPath = AppRoutes.crm;
  static const debtPath = AppRoutes.debt;
  static const expensesPath = AppRoutes.expenses;
  static const cashFlowPath = AppRoutes.cashflow;
  static const teamPath = AppRoutes.team;
  static const settingsPath = AppRoutes.settings;
  static const subscriptionPath = AppRoutes.subscription;
  static const businessesPath = AppRoutes.businesses;
  static const reportsPath = AppRoutes.reports;
  static const syncDiagnosticsPath = AppRoutes.syncDiagnostics;
  static const notificationsPath = AppRoutes.notifications;

  static GoRouter createRouter({
    required bool showLanguageSelection,
    required bool showOnboarding,
  }) {
    return GoRouter(initialLocation: AppRoutes.splash, routes: _buildRoutes());
  }
}
