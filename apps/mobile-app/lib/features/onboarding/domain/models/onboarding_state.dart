// Immutable state for the 7-screen onboarding flow.
//
// Written as a hand-rolled copyWith class so it compiles without build_runner.
// To migrate to code generation later:
//   1. Add freezed_annotation + freezed + build_runner to pubspec.yaml
//   2. Annotate with @freezed and add the part directive
//   3. Run: flutter pub run build_runner build --delete-conflicting-outputs

import '../../../../core/services/localization_service.dart';

// ─── STEP ENUM ────────────────────────────────────────────────────────────────

/// Each value maps to one screen in the 7-step flow.
/// The [stepIndex] drives the GoRouter redirect guard — a user cannot jump
/// ahead of the step they have legitimately reached.
enum OnboardingStep {
  welcome(0),        // Screen 1 — welcome + language picker
  phoneEntry(1),     // Screen 2 — phone number entry
  otpVerify(2),      // Screen 3 — OTP verification
  returningUser(3),  // Screen 4A — returning user detected
  newUserInfo(3),    // Screen 4B — new user personal info (same guard index as 4A)
  businessDetails(4),// Screen 5 — business details + personalised greeting
  passwordPin(5),    // Screen 6 — password + 4-digit PIN
  success(6);        // Screen 7 — success + dashboard entry

  const OnboardingStep(this.stepIndex);

  /// Minimum completed-step count needed to reach this screen.
  final int stepIndex;
}

// ─── STATE ────────────────────────────────────────────────────────────────────

class OnboardingState {
  const OnboardingState({
    // Screen 1 — Language
    this.currentStep = OnboardingStep.welcome,
    this.language = AppLanguage.english,

    // Screen 2 — Phone
    this.phone = '',
    this.verificationId = '',
    this.resendToken,

    // Screen 3 — OTP
    this.otpAttempts = 0,
    this.isOtpLocked = false,
    this.resendCooldownSeconds = 0,

    // Screen 4A/4B — User detection
    this.isReturningUser = false,
    this.existingUserId = '',

    // Screen 4B — Personal info
    this.firstName = '',
    this.lastName = '',
    this.city = '',
    this.role = '',

    // Screen 5 — Business details
    this.businessName = '',
    this.businessType = '',
    this.businessId = '',

    // Screen 6 — Security
    this.password = '',
    this.pin = '',

    // Async / UI
    this.isLoading = false,
    this.errorMessage,

    // Flow completion
    this.isComplete = false,
  });

  // ── Screen 1 ──────────────────────────────────────────────────────────────
  final OnboardingStep currentStep;
  final AppLanguage language;

  // ── Screen 2 ──────────────────────────────────────────────────────────────
  final String phone;
  final String verificationId;
  final int? resendToken;

  // ── Screen 3 ──────────────────────────────────────────────────────────────
  final int otpAttempts;
  final bool isOtpLocked;

  /// Seconds remaining before the resend button becomes active (0 = ready).
  final int resendCooldownSeconds;

  // ── Screen 4A/4B ──────────────────────────────────────────────────────────
  final bool isReturningUser;
  final String existingUserId;

  // ── Screen 4B ─────────────────────────────────────────────────────────────
  final String firstName;
  final String lastName;

  /// Used in both `users` and `businesses` Firestore documents.
  final String city;

  /// E.g. "Owner", "Manager" — stored as `role` in Firestore.
  final String role;

  // ── Screen 5 ──────────────────────────────────────────────────────────────
  final String businessName;
  final String businessType;

  /// Populated after [OnboardingService.saveBusinessProfile] returns.
  final String businessId;

  // ── Screen 6 ──────────────────────────────────────────────────────────────
  final String password;
  final String pin;

  // ── Async / UI ────────────────────────────────────────────────────────────
  final bool isLoading;
  final String? errorMessage;

  // ── Flow state ────────────────────────────────────────────────────────────
  final bool isComplete;

  // ─── DERIVED ──────────────────────────────────────────────────────────────

  bool get isSwahili => language == AppLanguage.swahili;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  /// Progress fraction 0.0–1.0 for linear progress indicators (capped at step 5).
  double get progressFraction =>
      (currentStep.stepIndex.clamp(0, 5) / 5.0);

  /// "Step 2 of 6" — used in screen headers.
  String get stepLabel =>
      'Step ${(currentStep.stepIndex + 1).clamp(1, 6)} of 6';

  // ─── copyWith ─────────────────────────────────────────────────────────────

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    AppLanguage? language,
    String? phone,
    String? verificationId,
    int? resendToken,
    int? otpAttempts,
    bool? isOtpLocked,
    int? resendCooldownSeconds,
    bool? isReturningUser,
    String? existingUserId,
    String? firstName,
    String? lastName,
    String? city,
    String? role,
    String? businessName,
    String? businessType,
    String? businessId,
    String? password,
    String? pin,
    bool? isLoading,
    // Use clearError: true to set errorMessage to null.
    String? errorMessage,
    bool clearError = false,
    bool? isComplete,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      language: language ?? this.language,
      phone: phone ?? this.phone,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      otpAttempts: otpAttempts ?? this.otpAttempts,
      isOtpLocked: isOtpLocked ?? this.isOtpLocked,
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
      isReturningUser: isReturningUser ?? this.isReturningUser,
      existingUserId: existingUserId ?? this.existingUserId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      city: city ?? this.city,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      businessId: businessId ?? this.businessId,
      password: password ?? this.password,
      pin: pin ?? this.pin,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingState &&
        other.currentStep == currentStep &&
        other.language == language &&
        other.phone == phone &&
        other.verificationId == verificationId &&
        other.otpAttempts == otpAttempts &&
        other.isOtpLocked == isOtpLocked &&
        other.resendCooldownSeconds == resendCooldownSeconds &&
        other.isReturningUser == isReturningUser &&
        other.existingUserId == existingUserId &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.city == city &&
        other.role == role &&
        other.businessName == businessName &&
        other.businessType == businessType &&
        other.businessId == businessId &&
        other.password == password &&
        other.pin == pin &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode => Object.hashAll([
        currentStep, language, phone, verificationId,
        otpAttempts, isOtpLocked, resendCooldownSeconds,
        isReturningUser, existingUserId,
        firstName, lastName, city, role,
        businessName, businessType, businessId,
        password, pin, isLoading, errorMessage, isComplete,
      ]);
}
