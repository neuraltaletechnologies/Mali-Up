import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
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
  final List<String> _businessTypes = [
    'Retail',
    'Wholesale',
    'Service',
    'Manufacturing',
    'Food & Beverage',
    'Other'
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

    setState(() => _isLoading = false);
    final phone = _phoneController.text.trim();

    // Prepare user data for registration
    final userData = {
      'name': _ownerNameController.text.trim(),
      'email': recoveryEmail,
      'phone': phone,
      'businessName': _includesBusiness ? _businessNameController.text.trim() : null,
      'businessType': _includesBusiness ? _selectedBusinessType : null,
      'businessCategory': _includesBusiness ? _businessCategoryKey : null,
      'placeOfBusiness': _includesBusiness ? _placeOfBusinessController.text.trim() : null,
      'defaultAccountType': _usagePreference,
      'accountTypes': _selectedAccountValues,
      'usagePreference': _usagePreference,
      'includesBusiness': _includesBusiness,
      'includesPersonal': _includesPersonal,
    };

    // Navigate to OTP verification for registration
    if (!mounted) return;
    context.push(
      AppRouter.otpPath,
      extra: {
        'phoneNumber': phone,
        'isRegistration': true,
        'userData': userData,
      },
    );
  }

  // Verification logic removed in favor of PIN registration.

  Future<void> _completeRegistration(User? user, String pin) async {
    try {
      if (user != null) {
        final recoveryEmail = _emailController.text.trim().toLowerCase();
        final displayName = _ownerNameController.text.trim();
        final normalizedPhone =
            _normalizeLocalPhone(_phoneController.text.trim());
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
                  'createdAt': FieldValue.serverTimestamp(),
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
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
                'createdAt': FieldValue.serverTimestamp(),
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
            'createdAt': FieldValue.serverTimestamp(),
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
      setState(() => _isLoading = false);
      _setFeedback(
        _tr(
          'Something didn\'t go as planned. Please try again.',
          'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.',
        ),
        EmotionalStatusTone.error,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Something didn\'t go as planned. Please try again.',
              'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.',
            ),
          ),
        ),
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
    const textPrimary = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF6B7280);
    const fieldBg = Color(0xFFEFF5F2);
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.25;
    final bottomInset = mediaQuery.viewInsets.bottom;

    InputDecoration fieldDecoration({
      required String hint,
      required IconData suffix,
      Widget? prefix,
      Widget? suffixWidget,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textSecondary),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        prefixIcon: prefix,
        suffixIcon: suffixWidget ?? Icon(suffix, color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      );
    }

    final headingStyle = GoogleFonts.poppins(
      fontSize: 30,
      color: textPrimary,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );

    final sectionTitleStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: textPrimary,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.primary,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                      child: Lottie.asset(
                        'assets/lottie/Login.json',
                        key: const ValueKey('register-hero-lottie'),
                        fit: BoxFit.contain,
                        repeat: false,
                        animate: true,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.38),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.76,
            minChildSize: 0.76,
            maxChildSize: 0.96,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: MaliUpLogo(size: 54)),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _tr('Create Account', 'Sajili Akaunti'),
                          textAlign: TextAlign.center,
                          style: headingStyle,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tr(
                                'Your information stays secure and private.',
                                'Taarifa zako zinabaki salama na faragha.',
                              ),
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_feedbackText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EmotionalStatusChip(
                            visible: true,
                            text: _feedbackText!,
                            tone: _feedbackTone,
                          ),
                        ),
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
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ownerNameController,
                        decoration: fieldDecoration(
                          hint: _tr('Full name', 'Jina kamili'),
                          suffix: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AccountManagementType>(
                        initialValue: _selectedAccountType,
                        decoration: fieldDecoration(
                          hint: _tr('Account usage', 'Matumizi ya akaunti'),
                          suffix: Icons.expand_more_rounded,
                        ),
                        items: AccountManagementType.values
                            .map(
                              (type) => DropdownMenuItem<AccountManagementType>(
                                value: type,
                                child: Text(
                                  type.label(_language == AppLanguage.swahili),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedAccountType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_includesBusiness) ...[
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
                        const SizedBox(height: 10),
                        TextField(
                          controller: _businessNameController,
                          decoration: fieldDecoration(
                            hint: _tr('Business name', 'Jina la biashara'),
                            suffix: Icons.store_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBusinessType,
                          decoration: fieldDecoration(
                            hint: _tr('Business Type', 'Aina ya Biashara'),
                            suffix: Icons.category_rounded,
                          ),
                          items: _businessTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedBusinessType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _placeOfBusinessController,
                          decoration: fieldDecoration(
                            hint: _tr(
                              'Place of business',
                              'Mahali pa biashara',
                            ),
                            suffix: Icons.location_on_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (i) => PinDigitBox(controller: _pinControllers[i]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _tr('Already have an account? ', 'Una akaunti? '),
                            style: GoogleFonts.poppins(color: textSecondary),
                          ),
                          TextButton(
                            onPressed: () => context.push(AppRouter.loginPath),
                            child: Text(
                              _tr('Login', 'Ingia'),
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.45),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
