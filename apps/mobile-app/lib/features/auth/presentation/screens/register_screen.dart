import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEV BYPASS — set to true to skip real SMS OTP during development.
// Automatically has no effect in release builds (kDebugMode == false).
// Dev OTP code: 9015  |  Any phone number is accepted.
// ─────────────────────────────────────────────────────────────────────────────
const bool _kDevBypassOtp = true;  // flip to false to test real Firebase flow
const String _kDevOtpCode = '9015';

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
  final TextEditingController _referralController = TextEditingController();
  
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
    // ── DEV BYPASS ──────────────────────────────────────────────────────────
    // When dev bypass is enabled, do not run Firebase readiness checks.
    // This avoids billing/SMS region errors during development.
    if (kDebugMode && _kDevBypassOtp) {
      await _sendRegistrationOTP();
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

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

    // ── DEV BYPASS ──────────────────────────────────────────────────────────
    // In debug builds with _kDevBypassOtp enabled, skip the real Firebase
    // SMS call and immediately show the OTP entry screen.
    if (kDebugMode && _kDevBypassOtp) {
      setState(() {
        _otpSent = true;
        _isLoading = false;
        _verificationId = '__dev_bypass__';

        // Prefill the OTP inputs for faster dev iteration.
        for (var i = 0; i < _otpControllers.length; i++) {
          _otpControllers[i].text = i < _kDevOtpCode.length ? _kDevOtpCode[i] : '';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('🛠 Dev mode: Enter $_kDevOtpCode to bypass OTP.', '🛠 Hali ya Maendeleo: Weka $_kDevOtpCode kupita OTP.'))),
        );
        _setFeedback(
          _tr('Dev mode active — use code $_kDevOtpCode', 'Hali ya Maendeleo — tumia OTP $_kDevOtpCode'),
          EmotionalStatusTone.neutral,
        );
      }
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

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
        _setFeedback(_tr('Code sent. Check your messages.', 'OTP umetumwa. Angalia ujumbe wako.'), EmotionalStatusTone.success);
        _triggerSuccessBurst();
      },
      codeAutoRetrievalTimeout: (vid) => _verificationId = vid,
    );
  }

  Future<void> _verifyAndRegister() async {
    setState(() => _isLoading = true);
    final smsCode = _otpControllers.map((c) => c.text).join();

    // ── DEV BYPASS ──────────────────────────────────────────────────────────
    // Skip Firebase credential check in debug builds. Accept the dev code
    // and navigate directly to the dashboard.
    if (kDebugMode && _kDevBypassOtp && _verificationId == '__dev_bypass__') {
      if (smsCode != _kDevOtpCode) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_tr('🛠 Dev mode: Wrong code. Use $_kDevOtpCode.', '🛠 Hali ya Maendeleo: OTP si sahihi. Tumia $_kDevOtpCode.'))),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dev_bypass_session', true);

      if (mounted) {
        _setFeedback(
          _tr('🛠 Dev bypass — entering app.', '🛠 Dev bypass — unaingia kwenye app.'),
          EmotionalStatusTone.success,
        );
        _triggerSuccessBurst();
        await Future.delayed(const Duration(milliseconds: 320));
        if (mounted) context.go(AppRouter.dashboardPath);
      }
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

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
    _referralController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE07B2A);
    const textPrimary = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF6B7280);
    const fieldBg = Color(0xFFEFF5F2);
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.30;
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
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
        prefixIcon: prefix,
        suffixIcon: suffixWidget ?? Icon(suffix, color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
    }

    final headingStyle = GoogleFonts.poppins(
      fontSize: 30,
      color: textPrimary,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    final subtitleStyle = GoogleFonts.poppins(
      color: textSecondary,
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w400,
    );
    final sectionTitleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: textPrimary,
      fontSize: 15,
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
                Image.network(
                  'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=1600&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF263238)),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Salama', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: topHeight - 22,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: MaliUpLogo(size: 54)),
                    const SizedBox(height: 16),
                    Center(child: Text('Jisajili Mali App', textAlign: TextAlign.center, style: headingStyle)),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _otpSent
                            ? 'Weka OTP ili kukamilisha usajili wako.'
                            : 'Fungua akaunti yako kwa dakika chache tu.',
                        textAlign: TextAlign.center,
                        style: subtitleStyle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 16, color: textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Taarifa zako zinabaki salama na faragha.',
                            style: GoogleFonts.poppins(color: textSecondary, fontSize: 12.5),
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
                    if (!_otpSent) ...[
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18, color: textPrimary),
                          const SizedBox(width: 8),
                          Text('Taarifa za Akaunti', style: sectionTitleStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ownerNameController,
                        decoration: fieldDecoration(hint: 'Jina kamili', suffix: Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: fieldDecoration(hint: 'Barua pepe', suffix: Icons.alternate_email_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: fieldDecoration(
                          hint: '7xx xxx xxx',
                          suffix: Icons.phone_iphone_rounded,
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇹🇿', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text('+255', style: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _referralController,
                        decoration: fieldDecoration(hint: 'Referral code (hiari)', suffix: Icons.card_giftcard_rounded),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Weka referral code kama umepewa. Unaweza kuacha wazi.',
                        style: GoogleFonts.poppins(color: textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _precheckAndSendOtp,
                          child: Text(
                            _isLoading ? 'Inatuma...' : 'Jisajili',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 18, color: textPrimary),
                          const SizedBox(width: 8),
                          Text('Thibitisha OTP', style: sectionTitleStyle),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (i) => _OTPBox(controller: _otpControllers[i])),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _verifyAndRegister,
                          child: Text(
                            _isLoading ? 'Inathibitisha...' : 'Jisajili',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _otpSent = false),
                          child: Text('Rudi kurekebisha taarifa', style: GoogleFonts.poppins(color: textSecondary)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Una akaunti? ', style: GoogleFonts.poppins(color: textSecondary)),
                        TextButton(
                          onPressed: () => context.push(AppRouter.loginPath),
                          child: Text('Ingia', style: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.fromOnboarding)
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: Container(
                  width: 112,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(999),
                  ),
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

