import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../models/account_type.dart';
import '../widgets/terms_and_conditions.dart';
import '../widgets/privacy_policy.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AccountManagementType {
  personal,
  business,
  both,
}

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
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _customerPhoneWithCountryCode = '255653520829';
  late AppLanguage _language;
  AccountManagementType _selectedManagementType = AccountManagementType.personal;
  
  bool _otpSent = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _verificationId;
  String _businessCategory = 'Retail';
  
  // Owner Details (used for all account types)
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Business Details
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _placeOfBusinessController = TextEditingController();
  
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  
  final List<String> _businessCategoriesEn = [
    'Retail',
    'Wholesale',
    'Manufacturing',
    'Services',
    'Agriculture',
    'Technology',
    'Healthcare',
    'Education',
    'Food & Beverage',
    'Transportation',
    'Other',
  ];

  final List<String> _businessCategoriesSw = [
    'Kuuza Rejareja',
    'Kuuza Kwa Jumla',
    'Utengenezaji',
    'Huduma',
    'Kilimo',
    'Teknolohia',
    'Afya',
    'Elimu',
    'Chakula na Vinywaji',
    'Usafiri',
    'Nyingineyo',
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await LocalizationService.getLanguage();
    if (mounted) {
      setState(() => _language = language);
    }
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
  }

  List<String> _getBusinessCategories() {
    return _language == AppLanguage.swahili ? _businessCategoriesSw : _businessCategoriesEn;
  }

  Future<void> _sendRegistrationOTP() async {
    // Validate owner details
    if (_ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Please enter your full name', 'Tafadhali weka jina lako kamili'))),
      );
      return;
    }
    
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Please enter phone number', 'Tafadhali weka namba ya simu'))),
      );
      return;
    }

    // Validate business details if business is selected
    if (_selectedManagementType == AccountManagementType.business ||
        _selectedManagementType == AccountManagementType.both) {
      if (_businessNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('Please enter business name', 'Tafadhali weka jina la biashara'))),
        );
        return;
      }
      if (_placeOfBusinessController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('Please enter place of business', 'Tafadhali weka mahali pa biashara'))),
        );
        return;
      }
    }

    final recoveryEmail = _emailController.text.trim();
    if (recoveryEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(recoveryEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Please enter a valid email', 'Tafadhali weka barua pepe halali'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    final phone = '+255${_phoneController.text.trim()}';
    
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _completeRegistration(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? _tr('Error', 'Hitilafu'))));
      },
      codeSent: (String vid, int? resendToken) {
        setState(() {
          _verificationId = vid;
          _otpSent = true;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (vid) => _verificationId = vid,
    );
  }

  Future<void> _verifyAndRegister() async {
    setState(() => _isLoading = true);
    final smsCode = _otpControllers.map((c) => c.text).join();
    final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: smsCode);
    await _completeRegistration(credential);
  }

  Future<void> _completeRegistration(AuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        final recoveryEmail = _emailController.text.trim().toLowerCase();
        final displayName = _ownerNameController.text.trim();

        // Write user document with both account types if "both" is selected
        List<String> accountTypes = [];
        if (_selectedManagementType == AccountManagementType.personal ||
            _selectedManagementType == AccountManagementType.both) {
          accountTypes.add(AccountType.personal.value);
        }
        if (_selectedManagementType == AccountManagementType.business ||
            _selectedManagementType == AccountManagementType.both) {
          accountTypes.add(AccountType.business.value);
        }

        await _firestore.collection('users').doc(user.uid).set({
          'phone': user.phoneNumber,
          'displayName': displayName,
          'defaultAccountType': accountTypes.first,
          'accountTypes': accountTypes,
          if (recoveryEmail.isNotEmpty) 'recoveryEmail': recoveryEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Create business tenant if business is selected
        if (_selectedManagementType == AccountManagementType.business ||
            _selectedManagementType == AccountManagementType.both) {
          await _firestore.collection('tenants').doc(user.uid).set({
            'businessName': _businessNameController.text.trim(),
            'businessCategory': _businessCategory,
            'placeOfBusiness': _placeOfBusinessController.text.trim(),
            'ownerName': displayName,
            'ownerPhone': user.phoneNumber,
            'ownerUid': user.uid,
            'accountType': AccountType.business.value,
            if (recoveryEmail.isNotEmpty) 'ownerEmail': recoveryEmail,
            'createdAt': FieldValue.serverTimestamp(),
            'plan': 'Trial',
          }, SetOptions(merge: true));
        }

        // Create personal account if personal is selected
        if (_selectedManagementType == AccountManagementType.personal ||
            _selectedManagementType == AccountManagementType.both) {
          await _firestore.collection('personal_accounts').doc(user.uid).set({
            'fullName': displayName,
            'phone': user.phoneNumber,
            'ownerUid': user.uid,
            'accountType': AccountType.personal.value,
            if (recoveryEmail.isNotEmpty) 'recoveryEmail': recoveryEmail,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        
        if (mounted) context.go(AppRouter.dashboardPath);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr('Registration failed', 'Ujisajili umeshindwa'))),
    );
    }
  }

  void _onManagementTypeChanged(AccountManagementType managementType) {
    setState(() {
      _selectedManagementType = managementType;
      _otpSent = false;
    });
  }

  void _useCustomerPhone() {
    // Keep local 9-digit format because +255 is already shown in UI.
    const localPhone = '653520829';
    setState(() {
      _phoneController.text = localPhone;
      _otpSent = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr('Customer number loaded: +255653520829', 'Namba ya mteja iliyokamatia: +255653520829'))),
    );
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _placeOfBusinessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Use customer number +$_customerPhoneWithCountryCode',
            onPressed: _useCustomerPhone,
            icon: const Icon(Icons.support_agent_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: MaliUpLogo(size: 80)),
              const SizedBox(height: 40),

              Text(
                _otpSent ? _tr('Verify Phone', 'Thibitisha Simu') : _tr('Create Your Account', 'Tengeneza Akaunti Yako'),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.secondary),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? _tr('Enter code sent to ${_phoneController.text}', 'Weka namba iliyotumwa kwa ${_phoneController.text}')
                    : _tr('Set up your account to get started', 'Tekeleza akaunti yako kuanza'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: !_otpSent
                      ? Column(
                          key: const ValueKey('register-form'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Owner Details Section (Always shown)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tr('Your Details', 'Maelezo Yako'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(_tr('Full Name', 'Jina Kamili'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  _GlowTextField(
                                    controller: _ownerNameController,
                                    decoration: InputDecoration(
                                      hintText: _tr('e.g. John Mushi', 'mfano: John Mushi'),
                                      prefixIcon: const Icon(Icons.person_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(_tr('Email (Optional)', 'Barua Pepe (Kisimu)'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  _GlowTextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: _tr('e.g. you@example.com', 'mfano: you@example.com'),
                                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(_tr('Mobile Number', 'Namba ya Simu'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  _GlowTextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: _tr('7xx xxx xxx', '7xx xxx xxx'),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🇹🇿', style: TextStyle(fontSize: 18)),
                                            const SizedBox(width: 8),
                                            Text('+255',
                                                style: const TextStyle(
                                                    color: AppColors.secondary,
                                                    fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Account Type Selection
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tr('What would you like to manage?', 'Unataaka kusimamia nini?'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<AccountManagementType>(
                                      isExpanded: true,
                                      underline: const SizedBox.shrink(),
                                      value: _selectedManagementType,
                                      onChanged: (AccountManagementType? newValue) {
                                        if (newValue != null) {
                                          _onManagementTypeChanged(newValue);
                                        }
                                      },
                                      items: AccountManagementType.values
                                          .map((AccountManagementType type) {
                                        return DropdownMenuItem<AccountManagementType>(
                                          value: type,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text(type.label(_language == AppLanguage.swahili)),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Business Details Section (Shown if business is selected)
                            if (_selectedManagementType == AccountManagementType.business ||
                                _selectedManagementType == AccountManagementType.both) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _tr('Business Details', 'Maelezo ya Biashara'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(_tr('Business Name', 'Jina la Biashara'),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _GlowTextField(
                                      controller: _businessNameController,
                                      decoration: InputDecoration(
                                        hintText: _tr('e.g. Neuraltale Tech', 'mfano: Neuraltale Tech'),
                                        prefixIcon: const Icon(Icons.business_rounded),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(_tr('Business Type', 'Aina ya Biashara'),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        underline: const SizedBox.shrink(),
                                        value: _businessCategory,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _businessCategory = newValue ?? _getBusinessCategories()[0];
                                          });
                                        },
                                        items: _getBusinessCategories().map((String category) {
                                          return DropdownMenuItem<String>(
                                            value: category,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text(category),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(_tr('Place of Business', 'Mahali pa Biashara'),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _GlowTextField(
                                      controller: _placeOfBusinessController,
                                      decoration: InputDecoration(
                                        hintText: _tr('e.g. Dar es Salaam', 'mfano: Dar es Salaam'),
                                        prefixIcon: const Icon(Icons.location_on_rounded),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Terms & Conditions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (value) {
                                    setState(() => _agreedToTerms = value ?? false);
                                  },
                                  activeColor: AppColors.primary,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        children: [
                                          TextSpan(text: _tr('I agree to the ', 'Nakubali ')),
                                          TextSpan(
                                            text: _tr('Terms & Conditions', 'Masharti na Hali'),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const TermsAndConditionsPage(),
                                                  ),
                                                );
                                              },
                                          ),
                                          TextSpan(text: _tr(' and ', ' na ')),
                                          TextSpan(
                                            text: _tr('Privacy Policy', 'Sera ya Faragha'),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const PrivacyPolicyPage(),
                                                  ),
                                                );
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: (_agreedToTerms && !_isLoading)
                                  ? _sendRegistrationOTP
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLoading) ...[
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Text(
                                    _isLoading ? _tr('Sending OTP...', 'Inatuma OTP...') : _tr('Continue', 'Endelea'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('register-otp'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr('Enter OTP to Complete Registration', 'Weka OTP kumaliza Ujisajili'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:
                                  List.generate(4, (i) => _OTPBox(controller: _otpControllers[i])),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _verifyAndRegister,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLoading) ...[
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Text(
                                    _isLoading ? _tr('Verifying...', 'Inathibitisha...') : _tr('Verify & Finish', 'Thibitisha na Maliza'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    _tr('Already have an account? Manage Account', 'Una akaunti tayari? Simamia Akaunti'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final InputDecoration decoration;

  const _GlowTextField({
    required this.controller,
    required this.decoration,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  State<_GlowTextField> createState() => _GlowTextFieldState();
}

class _GlowTextFieldState extends State<_GlowTextField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        if (_hasFocus != focused) {
          setState(() => _hasFocus = focused);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          decoration: widget.decoration,
        ),
      ),
    );
  }
}

class _OTPBox extends StatelessWidget {
  final TextEditingController controller;
  const _OTPBox({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65, height: 70,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 2)),
      child: Center(child: TextField(controller: controller, textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(counterText: "", border: InputBorder.none))),
    );
  }
}

