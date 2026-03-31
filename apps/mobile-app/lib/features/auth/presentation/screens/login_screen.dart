import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';

import 'package:firebase_auth/firebase_auth.dart';

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
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  
  final TextEditingController _phoneController = TextEditingController(text: '0653520829');
  final List<TextEditingController> _otpControllers = List.generate(4, (i) => TextEditingController(text: '9015'[i]));

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
            await _auth.signInWithCredential(credential);
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
      await _auth.signInWithCredential(credential);
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  const Center(child: MaliUpLogo(size: 80)),
                  const SizedBox(height: 80),

                  Text(
                    _otpSent ? 'Verification' : 'Welcome to Mali Up',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _otpSent 
                      ? 'We sent a code to +255 ${_phoneController.text}' 
                      : 'Enter your phone number to manage your business',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (!_otpSent) ...[
                    // Phone Input Section
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
                              Text('🇹🇿', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text('+255', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _sendOTP,
                      child: const Text('Send Code'),
                    ),
                  ] else ...[
                    // OTP Input Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) => _OTPBox(controller: _otpControllers[index])),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _verifyOTP,
                      child: const Text('Verify & Continue'),
                    ),
                    const SizedBox(height: 24),
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

