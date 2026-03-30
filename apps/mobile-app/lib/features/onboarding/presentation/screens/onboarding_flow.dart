import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import '../providers/onboarding_provider.dart';

/// Main container that manages the onboarding flow
/// Displays splash screen followed by onboarding screens
class OnboardingFlow extends ConsumerWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingStateProvider);

    return switch (onboardingState) {
      OnboardingState.splash =>
        SplashScreen(
          onSplashComplete: () {
            ref.read(onboardingStateProvider.notifier).showOnboarding();
          },
        ),
      OnboardingState.onboarding =>
        OnboardingScreen(
          onOnboardingComplete: () {
            ref.read(onboardingStateProvider.notifier).completeOnboarding();
            ref.read(hasCompletedOnboardingProvider.notifier).state = true;
            onComplete();
          },
        ),
      OnboardingState.complete =>
        // This shouldn't be reached due to onComplete callback
        const SizedBox.shrink(),
    };
  }
}
