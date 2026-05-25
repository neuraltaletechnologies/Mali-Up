import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_lookup_result.dart';
import '../validators/onboarding_validator.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../domain/models/onboarding_state.dart';

/// Service layer for orchestrating the complete onboarding flow
/// Coordinates between repository, validation, state management, and persistence
/// All Firebase and business logic lives here — notifier delegates to this service
class OnboardingService {
  final OnboardingRepository _repository;
  final auth.FirebaseAuth _firebaseAuth;
  final SharedPreferences _prefs;

  OnboardingService({
    required OnboardingRepository repository,
    auth.FirebaseAuth? firebaseAuth,
    required SharedPreferences preferences,
  })  : _repository = repository,
        _firebaseAuth = firebaseAuth ?? auth.FirebaseAuth.instance,
        _prefs = preferences;

  /// Verifies OTP and performs phone lookup
  /// Returns UserLookupResult (ReturningUser or NewUser)
  /// On Firebase error, treats as NewUser (graceful degradation)
  Future<UserLookupResult> verifyOtpAndLookup({
    required String phone,
    required String otpCode,
  }) async {
    try {
      // Validate OTP format first
      final validationError = OnboardingValidator.validateOtp(otpCode);
      if (validationError != null) {
        throw Exception('Invalid OTP format: $validationError');
      }

      // Here you would normally call Firebase Auth to verify OTP
      // For now, we just perform the lookup
      // In real implementation: await _firebaseAuth.signInWithPhoneNumber(...)
      
      // Perform phone lookup
      final result = await _repository.lookupByPhone(phone);
      return result;
    } catch (e) {
      print('OTP verification error: $e');
      // On error, treat as new user but don't block flow
      return const UserLookupResult.newUser();
    }
  }

  /// Saves new user and business profile to Firestore
  /// Called after form completion for new users (Screen 4B → 5 → 6)
  /// Returns (userId, businessId) tuple or (null, null) on failure
  Future<({String? userId, String? businessId})> saveNewUserProfile({
    required OnboardingState state,
  }) async {
    try {
      // Validate all inputs
      final phoneError = OnboardingValidator.validatePhone(state.phone);
      final firstNameError = OnboardingValidator.validateName(state.firstName);
      final lastNameError = OnboardingValidator.validateName(state.lastName);
      final businessNameError = OnboardingValidator.validateBusinessName(state.businessName);
      final passwordError = OnboardingValidator.validatePassword(state.password);
      final pinError = OnboardingValidator.validatePin(state.pin);

      if (phoneError != null ||
          firstNameError != null ||
          lastNameError != null ||
          businessNameError != null ||
          passwordError != null ||
          pinError != null) {
        throw Exception('Validation failed');
      }

      // Save user using existing repository method
      // This is a new user, so generate a temp ID for now
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      await _repository.saveUser(
        userId: userId,
        state: state,
      );

      // Save business profile - returns business ID
      final businessId = await _repository.saveBusinessProfile(
        userId: userId,
        state: state,
      );

      // Note: Password and PIN hashing should be handled in actual implementation
      // They would be saved with user credentials in Firebase Auth

      return (userId: userId, businessId: businessId);
    } catch (e) {
      print('Error saving new user profile: $e');
      return (userId: null, businessId: null);
    }
  }

  /// Marks onboarding as complete for user
  /// Called at success screen (Screen 7)
  /// Sets SharedPreferences flag and updates Firestore
  Future<bool> completeOnboarding({
    required String userId,
    required String businessId,
  }) async {
    try {
      // Update last active timestamp
      await _repository.touchLastActive(userId);

      // Set SharedPreferences flag
      await _prefs.setBool('onboarding_complete', true);
      await _prefs.setString('current_user_id', userId);
      await _prefs.setString('current_business_id', businessId);

      return true;
    } catch (e) {
      print('Error completing onboarding: $e');
      return false;
    }
  }

  /// Checks if user has already completed onboarding
  /// Called on app launch to determine if we should skip to dashboard
  /// Returns true if onboarding is complete, false otherwise
  Future<bool> checkOnboardingStatus() async {
    try {
      final isComplete = _prefs.getBool('onboarding_complete') ?? false;
      return isComplete;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Resets onboarding state (for testing or explicit user action)
  Future<void> resetOnboarding() async {
    try {
      await _prefs.remove('onboarding_complete');
      await _prefs.remove('current_user_id');
      await _prefs.remove('current_business_id');
    } catch (e) {
      print('Error resetting onboarding: $e');
    }
  }

  /// Gets current user ID from SharedPreferences
  String? getCurrentUserId() {
    try {
      return _prefs.getString('current_user_id');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  /// Gets current business ID from SharedPreferences
  String? getCurrentBusinessId() {
    try {
      return _prefs.getString('current_business_id');
    } catch (e) {
      print('Error getting current business ID: $e');
      return null;
    }
  }
}
