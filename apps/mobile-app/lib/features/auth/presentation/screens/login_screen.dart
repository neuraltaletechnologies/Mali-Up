import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _GlowTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? hintText;
  final Widget? prefixIcon;
  final TextStyle? style;
  final InputDecoration? decoration;

  const _GlowTextField({
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.hintText,
    this.prefixIcon,
    this.style,
    this.decoration,
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
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          style: widget.style,
          decoration: widget.decoration ??
              InputDecoration(
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon,
              ),
        ),
      ),
    );
  }
}


// Notification helper for success/error messages
class _NotificationHelper {
  static Future<void> showSuccess(BuildContext context, String message) async {
    _showNotification(context, message, Colors.green, Icons.check_circle);
  }

  static Future<void> showError(BuildContext context, String message) async {
    _showNotification(context, message, Colors.red, Icons.error_outline);
  }

  static Future<void> showInfo(BuildContext context, String message) async {
    _showNotification(context, message, Colors.blue, Icons.info_outline);
  }

  static void _showNotification(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String? initialPhone;
  final bool autoSendOtp;

  const LoginScreen({
    super.key,
    this.initialPhone,
    this.autoSendOtp = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _customerPhoneWithCountryCode = '255653520829';
  late final VoidCallback _languageListener;
  AppLanguage _language = AppLanguage.english;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _phoneAuthReady = false;
  String? _verificationId;
  String? _feedbackText;
  EmotionalStatusTone _feedbackTone = EmotionalStatusTone.neutral;
  int _successBurstTrigger = 0;
  
  final TextEditingController _phoneController = TextEditingController(text: '0653520829');
  final TextEditingController _recoveryEmailController = TextEditingController();
  final TextEditingController _emailOtpController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (i) => TextEditingController(text: '9015'[i]));
  final FocusNode _phoneFocusNode = FocusNode();

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
    final initial = widget.initialPhone;
    if (initial != null && initial.trim().isNotEmpty) {
      _phoneController.text = _normalizeLocalPhone(initial);
    }
    _language = LocalizationService.languageNotifier.value;
    _languageListener = () {
      if (mounted) {
        setState(() => _language = LocalizationService.languageNotifier.value);
      }
    };
    LocalizationService.languageNotifier.addListener(_languageListener);

    if (widget.autoSendOtp) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _precheckAndSendOtp();
      });
    }
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _sendEmailOtpCode() async {
    final email = _recoveryEmailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      await _NotificationHelper.showError(context, _tr('Please enter your email', 'Tafadhali weka barua pepe yako'));
      return;
    }

    if (!_isValidEmail(email)) {
      await _NotificationHelper.showError(context, _tr('Please enter a valid email address', 'Tafadhali weka barua pepe sahihi'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('email_otp_auth').doc(email).set({
        'email': email,
        'code': otp,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If Firebase Trigger Email extension is installed, this sends OTP email.
      await _firestore.collection('mail').add({
        'to': email,
        'message': {
          'subject': _tr('Your Mali Up OTP Code', 'Namba ya OTP ya Mali Up'),
          'text': _tr('Your OTP code is $otp. It expires in 10 minutes.', 'Namba yako ya OTP ni $otp. Itaisha ndani ya dakika 10.'),
        },
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_for_sign_in', email);

      if (mounted) {
        await _NotificationHelper.showSuccess(
          context,
          _tr('OTP sent to $email. Check your inbox.', 'OTP imetumwa kwa $email. Angalia ujumbe wako.'),
        );
        _setFeedback(
          _tr('Email OTP sent. Check your inbox.', 'OTP ya barua pepe imetumwa. Angalia kikasha.'),
          EmotionalStatusTone.success,
        );
        _triggerSuccessBurst();
      }
    } on FirebaseAuthException catch (e) {
      final message = _tr('Could not send email OTP: ${e.message ?? e.code}', 'Imeshindikana kutuma OTP ya barua pepe: ${e.message ?? e.code}');
      if (mounted) {
        await _NotificationHelper.showError(context, message);
        _setFeedback(_tr('Email OTP failed to send.', 'Kutuma OTP ya barua pepe kumeshindikana.'), EmotionalStatusTone.error);
      }
    } catch (e) {
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('Unexpected error: ${e.toString()}', 'Hitilafu isiyotarajiwa: ${e.toString()}'));
        _setFeedback(_tr('Unexpected issue. Try again.', 'Tatizo lisilotarajiwa. Jaribu tena.'), EmotionalStatusTone.warning);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyEmailOtpAndContinue() async {
    final email = _recoveryEmailController.text.trim().toLowerCase();
    final code = _emailOtpController.text.trim();

    if (code.length != 6) {
      await _NotificationHelper.showError(context, _tr('Enter the 6-digit OTP', 'Weka OTP ya namba 6'));
      return;
    }

    try {
      final doc = await _firestore.collection('email_otp_auth').doc(email).get();
      if (!mounted) return;
      if (!doc.exists) {
        await _NotificationHelper.showError(context, _tr('OTP not found. Request a new OTP.', 'OTP haijapatikana. Omba OTP mpya.'));
        return;
      }

      final data = doc.data()!;
      final savedCode = data['code'] as String?;
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      final isExpired = expiresAt == null || DateTime.now().isAfter(expiresAt);

      if (isExpired) {
        if (!mounted) return;
        await _NotificationHelper.showError(context, _tr('OTP expired. Request a new one.', 'OTP imekwisha muda. Omba nyingine.'));
        return;
      }

      if (savedCode != code) {
        if (!mounted) return;
        await _NotificationHelper.showError(context, _tr('Invalid OTP code.', 'Namba ya OTP si sahihi.'));
        return;
      }

      await _firestore.collection('email_otp_auth').doc(email).delete();
      if (!mounted) return;
      await _NotificationHelper.showSuccess(context, _tr('Email OTP verified.', 'OTP ya barua pepe imethibitishwa.'));
      _setFeedback(_tr('Email verified successfully.', 'Barua pepe imethibitishwa kikamilifu.'), EmotionalStatusTone.success);
      _triggerSuccessBurst();
      if (!mounted) return;
      context.go(AppRouter.dashboardPath);
    } catch (e) {
      if (!mounted) return;
      await _NotificationHelper.showError(context, _tr('Failed to verify email OTP.', 'Imeshindikana kuthibitisha OTP ya barua pepe.'));
      _setFeedback(_tr('Could not verify email OTP.', 'Imeshindikana kuthibitisha OTP ya barua pepe.'), EmotionalStatusTone.error);
    }
  }

  Future<void> _showEmailRecoveryDialog() async {
    bool isSending = false;
    bool otpSent = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_tr('Recover With Email OTP', 'Rejesha kwa OTP ya Barua Pepe')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr(
                      'Enter your email to receive a 6-digit OTP code.',
                      'Weka barua pepe yako upokee OTP ya namba 6.',
                    ),
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  _GlowTextField(
                    controller: _recoveryEmailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    hintText: _tr('Enter your email', 'Weka barua pepe yako'),
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                  ),
                  if (otpSent) ...[
                    const SizedBox(height: 12),
                    _GlowTextField(
                      controller: _emailOtpController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      hintText: _tr('Enter 6-digit OTP', 'Weka OTP ya namba 6'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(_tr('Cancel', 'Ghairi')),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setDialogState(() => isSending = true);
                          if (!otpSent) {
                            await _sendEmailOtpCode();
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              otpSent = true;
                              isSending = false;
                            });
                            return;
                          }
                          await _verifyEmailOtpAndContinue();
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSending) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        isSending
                            ? _tr('Please wait...', 'Tafadhali subiri...')
                            : otpSent
                                ? _tr('Verify OTP', 'Thibitisha OTP')
                                : _tr('Send OTP to Email', 'Tuma OTP kwa Barua Pepe'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    
    // Validate phone number
    if (phone.isEmpty) {
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('Please enter your phone number', 'Tafadhali weka namba yako ya simu'));
      }
      return;
    }
    
    if (phone.length != 9) {
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('Phone number must be 9 digits', 'Namba ya simu lazima iwe na tarakimu 9'));
      }
      return;
    }
    
    setState(() => _isLoading = true);
    final fullPhone = '+255$phone';
    
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (mounted) {
              await _NotificationHelper.showSuccess(context, _tr('Authentication successful!', 'Uthibitisho umefanikiwa!'));
              _setFeedback(_tr('Welcome back. You are in.', 'Karibu tena. Umeingia.'), EmotionalStatusTone.success);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) context.go(AppRouter.dashboardPath);
              });
            }
          } catch (e) {
            if (mounted) {
              await _NotificationHelper.showError(context, _tr('Sign in failed: ${e.toString()}', 'Kuingia kumeshindikana: ${e.toString()}'));
              _setFeedback(_tr('Could not sign in automatically.', 'Haikuwezekana kuingia kiotomatiki.'), EmotionalStatusTone.error);
              setState(() => _isLoading = false);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) setState(() => _isLoading = false);
          String errorMessage = _getFirebaseErrorMessage(e.code);
          if (mounted) {
            _NotificationHelper.showError(context, errorMessage);
            _setFeedback(_tr('OTP request failed.', 'Ombi la OTP limeshindwa.'), EmotionalStatusTone.error);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
            _NotificationHelper.showSuccess(context, 'Code sent to $fullPhone');
            _setFeedback(_tr('OTP sent. Enter your code.', 'OTP imetumwa. Weka msimbo wako.'), EmotionalStatusTone.success);
            _triggerSuccessBurst();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await _NotificationHelper.showError(context, 'Error: ${e.toString()}');
        _setFeedback(_tr('Network or auth issue detected.', 'Tatizo la mtandao au uthibitisho limegunduliwa.'), EmotionalStatusTone.warning);
      }
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return _tr('Invalid phone number format', 'Muundo wa namba ya simu si sahihi');
      case 'missing-client-identifier':
        return _tr('API configuration error. Please contact support.', 'Hitilafu ya mpangilio wa API. Wasiliana na msaada.');
      case 'invalid-api-key':
        return _tr('API key not configured. Please contact support.', 'API key haijapangwa. Wasiliana na msaada.');
      case 'too-many-requests':
        return _tr('Too many attempts. Please try again later.', 'Majaribio mengi sana. Jaribu tena baadaye.');
      case 'app-not-authorized':
        return _tr('App not authorized for phone authentication', 'App haijaidhinishwa kwa uthibitisho wa simu');
      case 'operation-not-allowed':
        return _tr('Phone authentication is not enabled', 'Uthibitisho wa simu haujawashwa');
      case 'network-request-failed':
        return _tr('Network error. Please check your connection.', 'Hitilafu ya mtandao. Tafadhali angalia muunganisho wako.');
      default:
        return _tr('Verification failed: $errorCode. Please try again.', 'Uthibitisho umeshindikana: $errorCode. Tafadhali jaribu tena.');
    }
  }

  String _getPhoneAuthErrorMessage(String code, String? fallbackMessage) {
    final raw = (fallbackMessage ?? '').toUpperCase();
    switch (code) {
      case 'operation-not-allowed':
        return _tr(
          'Phone sign-in is disabled. Enable Phone provider in Firebase Auth > Sign-in method.',
          'Kuingia kwa simu kumezimwa. Washa Phone provider kwenye Firebase Auth > Sign-in method.',
        );
      case 'invalid-phone-number':
        return _tr('Invalid phone number format.', 'Muundo wa namba ya simu si sahihi.');
      case 'too-many-requests':
        return _tr('Too many attempts. Try again later.', 'Majaribio mengi sana. Jaribu tena baadaye.');
      case 'quota-exceeded':
        return _tr('SMS quota exceeded. Check Firebase usage and billing.', 'Kikomo cha SMS kimefikiwa. Angalia matumizi na malipo ya Firebase.');
      case 'network-request-failed':
        return _tr('Network error. Check your internet connection.', 'Hitilafu ya mtandao. Angalia muunganisho wa intaneti.');
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
        return fallbackMessage ?? _tr('Phone verification failed.', 'Uthibitishaji wa simu umeshindikana.');
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

    if (code == 'internal-error' && (raw.contains('REGION') || raw.contains('SMS UNABLE TO BE SENT'))) {
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

    return _PhoneAuthPrecheckResult(
      isReady: false,
      title: _tr('Phone Auth Readiness Failed', 'Utayari wa Phone Auth Umeshindikana'),
      message: _getPhoneAuthErrorMessage(code, fallbackMessage),
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
              message: _tr('Configuration check passed. Continue to send OTP.', 'Ukaguzi wa mpangilio umefaulu. Endelea kutuma OTP.'),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.message,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  if (result.fixes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _tr('Recommended Fix Steps:', 'Hatua za Marekebisho Zinazopendekezwa:'),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 8),
                    ...result.fixes.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $step', style: const TextStyle(color: AppColors.textSecondary)),
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
      await _sendOTP();
      return;
    }

    final ready = await _showPhoneAuthPrecheckScreen();
    if (!ready) return;

    setState(() => _phoneAuthReady = true);
    await _sendOTP();
  }

  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);
    final smsCode = _otpControllers.map((c) => c.text).join();
    
    if (smsCode.length != 4 || smsCode.contains(' ')) {
      setState(() => _isLoading = false);
      if (mounted) {
        await _NotificationHelper.showError(context, 'Please enter all 4 digits');
      }
      return;
    }
    
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      if (mounted) {
        await _NotificationHelper.showSuccess(context, _tr('Verification successful!', 'Uthibitisho umefanikiwa!'));
        _setFeedback(_tr('OTP verified. Entering app...', 'OTP imethibitishwa. Inaingia kwenye app...'), EmotionalStatusTone.success);
        _triggerSuccessBurst();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go(AppRouter.dashboardPath);
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = e.code == 'invalid-verification-code'
          ? _tr('Invalid OTP. Please check and try again.', 'OTP si sahihi. Tafadhali angalia na ujaribu tena.')
          : _tr('Verification failed: ${e.message}', 'Uthibitisho umeshindikana: ${e.message}');
      if (mounted) {
        await _NotificationHelper.showError(context, errorMessage);
        _setFeedback(_tr('Incorrect OTP code. Try again.', 'OTP si sahihi. Jaribu tena.'), EmotionalStatusTone.error);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('Error: ${e.toString()}', 'Hitilafu: ${e.toString()}'));
        _setFeedback(_tr('Verification interrupted.', 'Uthibitishaji umekatizwa.'), EmotionalStatusTone.warning);
      }
    }
  }

  void _useCustomerPhone() {
    // Keep local 9-digit format because +255 is already shown in UI.
    const localPhone = '653520829';
    setState(() {
      _phoneController.text = localPhone;
      _otpSent = false;
    });
    _NotificationHelper.showInfo(
      context,
      'Customer number loaded: +$_customerPhoneWithCountryCode',
    );
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _phoneController.dispose();
    _recoveryEmailController.dispose();
    _emailOtpController.dispose();
    _phoneFocusNode.dispose();
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
              AppColors.success,
            ],
            intensity: 0.8,
          ),

          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                child: IconButton(
                  tooltip: 'Use customer number +$_customerPhoneWithCountryCode',
                  onPressed: _useCustomerPhone,
                  icon: const Icon(Icons.support_agent_rounded),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),
                  const Center(child: MaliUpLogo(size: 80)),
                  const SizedBox(height: 14),
                  Center(
                    child: EmotionalCompanion(
                      mood: _isLoading
                          ? CompanionMood.focused
                          : _otpSent
                              ? CompanionMood.excited
                              : CompanionMood.calm,
                      size: 88,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    _otpSent ? _tr('Verification', 'Uthibitisho') : _tr('Welcome to Mali Up', 'Karibu Mali Up'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _otpSent 
                      ? _tr('We sent a code to +255 ${_phoneController.text}', 'Tumepeleka msimbo kwa +255 ${_phoneController.text}')
                      : _tr('Enter your phone number to continue', 'Weka namba yako ya simu kuendelea'),
                    style: const TextStyle(
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
                              key: const ValueKey('phone-step'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr('Phone Number', 'Namba ya Simu'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _GlowTextField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocusNode,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                  decoration: const InputDecoration(
                                    hintText: '7xx xxx xxx',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('🇹🇿', style: TextStyle(fontSize: 20)),
                                          SizedBox(width: 8),
                                          Text('+255', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                EmotionalTapScale(
                                  enabled: !_isLoading,
                                  hapticStyle: TapHapticStyle.medium,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _precheckAndSendOtp,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isLoading) ...[
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Text(_isLoading ? _tr('Sending OTP...', 'Inatuma OTP...') : _tr('Send OTP', 'Tuma OTP')),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _showEmailRecoveryDialog,
                                    child: Text(
                                      _tr('Don\'t have my phone number', 'Sina namba yangu ya simu sasa'),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('otp-step'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr('Enter OTP Code', 'Weka Msimbo wa OTP'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(4, (index) => _OTPBox(controller: _otpControllers[index])),
                                ),
                                const SizedBox(height: 26),
                                EmotionalTapScale(
                                  enabled: !_isLoading,
                                  hapticStyle: TapHapticStyle.medium,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _verifyOTP,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isLoading) ...[
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Text(_isLoading ? _tr('Verifying...', 'Inathibitisha...') : _tr('Verify & Continue', 'Thibitisha na Endelea')),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() => _otpSent = false),
                                    child: Text(
                                      _tr('Change Number', 'Badili Namba'),
                                      style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _tr("Don't have an account?", 'Huna akaunti?'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRouter.registerPath),
                        child: Text(
                          _tr('Join Mali Up', 'Jiunge na Mali Up'),
                          style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
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
      width: 65,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary),
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

