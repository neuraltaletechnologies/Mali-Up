import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mali_up/config/routing.dart';
import 'package:mali_up/core/theme/app_theme.dart';
import 'firebase_options.dart';

const String _onboardingCompletedKey = 'onboarding_completed';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with the provided options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      prefs.getBool(_onboardingCompletedKey) ?? false;

  runApp(
    ProviderScope(
      child: MaliUpApp(hasCompletedOnboarding: hasCompletedOnboarding),
    ),
  );
}

class MaliUpApp extends StatelessWidget {
  final bool hasCompletedOnboarding;

  const MaliUpApp({
    super.key,
    required this.hasCompletedOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mali Up',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.createRouter(
        showOnboarding: !hasCompletedOnboarding,
      ),
    );
  }
}

