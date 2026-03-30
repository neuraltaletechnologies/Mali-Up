import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';

import 'package:firebase_auth/firebase_auth.dart';

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
  
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);
    final phone = '+255${_phoneController.text.trim()}';
    
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        if (mounted) context.go(AppRouter.dashboardPath);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verification failed')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);
    final smsCode = _otpControllers.map((c) => c.text).join();
    
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      if (mounted) context.go(AppRouter.dashboardPath);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
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

