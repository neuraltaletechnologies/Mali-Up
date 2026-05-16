import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mali_up/config/routing.dart';
import 'package:mali_up/core/theme/app_theme.dart';
import 'package:mali_up/core/services/localization_service.dart';
import 'package:mali_up/core/services/motion_service.dart';
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

class _MaliUpAppState extends State<MaliUpApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(
      showLanguageSelection: !widget.hasSelectedLanguage,
      showOnboarding:
          !widget.hasCompletedOnboarding && widget.hasSelectedLanguage,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

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
              routerConfig: _router,
            );
          },
        );
      },
    );
  }
}
