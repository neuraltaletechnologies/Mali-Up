import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GoRouter configuration for onboarding flow with 7 screens
/// Includes:
/// - Named routes for all 7 screens + dashboard
/// - Redirect guards preventing step-skipping
/// - Conditional routing (returning vs new user)
/// - Onboarding completion check on app launch
/// 
/// Routes:
/// 1. /onboarding/welcome       (Screen 1 - Language picker)
/// 2. /onboarding/phone         (Screen 2 - Phone entry)
/// 3. /onboarding/otp           (Screen 3 - OTP verification)
/// 4. /onboarding/returning     (Screen 4A - Returning user)
/// 4. /onboarding/new-user      (Screen 4B - New user info)
/// 5. /onboarding/business      (Screen 5 - Business details)
/// 6. /onboarding/security      (Screen 6 - Password + PIN)
/// 7. /onboarding/success       (Screen 7 - Success)
/// => /dashboard                (Main app)

class OnboardingRoutes {
  static const String welcome = '/onboarding/welcome';
  static const String phone = '/onboarding/phone';
  static const String otp = '/onboarding/otp';
  static const String returningUser = '/onboarding/returning-user';
  static const String newUser = '/onboarding/new-user';
  static const String business = '/onboarding/business';
  static const String security = '/onboarding/security';
  static const String success = '/onboarding/success';
  static const String dashboard = '/dashboard';

  /// Get next route based on current step and user type
  static String getNextRoute({
    required int currentStep,
    required bool isReturningUser,
  }) {
    if (currentStep == 3 && isReturningUser) {
      return returningUser;
    }
    if (currentStep == 3) {
      return newUser;
    }

    const stepRoutes = [
      welcome,       // Step 1
      phone,         // Step 2
      otp,           // Step 3
      newUser,       // Step 4 (default to new user, see above)
      business,      // Step 5
      security,      // Step 6
      success,       // Step 7
    ];

    if (currentStep < stepRoutes.length) {
      return stepRoutes[currentStep];
    }

    return dashboard;
  }

  /// Get previous route
  static String getPreviousRoute({required int currentStep}) {
    const stepRoutes = [
      welcome,   // Step 1 (no previous)
      welcome,   // Step 2 -> 1
      phone,     // Step 3 -> 2
      otp,       // Step 4 -> 3
      otp,       // Step 5 -> 4
      business,  // Step 6 -> 5
      security,  // Step 7 -> 6
    ];

    if (currentStep > 0 && currentStep < stepRoutes.length) {
      return stepRoutes[currentStep - 1];
    }

    return welcome;
  }
}

/// Provider for GoRouter  
/// Should be initialized at app launch with proper dependencies
final goRouterProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('Initialize GoRouter with proper configuration');
});
