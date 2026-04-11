import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mali_up/config/routing.dart';
import 'package:mali_up/core/services/default_context_routing_service.dart';
import 'package:mali_up/core/theme/app_theme.dart';
import 'package:mali_up/core/services/localization_service.dart';
import 'package:mali_up/core/services/motion_service.dart';
import 'firebase_options.dart';

const String _onboardingCompletedKey = 'onboarding_completed';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with the provided options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await LocalizationService.initialize();
  await MotionService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      prefs.getBool(_onboardingCompletedKey) ?? false;
  final hasSelectedLanguage = 
      await LocalizationService.hasLanguageBeenSelected();
  final hasDevBypassSession = kDebugMode && (prefs.getBool('dev_bypass_session') ?? false);
  final hasActiveSession = FirebaseAuth.instance.currentUser != null || hasDevBypassSession;
  final initialAuthenticatedPath = hasActiveSession
      ? await DefaultContextRoutingService.resolveInitialAuthenticatedPath(
        hasDevBypassSession: hasDevBypassSession,
      )
      : null;

  runApp(
    ProviderScope(
      child: MaliUpApp(
        hasCompletedOnboarding: hasCompletedOnboarding,
        hasSelectedLanguage: hasSelectedLanguage,
        hasActiveSession: hasActiveSession,
        initialAuthenticatedPath: initialAuthenticatedPath,
      ),
    ),
  );
}

class MaliUpApp extends StatelessWidget {
  final bool hasCompletedOnboarding;
  final bool hasSelectedLanguage;
  final bool hasActiveSession;
  final String? initialAuthenticatedPath;

  const MaliUpApp({
    super.key,
    required this.hasCompletedOnboarding,
    required this.hasSelectedLanguage,
    required this.hasActiveSession,
    required this.initialAuthenticatedPath,
  });

  @override
  Widget build(BuildContext context) {
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
              routerConfig: AppRouter.createRouter(
                showLanguageSelection: !hasSelectedLanguage,
                showOnboarding: !hasCompletedOnboarding && hasSelectedLanguage,
                hasActiveSession: hasActiveSession,
                authenticatedInitialPath: initialAuthenticatedPath,
              ),
            );
          },
        );
      },
    );
  }
}

