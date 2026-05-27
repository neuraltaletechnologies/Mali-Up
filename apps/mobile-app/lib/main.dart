import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mali_up/config/routing.dart';
import 'package:mali_up/core/theme/app_theme.dart';
import 'package:mali_up/core/services/localization_service.dart';
import 'package:mali_up/core/services/motion_service.dart';
import 'package:mali_up/core/services/security_service.dart';
import 'package:mali_up/features/security/presentation/screens/pin_lock_screen.dart';
import 'firebase_options.dart';

const String _onboardingCompletedKey = 'onboarding_completed';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    final message = error.toString();
    if (!message.contains('duplicate-app')) {
      rethrow;
    }
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    LocalizationService.initializeWithPrefs(prefs),
    MotionService.initializeWithPrefs(prefs),
    SecurityService.initialize(),
  ]);

  final hasCompletedOnboarding =
      prefs.getBool(_onboardingCompletedKey) ?? false;
  final hasSelectedLanguage =
      await LocalizationService.hasLanguageBeenSelected();

  runApp(
    ProviderScope(
      child: MaliUpApp(
        hasCompletedOnboarding: hasCompletedOnboarding,
        hasSelectedLanguage: hasSelectedLanguage,
      ),
    ),
  );
}

class MaliUpApp extends StatefulWidget {
  final bool hasCompletedOnboarding;
  final bool hasSelectedLanguage;

  const MaliUpApp({
    super.key,
    required this.hasCompletedOnboarding,
    required this.hasSelectedLanguage,
  });

  @override
  State<MaliUpApp> createState() => _MaliUpAppState();
}

class _MaliUpAppState extends State<MaliUpApp> with WidgetsBindingObserver {
  late final GoRouter _router;

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
    _router = AppRouter.createRouter(
      showLanguageSelection: !widget.hasSelectedLanguage,
      showOnboarding:
          !widget.hasCompletedOnboarding && widget.hasSelectedLanguage,
    );
    SecurityService.isLockedNotifier.addListener(_onLockStateChanged);
  }

  @override
  void dispose() {
    SecurityService.isLockedNotifier.removeListener(_onLockStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
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
          _router.go(AppRoutes.dashboard);
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
                  supportedLocales: const [
                    Locale('en'),
                    Locale('sw'),
                  ],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  routerConfig: _router,
                );
              },
            );
          },
        );
      },
    );
  }
}
