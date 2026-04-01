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

// Notification helper for success/error messages
class _NotificationHelper {
  static Future<void> showSuccess(BuildContext context, String message) async {
    _showNotification(context, message, AppColors.success, Icons.check_circle_outline_rounded);
  }

  static Future<void> showError(BuildContext context, String message) async {
    _showNotification(context, message, AppColors.error, Icons.error_outline_rounded);
  }

  static Future<void> showInfo(BuildContext context, String message) async {
    _showNotification(context, message, AppColors.info, Icons.info_outline_rounded);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _sendLoginLinkToEmail() async {
    final email = _recoveryEmailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      await _NotificationHelper.showError(context, 'Please enter your recovery email');
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
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Recover via Email'),
          content: TextField(
            controller: _recoveryEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your recovery email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendLoginLinkToEmail();
              },
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty || phone.length != 9) {
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
      case 'invalid-api-key':
        return 'API configuration error. Please contact support.';
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
        await _NotificationHelper.showError(context, 'Please enter all 4 digits of the OTP');
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
            icon: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(child: MaliUpLogo(size: 60)),
              const SizedBox(height: 40),

              // --- Header Text ---
              Text(
                _otpSent ? 'Enter Code' : 'Welcome Back',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _otpSent 
                  ? 'We sent a 4-digit code to +255 ${_phoneController.text}' 
                  : 'Login to your ${_selectedAccountType.value} account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // --- Account Type Switcher ---
              AccountTypeSwitcher(
                selectedType: _selectedAccountType,
                onChanged: _onAccountTypeChanged,
              ),
              const SizedBox(height: 32),

              // --- Animated Form Body ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isLoading
                    ? const Center(key: ValueKey('loader'), child: CircularProgressIndicator())
                    : _otpSent
                        ? _buildOtpForm(key: const ValueKey('otpForm'))
                        : _buildPhoneForm(key: const ValueKey('phoneForm')),
              ),
              
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
          decoration: InputDecoration(
            hintText: '7xx xxx xxx',
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇹🇿', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text('+255', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _sendOTP,
          child: const Text('Send Code'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _showEmailRecoveryDialog,
            child: const Text(
              'Use email instead',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpForm({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => _OTPBox(controller: _otpControllers[index])),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _verifyOTP,
          child: const Text('Verify & Continue'),
        ),
        const SizedBox(height: 16),
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
    );
  }

  Widget _buildFooter() {
    return Row(
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
    );
  }
}

class _OTPBox extends StatelessWidget {
  final TextEditingController controller;
  const _OTPBox({required this.controller});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 70,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.secondary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}

