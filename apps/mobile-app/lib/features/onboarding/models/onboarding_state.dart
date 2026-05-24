import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_lookup_result.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    /// Language selection: 'en' or 'sw'
    required String language,

    /// Current screen step (1-7)
    required int currentStep,

    /// Phone number (without country code, e.g., "756123456")
    required String phone,

    /// First name of user
    required String firstName,

    /// Last name of user
    required String lastName,

    /// Business name
    required String businessName,

    /// Business type (e.g., "Retail", "Services", "Manufacturing")
    required String businessType,

    /// Password (min 8 chars, at least 1 number)
    required String password,

    /// 4-digit PIN
    required String pin,

    /// Is returning user (determined after phone lookup)
    required bool isReturningUser,

    /// Business details for returning users
    required BusinessInfo? businessInfo,

    /// OTP code entered by user
    required String otpCode,

    /// Number of OTP verification attempts
    required int otpAttempts,

    /// Whether user is in OTP cooldown period (after failed attempts)
    required bool otpInCooldown,

    /// Cooldown end timestamp (milliseconds since epoch)
    required int otpCooldownEndTime,

    /// OTP expiry timestamp (milliseconds since epoch)
    required int otpExpiryTime,

    /// Error message for OTP
    required String otpErrorMessage,

    /// User lookup result (populated after phone verification)
    required UserLookupResult? userLookupResult,

    /// General error message
    required String errorMessage,
  }) = _OnboardingState;

  const OnboardingState._();

  /// Check if OTP is in cooldown
  bool get isOtpCoolingDown =>
      otpInCooldown && DateTime.now().millisecondsSinceEpoch < otpCooldownEndTime;

  /// Check if OTP is expired
  bool get isOtpExpired =>
      DateTime.now().millisecondsSinceEpoch > otpExpiryTime;

  /// Remaining cooldown seconds
  int get otpCooldownRemaining {
    if (!isOtpCoolingDown) return 0;
    return ((otpCooldownEndTime - DateTime.now().millisecondsSinceEpoch) / 1000)
        .ceil();
  }

  /// Check if all required fields are filled for a given step
  bool isStepValid(int step) {
    switch (step) {
      case 1:
        return language.isNotEmpty;
      case 2:
        return phone.isNotEmpty;
      case 3:
        return otpCode.isNotEmpty && !isOtpExpired;
      case 4:
        if (isReturningUser) {
          return userLookupResult != null;
        } else {
          return firstName.isNotEmpty && lastName.isNotEmpty;
        }
      case 5:
        return businessName.isNotEmpty && businessType.isNotEmpty;
      case 6:
        return password.isNotEmpty && pin.isNotEmpty;
      case 7:
        return true; // Success screen
      default:
        return false;
    }
  }

  /// Factory for creating initial state
  factory OnboardingState.initial() {
    final now = DateTime.now();
    return OnboardingState(
      language: 'en',
      currentStep: 1,
      phone: '',
      firstName: '',
      lastName: '',
      businessName: '',
      businessType: '',
      password: '',
      pin: '',
      isReturningUser: false,
      businessInfo: null,
      otpCode: '',
      otpAttempts: 0,
      otpInCooldown: false,
      otpCooldownEndTime: 0,
      otpExpiryTime: now.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      otpErrorMessage: '',
      userLookupResult: null,
      errorMessage: '',
    );
  }
}

@freezed
class BusinessInfo with _$BusinessInfo {
  const factory BusinessInfo({
    required String businessId,
    required String businessName,
    required String businessType,
    required String city,
    required String? logo,
  }) = _BusinessInfo;
}
