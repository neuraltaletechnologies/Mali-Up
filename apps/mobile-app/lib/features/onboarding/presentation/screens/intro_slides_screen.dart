import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routing.dart';
import 'onboarding_screen.dart';

/// Wraps the existing 4-page [OnboardingScreen] (Mali Up feature overview)
/// and navigates to the phone entry step when the user taps "Let's get started".
class IntroSlidesScreen extends StatelessWidget {
  const IntroSlidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      onOnboardingComplete: () => context.go(AppRoutes.phone),
    );
  }
}
