import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:mali_up/config/routing.dart';
import 'package:mali_up/core/theme/app_theme.dart';
import 'package:mali_up/core/services/localization_service.dart';
import 'package:mali_up/core/services/motion_service.dart';
import 'package:mali_up/core/services/sentry_metrics_service.dart';
import 'package:mali_up/core/services/security_service.dart';
import 'package:mali_up/core/services/version_gate_service.dart';
import 'package:mali_up/features/onboarding/providers/onboarding_notifier.dart'
    show onboardingBootstrapProvider, onboardingDraftBootstrapProvider, onboardingPhoneEntryBootstrapProvider, OnboardingDraft;
import 'package:mali_up/features/onboarding/data/services/onboarding_service.dart'
    show OnboardingService;
import 'package:mali_up/features/security/presentation/screens/pin_lock_screen.dart';
import 'package:mali_up/features/update/presentation/screens/update_required_screen.dart';
import 'firebase_options.dart';

// Must match OnboardingService._completedKey so the bootstrap read is consistent.
const String _onboardingCompletedKey = 'mali_onboarding_complete';
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const String _sentryEnvironment = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: 'development',
);
const String _sentryRelease = String.fromEnvironment('SENTRY_RELEASE');
const String _sentryDist = String.fromEnvironment('SENTRY_DIST');
const bool _sentryTestEvent = bool.fromEnvironment(
  'SENTRY_TEST_EVENT',
);

Future<void> _startApp() async {
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

  // Fire-and-forget: checks this build against the remote version gate.
  // Never awaited — must not delay startup, and fails open on any error.
  unawaited(VersionGateService.initialize());

  final prefs = await prefsFuture;
  await Future.wait([
    LocalizationService.initializeWithPrefs(prefs),
    MotionService.initializeWithPrefs(prefs),
    SecurityService.initialize(),
  ]);

  final hasCompletedOnboarding =
      prefs.getBool(_onboardingCompletedKey) ?? false;
  // initializeWithPrefs already loaded this value into languageSelectedNotifier.
  final hasSelectedLanguage = LocalizationService.languageSelectedNotifier.value;
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

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(
    ProviderScope(
      overrides: [
        // Tell the router immediately whether to skip onboarding.
        // This prevents a one-frame flicker to /welcome for returning users.
        onboardingBootstrapProvider.overrideWithValue(
          hasCompletedOnboarding && hasActiveSession,
        ),
        onboardingPhoneEntryBootstrapProvider.overrideWithValue(startAtPhoneEntry),
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
  SentryMetricsService.configure(enabled: _sentryDsn.isNotEmpty);

  if (_sentryDsn.isEmpty) {
    await _startApp();
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0; // ignore: experimental_member_use
        options.replay.sessionSampleRate = 1.0;
        options.replay.onErrorSampleRate = 1.0;
        options.privacy.maskAllText = true;
        options.privacy.maskAllImages = true;
        options.sendDefaultPii = true;
        options.debug = false;
        options.environment = _sentryEnvironment;
        if (_sentryRelease.isNotEmpty) {
          options.release = _sentryRelease;
        }
        if (_sentryDist.isNotEmpty) {
          options.dist = _sentryDist;
        }
      },
      appRunner: () async {
        // Chain Flutter framework error handler so layout/widget exceptions
        // are captured in addition to what SentryFlutter sets up internally.
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          originalOnError?.call(details);
          Sentry.captureException(
            details.exception,
            stackTrace: details.stack,
          );
        };

        // Catch unhandled async/isolate errors from the platform layer.
        PlatformDispatcher.instance.onError = (error, stack) {
          Sentry.captureException(error, stackTrace: stack);
          return true;
        };

        await _startApp();
        SentryMetricsService.appLaunched(sentryEnabled: true);
        if (_sentryTestEvent) {
          await Sentry.captureException(
            StateError('This is test exception'),
          );
        }
      },
    );
  }
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
                return SentryWidget(
                  child: MaterialApp.router(
                    title: 'Mali Up',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    locale: Locale(language.code),
                    supportedLocales: const [
                      Locale('en'),
                      Locale('sw'),
                    ],
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
                      return Theme(
                        data: Theme.of(context).copyWith(
                          bottomSheetTheme: Theme.of(context)
                              .bottomSheetTheme
                              .copyWith(
                                constraints: BoxConstraints(
                                  maxHeight: maxSheetHeight,
                                ),
                              ),
                        ),
                        child: child!,
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
