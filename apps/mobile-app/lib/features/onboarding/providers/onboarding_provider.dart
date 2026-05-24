import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/services/auth_service.dart';

/// Simple enum used only for high-level splash / shell routing.
/// The detailed per-screen state lives in [OnboardingState] (the class).
enum OnboardingFlowState {
  splash,
  onboarding,
  complete,
}

/// Provider for the top-level flow state (splash → onboarding → done).
final onboardingStateProvider =
    NotifierProvider<OnboardingFlowNotifier, OnboardingFlowState>(
  OnboardingFlowNotifier.new,
);

class OnboardingFlowNotifier extends Notifier<OnboardingFlowState> {
  @override
  OnboardingFlowState build() => OnboardingFlowState.onboarding;

  void showOnboarding() => state = OnboardingFlowState.onboarding;

  void completeOnboarding() => state = OnboardingFlowState.complete;

  void reset() => state = OnboardingFlowState.onboarding;
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

// ============================================
// DETAILED ONBOARDING STATE NOTIFIER
// ============================================

/// Complete onboarding state with all form fields
class OnboardingFormState {
  final String phoneNumber;
  final String verificationId;
  final String pinCode;
  final String displayName;
  final String businessName;
  final bool isLoading;
  final String? errorMessage;
  final OnboardingStep currentStep;

  OnboardingFormState({
    this.phoneNumber = '',
    this.verificationId = '',
    this.pinCode = '',
    this.displayName = '',
    this.businessName = '',
    this.isLoading = false,
    this.errorMessage,
    this.currentStep = OnboardingStep.phoneEntry,
  });

  OnboardingFormState copyWith({
    String? phoneNumber,
    String? verificationId,
    String? pinCode,
    String? displayName,
    String? businessName,
    bool? isLoading,
    String? errorMessage,
    OnboardingStep? currentStep,
  }) {
    return OnboardingFormState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      pinCode: pinCode ?? this.pinCode,
      displayName: displayName ?? this.displayName,
      businessName: businessName ?? this.businessName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Steps in the onboarding flow
enum OnboardingStep {
  phoneEntry,      // Enter phone number
  pinVerification, // Enter verification PIN
  personalInfo,    // Enter display name
  businessInfo,    // Enter business name
  complete,        // Onboarding complete
}

/// Provider for detailed onboarding form management
final onboardingFormProvider =
    NotifierProvider<OnboardingFormNotifier, OnboardingFormState>(
  OnboardingFormNotifier.new,
);

class OnboardingFormNotifier extends Notifier<OnboardingFormState> {
  late final AuthService _authService;

  @override
  OnboardingFormState build() {
    _authService = AuthService();
    return OnboardingFormState();
  }

  /// Set phone number
  void setPhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }

  /// Verify phone number - sends SMS code
  Future<bool> verifyPhoneNumber() async {
    if (state.phoneNumber.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Namba ya simu inahitajika',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: state.phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            verificationId: verificationId,
            currentStep: OnboardingStep.pinVerification,
            isLoading: false,
          );
        },
        onCodeAutoRetrieved: (verificationId, resendToken) {
          state = state.copyWith(
            verificationId: verificationId,
            currentStep: OnboardingStep.pinVerification,
            isLoading: false,
          );
        },
        onVerificationFailed: (error) {
          state = state.copyWith(
            errorMessage: error,
            isLoading: false,
          );
        },
        onCodeExpired: () {
          state = state.copyWith(
            errorMessage: 'Msimbo umeisha muda wake. Jaribu tena.',
            isLoading: false,
          );
        },
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Hitilafu: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Confirm PIN code and sign in
  Future<bool> confirmPin(String pinCode) async {
    if (pinCode.length != 6) {
      state = state.copyWith(
        errorMessage: 'Msimbo wa uhakiki ni tarakimu 6',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, pinCode: pinCode);

    try {
      final credential = await _authService.signInWithPhoneNumber(
        verificationId: state.verificationId,
        smsCode: pinCode,
      );

      if (credential.user != null) {
        state = state.copyWith(
          currentStep: OnboardingStep.personalInfo,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: 'Hitilafu katika kuhakiki. Jaribu tena.',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Msimbo si sahihi. Jaribu tena.',
        isLoading: false,
      );
      return false;
    }
  }

  /// Set display name
  void setDisplayName(String displayName) {
    state = state.copyWith(displayName: displayName);
  }

  /// Set business name
  void setBusinessName(String businessName) {
    state = state.copyWith(businessName: businessName);
  }

  /// Complete onboarding - create user profile
  Future<bool> completeOnboarding() async {
    if (state.displayName.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Jina lako linahitajika',
        isLoading: false,
      );
      return false;
    }

    if (state.businessName.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Jina la biashara lako linahitajika',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        state = state.copyWith(
          errorMessage: 'Hitilafu: Hakuna mtumiaji aliyesajiliwa',
          isLoading: false,
        );
        return false;
      }

      // Create user profile
      await _authService.createUserProfileAfterSignup(
        userId: userId,
        phoneNumber: state.phoneNumber,
        displayName: state.displayName,
        businessName: state.businessName,
      );

      state = state.copyWith(
        currentStep: OnboardingStep.complete,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Hitilafu: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Go to previous step
  void goToPreviousStep() {
    final currentStep = state.currentStep;
    OnboardingStep? previousStep;

    switch (currentStep) {
      case OnboardingStep.pinVerification:
        previousStep = OnboardingStep.phoneEntry;
        break;
      case OnboardingStep.personalInfo:
        previousStep = OnboardingStep.pinVerification;
        break;
      case OnboardingStep.businessInfo:
        previousStep = OnboardingStep.personalInfo;
        break;
      case OnboardingStep.complete:
        previousStep = OnboardingStep.businessInfo;
        break;
      case OnboardingStep.phoneEntry:
        // Cannot go back from first step
        break;
    }

    if (previousStep != null) {
      state = state.copyWith(currentStep: previousStep);
    }
  }

  /// Go to next step
  void goToNextStep() {
    final currentStep = state.currentStep;
    OnboardingStep? nextStep;

    switch (currentStep) {
      case OnboardingStep.phoneEntry:
        // Validation happens in verifyPhoneNumber
        break;
      case OnboardingStep.pinVerification:
        // Validation happens in confirmPin
        break;
      case OnboardingStep.personalInfo:
        if (state.displayName.isNotEmpty) {
          nextStep = OnboardingStep.businessInfo;
        }
        break;
      case OnboardingStep.businessInfo:
        // Validation happens in completeOnboarding
        break;
      case OnboardingStep.complete:
        // No next step
        break;
    }

    if (nextStep != null) {
      state = state.copyWith(currentStep: nextStep);
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith();
  }

  /// Reset the entire onboarding form
  void reset() {
    state = OnboardingFormState();
  }

  /// Get current step number (1-5)
  int get currentStepNumber {
    switch (state.currentStep) {
      case OnboardingStep.phoneEntry:
        return 1;
      case OnboardingStep.pinVerification:
        return 2;
      case OnboardingStep.personalInfo:
        return 3;
      case OnboardingStep.businessInfo:
        return 4;
      case OnboardingStep.complete:
        return 5;
    }
  }

  /// Get total number of steps
  int get totalSteps => 5;

  /// Get progress percentage (0.0 to 1.0)
  double get progress => currentStepNumber / totalSteps;
}

// ============================================
// SWAHILI UI STRINGS FOR ONBOARDING
// ============================================

/// Swahili strings for the onboarding UI
class OnboardingStrings {
  // Step titles
  static const String step1Title = 'Ingiza Namba ya Simu';
  static const String step1Subtitle = 'Tutakutumia msimbo wa uhakiki kupitia SMS';
  
  static const String step2Title = 'Ingiza Msimbo wa Uhakiki';
  static const String step2Subtitle = 'Tumekutumia msimbo wa tarakimu 6';
  
  static const String step3Title = 'Habari! Unaitwa Nani?';
  static const String step3Subtitle = 'Tafadhali ingiza jina lako kamili';
  
  static const String step4Title = 'Jina la Biashara Yako';
  static const String step4Subtitle = 'Hii itasaidia kutofautisha akaunti yako';
  
  static const String step5Title = 'Karibu Mali Up!';
  static const String step5Subtitle = 'Akaunti yako imeandaliwa. Hebu tuanze!';

  // Button labels
  static const String sendCodeButton = 'Tuma Msimbo';
  static const String verifyCodeButton = 'Hakiki Msimbo';
  static const String resendCodeButton = 'Tuma Msimbo Mpya';
  static const String continueButton = 'Endelea';
  static const String completeButton = 'Anza Sasa';
  static const String backButton = 'Rudi Nyuma';

  // Field labels
  static const String phoneNumberLabel = 'Namba ya Simu';
  static const String phoneNumberHint = 'Mfano: 0712345678';
  static const String pinCodeLabel = 'Msimbo wa Uhakiki';
  static const String pinCodeHint = 'Ingiza tarakimu 6';
  static const String displayNameLabel = 'Jina Lako Kamili';
  static const String displayNameHint = 'Jina lako la kwanza na la mwisho';
  static const String businessNameLabel = 'Jina la Biashara';
  static const String businessNameHint = 'Jina la duka au kampuni yako';

  // Error messages
  static const String phoneRequiredError = 'Namba ya simu inahitajika';
  static const String phoneInvalidError = 'Namba ya simu si sahihi';
  static const String pinRequiredError = 'Msimbo wa uhakiki unahitajika';
  static const String pinInvalidError = 'Msimbo ni tarakimu 6';
  static const String nameRequiredError = 'Jina linahitajika';
  static const String businessNameRequiredError = 'Jina la biashara linahitajika';
  static const String genericError = 'Hitilafu imetokea. Jaribu tena.';

  // Success messages
  static const String codeSentSuccess = 'Msimbo umetumwa kikamilifu';
  static const String verificationSuccess = 'Uhakiki umekamilika';
  static const String profileCreatedSuccess = 'Akaunti imeundwa kikamilifu';

  // Helper text
  static const String phoneHelperText = 'Tunatumia namba yako ya simu kwa ajili ya usalama';
  static const String pinHelperText = 'Hujapata msimbo? Angalia SMS yako';
  static const String resendTimerText = 'Tuma msimbo mpya baada ya';
}