import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());

  Future<void> _sendRegistrationOTP() async {
    if (_businessNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter business name')));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      },
      codeSent: (String vid, int? resendToken) {
        setState(() {
          _verificationId = vid;
          _otpSent = true;
          _isLoading = false;
        });
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
        // Create Tenant Document
        await _firestore.collection('tenants').doc(user.uid).set({
          'businessName': _businessNameController.text.trim(),
          'ownerPhone': user.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'plan': 'Trial',
        });
        
        if (mounted) context.go(AppRouter.dashboardPath);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  const Center(child: MaliUpLogo(size: 80)),
                  const SizedBox(height: 80),

              Text(
                _otpSent ? 'Verify Phone' : 'Manage Your Business',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.secondary),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent ? 'Enter code sent to ${_phoneController.text}' : 'Join thousands of businesses managing with Mali Up',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 48),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (!_otpSent) ...[
                const Text('Business Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(hintText: 'e.g. Neuraltale Tech', prefixIcon: Icon(Icons.business_rounded)),
                ),
                const SizedBox(height: 24),
                const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '7xx xxx xxx',
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇹🇿', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('+255', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(onPressed: _sendRegistrationOTP, child: const Text('Create Account')),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (i) => _OTPBox(controller: _otpControllers[i])),
                ),
                const SizedBox(height: 48),
                ElevatedButton(onPressed: _verifyAndRegister, child: const Text('Verify & Finish')),
              ],

              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Already have an account? Sign In', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
      child: Center(child: TextField(controller: controller, textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(counterText: "", border: InputBorder.none))),
    );
  }
}

