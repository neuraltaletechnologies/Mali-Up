import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum to track onboarding state
enum OnboardingState {
  splash,
  onboarding,
  complete,
}

/// Provider to manage onboarding flow
final onboardingStateProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => OnboardingState.splash;

  void showOnboarding() => state = OnboardingState.onboarding;

  void completeOnboarding() => state = OnboardingState.complete;

  void reset() => state = OnboardingState.splash;
}

/// Provider to check if onboarding has been completed
/// In a real app, this would read from local storage/SharedPreferences
final hasCompletedOnboardingProvider =
    NotifierProvider<HasCompletedOnboardingNotifier, bool>(
  HasCompletedOnboardingNotifier.new,
);

class HasCompletedOnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setCompleted(bool value) => state = value;
}
