
/// IMPLEMENTATION GUIDE FOR MALIX ONBOARDING
/// 
/// This file demonstrates different ways to integrate the onboarding
/// system into your Malix app.
/// IMPLEMENTATION GUIDE FOR MALIUP ONBOARDING
/// 
/// This file demonstrates different ways to integrate the onboarding
/// system into your MaliUp app.

// ============================================
// PATTERN 1: Go Router Integration (Recommended)
// ============================================
/*

// In your router configuration:

import 'package:go_router/go_router.dart';
import 'package:mali_up/features/onboarding/presentation/screens/onboarding_flow.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding', // Start with onboarding
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingFlow(
        onComplete: () {
          // Navigate to auth after onboarding
          context.go('/auth');
        },
      ),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
      routes: [
        GoRoute(
          path: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);

*/

// ============================================
// PATTERN 2: Conditional Routing with Riverpod
// ============================================
/*

// In your main.dart:

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasCompletedOnboarding') ?? true;
});

class MaliUpApp extends ConsumerWidget {
  const MaliUpApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstLaunch = ref.watch(isFirstLaunchProvider);

    return isFirstLaunch.when(
      data: (firstLaunch) {
        return MaterialApp.router(
          routerConfig: firstLaunch ? _onboardingRouter : _mainRouter,
          theme: AppTheme.lightTheme,
        );
      },
      loading: () => const Scaffold(body: Center(child: SizedBox())),
      error: (error, stack) => const Scaffold(body: SizedBox()),
    );
  }
}

final GoRouter _onboardingRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingFlow(
        onComplete: () async {
          // Save completion status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasCompletedOnboarding', false);
          
          // Navigate to main app
          if (context.mounted) {
            context.go('/dashboard');
          }
        },
      ),
    ),
  ],
);

final GoRouter _mainRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);

*/

// ============================================
// PATTERN 3: Riverpod State Management
// ============================================
/*

// Define app state provider:

enum AppState {
  splash,
  onboarding,
  authenticated,
  unauthenticated,
}

final appStateProvider = StateProvider<AppState>((ref) {
  final hasCompleted = ref.watch(hasCompletedOnboardingProvider);
  final isAuthenticated = ref.watch(authStateProvider);
  
  if (hasCompleted && isAuthenticated) {
    return AppState.authenticated;
  } else if (hasCompleted) {
    return AppState.unauthenticated;
  }
  return AppState.onboarding;
});

// Use in your app:

class MaliUpApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);

    return MaterialApp.router(
      routerConfig: _buildRouter(state),
      theme: AppTheme.lightTheme,
    );
  }

  GoRouter _buildRouter(AppState state) {
    return switch (state) {
      AppState.onboarding => GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => OnboardingFlow(
              onComplete: () {
                ref.refresh(hasCompletedOnboardingProvider);
              },
            ),
          ),
        ],
      ),
      AppState.unauthenticated => GoRouter(
        routes: [
          GoRoute(
            path: '/auth',
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      ),
      AppState.authenticated => GoRouter(
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
      ),
      _ => GoRouter(routes: []),
    };
  }
}

*/

// ============================================
// PATTERN 4: Simple Navigator Navigation
// ============================================
/*

import 'package:mali_up/features/onboarding/presentation/screens/onboarding_flow.dart';

// Navigate to onboarding:

Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => OnboardingFlow(
      onComplete: () {
        // Pop onboarding and go to next screen
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed('/login');
      },
    ),
  ),
);

*/

// ============================================
// PATTERN 5: Full Example with SharedPreferences
// ============================================
/*

// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mali_up/features/onboarding/presentation/screens/onboarding_flow.dart';
import 'package:mali_up/features/auth/screens/login_screen.dart';
import 'package:mali_up/features/dashboard/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    ProviderScope(
      child: MaliUpApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MaliUpApp extends StatefulWidget {
  final bool hasSeenOnboarding;

  const MaliUpApp({
    Key? key,
    required this.hasSeenOnboarding,
  }) : super(key: key);

  @override
  State<MaliUpApp> createState() => _MaliUpAppState();
}

class _MaliUpAppState extends State<MaliUpApp> {
  late bool _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.hasSeenOnboarding;
  }

  late final GoRouter _router = GoRouter(
    initialLocation: _hasSeenOnboarding ? '/login' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingFlow(
          onComplete: () async {
            // Mark onboarding as complete
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('hasSeenOnboarding', true);
            
            // Navigate to login
            if (mounted) {
              context.go('/login');
            }
          },
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MaliUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

*/

// ============================================
// INTEGRATION CHECKLIST
// ============================================
/*

- [ ] Add dependencies to pubspec.yaml:
  - smooth_page_indicator
  - animations
  - lottie 

- [ ] Import onboarding feature:
  - import 'package:mali_up/features/onboarding/...';

- [ ] Choose integration pattern:
  - [ ] Go Router (recommended for complex apps)
  - [ ] Riverpod state management
  - [ ] SharedPreferences for persistence
  - [ ] Simple Navigator
  - [ ] Combination of above

- [ ] Set up routing:
  - [ ] Add onboarding route
  - [ ] Set initialLocation based on first launch
  - [ ] Create onComplete callback

- [ ] Persist completion state:
  - [ ] Use SharedPreferences or local storage
  - [ ] Check on app restart

- [ ] Customize :
  - [ ] Edit colors in onboarding_colors.dart
  - [ ] Modify screen content in onboarding_model.dart
  - [ ] Adjust animations in animated_widgets.dart

- [ ] Test:
  - [ ] Run on Android emulator
  - [ ] Run on iOS simulator
  - [ ] Test transitions
  - [ ] Verify animations are smooth
  - [ ] Check button functionality

- [ ] Deploy:
  - [ ] Ensure SharedPreferences is saved
  - [ ] Monitor analytics for user flow
  - [ ] Track completion rate

*/

// ============================================
// ANALYTICS IMPLEMENTATION
// ============================================
/*

// Track onboarding events:

import 'package:firebase_analytics/firebase_analytics.dart';

final _analytics = FirebaseAnalytics.instance;

// In onboarding_flow.dart:

void _trackScreenView(String screenName) {
  _analytics.logScreenView(screenName: screenName);
}

// Call at each screen:
_trackScreenView('onboarding_splash');
_trackScreenView('onboarding_screen_1');
_trackScreenView('onboarding_screen_2');
_trackScreenView('onboarding_screen_3');
_trackScreenView('onboarding_screen_4_cta');

// Track completion:
_analytics.logEvent(
  name: 'onboarding_completed',
  parameters: {
    'timestamp': DateTime.now().toIso8601String(),
    'flow_duration_seconds': duration.inSeconds,
  },
);

*/

// ============================================
// COMMON ISSUES & SOLUTIONS
// ============================================
/*

Issue: Animations are laggy
Solution: 
- Check device doesn't have "Reduce motion" enabled
- Profile with Flutter DevTools (Performance tab)
- Reduce animation complexity

Issue: Splash screen doesn't transition
Solution:
- Ensure onComplete callback is called
- Check Riverpod providers are set up correctly
- Verify GoRouter/Navigator is configured

Issue: Colors don't match design
Solution:
- Edit onboarding_colors.dart
- Test on different devices (color profiles vary)
- Use Material Color Tool: https://material.io/resources/color/

Issue: Page indicator doesn't update
Solution:
- Ensure PageController is properly connected
- Check onPageChanged callback is triggered
- Verify widgets rebuild on state change

*/
