import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
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
  const LoginScreen({super.key});

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
  String? _verificationId;
  
  final TextEditingController _phoneController = TextEditingController(text: '0653520829');
  final TextEditingController _recoveryEmailController = TextEditingController();
  final TextEditingController _emailOtpController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (i) => TextEditingController(text: '9015'[i]));
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _language = LocalizationService.languageNotifier.value;
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
      }
    } on FirebaseAuthException catch (e) {
      final message = _tr('Could not send email OTP: ${e.message ?? e.code}', 'Imeshindikana kutuma OTP ya barua pepe: ${e.message ?? e.code}');
      if (mounted) {
        await _NotificationHelper.showError(context, message);
      }
    } catch (e) {
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('Unexpected error: ${e.toString()}', 'Hitilafu isiyotarajiwa: ${e.toString()}'));
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
      if (!doc.exists) {
        await _NotificationHelper.showError(context, _tr('OTP not found. Request a new OTP.', 'OTP haijapatikana. Omba OTP mpya.'));
        return;
      }

      final data = doc.data()!;
      final savedCode = data['code'] as String?;
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      final isExpired = expiresAt == null || DateTime.now().isAfter(expiresAt);

      if (isExpired) {
        await _NotificationHelper.showError(context, _tr('OTP expired. Request a new one.', 'OTP imekwisha muda. Omba nyingine.'));
        return;
      }

      if (savedCode != code) {
        await _NotificationHelper.showError(context, _tr('Invalid OTP code.', 'Namba ya OTP si sahihi.'));
        return;
      }

      await _firestore.collection('email_otp_auth').doc(email).delete();
      if (mounted) {
        await _NotificationHelper.showSuccess(context, _tr('Email OTP verified.', 'OTP ya barua pepe imethibitishwa.'));
        context.go(AppRouter.dashboardPath);
      }
    } catch (e) {
      await _NotificationHelper.showError(context, _tr('Failed to verify email OTP.', 'Imeshindikana kuthibitisha OTP ya barua pepe.'));
    }
  }

  Future<void> _showEmailRecoveryDialog() async {
    bool isSending = false;
    bool otpSent = false;
    await showDialog<void>(
      context: context,
      builder: (context) {
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
                  onPressed: isSending ? null : () => Navigator.of(context).pop(),
                  child: Text(_tr('Cancel', 'Ghairi')),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setDialogState(() => isSending = true);
                          if (!otpSent) {
                            await _sendEmailOtpCode();
                            if (mounted) {
                              setDialogState(() {
                                otpSent = true;
                                isSending = false;
                              });
                            }
                            return;
                          }
                          await _verifyEmailOtpAndContinue();
                          if (mounted) Navigator.of(context).pop();
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
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) context.go(AppRouter.dashboardPath);
              });
            }
          } catch (e) {
            if (mounted) {
              await _NotificationHelper.showError(context, _tr('Sign in failed: ${e.toString()}', 'Kuingia kumeshindikana: ${e.toString()}'));
              setState(() => _isLoading = false);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) setState(() => _isLoading = false);
          String errorMessage = _getFirebaseErrorMessage(e.code);
          if (mounted) {
            _NotificationHelper.showError(context, errorMessage);
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
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        await _NotificationHelper.showError(context, _tr('Error: ${e.toString()}', 'Hitilafu: ${e.toString()}'));
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
          // Minimalist Background Accents
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
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
                  const SizedBox(height: 36),

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
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _sendOTP,
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
                                ElevatedButton(
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

