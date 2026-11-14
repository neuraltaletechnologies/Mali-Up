import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mali_up/config/routing.dart';
import 'package:mali_up/core/theme/app_theme.dart';
import 'package:mali_up/core/theme/app_scroll_behavior.dart';
import 'package:mali_up/core/services/desktop_window_service.dart';
import 'package:mali_up/core/services/app_rating_service.dart';
import 'package:mali_up/core/services/localization_service.dart';
import 'package:mali_up/core/services/motion_service.dart';
import 'package:mali_up/core/services/error_reporter.dart';
import 'package:mali_up/core/services/notification_service.dart';
import 'package:mali_up/core/services/sentry_metrics_service.dart';
import 'package:mali_up/core/services/security_service.dart';
import 'package:mali_up/core/services/version_gate_service.dart';
import 'package:mali_up/core/providers/sync_provider.dart';
import 'package:mali_up/posthog/posthog.dart';
import 'package:mali_up/posthog/posthog_log.dart';
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

StreamSubscription<User?>? _postHogAuthSubscription;
String? _identifiedPostHogUserId;

/// Keeps the shared PostHog client aligned with Firebase Auth's session.
///
/// Firebase Auth emits the restored session on subscription, followed by each
/// sign-in and sign-out. The UID is Firebase's stable, non-PII user identifier;
/// person properties contain optional PII instead of event properties.
void _initializePostHogIdentity() {
  void syncIdentity(User? user) {
    if (user == null) {
      if (_identifiedPostHogUserId != null) {
        _identifiedPostHogUserId = null;
        unawaited(Posthog().reset());
      }
      return;
    }

    if (_identifiedPostHogUserId == user.uid) return;

    // A direct account switch may not emit an intermediate signed-out state.
    // Clear the prior identity before associating subsequent events and errors
    // with the newly authenticated Firebase user.
    if (_identifiedPostHogUserId != null) {
      unawaited(Posthog().reset());
    }

    _identifiedPostHogUserId = user.uid;
    final userProperties = <String, dynamic>{
      if (user.email != null) r'$email': user.email,
      if (user.displayName != null) r'$name': user.displayName,
      if (user.phoneNumber != null) r'$phone': user.phoneNumber,
    };
    unawaited(
      Posthog().identify(
        userId: user.uid,
        userProperties: userProperties,
      ),
    );
  }

  // Establish identity immediately for a restored session, then handle every
  // later auth transition exactly once through the same boundary.
  syncIdentity(FirebaseAuth.instance.currentUser);
  _postHogAuthSubscription ??= FirebaseAuth.instance.authStateChanges().listen(
    syncIdentity,
  );
}

Future<void> _startApp() async {
  // Fonts are bundled under assets/google_fonts/ — never fetch them over the
  // network. Without this, google_fonts tries to download DM Sans / JetBrains
  // Mono from fonts.gstatic.com on first use and throws an unhandled exception
  // on offline / DNS-restricted networks.
  GoogleFonts.config.allowRuntimeFetching = false;

  // SharedPreferences and Firebase init are independent — kick both off now.
  final prefsFuture = SharedPreferences.getInstance();
  // Windows desktop: open in full screen; F11 toggles it.
  await DesktopWindowService.initialize();
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

  // Start identity tracking immediately after Firebase Auth is available so
  // PostHog events and error tracking inherit the signed-in user's UID.
  _initializePostHogIdentity();

  // Drift is the source of truth for offline data — Firestore's own
  // persistence cache is disabled to prevent a dual-cache inconsistency.
  // On web this also keeps Firestore out of IndexedDB: the web build has no
  // offline mode at all (Drift is in-memory there, see
  // core/database/connection/web.dart), so every read comes from the network.
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
  //
  // Skipped on web: that needs a reCAPTCHA Enterprise site key
  // (providerWeb), which isn't set up yet. Register one before enforcing App
  // Check, or enforcement will lock the web app out too.
  //
  // Also skipped on desktop (Windows): firebase_app_check has no Windows
  // implementation, so enforcing App Check would lock the desktop app out —
  // keep that in mind before flipping enforcement.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    unawaited(_activateAppCheck());
  }

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

  posthogLog.info(
    'app_startup_completed',
    attributes: {
      'has_active_session': hasActiveSession,
      'onboarding_complete': hasCompletedOnboarding,
    },
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
  await setupPostHog();
  SentryMetricsService.configure(enabled: kDebugMode);

  // Preserve PostHog's global handlers while routing the same uncaught errors
  // through the app's existing reporter hook.
  final posthogFlutterErrorHandler = FlutterError.onError;
  final posthogPlatformErrorHandler = PlatformDispatcher.instance.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    posthogFlutterErrorHandler?.call(details);
    ErrorReporter.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.captureException(error, stackTrace: stack);
    return posthogPlatformErrorHandler?.call(error, stack) ?? true;
  };

  await _startApp();
  SentryMetricsService.appLaunched(sentryEnabled: false);
}

Future<void> _activateAppCheck() async {
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
  if (!kDebugMode) {
    return;
  }
  try {
    await FirebaseAppCheck.instance.getToken();
  } catch (e) {
    debugPrint(
      '[AppCheck] Debug token exchange failed: $e\n'
      'Find the line "Firebase App Check Debug Token: ..." in the Xcode or '
      'device log, then register it in Firebase Console → App Check → iOS '
      'app → Manage debug tokens (see apps/mobile-app/APP_CHECK_SETUP.md).',
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
      // Wait until after the PIN-lock MaterialApp has unmounted before
      // driving GoRouter — otherwise router.go during that teardown trips
      // NavigatorState.dispose's !_debugLocked assert.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && FirebaseAuth.instance.currentUser != null) {
            ref.read(goRouterProvider).go(AppRoutes.dashboard);
          }
        });
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
        posthogLog.info(
          'authenticated_app_resumed',
          attributes: {'sync_trigger': 'app_resumed'},
        );
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
            scrollBehavior: const AppScrollBehavior(),
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
            scrollBehavior: const AppScrollBehavior(),
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
                  scrollBehavior: const AppScrollBehavior(),
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
