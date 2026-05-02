import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/pin_digit_box.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/default_context_routing_service.dart';
import '../../../../core/services/localization_service.dart';
import '../utils/pin_auth_password.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Removed legacy PhoneAuth classes.

enum AccountManagementType { personal, business, both }

extension AccountManagementTypeX on AccountManagementType {
  String label(bool isSwahili) {
    switch (this) {
      case AccountManagementType.personal:
        return isSwahili ? 'Usimamizi wa Kibinafsi' : 'Personal Management';
      case AccountManagementType.business:
        return isSwahili ? 'Usimamizi wa Biashara' : 'Business Management';
      case AccountManagementType.both:
        return isSwahili ? 'Kibinafsi na Biashara' : 'Personal & Business';
    }
  }
}

class RegisterScreen extends StatefulWidget {
  final String? initialFullName;
  final String? initialPhone;
  final String? initialEmail;
  final bool fromOnboarding;

  const RegisterScreen({
    super.key,
    this.initialFullName,
    this.initialPhone,
    this.initialEmail,
    this.fromOnboarding = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final VoidCallback _languageListener;
  AppLanguage _language = LocalizationService.languageNotifier.value;
  AccountManagementType _selectedAccountType = AccountManagementType.personal;

  bool _isLoading = false;
  String? _feedbackText;
  EmotionalStatusTone _feedbackTone = EmotionalStatusTone.neutral;
  int _successBurstTrigger = 0;

  // Owner Details (used for all account types)
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  // Business Details
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _placeOfBusinessController =
      TextEditingController();
  String _selectedBusinessType = 'Retail';
  final List<Map<String, dynamic>> _businessTypes = [
    {'value': 'Retail', 'en': 'Retail', 'sw': 'Uuzaji', 'icon': Icons.store},
    {
      'value': 'Wholesale',
      'en': 'Wholesale',
      'sw': 'Uuzaji wa Jumla',
      'icon': Icons.store_mall_directory,
    },
    {
      'value': 'Service',
      'en': 'Service',
      'sw': 'Huduma',
      'icon': Icons.room_service,
    },
    {
      'value': 'Manufacturing',
      'en': 'Manufacturing',
      'sw': 'Uzalishaji',
      'icon': Icons.build,
    },
    {
      'value': 'Food & Beverage',
      'en': 'Food & Beverage',
      'sw': 'Chakula na Vinywaji',
      'icon': Icons.restaurant,
    },
    {
      'value': 'Agriculture',
      'en': 'Agriculture',
      'sw': 'Kilimo',
      'icon': Icons.agriculture,
    },
    {
      'value': 'Transport',
      'en': 'Transport',
      'sw': 'Usafiri',
      'icon': Icons.local_shipping,
    },
    {
      'value': 'Construction',
      'en': 'Construction',
      'sw': 'Ujenzi',
      'icon': Icons.construction,
    },
    {
      'value': 'Healthcare',
      'en': 'Healthcare',
      'sw': 'Afya',
      'icon': Icons.local_hospital,
    },
    {
      'value': 'Education',
      'en': 'Education',
      'sw': 'Elimu',
      'icon': Icons.school,
    },
    {
      'value': 'Technology',
      'en': 'Technology',
      'sw': 'Teknolojia',
      'icon': Icons.computer,
    },
    {
      'value': 'Hospitality',
      'en': 'Hospitality',
      'sw': 'Ukarimu',
      'icon': Icons.hotel,
    },
    {
      'value': 'Beauty & Wellness',
      'en': 'Beauty & Wellness',
      'sw': 'Uzuri na Afya',
      'icon': Icons.spa,
    },
    {
      'value': 'Entertainment',
      'en': 'Entertainment',
      'sw': 'Burudani',
      'icon': Icons.theater_comedy,
    },
    {
      'value': 'Real Estate',
      'en': 'Real Estate',
      'sw': 'Mali Isiyohamishika',
      'icon': Icons.apartment,
    },
    {
      'value': 'Financial Services',
      'en': 'Financial Services',
      'sw': 'Huduma za Kifedha',
      'icon': Icons.account_balance,
    },
    {
      'value': 'Professional Services',
      'en': 'Professional Services',
      'sw': 'Huduma za Kitaalam',
      'icon': Icons.business_center,
    },
    {'value': 'Other', 'en': 'Other', 'sw': 'Nyingine', 'icon': Icons.category},
  ];

  // Tanzania cities/regions for place of business
  String? _selectedCity;
  final List<Map<String, String>> _tanzaniaCities = [
    {'en': 'Dar es Salaam', 'sw': 'Dar es Salaam'},
    {'en': 'Dodoma', 'sw': 'Dodoma'},
    {'en': 'Mwanza', 'sw': 'Mwanza'},
    {'en': 'Arusha', 'sw': 'Arusha'},
    {'en': 'Mbeya', 'sw': 'Mbeya'},
    {'en': 'Morogoro', 'sw': 'Morogoro'},
    {'en': 'Tanga', 'sw': 'Tanga'},
    {'en': 'Zanzibar', 'sw': 'Zanzibar'},
    {'en': 'Kigoma', 'sw': 'Kigoma'},
    {'en': 'Mtwara', 'sw': 'Mtwara'},
    {'en': 'Tabora', 'sw': 'Tabora'},
    {'en': 'Iringa', 'sw': 'Iringa'},
    {'en': 'Singida', 'sw': 'Singida'},
    {'en': 'Shinyanga', 'sw': 'Shinyanga'},
    {'en': 'Musoma', 'sw': 'Musoma'},
    {'en': 'Bukoba', 'sw': 'Bukoba'},
    {'en': 'Sumbawanga', 'sw': 'Sumbawanga'},
    {'en': 'Njombe', 'sw': 'Njombe'},
    {'en': 'Other', 'sw': 'Nyingine'},
  ];

  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final String _businessCategoryKey = 'retail';

  bool get _includesBusiness =>
      _selectedAccountType == AccountManagementType.business ||
      _selectedAccountType == AccountManagementType.both;

  bool get _includesPersonal =>
      _selectedAccountType == AccountManagementType.personal ||
      _selectedAccountType == AccountManagementType.both;

  List<String> get _selectedAccountValues {
    switch (_selectedAccountType) {
      case AccountManagementType.personal:
        return ['personal'];
      case AccountManagementType.business:
        return ['business'];
      case AccountManagementType.both:
        return ['personal', 'business'];
    }
  }

  String get _usagePreference {
    switch (_selectedAccountType) {
      case AccountManagementType.personal:
        return 'personal';
      case AccountManagementType.business:
        return 'business';
      case AccountManagementType.both:
        return 'both';
    }
  }

  Future<void> _goToPostLoginLanding() async {
    final route = await DefaultContextRoutingService.resolveUserLandingPath(
      auth: _auth,
      firestore: _firestore,
    );
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _openWhatsAppHelpDesk() async {
    final message = Uri.encodeComponent(
      _tr(
        'Hello Mali App Help Desk, I need support with registration.',
        'Habari Mali App Help Desk, nahitaji msaada wa usajili.',
      ),
    );
    final uri = Uri.parse('https://wa.me/255653520829?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _normalizeLocalPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255') && digits.length >= 12) {
      return digits.substring(3);
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return digits.substring(1);
    }
    return digits;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFullName != null) {
      _ownerNameController.text = widget.initialFullName!.trim();
    }
    if (widget.initialPhone != null) {
      _phoneController.text = _normalizeLocalPhone(widget.initialPhone!);
    }
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!.trim();
    }
    _languageListener = () {
      if (mounted) {
        setState(() => _language = LocalizationService.languageNotifier.value);
      }
    };
    LocalizationService.languageNotifier.addListener(_languageListener);
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
  }

  void _setFeedback(String text, EmotionalStatusTone tone) {
    if (!mounted) return;
    setState(() {
      _feedbackText = text;
      _feedbackTone = tone;
    });
  }

  void _triggerSuccessBurst() {
    if (!mounted) return;
    setState(() => _successBurstTrigger++);
  }

  Widget _buildSelectField({
    required String placeholder,
    required String displayValue,
    required bool hasValue,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: hasValue ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? displayValue : placeholder,
                style: GoogleFonts.dmSans(
                  color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAccountTypeSheet() async {
    final isSwahili = _language == AppLanguage.swahili;
    final selected = await showModalBottomSheet<AccountManagementType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectSheet<AccountManagementType>(
        title: _tr('Account Usage', 'Matumizi ya Akaunti'),
        items: AccountManagementType.values,
        selectedValue: _selectedAccountType,
        labelBuilder: (type) => type.label(isSwahili),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedAccountType = selected);
    }
  }

  Future<void> _showBusinessTypeSheet() async {
    final isSwahili = _language == AppLanguage.swahili;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectSheet<String>(
        title: _tr('Business Type', 'Aina ya Biashara'),
        items: _businessTypes.map((t) => t['value'] as String).toList(),
        selectedValue: _selectedBusinessType,
        labelBuilder: (value) {
          final type = _businessTypes.firstWhere(
            (t) => t['value'] == value,
            orElse: () => _businessTypes.first,
          );
          return isSwahili ? type['sw'] as String : type['en'] as String;
        },
        iconBuilder: (value) {
          final type = _businessTypes.firstWhere(
            (t) => t['value'] == value,
            orElse: () => _businessTypes.first,
          );
          return type['icon'] as IconData;
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedBusinessType = selected);
    }
  }

  Future<void> _showCitySheet() async {
    final isSwahili = _language == AppLanguage.swahili;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectSheet<String>(
        title: _tr('City / Region', 'Mji / Mkoa'),
        items: _tanzaniaCities.map((c) => c['en']!).toList(),
        selectedValue: _selectedCity,
        labelBuilder: (value) {
          final city = _tanzaniaCities.firstWhere(
            (c) => c['en'] == value,
            orElse: () => _tanzaniaCities.first,
          );
          return isSwahili ? city['sw']! : city['en']!;
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCity = selected;
        _placeOfBusinessController.text = selected;
      });
    }
  }

  String _registrationNetworkErrorMessage() {
    return _tr(AppStrings.networkError, AppStrings.networkErrorSw);
  }

  String _registrationFallbackErrorMessage(Object error) {
    if (error is SocketException) {
      return _registrationNetworkErrorMessage();
    }

    if (error is FirebaseAuthException &&
        error.code == 'network-request-failed') {
      return _registrationNetworkErrorMessage();
    }

    if (error is FirebaseException && error.code == 'network-request-failed') {
      return _registrationNetworkErrorMessage();
    }

    return _tr(
      'Registration failed. Please try again.',
      'Usajili umeshindikana. Tafadhali jaribu tena.',
    );
  }

  Future<void> _handleRegistration() async {
    // Validate owner details
    if (_ownerNameController.text.isEmpty) {
      _setFeedback(
        _tr('Please enter your full name.', 'Tafadhali weka jina lako kamili.'),
        EmotionalStatusTone.warning,
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      _setFeedback(
        _tr(
          'Please enter your phone number.',
          'Tafadhali weka namba yako ya simu.',
        ),
        EmotionalStatusTone.warning,
      );
      return;
    }

    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length < 4) {
      _setFeedback(
        _tr('Please enter a 4-digit PIN.', 'Tafadhali weka PIN ya tarakimu 4.'),
        EmotionalStatusTone.warning,
      );
      return;
    }

    // Validate business details if business is selected
    if (_includesBusiness) {
      if (_businessNameController.text.isEmpty) {
        _setFeedback(
          _tr(
            'Please enter your business name.',
            'Tafadhali weka jina la biashara yako.',
          ),
          EmotionalStatusTone.warning,
        );
        return;
      }
      if (_placeOfBusinessController.text.isEmpty) {
        _setFeedback(
          _tr(
            'Please enter your place of business.',
            'Tafadhali weka mahali pa biashara yako.',
          ),
          EmotionalStatusTone.warning,
        );
        return;
      }
    }

    final recoveryEmail = _emailController.text.trim();
    if (recoveryEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(recoveryEmail)) {
      _setFeedback(
        _tr(
          'That email looks incorrect. Please check it.',
          'Barua pepe hiyo inaonekana si sahihi. Tafadhali ihakiki.',
        ),
        EmotionalStatusTone.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final normalizedPhone = _normalizeLocalPhone(phone);
    final email = '$normalizedPhone@mali.up';
    final authPassword = buildAuthPasswordFromPin(pin);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: authPassword,
      );
      try {
        await userCredential.user?.updateDisplayName(
          _ownerNameController.text.trim(),
        );
      } catch (_) {}
      await _completeRegistration(userCredential.user, pin);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      final String message = switch (e.code) {
        'email-already-in-use' => _tr(
          'This phone number is already registered.',
          'Namba hii ya simu tayari imesajiliwa.',
        ),
        'weak-password' => _tr(
          'PIN is too simple. Try another.',
          'PIN ni rahisi sana. Jaribu nyingine.',
        ),
        _ => _tr(
          'Registration failed. Please try again.',
          'Usajili umeshindikana. Tafadhali jaribu tena.',
        ),
      };
      _setFeedback(message, EmotionalStatusTone.error);
    } catch (e) {
      setState(() => _isLoading = false);
      _setFeedback(
        _registrationFallbackErrorMessage(e),
        EmotionalStatusTone.error,
      );
    }
  }

  // Verification logic removed in favor of PIN registration.

  Future<void> _completeRegistration(User? user, String pin) async {
    try {
      if (user != null) {
        final recoveryEmail = _emailController.text.trim().toLowerCase();
        final displayName = _ownerNameController.text.trim();
        final normalizedPhone = _normalizeLocalPhone(
          _phoneController.text.trim(),
        );
        final businessId = _firestore
            .collection('tenants')
            .doc(user.uid)
            .collection('businesses')
            .doc()
            .id;

        final selectedAccountTypes = _selectedAccountValues;
        final defaultAccountType = selectedAccountTypes.first;
        final usagePreference = _usagePreference;
        final defaultContext = _includesBusiness
            ? 'business:$businessId'
            : 'personal';

        final businesses = _includesBusiness
            ? [
                {
                  'id': businessId,
                  'name': _businessNameController.text.trim(),
                  'type': _selectedBusinessType,
                  'category': _businessCategoryKey,
                  'placeOfBusiness': _placeOfBusinessController.text.trim(),
                  'createdAt': DateTime.now().toIso8601String(),
                },
              ]
            : <Map<String, dynamic>>[];

        await _firestore.collection('users').doc(user.uid).set({
          'phone': normalizedPhone,
          'pin': pin, // Stored for lookup if needed, though Auth handles login
          'name': displayName,
          'displayName': displayName,
          if (recoveryEmail.isNotEmpty) 'email': recoveryEmail,
          if (_includesBusiness)
            'businessName': _businessNameController.text.trim(),
          'defaultAccountType': defaultAccountType,
          'accountTypes': selectedAccountTypes,
          'usagePreference': usagePreference,
          'defaultContext': defaultContext,
          'selectedBusinessId': _includesBusiness ? businessId : null,
          'businesses': businesses,
          if (recoveryEmail.isNotEmpty) 'recoveryEmail': recoveryEmail,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        // Create business tenant if business is selected
        if (_includesBusiness) {
          await _firestore
              .collection('tenants')
              .doc(user.uid)
              .collection('businesses')
              .doc(businessId)
              .set({
                'id': businessId,
                'businessName': _businessNameController.text.trim(),
                'businessType': _selectedBusinessType,
                'businessCategory': _businessCategoryKey,
                'placeOfBusiness': _placeOfBusinessController.text.trim(),
                'ownerName': displayName,
                'ownerPhone': normalizedPhone,
                'ownerUid': user.uid,
                'accountType': 'business',
                if (recoveryEmail.isNotEmpty) 'ownerEmail': recoveryEmail,
                'createdAt': DateTime.now().toIso8601String(),
                'plan': 'Trial',
              }, SetOptions(merge: true));
        }

        // Create personal account if personal is selected
        if (_includesPersonal) {
          await _firestore.collection('personal_accounts').doc(user.uid).set({
            'fullName': displayName,
            'phone': normalizedPhone,
            'ownerUid': user.uid,
            'accountType': 'personal',
            if (recoveryEmail.isNotEmpty) 'recoveryEmail': recoveryEmail,
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }

        if (mounted) {
          _setFeedback(
            _tr(
              'Great news, your workspace is ready.',
              'Habari njema, workspace yako iko tayari.',
            ),
            EmotionalStatusTone.success,
          );
          _triggerSuccessBurst();
          await Future.delayed(const Duration(milliseconds: 420));
        }
        if (mounted) {
          await _goToPostLoginLanding();
        }
      }
    } catch (e) {
      debugPrint('FIRESTORE REGISTRATION ERROR: $e');
      if (!mounted) return;
      // If Firestore fails, we need to clean up the Firebase user to prevent "already registered" error
      try {
        await user?.delete();
      } catch (deleteError) {
        debugPrint('Failed to cleanup Firebase user: $deleteError');
      }
      setState(() => _isLoading = false);
      _setFeedback(
        _registrationFallbackErrorMessage(e),
        EmotionalStatusTone.error,
      );
    }
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _placeOfBusinessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = AppColors.textPrimary;
    const textSecondary = AppColors.textSecondary;
    const fieldBg = AppColors.surface;
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.35;

    InputDecoration fieldDecoration({
      required String hint,
      required IconData suffix,
      Widget? prefix,
      Widget? suffixWidget,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        prefixIcon: prefix != null
            ? Padding(padding: const EdgeInsets.only(left: 12), child: prefix)
            : null,
        suffixIcon:
            suffixWidget ??
            Icon(suffix, color: AppColors.textSecondary, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );
    }

    final headingStyle = GoogleFonts.poppins(
      fontSize: 28,
      color: textPrimary,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.5,
    );

    final sectionTitleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      color: textPrimary,
      fontSize: 14,
      letterSpacing: 0.3,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // Premium gradient header
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Subtle pattern overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: Image.asset(
                        'assets/images/pattern.png',
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                      child: Lottie.asset(
                        'assets/lottie/Login.json',
                        key: const ValueKey('register-hero-lottie'),
                        fit: BoxFit.contain,
                        repeat: false,
                        animate: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.go(AppRouter.loginPath),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _openWhatsAppHelpDesk,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.call_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tr('Call', 'Piga'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content sheet — "bottom content panel"
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.55,
            maxChildSize: 0.96,
            builder: (context, scrollController) {
              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (overscroll) {
                    overscroll.disallowIndicator();
                    return true;
                  },
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Logo
                        const Center(child: MaliUpLogo(size: 48)),
                        const SizedBox(height: 16),
                        // Title
                        Center(
                          child: Text(
                            _tr('Create Account', 'Sajili Akaunti'),
                            textAlign: TextAlign.center,
                            style: headingStyle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Center(
                          child: Text(
                            _tr(
                              'Create your Mali workspace in seconds.',
                              'Tengeneza workspace yako ya Mali kwa sekunde chache.',
                            ),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: textSecondary,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Security badge
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _tr(
                                    'Your information stays secure and private.',
                                    'Taarifa zako zinabaki salama na faragha.',
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Feedback message
                        if (_feedbackText != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: EmotionalStatusChip(
                              visible: true,
                              text: _feedbackText!,
                              tone: _feedbackTone,
                            ),
                          ),
                        // Personal Details section
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tr('Personal Details', 'Taarifa Binafsi'),
                              style: sectionTitleStyle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Full name field
                        TextField(
                          controller: _ownerNameController,
                          decoration: fieldDecoration(
                            hint: _tr('Full name', 'Jina kamili'),
                            suffix: Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Email field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: fieldDecoration(
                            hint: _tr(
                              'Email address (optional)',
                              'Barua pepe (hiari)',
                            ),
                            suffix: Icons.alternate_email_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Phone field
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          decoration: fieldDecoration(
                            hint: _tr('Phone number', 'Namba ya simu'),
                            suffix: Icons.phone_iphone_rounded,
                            prefix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🇹🇿',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+255',
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Account type selector
                        _buildSelectField(
                          placeholder: _tr(
                            'Account usage',
                            'Matumizi ya akaunti',
                          ),
                          displayValue: _selectedAccountType.label(
                            _language == AppLanguage.swahili,
                          ),
                          hasValue: true,
                          onTap: _showAccountTypeSheet,
                          icon: Icons.manage_accounts_rounded,
                        ),
                        const SizedBox(height: 16),
                        // Business Details section
                        if (_includesBusiness) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                size: 18,
                                color: textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _tr('Business Details', 'Taarifa za Biashara'),
                                style: sectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Business name field
                          TextField(
                            controller: _businessNameController,
                            decoration: fieldDecoration(
                              hint: _tr('Business name', 'Jina la biashara'),
                              suffix: Icons.store_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Business type selector
                          _buildSelectField(
                            placeholder: _tr(
                              'Business Type',
                              'Aina ya Biashara',
                            ),
                            displayValue: () {
                              final type = _businessTypes.firstWhere(
                                (t) => t['value'] == _selectedBusinessType,
                                orElse: () => _businessTypes.first,
                              );
                              return _language == AppLanguage.swahili
                                  ? type['sw'] as String
                                  : type['en'] as String;
                            }(),
                            hasValue: true,
                            onTap: _showBusinessTypeSheet,
                            icon: Icons.category_rounded,
                          ),
                          const SizedBox(height: 12),
                          // City/Region selector
                          _buildSelectField(
                            placeholder: _tr('City/Region', 'Mji/Mkoa'),
                            displayValue: () {
                              if (_selectedCity == null) return '';
                              final city = _tanzaniaCities.firstWhere(
                                (c) => c['en'] == _selectedCity,
                                orElse: () => _tanzaniaCities.first,
                              );
                              return _language == AppLanguage.swahili
                                  ? city['sw']!
                                  : city['en']!;
                            }(),
                            hasValue: _selectedCity != null,
                            onTap: _showCitySheet,
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 20),
                        ],
                        // PIN section
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tr(
                                'Set your 4-digit PIN',
                                'Weka PIN ya tarakimu 4',
                              ),
                              style: sectionTitleStyle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // PIN digit boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            4,
                            (i) => PinDigitBox(controller: _pinControllers[i]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(
                                alpha: 0.3,
                              ),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleRegistration,
                            child: Text(
                              _isLoading
                                  ? _tr('Registering...', 'Inasajili...')
                                  : _tr('Register Account', 'Sajili Akaunti'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _tr('Already have an account? ', 'Una akaunti? '),
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRouter.loginPath),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                _tr('Login', 'Ingia'),
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.55),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: ShimmerBox(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;

  const _SelectSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.labelBuilder,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final label = labelBuilder(item);
                  final icon = iconBuilder?.call(item);
                  final isSelected = item == selectedValue;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(item),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                size: 17,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SafeArea(top: false, child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}
