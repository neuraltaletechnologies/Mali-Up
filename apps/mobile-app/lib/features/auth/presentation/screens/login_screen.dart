import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_type.dart';
import '../widgets/account_type_switcher.dart';

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
                    color: AppColors.primary.withOpacity(0.18),
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
  AccountType _selectedAccountType = AccountType.business;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  
  final TextEditingController _phoneController = TextEditingController(text: '0653520829');
  final TextEditingController _recoveryEmailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (i) => TextEditingController(text: '9015'[i]));
  final FocusNode _phoneFocusNode = FocusNode();

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _sendLoginLinkToEmail() async {
    final email = _recoveryEmailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      await _NotificationHelper.showError(context, 'Please enter your Email');
      return;
    }

    if (!_isValidEmail(email)) {
      await _NotificationHelper.showError(context, 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://maliup.page.link/login',
        handleCodeInApp: true,
        androidPackageName: 'com.neuraltale.maliup',
        androidInstallApp: true,
        iOSBundleId: 'com.neuraltale.maliup',
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_for_sign_in', email);

      if (mounted) {
        await _NotificationHelper.showSuccess(
          context,
          'Login link sent to $email. Check your inbox.',
        );
      }
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-email' => 'This email is invalid.',
        'missing-continue-uri' => 'Email login setup is incomplete (missing continue URL).',
        'unauthorized-continue-uri' => 'Continue URL is not authorized in Firebase.',
        'operation-not-allowed' => 'Email link sign-in is not enabled in Firebase.',
        _ => 'Could not send email login link: ${e.message ?? e.code}',
      };
      if (mounted) {
        await _NotificationHelper.showError(context, message);
      }
    } catch (e) {
      if (mounted) {
        await _NotificationHelper.showError(context, 'Unexpected error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEmailRecoveryDialog() async {
    bool isSending = false;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Recover With Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'If you no longer have your phone number, we can send a secure login link to your email.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  _GlowTextField(
                    controller: _recoveryEmailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setDialogState(() => isSending = true);
                          await _sendLoginLinkToEmail();
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
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
                      Text(isSending ? 'Sending...' : 'Send OPT'),
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
        await _NotificationHelper.showError(context, 'Please enter your phone number');
      }
      return;
    }
    
    if (phone.length != 9) {
      if (mounted) {
        await _NotificationHelper.showError(context, 'Phone number must be 9 digits');
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
            final userCredential = await _auth.signInWithCredential(credential);
            final user = userCredential.user;
            if (user != null) {
              await _persistAccountType(user.uid);
            }
            if (mounted) {
              await _NotificationHelper.showSuccess(context, 'Authentication successful!');
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) context.go(AppRouter.dashboardPath);
              });
            }
          } catch (e) {
            if (mounted) {
              await _NotificationHelper.showError(context, 'Sign in failed: ${e.toString()}');
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
        return 'Invalid phone number format';
      case 'missing-client-identifier':
        return 'API configuration error. Please contact support.';
      case 'invalid-api-key':
        return 'API key not configured. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'app-not-authorized':
        return 'App not authorized for phone authentication';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Verification failed: $errorCode. Please try again.';
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
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _persistAccountType(user.uid);
      }
      if (mounted) {
        await _NotificationHelper.showSuccess(context, 'Verification successful!');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go(AppRouter.dashboardPath);
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = e.code == 'invalid-verification-code'
          ? 'Invalid OTP. Please check and try again.'
          : 'Verification failed: ${e.message}';
      if (mounted) {
        await _NotificationHelper.showError(context, errorMessage);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        await _NotificationHelper.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  Future<void> _persistAccountType(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'defaultAccountType': _selectedAccountType.value,
      'accountTypes': FieldValue.arrayUnion([_selectedAccountType.value]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_account_type', _selectedAccountType.value);
  }

  void _onAccountTypeChanged(AccountType accountType) {
    setState(() {
      _selectedAccountType = accountType;
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
    _NotificationHelper.showInfo(
      context,
      'Customer number loaded: +$_customerPhoneWithCountryCode',
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _recoveryEmailController.dispose();
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
                color: AppColors.primary.withOpacity(0.05),
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
                  icon: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.secondary,
                  ),
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
                    _otpSent ? 'Verification' : 'Welcome to Mali Up',
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
                      ? 'We sent a code to +255 ${_phoneController.text}' 
                      : _selectedAccountType == AccountType.business
                          ? 'Enter your phone number to manage your business'
                          : 'Enter your phone number to manage your wealth',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AccountTypeSwitcher(
                    selectedType: _selectedAccountType,
                    onChanged: _onAccountTypeChanged,
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
                                  key: const ValueKey('phone-step'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Phone Number',
                                      style: TextStyle(
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
                                      decoration: InputDecoration(
                                        hintText: '7xx xxx xxx',
                                        prefixIcon: const Padding(
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
                                          Text(_isLoading ? 'Sending OTP...' : 'Send OTP'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _showEmailRecoveryDialog,
                                        child: const Text(
                                          'Don\'t have my phone number',
                                          style: TextStyle(
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
                                    const Text(
                                      'Enter OTP Code',
                                      style: TextStyle(
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
                                          Text(_isLoading ? 'Verifying...' : 'Verify & Continue'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Center(
                                      child: TextButton(
                                        onPressed: () => setState(() => _otpSent = false),
                                        child: const Text(
                                          'Change Number',
                                          style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
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
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRouter.registerPath),
                        child: const Text(
                          'Join Mali Up',
                          style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
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

