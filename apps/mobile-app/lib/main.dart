import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mali_up/config/routing.dart';
import 'package:mali_up/core/theme/app_theme.dart';
import 'package:mali_up/core/services/app_rating_service.dart';
import 'package:mali_up/core/services/localization_service.dart';
import 'package:mali_up/core/services/motion_service.dart';
import 'package:mali_up/core/services/error_reporter.dart';
import 'package:mali_up/core/services/notification_service.dart';
import 'package:mali_up/core/services/sentry_metrics_service.dart';
import 'package:mali_up/core/services/security_service.dart';
import 'package:mali_up/core/services/version_gate_service.dart';
import 'package:mali_up/core/providers/sync_provider.dart';
import 'package:mali_up/features/onboarding/providers/onboarding_notifier.dart'
    show
        onboardingBootstrapProvider,
        onboardingDraftBootstrapProvider,
        onboardingPhoneEntryBootstrapProvider,
        OnboardingDraft;
import 'package:mali_up/features/onboarding/data/services/onboarding_service.dart'
    show OnboardingService;
import 'package:mali_up/features/security/presentation/screens/pin_lock_screen.dart';
import 'package:mali_up/features/update/presentation/screens/update_required_screen.dart';
import 'firebase_options.dart';

// Must match OnboardingService._completedKey so the bootstrap read is consistent.
const String _onboardingCompletedKey = 'mali_onboarding_complete';

Future<void> _startApp() async {
  // Fonts are bundled under assets/google_fonts/ — never fetch them over the
  // network. Without this, google_fonts tries to download DM Sans / JetBrains
  // Mono / DM Serif Display from fonts.gstatic.com on first use and throws an
  // unhandled exception on offline / DNS-restricted networks.
  GoogleFonts.config.allowRuntimeFetching = false;

  // SharedPreferences and Firebase init are independent — kick both off now.
  final prefsFuture = SharedPreferences.getInstance();
  // Guard: if env vars weren't injected (e.g. --dart-define-from-file missing),
  // the options will have empty strings, which causes a native NSException crash on
  // iOS rather than a catchable Dart error. Fail fast with a readable message.
  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  assert(
    firebaseOptions.projectId.isNotEmpty,
    'Firebase options are empty. Run with: flutter run --dart-define-from-file=.env.json',
  );
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(options: firebaseOptions);
    } catch (error) {
      final message = error.toString();
      if (!message.contains('duplicate-app')) {
        rethrow;
      }
    }
  }

  // Drift is the source of truth for offline data — Firestore's own
  // persistence cache is disabled to prevent a dual-cache inconsistency.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  // Attaches an attestation token (Play Integrity on Android, App Attest /
  // DeviceCheck on iOS) to every Firestore and callable-Functions request,
  // proving the call comes from a genuine build of this app rather than a
  // script hitting our endpoints directly. Debug builds use the debug
  // provider so local development keeps working — see
  // APP_CHECK_SETUP.md for registering the printed debug token in the
  // Firebase console.
  //
  // Activating App Check does NOT enforce it yet — enforcement (Console →
  // App Check → APIs → Enforce) is a separate, deliberate switch to flip
  // only once this build has rolled out to the great majority of installs.
  // Flipping it earlier locks out every user still on an older app version
  // that never attaches a token.
  unawaited(
    FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    ),
  );

  // Fire-and-forget: checks this build against the remote version gate.
  // Never awaited — must not delay startup, and fails open on any error.
  unawaited(VersionGateService.initialize());
  // Seeds the install date used to gate the "rate us" prompt.
  unawaited(AppRatingService.recordFirstLaunchIfNeeded());

  final prefs = await prefsFuture;
  await Future.wait([
    LocalizationService.initializeWithPrefs(prefs),
    MotionService.initializeWithPrefs(prefs),
    SecurityService.initialize(),
    NotificationService.initialize(),
  ]);

  final hasCompletedOnboarding =
      prefs.getBool(_onboardingCompletedKey) ?? false;
  // initializeWithPrefs already loaded this value into languageSelectedNotifier.
  final hasSelectedLanguage =
      LocalizationService.languageSelectedNotifier.value;
  // If onboarding was completed before but there is no active Firebase session
  // (user logged out then killed the app), we must NOT treat them as fully
  // onboarded — instead start at phone-entry so they can sign back in.
  final hasActiveSession = FirebaseAuth.instance.currentUser != null;
  final startAtPhoneEntry = hasCompletedOnboarding && !hasActiveSession;
  // Restore a partially-completed new-user registration so the user doesn't
  // have to re-enter their name/business info after the app is killed mid-flow.
  final OnboardingDraft? registrationDraft = hasCompletedOnboarding
      ? null
      : OnboardingService.loadDraft(prefs);

  // Edge-to-edge is the default on Flutter targeting Android SDK 35+, but set it
  // explicitly so the behaviour doesn't depend on the framework default and the
  // app draws behind the status/navigation bars on every supported version.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      // Transparent nav bar with contrast enforcement off: setting an opaque
      // colour maps to Window.setNavigationBarColor, which Android 15 deprecates.
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        // Tell the router immediately whether to skip onboarding.
        // This prevents a one-frame flicker to /welcome for returning users.
        onboardingBootstrapProvider.overrideWithValue(
          hasCompletedOnboarding && hasActiveSession,
        ),
        onboardingPhoneEntryBootstrapProvider.overrideWithValue(
          startAtPhoneEntry,
        ),
        onboardingDraftBootstrapProvider.overrideWithValue(registrationDraft),
      ],
      child: MaliUpApp(
        hasCompletedOnboarding: hasCompletedOnboarding,
        hasSelectedLanguage: hasSelectedLanguage,
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SentryMetricsService.configure(enabled: kDebugMode);

  // Route caught framework/platform errors through the single reporter hook.
  // `sentry_flutter` used to do this; it was removed for app size (it shipped
  // ~1.5 MB of native code but never carried a production DSN). ErrorReporter
  // is where a real crash reporter (e.g. firebase_crashlytics) plugs back in.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    originalOnError?.call(details);
    ErrorReporter.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.captureException(error, stackTrace: stack);
    return true;
  };

  await _startApp();
  SentryMetricsService.appLaunched(sentryEnabled: false);
}

class MaliUpApp extends ConsumerStatefulWidget {
  final bool hasCompletedOnboarding;
  final bool hasSelectedLanguage;

  const MaliUpApp({
    super.key,
    required this.hasCompletedOnboarding,
    required this.hasSelectedLanguage,
  });

  @override
  ConsumerState<MaliUpApp> createState() => _MaliUpAppState();
}

class _MaliUpAppState extends ConsumerState<MaliUpApp>
    with WidgetsBindingObserver {
  // True when the app was launched with the lock screen active (PIN lock set).
  late final bool _startedLocked;
  // Flipped to true after the first post-unlock navigation so subsequent
  // lock/unlock cycles (app backgrounded and resumed) don't force a redirect.
  bool _navigatedAfterFirstUnlock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedLocked = SecurityService.isLockedNotifier.value;
    SecurityService.isLockedNotifier.addListener(_onLockStateChanged);
  }

  @override
  void dispose() {
    SecurityService.isLockedNotifier.removeListener(_onLockStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // When the app was started locked and the user just verified their PIN,
  // skip the splash screen and go straight to the dashboard.
  void _onLockStateChanged() {
    if (!SecurityService.isLockedNotifier.value &&
        _startedLocked &&
        !_navigatedAfterFirstUnlock) {
      _navigatedAfterFirstUnlock = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && FirebaseAuth.instance.currentUser != null) {
          ref.read(goRouterProvider).go(AppRoutes.dashboard);
        }
      });
    }
  }

  // Lock only when fully backgrounded — not on transient inactive states
  // (notification shade, volume overlay, app switcher, etc.).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      SecurityService.lockApp();
    } else if (state == AppLifecycleState.resumed) {
      // Re-check the version gate on every foreground, not just cold start —
      // an admin can mandate an update while a user keeps the app
      // backgrounded for days, and this swaps in UpdateRequiredScreen
      // (see build()) without waiting for them to fully relaunch.
      unawaited(VersionGateService.initialize());
      // SyncService otherwise only runs on cold start or a connectivity
      // blip — without this, changes made on another device (e.g. a
      // customer or product added elsewhere) don't appear here until one
      // of those happens to fire. Pull on every foreground instead.
      if (FirebaseAuth.instance.currentUser != null) {
        unawaited(ref.read(syncServiceProvider).syncNow());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // goRouterProvider is Riverpod-aware: its refreshListenable fires whenever
    // onboardingNotifierProvider or permissionServiceProvider change, causing
    // the router to re-evaluate redirects without a full app rebuild.
    final router = ref.watch(goRouterProvider);

    return ValueListenableBuilder<VersionGateStatus>(
      valueListenable: VersionGateService.statusNotifier,
      builder: (context, versionGateStatus, _) {
        // A forced update takes priority over everything else, including the
        // PIN lock — the update itself may carry a security fix.
        if (versionGateStatus.tier == VersionGateTier.hardBlock) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: UpdateRequiredScreen(status: versionGateStatus),
          );
        }

        return _buildGatedApp(router);
      },
    );
  }

  Widget _buildGatedApp(GoRouter router) {
    return ValueListenableBuilder<bool>(
      valueListenable: SecurityService.isLockedNotifier,
      builder: (context, isLocked, _) {
        // When locked, show the PIN lock screen as a standalone MaterialApp
        // so it sits on top of everything and cannot be bypassed.
        if (isLocked) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const PinLockScreen(),
          );
        }

        return ValueListenableBuilder<AppLanguage>(
          valueListenable: LocalizationService.languageNotifier,
          builder: (context, language, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: MotionService.reducedMotionNotifier,
              builder: (context, reducedMotion, child) {
                return MaterialApp.router(
                  title: 'Mali Up',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  locale: Locale(language.code),
                  supportedLocales: const [Locale('en'), Locale('sw')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  routerConfig: router,
                  builder: (context, child) {
                      // Cap every modal bottom sheet at 80% of screen height so
                      // they never cover the full screen. The constraint is applied
                      // at the route level and works regardless of backgroundColor.
                      final maxSheetHeight =
                          MediaQuery.sizeOf(context).height * 0.8;
                      final mediaQuery = MediaQuery.of(context);
                      return MediaQuery(
                        data: mediaQuery.copyWith(
                          disableAnimations:
                              mediaQuery.disableAnimations || reducedMotion,
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            bottomSheetTheme: Theme.of(context).bottomSheetTheme
                                .copyWith(
                                  constraints: BoxConstraints(
                                    maxHeight: maxSheetHeight,
                                  ),
                                ),
                          ),
                          child: child!,
                        ),
                      );
                    },
                );
              },
            );
          },
        );
      },
    );
  }
}
