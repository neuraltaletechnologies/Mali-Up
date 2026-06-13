import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routing.dart';
import '../../providers/onboarding_notifier.dart';
import 'onboarding_screen.dart';

/// Wraps the existing 4-page [OnboardingScreen] (Mali Up feature overview)
/// and navigates to the phone entry step when the user taps "Let's get started".
class IntroSlidesScreen extends ConsumerWidget {
  const IntroSlidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScreen(
      onOnboardingComplete: () {
        ref.read(onboardingNotifierProvider.notifier).advanceFromIntro();
        context.go(AppRoutes.phone);
      },
    );
  }
}
