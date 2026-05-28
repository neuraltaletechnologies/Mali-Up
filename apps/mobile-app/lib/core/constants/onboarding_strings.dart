/// Complete bilingual content for the 7-screen Mali Up onboarding flow.
///
/// Every screen section is grouped with a clear header comment.
/// Use the [s] helper to pick English or Swahili at call-site:
///
/// ```dart
/// Text(OnboardingStrings.s(state.isSwahili,
///   en: OnboardingStrings.phoneTitleEn,
///   sw: OnboardingStrings.phoneTitleSw))
/// ```
///
/// String methods that accept a parameter (e.g. name substitution) are
/// static functions rather than constants.
abstract final class OnboardingStrings {
  // ─── HELPER ──────────────────────────────────────────────────────────────

  /// Returns [sw] when [isSwahili] is true, otherwise [en].
  static String s(bool isSwahili, {required String en, required String sw}) =>
      isSwahili ? sw : en;

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 1 — WELCOME + LANGUAGE PICKER
  // ═══════════════════════════════════════════════════════════════════════════

  static const welcomeTaglineEn = 'Your business, your control.';
  static const welcomeTaglineSw = 'Biashara yako, mamlaka yako.';

  static const welcomeBodyEn =
      'Built for African entrepreneurs who mean business.';
  static const welcomeBodySw =
      'Imeundwa kwa wajasiriamali wa Afrika wanaojua biashara.';

  static const chooseLangPromptEn = 'Choose your language to get started:';
  static const chooseLangPromptSw = 'Chagua lugha yako ili uanze:';

  static const langEnglishLabelEn = 'English';
  static const langEnglishLabelSw = 'Kiingereza';

  static const langSwahiliLabelEn = 'Kiswahili';
  static const langSwahiliLabelSw = 'Kiswahili';

  static const welcomeCtaEn = 'Get Started';
  static const welcomeCtaSw = 'Anza';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 2 — PHONE NUMBER ENTRY
  // ═══════════════════════════════════════════════════════════════════════════

  static const phoneTitleEn = "What's your phone number?";
  static const phoneTitleSw = 'Namba yako ya simu ni ipi?';

  static const phoneSubEn = 'Enter your phone number to get started.';
  static const phoneSubSw = 'Weka namba yako ya simu ili uanze.';

  static const phoneLabelEn = 'Phone number';
  static const phoneLabelSw = 'Namba ya simu';

  static const phoneHintEn = '07XX XXX XXX';
  static const phoneHintSw = '07XX XXX XXX';

  static const phoneCountryChipEn = '+255  Tanzania';
  static const phoneCountryChipSw = '+255  Tanzania';

  static const phoneHelperEn = 'Your number is kept private and secure.';
  static const phoneHelperSw = 'Namba yako inabaki siri na salama.';

  static const phoneSendCtaEn = 'Continue';
  static const phoneSendCtaSw = 'Endelea';

  // Errors
  static const phoneRequiredEn = 'Phone number is required.';
  static const phoneRequiredSw = 'Namba ya simu inahitajika.';

  static const phoneInvalidEn =
      'Enter a valid Tanzania number (+255 or 07/06 followed by 8 digits).';
  static const phoneInvalidSw =
      'Ingiza namba sahihi ya Tanzania (+255 au 07/06 ikifuatiwa na tarakimu 8).';

  static const phoneSendFailedEn =
      'Could not send code. Check your connection and try again.';
  static const phoneSendFailedSw =
      'Imeshindwa kutuma msimbo. Angalia muunganiko na ujaribu tena.';

  static const phoneTooManyRequestsEn =
      'Too many requests. Please wait a moment and try again.';
  static const phoneTooManyRequestsSw =
      'Maombi mengi sana. Subiri kidogo kisha ujaribu tena.';

  static const phoneInvalidNumberEn =
      'Invalid phone number. Please check and try again.';
  static const phoneInvalidNumberSw =
      'Namba ya simu si sahihi. Angalia na ujaribu tena.';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 3 — OTP VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  static const otpTitleEn = 'Enter the code we sent you';
  static const otpTitleSw = 'Ingiza msimbo tuliotuma';

  /// [phone] — the masked or full phone number displayed to the user.
  static String otpSubEn(String phone) =>
      'A 6-digit code was sent to $phone.';
  static String otpSubSw(String phone) =>
      'Msimbo wa tarakimu 6 umetumwa kwa $phone.';

  static const otpFieldLabelEn = 'Verification code';
  static const otpFieldLabelSw = 'Msimbo wa uhakiki';

  static const otpVerifyCtaEn = 'Verify';
  static const otpVerifyCtaSw = 'Hakiki';

  static const otpResendLinkEn = 'Resend code';
  static const otpResendLinkSw = 'Tuma msimbo mpya';

  /// [seconds] — remaining cooldown displayed on the resend button.
  static String otpResendCooldownEn(int seconds) => 'Resend in ${seconds}s';
  static String otpResendCooldownSw(int seconds) =>
      'Tuma tena baada ya ${seconds}s';

  // Error states
  static const otpWrongCodeEn =
      'Incorrect code. Please check and try again.';
  static const otpWrongCodeSw =
      'Msimbo si sahihi. Angalia na ujaribu tena.';

  static const otpExpiredEn =
      'Code has expired. Tap "Resend" to get a fresh one.';
  static const otpExpiredSw =
      'Msimbo umeisha muda wake. Bonyeza "Tuma Upya" kupata mpya.';

  static const otpLockedEn =
      'Too many attempts. Tap "Resend" to request a new code.';
  static const otpLockedSw =
      'Majaribio mengi mno. Bonyeza "Tuma Upya" kuomba msimbo mpya.';

  static const otpGeneralFailEn =
      'Verification failed. Please try again.';
  static const otpGeneralFailSw =
      'Uhakiki umeshindwa. Tafadhali jaribu tena.';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 4A — PIN LOGIN (existing owner / activated team member)
  // ═══════════════════════════════════════════════════════════════════════════

  /// [name] — first name of the user.
  static String pinLoginGreetEn(String name) => 'Welcome back, $name!';
  static String pinLoginGreetSw(String name) => 'Karibu tena, $name!';

  static const pinLoginSubEn = 'Enter your 4-digit PIN to sign in.';
  static const pinLoginSubSw = 'Weka PIN yako ya tarakimu 4 ili uingie.';

  static const pinLoginFieldLabelEn = 'Your PIN';
  static const pinLoginFieldLabelSw = 'PIN yako';

  static const pinLoginCtaEn = 'Sign In';
  static const pinLoginCtaSw = 'Ingia';

  static const pinLoginWrongEn = 'Incorrect PIN. Please try again.';
  static const pinLoginWrongSw = 'PIN si sahihi. Tafadhali jaribu tena.';

  static const pinLoginForgotEn = 'Forgot your PIN? Contact support.';
  static const pinLoginForgotSw = 'Umesahau PIN? Wasiliana na msaada.';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 4B — TEAM MEMBER FIRST-TIME SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// [name] — first name of the team member.
  static String teamGreetEn(String name) => 'Hi $name, your account is ready!';
  static String teamGreetSw(String name) => 'Habari $name, akaunti yako iko tayari!';

  static const teamSubEn =
      'Your employer has added you. Set a PIN to activate your account.';
  static const teamSubSw =
      'Mwajiri wako amekuongeza. Weka PIN ili uwashe akaunti yako.';

  static const teamBusinessLabelEn = 'You have been added to:';
  static const teamBusinessLabelSw = 'Umeongezwa kwenye:';

  static const teamRoleLabelEn = 'Your role:';
  static const teamRoleLabelSw = 'Nafsi yako:';

  static const teamContinueCtaEn = 'Set Up My PIN';
  static const teamContinueCtaSw = 'Weka PIN Yangu';

  static const teamStartOverCtaEn = "That's not me — register instead";
  static const teamStartOverCtaSw = 'Hiyo si mimi — jisajili badala yake';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 6 — PIN SETUP (replaces password + PIN screen)
  // ═══════════════════════════════════════════════════════════════════════════

  static const pinSetupTitleEn = 'Set your PIN';
  static const pinSetupTitleSw = 'Weka PIN yako';

  static const pinSetupSubEn =
      'Choose a 4-digit PIN you will remember. Keep it private.';
  static const pinSetupSubSw =
      'Chagua PIN ya tarakimu 4 utakayoikumbuka. Isimwambie mtu.';

  static const pinSetupEnterLabelEn = 'Create PIN';
  static const pinSetupEnterLabelSw = 'Tengeneza PIN';

  static const pinSetupConfirmLabelEn = 'Confirm PIN';
  static const pinSetupConfirmLabelSw = 'Thibitisha PIN';

  static const pinSetupMismatchEn = 'PINs do not match. Please try again.';
  static const pinSetupMismatchSw = 'PIN hazilingani. Tafadhali jaribu tena.';

  static const pinSetupCtaEn = 'Create Account';
  static const pinSetupCtaSw = 'Tengeneza Akaunti';

  static const pinSetupSavingEn = 'Setting up your workspace…';
  static const pinSetupSavingSw = 'Inaandaa eneo lako la kazi…';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 4A — RETURNING USER DETECTED (legacy — kept for reference)
  // ═══════════════════════════════════════════════════════════════════════════

  /// [name] — first name of the returning user.
  static String returningGreetEn(String name) => 'Welcome back, $name!';
  static String returningGreetSw(String name) => 'Karibu tena, $name!';

  static const returningFoundEn = 'We found your account.';
  static const returningFoundSw = 'Tumepata akaunti yako.';

  static const returningBusinessLabelEn = 'Your saved business:';
  static const returningBusinessLabelSw = 'Biashara yako iliyohifadhiwa:';

  static const returningInfoNoteEn =
      'All your data — sales, inventory, customers — is waiting for you.';
  static const returningInfoNoteSw =
      'Data yako yote — mauzo, stoo, wateja — inakungoja.';

  static const returningContinueCtaEn = 'Continue as this account';
  static const returningContinueCtaSw = 'Endelea na akaunti hii';

  static const returningStartOverCtaEn = "That's not me — start fresh";
  static const returningStartOverCtaSw = 'Hiyo si mimi — anza upya';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 4B — NEW USER PERSONAL INFO
  // ═══════════════════════════════════════════════════════════════════════════

  static const newUserTitleEn = 'Tell us about yourself';
  static const newUserTitleSw = 'Tuambie kuhusu wewe';

  static const newUserSubEn =
      'This helps us personalise your Mali Up experience.';
  static const newUserSubSw =
      'Hii itatusaidia kukufanyia mipangilio inayokufaa kwenye Mali Up.';

  static const firstNameLabelEn = 'First name';
  static const firstNameLabelSw = 'Jina la kwanza';

  static const firstNameHintEn = 'e.g. Amina';
  static const firstNameHintSw = 'mfano Amina';

  static const lastNameLabelEn = 'Last name';
  static const lastNameLabelSw = 'Jina la ukoo';

  static const lastNameHintEn = 'e.g. Njoroge';
  static const lastNameHintSw = 'mfano Njoroge';

  static const cityLabelEn = 'City';
  static const cityLabelSw = 'Mji';

  static const cityHintEn = 'e.g. Dar es Salaam';
  static const cityHintSw = 'mfano Dar es Salaam';

  static const roleLabelEn = 'Your role';
  static const roleLabelSw = 'Nafsi yako katika biashara';

  static const roleHintEn = 'e.g. Owner, Manager, Cashier';
  static const roleHintSw = 'mfano Mmiliki, Meneja, Kashe';

  static const newUserCtaEn = 'Continue';
  static const newUserCtaSw = 'Endelea';

  // Errors
  static const nameRequiredEn = 'Name is required.';
  static const nameRequiredSw = 'Jina linahitajika.';

  static const nameTooShortEn = 'Name must be at least 2 characters.';
  static const nameTooShortSw = 'Jina lazima liwe na angalau herufi 2.';

  static const nameNoNumbersEn = 'Name must not contain numbers.';
  static const nameNoNumbersSw = 'Jina halitakiwi kuwa na nambari.';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 5 — BUSINESS DETAILS (PERSONALISED GREETING)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Personalised greeting shown at the top of Screen 5.
  /// [firstName] — user's first name from Screen 4B.
  static String bizGreetEn(String firstName) =>
      'Hellow $firstName';
  static String bizGreetSw(String firstName) =>
      'Habari $firstName';

  static const bizSubEn =
      'What business are we managing today?';
  static const bizSubSw =
      'Tunasimamia biashara gani leo?';

  static const bizNameLabelEn = 'Business name';
  static const bizNameLabelSw = 'Jina la biashara';

  static const bizNameHintEn = "e.g. Mama Lucy's Shop";
  static const bizNameHintSw = 'mfano Duka la Mama Lucy';

  static const bizTypeLabelEn = 'What type of business?';
  static const bizTypeLabelSw = 'Biashara ya aina gani?';

  static const bizTypeSelectPromptEn = 'Select business type';
  static const bizTypeSelectPromptSw = 'Chagua aina ya biashara';

  static const bizCtaEn = 'Next';
  static const bizCtaSw = 'Ifuatayo';

  // Errors
  static const bizNameRequiredEn = 'Business name is required.';
  static const bizNameRequiredSw = 'Jina la biashara linahitajika.';

  static const bizNameTooShortEn = 'Business name must be at least 2 characters.';
  static const bizNameTooShortSw =
      'Jina la biashara lazima liwe na angalau herufi 2.';

  static const bizTypeRequiredEn = 'Please select a business type.';
  static const bizTypeRequiredSw = 'Tafadhali chagua aina ya biashara.';

  // ── Business type labels ───────────────────────────────────────────────────
  //
  // Key = Firestore businessType value (snake_case).
  // Value = (en, sw) display labels for the dropdown.

  static const Map<String, ({String en, String sw})> businessTypes = {
    'retail':          (en: 'Retail Shop',               sw: 'Duka la Rejareja'),
    'wholesale':       (en: 'Wholesale',                  sw: 'Jumla'),
    'food_beverages':  (en: 'Food & Beverages',           sw: 'Chakula na Vinywaji'),
    'restaurant':      (en: 'Restaurant / Café',          sw: 'Mkahawa / Café'),
    'salon':           (en: 'Salon & Beauty',             sw: 'Saluni na Urembo'),
    'tailoring':       (en: 'Tailoring & Fashion',        sw: 'Ushonaji na Mitindo'),
    'electronics':     (en: 'Electronics',                sw: 'Vifaa vya Elektroniki'),
    'hardware':        (en: 'Hardware & Building',        sw: 'Vifaa vya Ujenzi'),
    'pharmacy':        (en: 'Pharmacy',                   sw: 'Duka la Dawa'),
    'agriculture':     (en: 'Agriculture & Farming',      sw: 'Kilimo na Ufugaji'),
    'transport':       (en: 'Transport & Logistics',      sw: 'Usafirishaji na Usambazaji'),
    'health':          (en: 'Health & Wellness',          sw: 'Afya na Ustawi'),
    'education':       (en: 'Education & Training',       sw: 'Elimu na Mafunzo'),
    'construction':    (en: 'Construction',               sw: 'Ujenzi'),
    'real_estate':     (en: 'Real Estate',                sw: 'Mali Isiyohamishika'),
    'printing':        (en: 'Printing & Branding',        sw: 'Uchapishaji na Utengenezaji Chapa'),
    'cleaning':        (en: 'Cleaning Services',          sw: 'Huduma za Usafi'),
    'tech_services':   (en: 'IT & Tech Services',         sw: 'Huduma za TEHAMA'),
    'events':          (en: 'Events & Entertainment',     sw: 'Matukio na Burudani'),
    'freelance':       (en: 'Freelancing',                sw: 'Kazi za Mkataba'),
    'consultancy':     (en: 'Consultancy',                sw: 'Ushauri wa Kitaalamu'),
    'banking_finance': (en: 'Banking & Finance',          sw: 'Benki na Fedha'),
    'insurance':       (en: 'Insurance',                  sw: 'Bima'),
    'mobile_money':    (en: 'Mobile Money Agent',         sw: 'Wakala wa Pesa za Simu'),
    'photography':     (en: 'Photography & Video',        sw: 'Upigaji Picha na Video'),
    'media':           (en: 'Media & Marketing',          sw: 'Habari na Masoko'),
    'legal':           (en: 'Legal Services',             sw: 'Huduma za Kisheria'),
    'security_guard':  (en: 'Security Services',          sw: 'Huduma za Usalama'),
    'travel':          (en: 'Travel & Tourism',           sw: 'Usafiri na Utalii'),
    'other':           (en: 'Other',                      sw: 'Nyingine'),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 6 — PASSWORD + 4-DIGIT PIN
  // ═══════════════════════════════════════════════════════════════════════════

  static const securityTitleEn = 'Secure your account';
  static const securityTitleSw = 'Linda akaunti yako';

  static const securitySubEn =
      'Create a password and a 4-digit PIN for quick access.';
  static const securitySubSw =
      'Tengeneza nywila na PIN ya tarakimu 4 kwa ufikiaji wa haraka.';

  static const passwordLabelEn = 'Password';
  static const passwordLabelSw = 'Nywila';

  static const passwordHintEn = 'At least 8 characters including one number';
  static const passwordHintSw = 'Angalau herufi 8 ikijumuisha nambari moja';

  static const passwordToggleShowEn = 'Show';
  static const passwordToggleShowSw = 'Onyesha';

  static const passwordToggleHideEn = 'Hide';
  static const passwordToggleHideSw = 'Ficha';

  static const pinLabelEn = '4-digit PIN';
  static const pinLabelSw = 'PIN ya tarakimu 4';

  static const pinHintEn = 'Used for quick login';
  static const pinHintSw = 'Hutumika kwa kuingia haraka';

  static const pinHelperEn =
      'Choose a PIN you will remember easily. Do not share it.';
  static const pinHelperSw =
      'Chagua PIN utakayoikumbuka kwa urahisi. Usimwambie mtu.';

  static const securityCreateCtaEn = 'Create Account';
  static const securityCreateCtaSw = 'Tengeneza Akaunti';

  static const securitySavingEn = 'Setting up your workspace…';
  static const securitySavingSw = 'Inaandaa eneo lako la kazi…';

  // Errors
  static const passwordTooShortEn =
      'Password must be at least 8 characters.';
  static const passwordTooShortSw =
      'Nywila lazima iwe na angalau herufi 8.';

  static const passwordNeedsNumberEn =
      'Password must contain at least one number.';
  static const passwordNeedsNumberSw =
      'Nywila lazima iwe na angalau nambari moja.';

  static const pinLengthEn = 'PIN must be exactly 4 digits.';
  static const pinLengthSw = 'PIN lazima iwe tarakimu 4 tu.';

  static const pinDigitsOnlyEn = 'PIN must contain digits only.';
  static const pinDigitsOnlySw = 'PIN lazima iwe nambari tu, bila herufi.';

  static const saveFailedEn =
      'Could not save your profile. Please try again.';
  static const saveFailedSw =
      'Imeshindwa kuhifadhi wasifu wako. Tafadhali jaribu tena.';

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 7 — SUCCESS + DASHBOARD ENTRY
  // ═══════════════════════════════════════════════════════════════════════════

  /// [firstName] — personalised success heading.
  static String successTitleEn(String firstName) =>
      "You're all set, $firstName!";
  static String successTitleSw(String firstName) =>
      'Umewekwa vizuri, $firstName!';

  static const successBodyEn =
      'Your business workspace is ready. Time to make every shilling count.';
  static const successBodySw =
      'Eneo lako la biashara liko tayari. Ni wakati wa kuhesabu kila shilingi.';

  static const successWelcomeTagEn =
      'Welcome to Mali Up — where every shilling counts.';
  static const successWelcomeTagSw =
      'Karibu Mali Up — mahali ambapo kila shilingi inahesabiwa.';

  static const successCtaEn = 'Go to Dashboard';
  static const successCtaSw = 'Nenda kwenye Dashibodi';

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED / COMMON
  // ═══════════════════════════════════════════════════════════════════════════

  static const backEn = 'Back';
  static const backSw = 'Rudi';

  static const continueEn = 'Continue';
  static const continueSw = 'Endelea';

  static const retryEn = 'Try Again';
  static const retrySw = 'Jaribu Tena';

  static const cancelEn = 'Cancel';
  static const cancelSw = 'Ghairi';

  static const loadingEn = 'Loading…';
  static const loadingSw = 'Inapakia…';

  static const genericErrorEn = 'Something went wrong. Please try again.';
  static const genericErrorSw = 'Hitilafu imetokea. Tafadhali jaribu tena.';

  static const networkErrorEn =
      'No internet connection. Check your network and try again.';
  static const networkErrorSw =
      'Hakuna muunganiko wa intaneti. Angalia mtandao wako na ujaribu tena.';

  /// [current] — current step number, [total] — total step count.
  static String stepOfEn(int current, int total) => 'Step $current of $total';
  static String stepOfSw(int current, int total) =>
      'Hatua $current kati ya $total';
}
