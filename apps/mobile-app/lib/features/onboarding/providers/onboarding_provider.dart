import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum to track onboarding state
enum OnboardingState {
  splash,
  onboarding,
  complete,
}

/// Provider to manage onboarding flow
final onboardingStateProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

/// Notifier to handle onboarding state transitions
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState.splash);

  void showOnboarding() {
    state = OnboardingState.onboarding;
  }

  void completeOnboarding() {
    state = OnboardingState.complete;
  }

  void reset() {
    state = OnboardingState.splash;
  }
}

/// Provider to check if onboarding has been completed
/// In a real app, this would read from local storage/SharedPreferences
final hasCompletedOnboardingProvider = StateProvider<bool>((ref) {
  // TODO: Replace with SharedPreferences check
  return false;
});
