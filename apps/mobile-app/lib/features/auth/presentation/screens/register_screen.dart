import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/pin_digit_box.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/default_context_routing_service.dart';
import '../../../../core/services/localization_service.dart';
import '../utils/pin_auth_password.dart';
import '../widgets/privacy_policy.dart';
import '../widgets/terms_and_conditions.dart';
import '../../../../core/services/lookup_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Removed legacy PhoneAuth classes.

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
  bool _isLoading = false;
  String _selectedAccountType = 'business';
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
  List<Map<String, dynamic>> _businessTypes =
      LookupService.defaultBusinessTypes;

  // Tanzania cities/regions for place of business
  String? _selectedCity;
  List<Map<String, String>> _tanzaniaCities =
      LookupService.defaultTanzaniaCities;

  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  final String _businessCategoryKey = 'retail';
  final List<Map<String, String>> _accountTypes = const [
    {'value': 'business', 'en': 'Business', 'sw': 'Biashara'},
    {
      'value': 'personal',
      'en': 'Personal (Coming soon)',
      'sw': 'Binafsi (Inakuja)',
    },
  ];

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

  void _openTermsAndConditions() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()));
  }

  void _openPrivacyPolicy() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
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
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final types = await LookupService.fetchBusinessTypes();
      final cities = await LookupService.fetchCities();
      if (mounted) {
        setState(() {
          _businessTypes = types;
          _tanzaniaCities = cities;
        });
      }
    } catch (_) {}
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

  Future<void> _showBusinessTypeSheet() async {
    final isSwahili = _language == AppLanguage.swahili;
    final selected = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaliSelectSheet<String>(
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
          final iconRaw = type['icon'];
          if (iconRaw is IconData) return iconRaw;
          if (iconRaw is String) return LookupService.iconFromName(iconRaw);
          return Icons.category;
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaliSelectSheet<String>(
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

  Future<void> _showAccountTypeSheet() async {
    final isSwahili = _language == AppLanguage.swahili;
    final selected = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaliSelectSheet<String>(
        title: _tr('Account Type', 'Aina ya Akaunti'),
        items: _accountTypes.map((a) => a['value']!).toList(),
        selectedValue: _selectedAccountType,
        labelBuilder: (value) {
          final accountType = _accountTypes.firstWhere(
            (a) => a['value'] == value,
            orElse: () => _accountTypes.first,
          );
          return isSwahili ? accountType['sw']! : accountType['en']!;
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedAccountType = selected);
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

  Future<bool> _hasInternetConnection() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none) || results.isNotEmpty;
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

    // Validate business details
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

    // Check internet connection before attempting registration
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      _setFeedback(
        _registrationNetworkErrorMessage(),
        EmotionalStatusTone.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final normalizedPhone = _normalizeLocalPhone(phone);
    final normalizedRecoveryEmail = recoveryEmail.toLowerCase();
    final authEmail = normalizedRecoveryEmail.isNotEmpty
        ? normalizedRecoveryEmail
        : '$normalizedPhone@mali.up';
    final authPassword = buildAuthPasswordFromPin(pin);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
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
        final authEmail = recoveryEmail.isNotEmpty
            ? recoveryEmail
            : '$normalizedPhone@mali.up';
        final businessId = _firestore
            .collection('tenants')
            .doc(user.uid)
            .collection('businesses')
            .doc()
            .id;

        await _firestore.collection('users').doc(user.uid).set({
          'phone': normalizedPhone,
          'pin': pin,
          'name': displayName,
          'displayName': displayName,
          'authEmail': authEmail,
          if (recoveryEmail.isNotEmpty) 'email': recoveryEmail,
          'businessName': _businessNameController.text.trim(),
          'defaultAccountType': 'business',
          'accountTypes': ['business'],
          'usagePreference': 'business',
          'defaultContext': 'business:$businessId',
          'selectedBusinessId': businessId,
          'businesses': [
            {
              'id': businessId,
              'name': _businessNameController.text.trim(),
              'type': _selectedBusinessType,
              'category': _businessCategoryKey,
              'placeOfBusiness': _placeOfBusinessController.text.trim(),
              'createdAt': DateTime.now().toIso8601String(),
            },
          ],
          if (recoveryEmail.isNotEmpty) 'recoveryEmail': recoveryEmail,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

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
    for (final node in _pinFocusNodes) {
      node.dispose();
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
    final isPersonalManagement = _selectedAccountType == 'personal';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header image
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: ClipRect(
              child: Image.asset(
                'assets/Picture/sign_in.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRouter.loginPath),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openWhatsAppHelpDesk,
                    icon: const Icon(
                      Icons.headset_mic_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    label: Text(
                      _tr('Help', 'Msaada'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content sheet — "bottom content panel"
          DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.68,
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
                            const Icon(
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
                        const SizedBox(height: 16),
                        // Account type selector
                        Row(
                          children: [
                            const Icon(
                              Icons.account_circle_outlined,
                              size: 18,
                              color: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tr('Account Type', 'Aina ya Akaunti'),
                              style: sectionTitleStyle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MaliSelectField(
                          placeholder: _tr('Account Type', 'Aina ya Akaunti'),
                          displayValue: () {
                            final accountType = _accountTypes.firstWhere(
                              (a) => a['value'] == _selectedAccountType,
                              orElse: () => _accountTypes.first,
                            );
                            return _language == AppLanguage.swahili
                                ? accountType['sw']!
                                : accountType['en']!;
                          }(),
                          hasValue: true,
                          onTap: _showAccountTypeSheet,
                          icon: Icons.account_circle_outlined,
                        ),
                        if (isPersonalManagement) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _tr(
                                      'Personal management accounts are coming soon. Please register a business account for now.',
                                      'Akaunti za usimamizi binafsi zinakuja hivi karibuni. Tafadhali sajili akaunti ya biashara kwa sasa.',
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Business Details section
                        Row(
                          children: [
                            const Icon(
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
                        MaliSelectField(
                          placeholder: _tr('Business Type', 'Aina ya Biashara'),
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
                        MaliSelectField(
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
                        // PIN section
                        Row(
                          children: [
                            const Icon(
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
                            (i) => PinDigitBox(
                              controller: _pinControllers[i],
                              previousController: i > 0
                                  ? _pinControllers[i - 1]
                                  : null,
                              focusNode: _pinFocusNodes[i],
                              previousFocusNode: i > 0
                                  ? _pinFocusNodes[i - 1]
                                  : null,
                              nextFocusNode: i < 3
                                  ? _pinFocusNodes[i + 1]
                                  : null,
                              isLast: i == 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: _tr(
                                    'By registering, you agree to the ',
                                    'Kwa kusajili, unakubali ',
                                  ),
                                ),
                                TextSpan(
                                  text: _tr(
                                    'User Terms and Conditions',
                                    'Sheria na Masharti ya Mtumiaji',
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFFFC107),
                                    fontSize: 12,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _openTermsAndConditions,
                                ),
                                TextSpan(text: _tr(' and ', ' na ')),
                                TextSpan(
                                  text: _tr(
                                    'Privacy Policy.',
                                    'Sera ya Faragha.',
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFFFC107),
                                    fontSize: 12,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _openPrivacyPolicy,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                            onPressed:
                                _isLoading || _selectedAccountType == 'personal'
                                ? null
                                : _handleRegistration,
                            child: Text(
                              _isLoading
                                  ? _tr('Registering...', 'Inasajili...')
                                  : _selectedAccountType == 'personal'
                                  ? _tr('Coming Soon', 'Inakuja Hivi Karibuni')
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
