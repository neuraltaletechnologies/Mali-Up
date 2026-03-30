import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import '../../providers/onboarding_provider.dart';

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

    if (onboardingState == OnboardingState.splash) {
      return SplashScreen(
        onSplashComplete: () {
          ref.read(onboardingStateProvider.notifier).showOnboarding();
        },
      );
    }

    if (onboardingState == OnboardingState.onboarding) {
      return OnboardingScreen(
        onOnboardingComplete: () {
          ref.read(onboardingStateProvider.notifier).completeOnboarding();
          ref
              .read(hasCompletedOnboardingProvider.notifier)
              .setCompleted(true);
          onComplete();
        },
      );
    }

    // This shouldn't be reached due to onComplete callback.
    return const SizedBox.shrink();
  }
}
