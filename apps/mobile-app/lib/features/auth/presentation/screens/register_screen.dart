import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../onboarding/core/onboarding_colors.dart';
import '../models/account_type.dart';
import '../widgets/terms_and_conditions.dart';
import '../widgets/privacy_policy.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _PhoneAuthPrecheckResult {
  final bool isReady;
  final String title;
  final String message;
  final List<String> fixes;

  const _PhoneAuthPrecheckResult({
    required this.isReady,
    required this.title,
    required this.message,
    this.fixes = const [],
  });
}

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
  static const String _customerPhoneWithCountryCode = '255653520829';
  late final VoidCallback _languageListener;
  AppLanguage _language = LocalizationService.languageNotifier.value;
  AccountManagementType _selectedManagementType = AccountManagementType.personal;
  
  bool _otpSent = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _verificationId;
  String? _feedbackText;
  EmotionalStatusTone _feedbackTone = EmotionalStatusTone.neutral;
  int _successBurstTrigger = 0;
  
  // Owner Details (used for all account types)
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Business Details
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _placeOfBusinessController = TextEditingController();
  
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  
  final List<String> _businessCategoryKeys = [
    'retail',
    'wholesale',
    'manufacturing',
    'services',
    'agriculture',
    'technology',
    'healthcare',
    'education',
    'food_and_beverage',
    'transportation',
    'other',
  ];

  String _businessCategoryKey = 'retail';
  bool _phoneAuthReady = false;

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

  List<String> _getBusinessCategories() {
    return _businessCategoryKeys;
  }

  String _getPhoneAuthErrorMessage(String code, String? fallbackMessage) {
    final raw = (fallbackMessage ?? '').toUpperCase();
    switch (code) {
      case 'operation-not-allowed':
        return _tr(
          'Phone sign-in is disabled for this Firebase project. Enable Phone provider in Firebase Auth > Sign-in method.',
          'Kuingia kwa simu kumezimwa kwenye mradi huu wa Firebase. Washa Phone provider kwenye Firebase Auth > Sign-in method.',
        );
      case 'invalid-phone-number':
        return _tr('That number looks off. Please check and try again.', 'Namba hiyo inaonekana si sahihi. Tafadhali hakiki kisha ujaribu tena.');
      case 'too-many-requests':
        return _tr('Let\'s pause for a bit, then try again.', 'Tusimame kidogo, kisha ujaribu tena.');
      case 'quota-exceeded':
        return _tr('SMS quota exceeded. Check Firebase usage and billing.', 'Kikomo cha SMS kimefikiwa. Angalia matumizi na malipo ya Firebase.');
      case 'network-request-failed':
        return _tr('We\'re having trouble connecting. Check internet and try again.', 'Tunapata shida ya muunganisho. Angalia intaneti kisha ujaribu tena.');
      case 'internal-error':
        if (raw.contains('BILLING_NOT_ENABLED')) {
          return _tr(
            'Firebase billing is not enabled. Enable billing in Google Cloud/Firebase to send SMS OTP.',
            'Billing ya Firebase haijawashwa. Washa billing kwenye Google Cloud/Firebase ili kutuma SMS OTP.',
          );
        }
        if (raw.contains('REGION') || raw.contains('SMS UNABLE TO BE SENT')) {
          return _tr(
            'SMS region policy blocks this phone region. Enable Tanzania (+255) in Firebase Auth > Settings > SMS region policy.',
            'Sera ya eneo la SMS imezuia eneo hili. Washa Tanzania (+255) kwenye Firebase Auth > Settings > SMS region policy.',
          );
        }
        return _tr('Internal auth error. Check Firebase Auth and billing settings.', 'Hitilafu ya ndani ya uthibitishaji. Angalia mipangilio ya Firebase Auth na billing.');
      default:
        return fallbackMessage ?? _tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.');
    }
  }

  _PhoneAuthPrecheckResult _buildPrecheckFailure(String code, String? fallbackMessage) {
    final raw = (fallbackMessage ?? '').toUpperCase();

    if (code == 'operation-not-allowed') {
      return _PhoneAuthPrecheckResult(
        isReady: false,
        title: _tr('Phone Auth Not Enabled', 'Phone Auth Haijawashwa'),
        message: _getPhoneAuthErrorMessage(code, fallbackMessage),
        fixes: [
          _tr('Open Firebase Console > Authentication > Sign-in method.', 'Fungua Firebase Console > Authentication > Sign-in method.'),
          _tr('Enable Phone provider and Save.', 'Washa Phone provider kisha Save.'),
        ],
      );
    }

    if (code == 'internal-error' && raw.contains('BILLING_NOT_ENABLED')) {
      return _PhoneAuthPrecheckResult(
        isReady: false,
        title: _tr('Billing Required For SMS', 'Billing Inahitajika kwa SMS'),
        message: _getPhoneAuthErrorMessage(code, fallbackMessage),
        fixes: [
          _tr('Open Google Cloud Console for this Firebase project.', 'Fungua Google Cloud Console kwa mradi huu wa Firebase.'),
          _tr('Enable billing account for project neuraltale-mali-up.', 'Washa billing account kwa mradi neuraltale-mali-up.'),
          _tr('In Firebase Auth settings, verify SMS region policy allows +255.', 'Kwenye Firebase Auth settings, hakikisha SMS region policy inaruhusu +255.'),
        ],
      );
    }

    if ((code == 'internal-error' && (raw.contains('REGION') || raw.contains('SMS UNABLE TO BE SENT')))) {
      return _PhoneAuthPrecheckResult(
        isReady: false,
        title: _tr('SMS Region Blocked', 'Eneo la SMS Limezuiwa'),
        message: _getPhoneAuthErrorMessage(code, fallbackMessage),
        fixes: [
          _tr('Open Firebase Console > Authentication > Settings.', 'Fungua Firebase Console > Authentication > Settings.'),
          _tr('Set SMS region policy to include Tanzania (+255).', 'Weka SMS region policy ijumuisha Tanzania (+255).'),
        ],
      );
    }

    if (code == 'network-request-failed') {
      return _PhoneAuthPrecheckResult(
        isReady: false,
        title: _tr('Network Check Failed', 'Ukaguzi wa Mtandao Umeshindikana'),
        message: _getPhoneAuthErrorMessage(code, fallbackMessage),
        fixes: [
          _tr('Check internet connection.', 'Angalia muunganisho wa intaneti.'),
          _tr('Retry readiness check.', 'Jaribu tena ukaguzi wa utayari.'),
        ],
      );
    }

    return _PhoneAuthPrecheckResult(
      isReady: false,
      title: _tr('Phone Auth Readiness Failed', 'Utayari wa Phone Auth Umeshindikana'),
      message: _getPhoneAuthErrorMessage(code, fallbackMessage),
      fixes: [
        _tr('Confirm Phone provider is enabled in Firebase Auth.', 'Hakikisha Phone provider imewashwa kwenye Firebase Auth.'),
        _tr('Confirm billing is enabled for SMS.', 'Hakikisha billing imewashwa kwa SMS.'),
      ],
    );
  }

  Future<_PhoneAuthPrecheckResult> _runPhoneAuthReadinessCheck() async {
    final completer = Completer<_PhoneAuthPrecheckResult>();
    var done = false;

    void finish(_PhoneAuthPrecheckResult result) {
      if (!done && !completer.isCompleted) {
        done = true;
        completer.complete(result);
      }
    }

    try {
      await _auth.verifyPhoneNumber(
        // Probe number: intentionally non-real to avoid sending SMS.
        phoneNumber: '+255000000000',
        timeout: const Duration(seconds: 8),
        verificationCompleted: (_) {
          finish(_PhoneAuthPrecheckResult(
            isReady: true,
            title: _tr('Phone Auth Ready', 'Phone Auth Iko Tayari'),
            message: _tr('Firebase Phone Auth is configured correctly.', 'Firebase Phone Auth imepangwa sawa.'),
          ));
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'invalid-phone-number') {
            finish(_PhoneAuthPrecheckResult(
              isReady: true,
              title: _tr('Phone Auth Ready', 'Phone Auth Iko Tayari'),
              message: _tr(
                'Configuration check passed. You can continue to send OTP to real numbers.',
                'Ukaguzi wa mpangilio umefaulu. Unaweza kuendelea kutuma OTP kwa namba halisi.',
              ),
            ));
            return;
          }

          finish(_buildPrecheckFailure(e.code, e.message));
        },
        codeSent: (_, resendToken) {
          finish(_PhoneAuthPrecheckResult(
            isReady: true,
            title: _tr('Phone Auth Ready', 'Phone Auth Iko Tayari'),
            message: _tr('Phone verification service is reachable.', 'Huduma ya uthibitishaji wa simu inapatikana.'),
          ));
        },
        codeAutoRetrievalTimeout: (_) {
          finish(_PhoneAuthPrecheckResult(
            isReady: true,
            title: _tr('Phone Auth Ready', 'Phone Auth Iko Tayari'),
            message: _tr('Readiness check completed.', 'Ukaguzi wa utayari umekamilika.'),
          ));
        },
      );
    } catch (e) {
      finish(_PhoneAuthPrecheckResult(
        isReady: false,
        title: _tr('Readiness Check Failed', 'Ukaguzi wa Utayari Umeshindikana'),
        message: _tr('Unexpected error: ${e.toString()}', 'Hitilafu isiyotarajiwa: ${e.toString()}'),
      ));
    }

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => _PhoneAuthPrecheckResult(
        isReady: false,
        title: _tr('Check Timed Out', 'Ukaguzi Umeishiwa Muda'),
        message: _tr('Could not verify Firebase phone auth readiness in time.', 'Haikuwezekana kuthibitisha utayari wa Firebase phone auth kwa muda.'),
      ),
    );
  }

  Future<bool> _showPhoneAuthPrecheckScreen() async {
    final result = await _runPhoneAuthReadinessCheck();
    if (!mounted) return false;

    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        result.isReady ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: result.isReady ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (result.fixes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _tr('Recommended Fix Steps:', 'Hatua za Marekebisho Zinazopendekezwa:'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.fixes.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• $step',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(_tr('Close', 'Funga')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: result.isReady ? () => Navigator.of(context).pop(true) : null,
                          child: Text(_tr('Continue', 'Endelea')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _precheckAndSendOtp() async {
    if (_phoneAuthReady) {
      await _sendRegistrationOTP();
      return;
    }

    final ready = await _showPhoneAuthPrecheckScreen();
    if (!ready) return;

    setState(() => _phoneAuthReady = true);
    await _sendRegistrationOTP();
  }

  String _businessCategoryLabel(String key) {
    switch (key) {
      case 'retail':
        return _tr('Retail', 'Kuuza Rejareja');
      case 'wholesale':
        return _tr('Wholesale', 'Kuuza Kwa Jumla');
      case 'manufacturing':
        return _tr('Manufacturing', 'Utengenezaji');
      case 'services':
        return _tr('Services', 'Huduma');
      case 'agriculture':
        return _tr('Agriculture', 'Kilimo');
      case 'technology':
        return _tr('Technology', 'Teknolojia');
      case 'healthcare':
        return _tr('Healthcare', 'Afya');
      case 'education':
        return _tr('Education', 'Elimu');
      case 'food_and_beverage':
        return _tr('Food & Beverage', 'Chakula na Vinywaji');
      case 'transportation':
        return _tr('Transportation', 'Usafiri');
      case 'other':
      default:
        return _tr('Other', 'Nyingineyo');
    }
  }

  Future<void> _sendRegistrationOTP() async {
    // Validate owner details
    if (_ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Quick check, this field is still empty.', 'Ukaguzi wa haraka, sehemu hii bado iko wazi.'))),
      );
      return;
    }
    
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Quick check, this field is still empty.', 'Ukaguzi wa haraka, sehemu hii bado iko wazi.'))),
      );
      return;
    }

    // Validate business details if business is selected
    if (_selectedManagementType == AccountManagementType.business ||
        _selectedManagementType == AccountManagementType.both) {
      if (_businessNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('Quick check, this field is still empty.', 'Ukaguzi wa haraka, sehemu hii bado iko wazi.'))),
        );
        return;
      }
      if (_placeOfBusinessController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('Quick check, this field is still empty.', 'Ukaguzi wa haraka, sehemu hii bado iko wazi.'))),
        );
        return;
      }
    }

    final recoveryEmail = _emailController.text.trim();
    if (recoveryEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(recoveryEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('That email looks incorrect. Please check it.', 'Barua pepe hiyo inaonekana si sahihi. Tafadhali ihakiki.'))),
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
        final message = _getPhoneAuthErrorMessage(e.code, e.message);
        _setFeedback(_tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.'), EmotionalStatusTone.error);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
      codeSent: (String vid, int? resendToken) {
        setState(() {
          _verificationId = vid;
          _otpSent = true;
          _isLoading = false;
        });
        _setFeedback(_tr('Code sent. Check your messages.', 'Msimbo umetumwa. Angalia ujumbe wako.'), EmotionalStatusTone.success);
        _triggerSuccessBurst();
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
          'name': displayName,
          'displayName': displayName,
          if (recoveryEmail.isNotEmpty) 'email': recoveryEmail,
          'businessName': _businessNameController.text.trim(),
          'defaultAccountType': accountTypes.first,
          'accountTypes': accountTypes,
          if (recoveryEmail.isNotEmpty) 'recoveryEmail': recoveryEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Create business tenant if business is selected
        if (_selectedManagementType == AccountManagementType.business ||
            _selectedManagementType == AccountManagementType.both) {
          await _firestore.collection('tenants').doc(user.uid).set({
            'businessName': _businessNameController.text.trim(),
            'businessCategory': _businessCategoryKey,
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
        
        if (mounted) {
          _setFeedback(_tr('Great news, your workspace is ready.', 'Habari njema, workspace yako iko tayari.'), EmotionalStatusTone.success);
          _triggerSuccessBurst();
          await Future.delayed(const Duration(milliseconds: 420));
        }
        if (mounted) {
          context.go(AppRouter.dashboardPath);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    _setFeedback(_tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.'), EmotionalStatusTone.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.'))),
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
    _setFeedback(_tr('Demo number loaded.', 'Namba ya mfano imewekwa.'), EmotionalStatusTone.neutral);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr('Customer number loaded: +255653520829', 'Namba ya mteja iliyokamatia: +255653520829'))),
    );
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
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
      body: Stack(
        children: [
          const AmbientEmotionBackground(
            palette: [
              AppColors.primary,
              AppColors.secondaryLight,
              AppColors.info,
            ],
            intensity: 0.78,
          ),
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  child: IconButton(
                    tooltip: 'Use customer care number +$_customerPhoneWithCountryCode',
                    onPressed: _useCustomerPhone,
                    icon: const Icon(Icons.support_agent_rounded),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),
                  const Center(child: MaliUpLogo(size: 80)),
                  const SizedBox(height: 20),
                  Text(
                    _otpSent ? _tr('Confirm your phone number', 'Thibitisha namba yako ya simu') : _tr('Let\'s get you started', 'Tuanze kukuweka tayari'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _otpSent
                        ? _tr('We sent a code to +255 ${_phoneController.text}.', 'Tumetuma msimbo kwa +255 ${_phoneController.text}.')
                        : _tr('Tell us about you and your business.', 'Tuambie kuhusu wewe na biashara yako.'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        EmotionalStatusChip(
                          visible: _feedbackText != null,
                          text: _feedbackText ?? '',
                          tone: _feedbackTone,
                        ),
                        if (_feedbackTone == EmotionalStatusTone.success)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: EmotionalSuccessBurst(trigger: _successBurstTrigger),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.06),
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
                                    _tr('About you', 'Kuhusu wewe'),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondary,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _tr('Your Full name', 'Jina lako kamili'),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  _GlowTextField(
                                    controller: _ownerNameController,
                                    decoration: InputDecoration(
                                      hintText: _tr('Example: Amina Juma', 'Mfano: Amina Juma'),
                                      prefixIcon: const Icon(Icons.person_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _tr('Recovery email (optional)', 'Barua pepe ya kurejesha (hiari)'),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  _GlowTextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: _tr('e.g. you@example.com', 'mfano: you@example.com'),
                                      prefixIcon: const Icon(Icons.email_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _tr('Mobile number', 'Namba ya simu'),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
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
                                            Text('🇹🇿', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18)),
                                            const SizedBox(width: 8),
                                            Text('+255',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    color: AppColors.secondary,
                                                    fontWeight: FontWeight.w700)),
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
                                    _tr('What would you like to manage first?', 'Ungependa kusimamia nini kwanza?'),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
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
                                      _tr('Tell us about your business', 'Tuambie kuhusu biashara yako'),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.secondary,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(_tr('Brand or shop name', 'Jina la chapa au duka'),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            )),
                                    const SizedBox(height: 8),
                                    _GlowTextField(
                                      controller: _businessNameController,
                                      decoration: InputDecoration(
                                        hintText: _tr('e.g. Neuraltale Tech', 'mfano: Neuraltale Tech'),
                                        prefixIcon: const Icon(Icons.business_rounded),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(_tr('Business category', 'Kundi la biashara'),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            )),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        underline: const SizedBox.shrink(),
                                        value: _businessCategoryKey,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _businessCategoryKey = newValue ?? _businessCategoryKeys.first;
                                          });
                                        },
                                        items: _getBusinessCategories().map((String category) {
                                          return DropdownMenuItem<String>(
                                            value: category,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text(_businessCategoryLabel(category)),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(_tr('Where you operate', 'Unapofanyia biashara'),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            )),
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
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        children: [
                                          TextSpan(text: _tr('Continuing means you accept our ', 'Kuendelea kunamaanisha unakubali ')),
                                          TextSpan(
                                            text: _tr('Terms & Conditions', 'Masharti na Hali'),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
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
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
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
                            EmotionalTapScale(
                              enabled: _agreedToTerms && !_isLoading,
                              hapticStyle: TapHapticStyle.medium,
                              child: ElevatedButton(
                                onPressed: (_agreedToTerms && !_isLoading)
                                    ? _precheckAndSendOtp
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
                                      _isLoading ? _tr('Code on the way...', 'Msimbo unakuja...') : _tr('Send verification code', 'Tuma msimbo wa uthibitisho'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('register-otp'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr('Confirm your phone number', 'Thibitisha namba yako ya simu'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
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
                            EmotionalTapScale(
                              enabled: !_isLoading,
                              hapticStyle: TapHapticStyle.medium,
                              child: ElevatedButton(
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
                                      _isLoading ? _tr('Almost done...', 'Karibu kumaliza...') : _tr('Verify and finish', 'Thibitisha na umalize'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(AppRouter.loginPath),
                      child: Text(
                        _tr('Have an account already? Sign in instead', 'Una akaunti tayari? Ingia badala yake'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.fromOnboarding)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildOnboardingBottomCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildOnboardingBottomCard() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: OnboardingColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OnboardingColors.divider),
            boxShadow: [
              BoxShadow(
                color: OnboardingColors.primaryDeep.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const AnimatedSmoothIndicator(
                activeIndex: 3,
                count: 4,
                effect: CustomizableEffect(
                  activeDotDecoration: DotDecoration(
                    width: 28,
                    height: 8,
                    color: OnboardingColors.accentGreen,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  dotDecoration: DotDecoration(
                    width: 8,
                    height: 8,
                    color: OnboardingColors.divider,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  spacing: 6,
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
                    color: AppColors.primary.withValues(alpha: 0.18),
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
      child: Center(child: TextField(controller: controller, textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.secondary), decoration: const InputDecoration(counterText: "", border: InputBorder.none))),
    );
  }
}

