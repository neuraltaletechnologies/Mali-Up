import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEV BYPASS — set to true to skip real SMS OTP during development.
// Automatically has no effect in release builds (kDebugMode == false).
// Dev OTP code: 9015  |  Any phone number is accepted.
// ─────────────────────────────────────────────────────────────────────────────
const bool _kDevBypassOtp = true;  // flip to false to test real Firebase flow
const String _kDevOtpCode = '9015'; // must match controller pre-fill below

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
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? hintText;
  final Widget? prefixIcon;

  const _GlowTextField({
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.hintText,
    this.prefixIcon,
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
          decoration: InputDecoration(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();

    // Validate phone number
    if (phone.isEmpty) {
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('Quick check, this field is still empty.', 'Ukaguzi wa haraka, sehemu hii bado iko wazi.'));
      }
      return;
    }

    if (phone.length != 9) {
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('That number looks off. Please check and try again.', 'Namba hiyo inaonekana si sahihi. Tafadhali hakiki kisha ujaribu tena.'));
      }
      return;
    }

    // ── DEV BYPASS ──────────────────────────────────────────────────────────
    // In debug builds with _kDevBypassOtp enabled, skip the real Firebase
    // SMS call and immediately show the OTP entry screen pre-filled with
    // the dev code. No network call is made.
    if (kDebugMode && _kDevBypassOtp) {
      setState(() {
        _otpSent = true;
        _isLoading = false;
        _verificationId = '__dev_bypass__';
      });
      if (mounted) {
        _NotificationHelper.showInfo(
          context,
          _tr(
            '🛠 Dev mode: Enter $_kDevOtpCode to bypass OTP.',
            '🛠 Hali ya Maendeleo: Weka $_kDevOtpCode kupita OTP.',
          ),
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
    final fullPhone = '+255$phone';
    
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (mounted) {
              await _NotificationHelper.showSuccess(context, _tr('All set. Let\'s get to work.', 'Kila kitu kiko sawa. Twende kazini.'));
              _setFeedback(_tr('All set. Let\'s get to work.', 'Kila kitu kiko sawa. Twende kazini.'), EmotionalStatusTone.success);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) context.go(AppRouter.dashboardPath);
              });
            }
          } catch (e) {
            if (mounted) {
              await _NotificationHelper.showError(context, _tr('We could not sign you in automatically: ${e.toString()}', 'Hatukuweza kukuingiza kiotomatiki: ${e.toString()}'));
              _setFeedback(_tr('Automatic sign-in was not completed yet.', 'Uingizaji wa kiotomatiki haujakamilika bado.'), EmotionalStatusTone.error);
              setState(() => _isLoading = false);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) setState(() => _isLoading = false);
          String errorMessage = _getFirebaseErrorMessage(e.code);
          if (mounted) {
            _NotificationHelper.showError(context, errorMessage);
            _setFeedback(_tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.'), EmotionalStatusTone.error);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
            _NotificationHelper.showSuccess(context, _tr('A verification code was sent to $fullPhone', 'OTP wa uthibitisho umetumwa kwa $fullPhone'));
            _setFeedback(_tr('Code sent. Check your messages.', 'OTP umetumwa. Angalia ujumbe wako.'), EmotionalStatusTone.success);
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
        await _NotificationHelper.showError(context, _tr('We\'re having trouble connecting. Check internet and try again.', 'Tunapata shida ya muunganisho. Angalia intaneti kisha ujaribu tena.'));
        _setFeedback(_tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.'), EmotionalStatusTone.warning);
      }
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return _tr('That number looks off. Please check and try again.', 'Namba hiyo inaonekana si sahihi. Tafadhali hakiki kisha ujaribu tena.');
      case 'missing-client-identifier':
        return _tr('API configuration error. Please contact support.', 'Hitilafu ya mpangilio wa API. Wasiliana na msaada.');
      case 'invalid-api-key':
        return _tr('API key not configured. Please contact support.', 'API key haijapangwa. Wasiliana na msaada.');
      case 'too-many-requests':
        return _tr('Let\'s pause for a bit, then try again.', 'Tusimame kidogo, kisha ujaribu tena.');
      case 'app-not-authorized':
        return _tr('App not authorized for phone authentication', 'App haijaidhinishwa kwa uthibitisho wa simu');
      case 'operation-not-allowed':
        return _tr('Phone verification setup still needs attention.', 'Mipangilio ya uthibitisho wa simu bado inahitaji marekebisho.');
      case 'network-request-failed':
        return _tr('We\'re having trouble connecting. Check internet and try again.', 'Tunapata shida ya muunganisho. Angalia intaneti kisha ujaribu tena.');
      default:
        return _tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.');
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
      await _sendOTP();
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

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
        await _NotificationHelper.showError(context, _tr('Please enter all 4 digits.', 'Tafadhali weka tarakimu zote 4.'));
      }
      return;
    }

    // ── DEV BYPASS ──────────────────────────────────────────────────────────
    // Skip Firebase credential check in debug builds. Accept the dev code
    // and navigate directly to the dashboard.
    if (kDebugMode && _kDevBypassOtp && _verificationId == '__dev_bypass__') {
      if (smsCode != _kDevOtpCode) {
        setState(() => _isLoading = false);
        if (mounted) {
          await _NotificationHelper.showError(
            context,
            _tr(
              '🛠 Dev mode: Wrong code. Use $_kDevOtpCode.',
              '🛠 Hali ya Maendeleo: OTP si sahihi. Tumia $_kDevOtpCode.',
            ),
          );
        }
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dev_bypass_session', true);
      if (mounted) {
        await _NotificationHelper.showSuccess(
          context,
          _tr('🛠 Dev bypass — entering app.', '🛠 Dev bypass — unaingia kwenye app.'),
        );
        _setFeedback(_tr('All set. Let\'s get to work.', 'Kila kitu kiko sawa. Twende kazini.'), EmotionalStatusTone.success);
        _triggerSuccessBurst();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go(AppRouter.dashboardPath);
        });
      }
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      if (mounted) {
        await _NotificationHelper.showSuccess(context, _tr('All set. Let\'s get to work.', 'Kila kitu kiko sawa. Twende kazini.'));
        _setFeedback(_tr('All set. Let\'s get to work.', 'Kila kitu kiko sawa. Twende kazini.'), EmotionalStatusTone.success);
        _triggerSuccessBurst();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go(AppRouter.dashboardPath);
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = e.code == 'invalid-verification-code'
          ? _tr('Not quite. Re-enter the code and continue.', 'Bado. Weka tena OTP kisha endelea.')
          : _tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.');
      if (mounted) {
        await _NotificationHelper.showError(context, errorMessage);
        _setFeedback(_tr('Not quite. Re-enter the code and continue.', 'Bado. Weka tena OTP kisha endelea.'), EmotionalStatusTone.error);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.'));
        _setFeedback(_tr('Something didn\'t go as planned. Please try again.', 'Kitu hakikuenda kama tulivyotarajia. Tafadhali jaribu tena.'), EmotionalStatusTone.warning);
      }
    }
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
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
                Container(
                  color: AppColors.secondary,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                      child: Lottie.asset(
                        'assets/lottie/Login.json',
                        fit: BoxFit.contain,
                        repeat: true,
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
                        _otpSent ? _tr('Verify OTP', 'Thibitisha OTP') : _tr('Login to Mali App', 'Ingia Mali App'),
                        textAlign: TextAlign.center,
                        style: headingStyle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _otpSent
                            ? _tr('We sent a code to your number. Enter the 4 digits to continue.', 'Tumetuma msimbo kwa namba yako. Weka tarakimu 4 kuendelea.')
                            : _tr('Welcome back. Enter your phone number to continue securely.', 'Karibu tena. Weka namba yako ya simu ili kuendelea salama.'),
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
                            _tr('Your transactions are protected with secure encryption.', 'Miamala yako inalindwa kwa usimbaji salama.'),
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
                          Text(_tr('Account Details', 'Taarifa za Akaunti'), style: sectionTitleStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                            _isLoading ? _tr('Sending...', 'Inatuma...') : _tr('Send OTP', 'Tuma OTP'),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: textPrimary),
                          const SizedBox(width: 8),
                          Text(_tr('Enter the 4-digit OTP', 'Weka OTP ya tarakimu 4'), style: sectionTitleStyle),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) => _OTPBox(controller: _otpControllers[index])),
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
                          onPressed: _isLoading ? null : _verifyOTP,
                          child: Text(
                            _isLoading ? _tr('Verifying...', 'Inathibitisha...') : _tr('Login', 'Ingia'),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _otpSent = false),
                          child: Text(_tr('Use another phone number', 'Tumia namba nyingine'), style: GoogleFonts.poppins(color: textSecondary)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_tr('No account? ', 'Huna akaunti? '), style: GoogleFonts.poppins(color: textSecondary)),
                        TextButton(
                          onPressed: () => context.push(AppRouter.registerPath),
                          child: Text(
                            _tr('Register', 'Jisajili'),
                            style: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w700),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.secondary),
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

