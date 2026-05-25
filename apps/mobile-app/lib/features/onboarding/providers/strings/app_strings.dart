/// Centralized content strings for all 7 onboarding screens
/// Supports English ('en') and Swahili ('sw')
class AppStrings {
  /// Screen 1: Welcome + Language picker
  static String welcomeTitle(String language) =>
      language == 'sw' ? 'Karibu Mali Up' : 'Welcome to Mali Up';

  static String welcomeSubtitle(String language) => language == 'sw'
      ? 'Kusimamia biashara yako kwa urahisi'
      : 'Manage your business with ease';

  static String welcomeDescription(String language) => language == 'sw'
      ? 'Mali Up ni zana kamili ya kusimamia biashara yako ndogo na kati. Jadili wateja, dhamana, hazina, na mada zaidi.'
      : 'Mali Up is your complete business management platform. Track customers, inventory, finances, and more.';

  static String selectLanguage(String language) =>
      language == 'sw' ? 'Chagua lugha' : 'Select Language';

  static String english(String language) => 'English';

  static String swahili(String language) => language == 'sw' ? 'Kiswahili' : 'Swahili';

  static String continueButton(String language) =>
      language == 'sw' ? 'Endelea' : 'Continue';

  /// Screen 2: Phone number entry
  static String phoneTitle(String language) =>
      language == 'sw' ? 'Namba yako ya simu' : 'Your phone number';

  static String phoneSubtitle(String language) => language == 'sw'
      ? 'Tutatumia hii kumkumbuka kwa baadaye na kwa usalama'
      : 'We\'ll use this to verify your account';

  static String phoneLabel(String language) =>
      language == 'sw' ? 'Namba ya simu' : 'Phone Number';

  static String phonePlaceholder(String language) =>
      language == 'sw' ? '756 123 456' : '756 123 456';

  static String phoneError(String language) => language == 'sw'
      ? 'Tafadhali ingiza namba sahihi ya simu ya Tanzania'
      : 'Please enter a valid Tanzanian phone number';

  static String getOtpButton(String language) =>
      language == 'sw' ? 'Pata OTP' : 'Get OTP';

  /// Screen 3: OTP verification
  static String otpTitle(String language) =>
      language == 'sw' ? 'Thibitisha simu yako' : 'Verify your phone';

  static String otpSubtitle(String language) => language == 'sw'
      ? 'Tumetuma namba maalum kwa \$phone'
      : 'We sent a code to \$phone';

  static String otpLabel(String language) => language == 'sw' ? 'OTP' : 'OTP Code';

  static String otpPlaceholder(String language) =>
      language == 'sw' ? '000000' : '000000';

  static String otpWrongCode(String language) => language == 'sw'
      ? 'Namba si sahihi. Jaribu tena.'
      : 'Wrong code. Try again.';

  static String otpExpired(String language) => language == 'sw'
      ? 'Namba imeishia umeme. Omba nyingine.'
      : 'Code expired. Request a new one.';

  static String otpTooManyAttempts(String language) => language == 'sw'
      ? 'Jaribu mara nyingi sana. Jaribu baada ya dakika 30.'
      : 'Too many attempts. Try again in 30 seconds.';

  static String resendOtp(String language) =>
      language == 'sw' ? 'Omba nyingine' : 'Resend Code';

  static String resendCooldown(String language, int seconds) =>
      language == 'sw'
          ? 'Omba nyingine kwa \$seconds sec'
          : 'Resend in \$seconds sec';

  static String verifyButton(String language) =>
      language == 'sw' ? 'Thibitisha' : 'Verify';

  /// Screen 4A: Returning user detected
  static String returningUserTitle(String language) =>
      language == 'sw' ? 'Karibu tena!' : 'Welcome back!';

  static String returningUserMessage(String language, String businessName) =>
      language == 'sw'
          ? 'Tulikutambua! Biashara "\$businessName" ni imekutolewa.'
          : 'We found your account! Business "\$businessName" is ready.';

  static String continueWithBusiness(String language) =>
      language == 'sw' ? 'Endelea na \$businessName' : 'Continue with \$businessName';

  static String startFresh(String language) =>
      language == 'sw' ? 'Anza kwa huduma mpya' : 'Start fresh account';

  /// Screen 4B: New user personal info
  static String newUserTitle(String language) =>
      language == 'sw' ? 'Habari zako za kibinafsi' : 'Your personal details';

  static String newUserSubtitle(String language) => language == 'sw'
      ? 'Tunahitaji kujua kwamba nani unaye'
      : 'Help us get to know you better';

  static String firstNameLabel(String language) =>
      language == 'sw' ? 'Jina la kwanza' : 'First Name';

  static String firstNamePlaceholder(String language) =>
      language == 'sw' ? 'Juma' : 'John';

  static String lastNameLabel(String language) =>
      language == 'sw' ? 'Jina la pili' : 'Last Name';

  static String lastNamePlaceholder(String language) =>
      language == 'sw' ? 'Salim' : 'Doe';

  static String nameRequired(String language) => language == 'sw'
      ? 'Jina linahitajika'
      : 'Name is required';

  static String nameMinLength(String language) => language == 'sw'
      ? 'Jina lazima liwe na angalau herufi 2'
      : 'Name must be at least 2 characters';

  static String nextButton(String language) =>
      language == 'sw' ? 'Ifuatayo' : 'Next';

  /// Screen 5: Business details
  static String businessTitle(String language, String firstName) =>
      language == 'sw'
          ? 'Habari \$firstName, biashara gani tunayosimamia leo?'
          : 'Hey \$firstName, what business are we managing today?';

  static String businessSubtitle(String language) => language == 'sw'
      ? 'Tunataka kujua kuhusu kazi yako'
      : 'Tell us about your business';

  static String businessNameLabel(String language) =>
      language == 'sw' ? 'Jina la biashara' : 'Business Name';

  static String businessNamePlaceholder(String language) =>
      language == 'sw' ? 'Duka lako' : 'Your Store';

  static String businessTypeLabel(String language) =>
      language == 'sw' ? 'Aina ya biashara' : 'Business Type';

  static String businessTypeRetail(String language) =>
      language == 'sw' ? 'Duka la Rejareja' : 'Retail Store';

  static String businessTypeWholesale(String language) =>
      language == 'sw' ? 'Jumla' : 'Wholesale';

  static String businessTypeServices(String language) =>
      language == 'sw' ? 'Huduma' : 'Services';

  static String businessTypeManufacturing(String language) =>
      language == 'sw' ? 'Uzalishaji' : 'Manufacturing';

  static String businessTypeRestaurant(String language) =>
      language == 'sw' ? 'Ukahawa' : 'Restaurant/Food';

  static String businessTypeBeauty(String language) =>
      language == 'sw' ? 'Uzuri & Spa' : 'Beauty & Spa';

  static String businessTypeAgriculture(String language) =>
      language == 'sw' ? 'Kilimo' : 'Agriculture';

  static String businessTypeTransport(String language) =>
      language == 'sw' ? 'Usafiri' : 'Transport';

  static String businessTypeEducation(String language) =>
      language == 'sw' ? 'Elimu' : 'Education';

  static String businessTypeOther(String language) =>
      language == 'sw' ? 'Nyingine' : 'Other';

  static String cityLabel(String language) =>
      language == 'sw' ? 'Jiji' : 'City';

  static String cityPlaceholder(String language) =>
      language == 'sw' ? 'Dar es Salaam' : 'Dar es Salaam';

  static String businessNameRequired(String language) => language == 'sw'
      ? 'Jina la biashara linahitajika'
      : 'Business name is required';

  /// Screen 6: Password + PIN setup
  static String securityTitle(String language) =>
      language == 'sw' ? 'Usalama wa akaunti' : 'Secure your account';

  static String securitySubtitle(String language) => language == 'sw'
      ? 'Tengeneza neno la siri na PIN ya tarakimu 4'
      : 'Create a password and 4-digit PIN for quick access';

  static String passwordLabel(String language) =>
      language == 'sw' ? 'Neno la siri' : 'Password';

  static String passwordPlaceholder(String language) =>
      language == 'sw' ? 'Angalau herufi 8' : 'At least 8 characters';

  static String passwordHint(String language) => language == 'sw'
      ? 'Angalau herufi 8, kumbe namba moja'
      : 'At least 8 characters, must include 1 number';

  static String passwordWeak(String language) => language == 'sw'
      ? 'Neno la siri ni dhaifu. Kuongeza herufi na tarakimu zaidi.'
      : 'Password is weak. Add more characters and numbers.';

  static String pinLabel(String language) =>
      language == 'sw' ? 'PIN (tarakimu 4)' : 'PIN (4 digits)';

  static String pinPlaceholder(String language) =>
      language == 'sw' ? '0000' : '0000';

  static String pinHint(String language) =>
      language == 'sw'
          ? 'PIN ni kwa haraka haraka. Hakikisha kunaangalau tarakimu 4'
          : 'PIN is for quick access. Must be exactly 4 digits';

  static String confirmButton(String language) =>
      language == 'sw' ? 'Thibitisha' : 'Confirm';

  /// Screen 7: Success + Dashboard entry
  static String successTitle(String language) =>
      language == 'sw' ? 'Umefanikiwa!' : 'You\'re all set!';

  static String successMessage(String language, String businessName) =>
      language == 'sw'
          ? 'Akaunti yako kwa \$businessName imetayarisha. Tupo hapa kusaidia!'
          : 'Your account for \$businessName is ready. Let\'s get started!';

  static String successTip1(String language) => language == 'sw'
      ? '📊 Tazama muhtasari wa biashara'
      : '📊 View your business dashboard';

  static String successTip2(String language) => language == 'sw'
      ? '👥 Ongeza wateja na mandhari'
      : '👥 Add customers and inventory';

  static String successTip3(String language) => language == 'sw'
      ? '💰 Fuata malipo na hazina'
      : '💰 Track payments and finances';

  static String goToDashboard(String language) =>
      language == 'sw' ? 'Nenda kwa Dashboard' : 'Go to Dashboard';

  /// General error messages
  static String networkError(String language) => language == 'sw'
      ? 'Tatizo la mtandao. Tafadhali jaribu tena.'
      : 'Network error. Please try again.';

  static String firebaseError(String language) => language == 'sw'
      ? 'Tatizo la seva. Tafadhali jaribu tena baadaye.'
      : 'Server error. Please try again later.';

  static String savingError(String language) => language == 'sw'
      ? 'Tatizo katika kuokoa data. Jaribu tena.'
      : 'Error saving data. Please try again.';

  static String retryButton(String language) =>
      language == 'sw' ? 'Jaribu tena' : 'Try again';

  static String backButton(String language) =>
      language == 'sw' ? 'Nyuma' : 'Back';

  static String cancelButton(String language) =>
      language == 'sw' ? 'Geuza' : 'Cancel';

  /// Business types for selection dropdown
  static List<Map<String, String>> getBusinessTypes(String language) {
    return [
      {
        'value': 'retail',
        'label': businessTypeRetail(language),
      },
      {
        'value': 'wholesale',
        'label': businessTypeWholesale(language),
      },
      {
        'value': 'services',
        'label': businessTypeServices(language),
      },
      {
        'value': 'manufacturing',
        'label': businessTypeManufacturing(language),
      },
      {
        'value': 'restaurant',
        'label': businessTypeRestaurant(language),
      },
      {
        'value': 'beauty',
        'label': businessTypeBeauty(language),
      },
      {
        'value': 'agriculture',
        'label': businessTypeAgriculture(language),
      },
      {
        'value': 'transport',
        'label': businessTypeTransport(language),
      },
      {
        'value': 'education',
        'label': businessTypeEducation(language),
      },
      {
        'value': 'other',
        'label': businessTypeOther(language),
      },
    ];
  }

  /// Get all strings for a language
  static Map<String, String> getAllStrings(String language) {
    return {
      // Screen 1
      'welcome_title': welcomeTitle(language),
      'welcome_subtitle': welcomeSubtitle(language),
      'welcome_description': welcomeDescription(language),
      'select_language': selectLanguage(language),
      'english': english(language),
      'swahili': swahili(language),
      'continue_btn': continueButton(language),

      // Screen 2
      'phone_title': phoneTitle(language),
      'phone_subtitle': phoneSubtitle(language),
      'phone_label': phoneLabel(language),
      'phone_placeholder': phonePlaceholder(language),
      'phone_error': phoneError(language),
      'get_otp_btn': getOtpButton(language),

      // Screen 3
      'otp_title': otpTitle(language),
      'otp_label': otpLabel(language),
      'otp_placeholder': otpPlaceholder(language),
      'otp_wrong': otpWrongCode(language),
      'otp_expired': otpExpired(language),
      'otp_too_many': otpTooManyAttempts(language),
      'resend_otp': resendOtp(language),
      'verify_btn': verifyButton(language),

      // Screen 4A
      'returning_title': returningUserTitle(language),
      'returning_start_fresh': startFresh(language),

      // Screen 4B
      'new_user_title': newUserTitle(language),
      'new_user_subtitle': newUserSubtitle(language),
      'first_name_label': firstNameLabel(language),
      'last_name_label': lastNameLabel(language),
      'next_btn': nextButton(language),

      // Screen 5
      'business_subtitle': businessSubtitle(language),
      'business_name_label': businessNameLabel(language),
      'business_name_placeholder': businessNamePlaceholder(language),
      'business_type_label': businessTypeLabel(language),
      'city_label': cityLabel(language),
      'city_placeholder': cityPlaceholder(language),

      // Screen 6
      'security_title': securityTitle(language),
      'security_subtitle': securitySubtitle(language),
      'password_label': passwordLabel(language),
      'password_placeholder': passwordPlaceholder(language),
      'password_hint': passwordHint(language),
      'pin_label': pinLabel(language),
      'pin_placeholder': pinPlaceholder(language),
      'pin_hint': pinHint(language),
      'confirm_btn': confirmButton(language),

      // Screen 7
      'success_title': successTitle(language),
      'success_tip_1': successTip1(language),
      'success_tip_2': successTip2(language),
      'success_tip_3': successTip3(language),
      'go_dashboard_btn': goToDashboard(language),

      // Errors
      'network_error': networkError(language),
      'firebase_error': firebaseError(language),
      'saving_error': savingError(language),
      'retry_btn': retryButton(language),
      'back_btn': backButton(language),
      'cancel_btn': cancelButton(language),
    };
  }
}
