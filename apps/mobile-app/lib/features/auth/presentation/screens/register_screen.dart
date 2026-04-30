import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/default_context_routing_service.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/motion_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Removed dev bypasses for real flow.

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
  late final VoidCallback _languageListener;
  AppLanguage _language = LocalizationService.languageNotifier.value;
  AccountManagementType _selectedAccountType = AccountManagementType.personal;
  
  bool _otpSent = false;
  bool _isLoading = false;
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
  
  final List<TextEditingController> _pinControllers = List.generate(4, (_) => TextEditingController());
  
  final String _businessCategoryKey = 'retail';
  bool _phoneAuthReady = false;

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

  Future<void> _openWhatsAppHelpDesk() async {
    final message = Uri.encodeComponent(
      _tr(
        'Hello Mali App Help Desk, I need emergency support with registration.',
        'Habari Mali App Help Desk, nahitaji msaada wa dharura wa usajili.',
      ),
    );
    final uri = Uri.parse('https://wa.me/255653520829?text=$message');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('We could not open WhatsApp right now.', 'Hatukuweza kufungua WhatsApp sasa.')),
        ),
      );
    }
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
              message: _tr('Configuration check passed. You can continue to send OTP to real numbers.', 'Ukaguzi wa mpangilio umefaulu. Unaweza kuendelea kutuma OTP kwa namba halisi.'),
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

  Future<void> _handleRegistration() async {
    // Validate owner details
    if (_ownerNameController.text.isEmpty) {
      _setFeedback(_tr('Please enter your full name.', 'Tafadhali weka jina lako kamili.'), EmotionalStatusTone.warning);
      return;
    }
    
    if (_phoneController.text.isEmpty) {
      _setFeedback(_tr('Please enter your phone number.', 'Tafadhali weka namba yako ya simu.'), EmotionalStatusTone.warning);
      return;
    }

    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length < 4) {
      _setFeedback(_tr('Please enter a 4-digit PIN.', 'Tafadhali weka PIN ya tarakimu 4.'), EmotionalStatusTone.warning);
      return;
    }

    // Validate business details if business is selected
    if (_includesBusiness) {
      if (_businessNameController.text.isEmpty) {
        _setFeedback(_tr('Please enter your business name.', 'Tafadhali weka jina la biashara yako.'), EmotionalStatusTone.warning);
        return;
      }
      if (_placeOfBusinessController.text.isEmpty) {
        _setFeedback(_tr('Please enter your place of business.', 'Tafadhali weka mahali pa biashara yako.'), EmotionalStatusTone.warning);
        return;
      }
    }

    final recoveryEmail = _emailController.text.trim();
    if (recoveryEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(recoveryEmail)) {
      _setFeedback(_tr('That email looks incorrect. Please check it.', 'Barua pepe hiyo inaonekana si sahihi. Tafadhali ihakiki.'), EmotionalStatusTone.warning);
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final normalizedPhone = _normalizeLocalPhone(phone);
    final email = '$normalizedPhone@mali.up';

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pin,
      );
      await _completeRegistration(userCredential.user, pin);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = switch (e.code) {
        'email-already-in-use' => _tr('This phone number is already registered.', 'Namba hii ya simu tayari imesajiliwa.'),
        'weak-password' => _tr('PIN is too simple. Try another.', 'PIN ni rahisi sana. Jaribu nyingine.'),
        _ => _tr('Registration failed. Please try again.', 'Usajili umeshindikana. Tafadhali jaribu tena.'),
      };
      _setFeedback(message, EmotionalStatusTone.error);
    } catch (e) {
      setState(() => _isLoading = false);
      _setFeedback(_tr('An unexpected error occurred.', 'Hitilafu isiyotarajiwa imetokea.'), EmotionalStatusTone.error);
    }
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
        if (mounted) {
          await _goToPostLoginLanding();
        }
      }
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

    final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: smsCode);
    await _completeRegistration(credential);
  }

  Future<void> _completeRegistration(User? user, String pin) async {
    try {
      if (user != null) {
        final recoveryEmail = _emailController.text.trim().toLowerCase();
        final displayName = _ownerNameController.text.trim();
        final businessId = _firestore.collection('tenants').doc(user.uid).collection('businesses').doc().id;

        final selectedAccountTypes = _selectedAccountValues;
        final defaultAccountType = selectedAccountTypes.first;
        final usagePreference = _usagePreference;
        final defaultContext = _includesBusiness ? 'business:$businessId' : 'personal';

        final businesses = _includesBusiness
            ? [
                {
                  'id': businessId,
                  'name': _businessNameController.text.trim(),
                  'category': _businessCategoryKey,
                  'placeOfBusiness': _placeOfBusinessController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                },
              ]
            : <Map<String, dynamic>>[];

        await _firestore.collection('users').doc(user.uid).set({
          'phone': _phoneController.text.trim(),
          'pin': pin, // Stored for lookup if needed, though Auth handles login
          'name': displayName,
          'displayName': displayName,
          if (recoveryEmail.isNotEmpty) 'email': recoveryEmail,
          if (_includesBusiness) 'businessName': _businessNameController.text.trim(),
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
          await _firestore.collection('tenants').doc(user.uid).collection('businesses').doc(businessId).set({
            'id': businessId,
            'businessName': _businessNameController.text.trim(),
            'businessCategory': _businessCategoryKey,
            'placeOfBusiness': _placeOfBusinessController.text.trim(),
            'ownerName': displayName,
            'ownerPhone': _phoneController.text.trim(),
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
            'phone': _phoneController.text.trim(),
            'ownerUid': user.uid,
            'accountType': 'personal',
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
          await _goToPostLoginLanding();
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
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
                Container(
                  color: AppColors.primary,
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: MotionService.reducedMotionNotifier,
                      builder: (context, reducedMotion, _) {
                        return RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                            child: Lottie.asset(
                              'assets/lottie/Sign up.json',
                              fit: BoxFit.contain,
                              repeat: false,
                              animate: !reducedMotion,
                            ),
                          ),
                        );
                      },
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
                  Row(
                    children: [
                      Material(
                        color: const Color(0xFF25D366).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(999),
                        child: IconButton(
                          tooltip: _tr('Emergency WhatsApp support', 'Msaada wa dharura WhatsApp'),
                          icon: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
                          onPressed: _openWhatsAppHelpDesk,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              _tr('Secure', 'Salama'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.72,
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
                          _tr('Register to Mali App', 'Jisajili Mali App'),
                          textAlign: TextAlign.center,
                          style: headingStyle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _tr('Create your account and set a 4-digit PIN for secure access.', 'Fungua akaunti yako na uweke PIN ya tarakimu 4 kwa ufikiaji salama.'),
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
                              _tr('Your information stays secure and private.', 'Taarifa zako zinabaki salama na faragha.'),
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
                            Text(_tr('Personal Details', 'Taarifa Binafsi'), style: sectionTitleStyle),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                            hint: _tr('Email address', 'Barua pepe'),
                            suffix: Icons.alternate_email_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: fieldDecoration(
                            hint: _tr('Phone number', 'Namba ya simu'),
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
                                  child: Text(type.label(_language == AppLanguage.swahili)),
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
                              const Icon(Icons.storefront_rounded, size: 18, color: textPrimary),
                              const SizedBox(width: 8),
                              Text(_tr('Business Details', 'Taarifa za Biashara'), style: sectionTitleStyle),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _businessNameController,
                            decoration: fieldDecoration(
                              hint: _tr('Business name', 'Jina la biashara'),
                              suffix: Icons.storefront_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _placeOfBusinessController,
                            decoration: fieldDecoration(
                              hint: _tr('Place of business', 'Mahali pa biashara'),
                              suffix: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _referralController,
                          decoration: fieldDecoration(
                            hint: _tr('Referral code (optional)', 'Referral code (hiari)'),
                            suffix: Icons.card_giftcard_rounded,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tr('Enter a referral code if you received one.', 'Weka referral code kama umepewa.'),
                          style: GoogleFonts.poppins(color: textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 18, color: textPrimary),
                            const SizedBox(width: 8),
                            Text(_tr('Set your 4-digit PIN', 'Weka PIN yako ya tarakimu 4'), style: sectionTitleStyle),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (i) => _OTPBox(controller: _pinControllers[i])),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _handleRegistration,
                            child: Text(
                              _isLoading ? _tr('Registering...', 'Inasajili...') : _tr('Register Account', 'Sajili Akaunti'),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
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
                              style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700),
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
        ],
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

